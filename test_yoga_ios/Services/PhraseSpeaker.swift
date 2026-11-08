//
//  PhraseSpeaker.swift
//  test_yoga_ios
//

import AVFoundation

/// Speaks practice phrases one after another in the natural voice, using the
/// device voice for any phrase whose recording isn't on the device in time
final class PhraseSpeaker {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var task: Task<Void, Never>?
    /// What's being said and what was just said where the microphone can hear it,
    /// so voice commands can tell this voice from the user's
    private var currentPhrase: String?
    private var previousPhrase: (text: String, endedAt: ContinuousClock.Instant)?

    /// While voice commands are on, recordings play through their audio, so the microphone
    /// can take this voice out of what it hears
    weak var voiceCommands: VoiceCommandService?

    /// Whether `word` is in what's being said, or what was said in the last 2 seconds
    /// (speech recognition can take that long to report a word)
    func isSaying(_ word: String) -> Bool {
        var recent = [currentPhrase]
        if let previousPhrase, ContinuousClock.now - previousPhrase.endedAt < .seconds(2) {
            recent.append(previousPhrase.text)
        }
        return recent.compactMap { $0 }.contains { phrase in
            phrase.lowercased().split(whereSeparator: { !$0.isLetter }).contains(Substring(word))
        }
    }

    /// Replaces whatever is being spoken
    func speak(_ phrases: [String]) {
        stop()
        task = Task { [weak self] in
            for (index, phrase) in phrases.enumerated() {
                // A short pause between phrases so they don't run together
                if index > 0 {
                    try? await Task.sleep(for: .milliseconds(500))
                }
                guard let self, !Task.isCancelled else { return }
                await self.play(phrase)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        player?.stop()
        player = nil
        voiceCommands?.stopAppSpeech()
        synthesizer.stopSpeaking(at: .immediate)
        finishPhrase()
    }

    private func finishPhrase() {
        guard let currentPhrase else { return }
        previousPhrase = (currentPhrase, .now)
        self.currentPhrase = nil
    }

    private func play(_ phrase: String) async {
        // Wait a moment for a recording that's still downloading, so the voice doesn't keep switching
        let clip = await SpeechClipService.shared.clip(for: phrase, timeout: .seconds(4))
        guard !Task.isCancelled else { return }
        var startAt: TimeInterval = 0
        if let clip, let voiceCommands {
            // The microphone doesn't hear it this way, so it isn't tracked in currentPhrase
            switch await voiceCommands.playAppSpeech(clip, volume: 0.8) {
            case .finished:
                return
            case .stopped(let time):
                // Carry on from there the usual way
                startAt = time
            case .unavailable:
                break
            }
            guard !Task.isCancelled else { return }
        }

        currentPhrase = phrase
        // stop() has already finished a cancelled phrase, and a newer one may have started since
        defer { if !Task.isCancelled { finishPhrase() } }
        if let clip, let player = try? AVAudioPlayer(contentsOf: clip) {
            self.player = player
            player.volume = 0.8
            player.currentTime = startAt
            player.play()
            // A change to the audio settings (like voice commands turning on) pauses the recording
            // partway; carry on from there rather than skipping the rest of the phrase
            var resumes = 0
            while !Task.isCancelled {
                if player.isPlaying {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }
                guard player.currentTime > 0, player.duration - player.currentTime > 0.1, resumes < 3 else { break }
                resumes += 1
                print("[PhraseSpeaker] resuming after an interruption")
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { break }
                player.play()
            }
            return
        }

        guard !Task.isCancelled else { return }
        // Record it for next time
        await SpeechClipService.shared.prefetch([phrase])
        synthesizer.speak(Self.deviceUtterance(phrase))
        while synthesizer.isSpeaking && !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private static func deviceUtterance(_ phrase: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        // Pick the highest-quality installed en-US voice (premium > enhanced > default).
        // If none found, utterance.voice stays nil → system default, still speaks.
        utterance.voice = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "en-US" }
            .max(by: { $0.quality.rawValue < $1.quality.rawValue })
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 0.8
        return utterance
    }
}
