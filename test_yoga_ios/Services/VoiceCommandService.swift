//
//  VoiceCommandService.swift
//  test_yoga_ios
//
//  Created by Claude on 3/12/26.
//

import AVFoundation
import Speech
import Observation

enum VoiceCommand {
    case next
    case previous
    case pause
    case resume
}

/// Listens for a few command words during practice. Speech is understood on the device
/// and is never recorded, saved, or sent anywhere.
@Observable
@MainActor
final class VoiceCommandService {

    var isListening = false
    var onCommand: ((VoiceCommand) -> Void)?
    /// Whether the app itself is saying a word right now (like "back" in a cue), so the
    /// microphone picking up the app's voice doesn't trigger commands
    var isAppSpeech: ((String) -> Bool)?

    private static let commandWords: [String: VoiceCommand] = [
        "next": .next, "forward": .next,
        "back": .previous, "previous": .previous,
        "pause": .pause, "stop": .pause, "hold": .pause,
        "play": .resume, "resume": .resume, "continue": .resume,
    ]
    /// What speech recognition sometimes writes for a command word said from across a room.
    /// Not given to the recognizers as words to expect, so they don't start hearing these instead
    private static let soundAlikes: [String: VoiceCommand] = [
        "necks": .next, "nex": .next,
        "bach": .previous,
        "paws": .pause, "paused": .pause,
        "resumed": .resume,
    ]
    private static let locale = Locale(identifier: "en-US")

    private var audioEngine = AVAudioEngine()
    /// Plays the app's own speech through the same audio as the microphone, so voice
    /// processing can take it out of what the microphone hears
    private let speechPlayer = AVAudioPlayerNode()
    private static let speechFormat = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    private let microphone = MicrophoneSink()
    private var observers: [NSObjectProtocol] = []
    /// Bumped on every start and stop, so work from an earlier session is ignored
    private var sessionGeneration = 0

    private var lastCommandTime: Date = .distantPast
    private let debounceDuration: TimeInterval = 0.8

    // Apple's newer on-device model (iOS 26), used once it's downloaded
    private var analyzer: SpeechAnalyzer?
    private var analyzerFeeder: AnalyzerFeeder?
    private var resultsTask: Task<Void, Never>?
    /// How many of each command have been acted on (or ignored because the app said them) in the speech
    /// the model is still working on, so its updated guesses don't act on the same words again
    private var handledInSegment: [VoiceCommand: Int] = [:]

    // The older recognizer, used until the newer model is on the device
    private let legacyRecognizer = SFSpeechRecognizer(locale: VoiceCommandService.locale)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var processedWordCount = 0
    /// Times in a row the recognizer failed right after starting, like when its model is missing
    private var quickFailures = 0

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    // MARK: - Start / Stop

    /// Returns false if voice commands can't run on this device right now
    func start() async -> Bool {
        guard !isListening else { return true }
        sessionGeneration += 1
        let generation = sessionGeneration
        isListening = true

        let started: Bool
        if await startAnalyzer(generation: generation) {
            started = true
        } else if generation == sessionGeneration {
            started = startLegacyRecognizer()
        } else {
            return false
        }
        guard generation == sessionGeneration else { return false }

        do {
            guard started else { throw VoiceCommandError.noOnDeviceRecognizer }
            try await configureAudioSession()
            guard generation == sessionGeneration else { return false }
            try installEngineAndStart()
            registerObservers()
            return true
        } catch {
            print("[VoiceCommand] start failed: \(error)")
            stop()
            return false
        }
    }

    func stop() {
        sessionGeneration += 1
        isListening = false
        unregisterObservers()
        microphone.setReceiver(nil)

        resultsTask?.cancel()
        resultsTask = nil
        analyzerFeeder?.finish()
        analyzerFeeder = nil
        if let analyzer {
            Task { await analyzer.cancelAndFinishNow() }
        }
        analyzer = nil
        handledInSegment = [:]

        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        processedWordCount = 0
        quickFailures = 0

        speechPlayer.stop()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        // Back to practice's playback settings, which play alongside the user's music instead of stopping it
        AudioSessionQueue.enqueue { session in
            try? session.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Engine management

    private func configureAudioSession() async throws {
        try await AudioSessionQueue.perform { session in
            // Bluetooth speakers and headphones keep playing while the iPhone's microphone listens,
            // rather than everything moving to the iPhone's speaker, right next to the microphone
            try session.setCategory(.playAndRecord, options: [.mixWithOthers, .duckOthers, .defaultToSpeaker, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }
    }

    private func installEngineAndStart() throws {
        let input = audioEngine.inputNode
        // Voice processing takes what this engine plays (the app's speech) out of what the microphone
        // hears. It can't do that for other sound, like music, so it turns that down instead, only
        // while someone is speaking, which also makes the user's commands easier to hear
        do {
            if !input.isVoiceProcessingEnabled {
                try input.setVoiceProcessingEnabled(true)
            }
            input.voiceProcessingOtherAudioDuckingConfiguration = .init(enableAdvancedDucking: true, duckingLevel: .mid)
        } catch {
            print("[VoiceCommand] voice processing unavailable: \(error)")
        }
        if speechPlayer.engine == nil {
            audioEngine.attach(speechPlayer)
            audioEngine.connect(speechPlayer, to: audioEngine.mainMixerNode, format: Self.speechFormat)
        }
        input.removeTap(onBus: 0)
        let microphone = self.microphone
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { @Sendable buffer, _ in
            microphone.receive(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    /// Called whenever the engine has stopped unexpectedly while we should be listening.
    /// Retries up to 6 times with a 700 ms delay between attempts, which gives
    /// AVSpeechSynthesizer / system sounds time to release the audio session
    /// before we try setActive(true) again (avoiding the !pri / 561017449 error).
    private func restartEngine(attempt: Int = 0) {
        guard isListening, !audioEngine.isRunning else { return }
        let generation = sessionGeneration
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.configureAudioSession()
                // Voice commands may have stopped, or the engine started elsewhere, in the meantime
                guard self.sessionGeneration == generation, !self.audioEngine.isRunning else { return }
                try self.installEngineAndStart()
            } catch {
                print("[VoiceCommand] engine restart failed (attempt \(attempt + 1)): \(error)")
                guard attempt < 5 else { return }
                try? await Task.sleep(for: .milliseconds(700))
                guard self.sessionGeneration == generation else { return }
                self.restartEngine(attempt: attempt + 1)
            }
        }
    }

    // MARK: - Notifications

    private func registerObservers() {
        // AVSpeechSynthesizer and system sounds (playChime) can trigger interruptions
        // or cause the engine configuration to change. Handle both.
        let interruptionObs = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] note in
            Task { @MainActor [weak self] in self?.handleInterruption(note) }
        }

        // Fires when AVAudioEngine stops due to audio hardware/session changes.
        let configObs = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.restartEngine() }
        }

        observers = [interruptionObs, configObs]
    }

    private func unregisterObservers() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
    }

    private func handleInterruption(_ note: Notification) {
        guard isListening,
              let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                .flatMap(AVAudioSession.InterruptionType.init) else { return }
        if type == .ended {
            restartEngine()
        }
    }

    // MARK: - Newer on-device model

    /// Starts Apple's newer speech model if it's on the device; otherwise starts downloading it for next time
    private func startAnalyzer(generation: Int) async -> Bool {
        guard SpeechTranscriber.isAvailable,
              let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Self.locale) else { return false }

        // Fast, word-by-word guesses as the user speaks
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults, .fastResults],
            attributeOptions: []
        )

        guard await AssetInventory.status(forModules: [transcriber]) == .installed else {
            Task.detached {
                do {
                    try await AssetInventory.assetInstallationRequest(supporting: [transcriber])?.downloadAndInstall()
                } catch {
                    print("[VoiceCommand] speech model download failed: \(error)")
                }
            }
            return false
        }

        do {
            guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else { return false }
            let analyzer = SpeechAnalyzer(modules: [transcriber], options: .init(priority: .userInitiated, modelRetention: .lingering))
            let context = AnalysisContext()
            // Priming the model with the command words helps it pick them out
            context.contextualStrings[.general] = Array(Self.commandWords.keys)
            try await analyzer.setContext(context)
            try await analyzer.prepareToAnalyze(in: format)

            let (inputs, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
            try await analyzer.start(inputSequence: inputs)
            guard generation == sessionGeneration else {
                continuation.finish()
                await analyzer.cancelAndFinishNow()
                return false
            }

            let feeder = AnalyzerFeeder(format: format, continuation: continuation)
            microphone.setReceiver { @Sendable buffer in feeder.feed(buffer) }
            self.analyzer = analyzer
            analyzerFeeder = feeder
            resultsTask = Task { [weak self] in
                do {
                    for try await result in transcriber.results {
                        self?.handle(result)
                    }
                } catch {
                    print("[VoiceCommand] speech model stopped: \(error)")
                }
                // Stopped on its own rather than by stop(), so voice commands show as off
                if let self, self.sessionGeneration == generation {
                    self.stop()
                }
            }
            print("[VoiceCommand] listening with the on-device speech model")
            return true
        } catch {
            print("[VoiceCommand] speech model unavailable: \(error)")
            return false
        }
    }

    private func handle(_ result: SpeechTranscriber.Result) {
        let isFinal = CMTimeCompare(result.range.end, result.resultsFinalizationTime) <= 0
        #if DEBUG
        // Only in builds from Xcode, to see what was misheard and how long it took
        let behind = (analyzerFeeder?.audioSeconds ?? 0) - result.range.end.seconds
        print("[VoiceCommand] heard\(isFinal ? "" : " (so far)") at \(String(format: "%.1f", result.range.start.seconds))s, \(String(format: "%.1f", behind))s behind: \(String(result.text.characters))")
        #endif
        // Each guess repeats the words of the guesses before it, so only act on the ones beyond those
        var counts: [VoiceCommand: Int] = [:]
        for word in Self.words(in: String(result.text.characters)) {
            guard let command = Self.command(for: word) else { continue }
            counts[command, default: 0] += 1
            guard counts[command, default: 0] > handledInSegment[command, default: 0] else { continue }
            handledInSegment[command] = counts[command]
            fire(command, word: word)
        }
        if isFinal {
            // Done with this speech. Commands acted on that aren't in its final words (like when the
            // model finishes the speech in two parts) carry over, so they aren't acted on again
            handledInSegment = handledInSegment.reduce(into: [:]) { leftover, handled in
                let remaining = handled.value - counts[handled.key, default: 0]
                if remaining > 0 { leftover[handled.key] = remaining }
            }
        }
    }

    // MARK: - The app's own speech

    /// How playing the app's speech through voice commands' audio went
    enum AppSpeechPlayback {
        case finished
        /// Stopped partway, like when the audio settings changed, so the rest can be played another way
        case stopped(at: TimeInterval)
        /// Voice commands aren't running, or the recording couldn't be read
        case unavailable
    }

    /// Plays a recording of the app's speech where the microphone's voice processing can take it out
    /// of what the microphone hears, so it isn't mistaken for the user and doesn't drown them out
    func playAppSpeech(_ clip: URL, volume: Float) async -> AppSpeechPlayback {
        guard isListening, audioEngine.isRunning, speechPlayer.engine != nil,
              let buffer = Self.buffer(from: clip, in: Self.speechFormat) else { return .unavailable }
        let finished = PlaybackFlag()
        speechPlayer.volume = volume
        speechPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts, completionCallbackType: .dataPlayedBack) { _ in
            finished.set()
        }
        speechPlayer.play()

        var playedFrames: AVAudioFramePosition = 0
        while !Task.isCancelled && !finished.isSet {
            if let nodeTime = speechPlayer.lastRenderTime,
               let playerTime = speechPlayer.playerTime(forNodeTime: nodeTime) {
                playedFrames = max(playedFrames, playerTime.sampleTime)
            }
            if !audioEngine.isRunning || !speechPlayer.isPlaying {
                speechPlayer.stop()
                return .stopped(at: Double(playedFrames) / Self.speechFormat.sampleRate)
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return .finished
    }

    func stopAppSpeech() {
        speechPlayer.stop()
    }

    /// A recording's audio, converted to `format`
    private static func buffer(from url: URL, in format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url),
              let source = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: source)) != nil else { return nil }
        guard let converter = AVAudioConverter(from: source.format, to: format) else { return nil }
        let ratio = format.sampleRate / source.format.sampleRate
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(source.frameLength) * ratio) + 4096) else { return nil }
        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumed {
                status.pointee = .endOfStream
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return source
        }
        return error == nil && output.frameLength > 0 ? output : nil
    }

    // MARK: - Older recognizer

    private func startLegacyRecognizer() -> Bool {
        // Only on-device recognition, so nothing said is sent anywhere
        guard let legacyRecognizer, legacyRecognizer.isAvailable, legacyRecognizer.supportsOnDeviceRecognition else { return false }
        startNewTask(recognizer: legacyRecognizer)
        print("[VoiceCommand] listening with the older on-device recognizer")
        return true
    }

    private func startNewTask(recognizer: SFSpeechRecognizer) {
        let generation = sessionGeneration
        recognitionTask?.cancel()
        processedWordCount = 0

        // If a sound effect or speech synthesis killed the engine, revive it now.
        restartEngine()

        let startedAt = ContinuousClock.now
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        // .search optimizes for short phrases/keywords rather than long dictation.
        request.taskHint = .search
        // Priming the recognizer with expected words improves first-attempt accuracy for these terms.
        request.contextualStrings = Array(Self.commandWords.keys)
        recognitionRequest = request
        microphone.setReceiver { @Sendable buffer in request.append(buffer) }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                // Only the current task; an earlier one may still report that it was cancelled
                guard let self, self.sessionGeneration == generation, self.recognitionRequest === request else { return }
                if let result { self.handleLegacyResult(result) }
                guard error != nil || result?.isFinal == true else { return }
                self.restartLegacyRecognizer(recognizer, failedQuickly: error != nil && ContinuousClock.now - startedAt < .seconds(2), error: error)
            }
        }
    }

    /// Starts a new recognition task after one ends. A recognizer that keeps failing as soon as it
    /// starts is retried a little later each time and then turned off, rather than restarted
    /// hundreds of times a second
    private func restartLegacyRecognizer(_ recognizer: SFSpeechRecognizer, failedQuickly: Bool, error: Error?) {
        guard isListening else { return }
        quickFailures = failedQuickly ? quickFailures + 1 : 0
        guard quickFailures < 3 else {
            print("[VoiceCommand] on-device recognizer isn't working: \(String(describing: error))")
            stop()
            return
        }
        guard quickFailures > 0 else {
            startNewTask(recognizer: recognizer)
            return
        }
        let generation = sessionGeneration
        let delay = Duration.seconds(quickFailures)
        Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard let self, self.sessionGeneration == generation else { return }
            self.startNewTask(recognizer: recognizer)
        }
    }

    private func handleLegacyResult(_ result: SFSpeechRecognitionResult) {
        #if DEBUG
        print("[VoiceCommand] older recognizer heard: \(result.bestTranscription.formattedString)")
        #endif
        let segments = result.bestTranscription.segments
        // When the recognizer revises backwards (segment count shrinks), reset the
        // cursor so we don't get permanently stuck ahead of the real count.
        if segments.count < processedWordCount {
            processedWordCount = segments.count
            return
        }
        guard segments.count > processedWordCount else { return }
        let newWords = segments[processedWordCount...].flatMap { Self.words(in: $0.substring) }
        processedWordCount = segments.count
        for word in newWords {
            if let command = Self.command(for: word) {
                fire(command, word: word)
            }
        }
    }

    // MARK: - Commands

    private static func words(in text: String) -> [String] {
        // "Resumé" counts as "resume"
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
            .split(whereSeparator: { !$0.isLetter })
            .map(String.init)
    }

    private static func command(for word: String) -> VoiceCommand? {
        commandWords[word] ?? soundAlikes[word]
    }

    private func fire(_ command: VoiceCommand, word: String) {
        // Checked after the word is counted as handled, so a word the app said isn't taken
        // as the user's once the app has finished saying it and the guess is updated
        if isAppSpeech?(word) == true {
            print("[VoiceCommand] ignored \"\(word)\": the app is saying it")
            return
        }
        guard Date().timeIntervalSince(lastCommandTime) >= debounceDuration else {
            print("[VoiceCommand] debounced: \(command)")
            return
        }
        lastCommandTime = Date()
        print("[VoiceCommand] command fired: \(command)")
        onCommand?(command)
    }
}

/// Set once a recording has finished playing, from the audio thread
private nonisolated final class PlaybackFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var isSet: Bool { lock.withLock { value } }

    func set() {
        lock.withLock { value = true }
    }
}

nonisolated enum VoiceCommandError: Error {
    case noOnDeviceRecognizer
}

/// Hands microphone audio from the audio thread to whichever recognizer is running
private nonisolated final class MicrophoneSink: @unchecked Sendable {
    private let lock = NSLock()
    private var receiver: (@Sendable (AVAudioPCMBuffer) -> Void)?

    func setReceiver(_ receiver: (@Sendable (AVAudioPCMBuffer) -> Void)?) {
        lock.withLock { self.receiver = receiver }
    }

    func receive(_ buffer: AVAudioPCMBuffer) {
        lock.withLock { receiver }?(buffer)
    }
}

/// Converts microphone audio to the format the speech model expects and passes it on
private nonisolated final class AnalyzerFeeder: @unchecked Sendable {
    private let format: AVAudioFormat
    private let continuation: AsyncStream<AnalyzerInput>.Continuation
    // Only used on the audio thread
    private var converter: AVAudioConverter?

    init(format: AVAudioFormat, continuation: AsyncStream<AnalyzerInput>.Continuation) {
        self.format = format
        self.continuation = continuation
    }

    func feed(_ buffer: AVAudioPCMBuffer) {
        if converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: format)
            converter?.primeMethod = .none
        }
        guard let converter else { return }

        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return }

        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        if error == nil, output.frameLength > 0 {
            continuation.yield(AnalyzerInput(buffer: output))
            lock.withLock { fedFrames += AVAudioFramePosition(output.frameLength) }
        }
    }

    private let lock = NSLock()
    private var fedFrames: AVAudioFramePosition = 0

    /// How much audio has been handed to the model, to see how far behind its results are
    var audioSeconds: Double {
        Double(lock.withLock { fedFrames }) / format.sampleRate
    }

    func finish() {
        continuation.finish()
    }
}
