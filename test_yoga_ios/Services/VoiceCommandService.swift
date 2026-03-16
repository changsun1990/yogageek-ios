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

@Observable
@MainActor
final class VoiceCommandService {

    var isListening = false
    var onCommand: ((VoiceCommand) -> Void)?

    private let recognizer: SFSpeechRecognizer?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var taskGeneration = 0

    private var processedWordCount = 0
    private var lastCommandTime: Date = .distantPast
    private let debounceDuration: TimeInterval = 0.8

    /// True while the user is actively speaking; resets 2 s after the last word.
    private(set) var isSpeaking = false
    private var speakingResetTask: Task<Void, Never>?

    private var observers: [NSObjectProtocol] = []

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

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

    func start() {
        guard !isListening else { return }
        guard let recognizer, recognizer.isAvailable else { return }

        do {
            try configureAudioSession()
            try installEngineAndStart()
            isListening = true
            startNewTask(recognizer: recognizer)
            registerObservers()
        } catch {
            print("[VoiceCommand] start failed: \(error)")
        }
    }

    func stop() {
        isListening = false
        isSpeaking = false
        speakingResetTask?.cancel()
        speakingResetTask = nil
        taskGeneration += 1
        unregisterObservers()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        processedWordCount = 0
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Engine management

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.mixWithOthers, .duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func installEngineAndStart() throws {
        audioEngine.inputNode.removeTap(onBus: 0)
        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    /// Called whenever the engine has stopped unexpectedly while we should be listening.
    /// Retries up to 3 times with a 600 ms delay between attempts, which gives
    /// AVSpeechSynthesizer / system sounds time to release the audio session
    /// before we try setActive(true) again (avoiding the !pri / 561017449 error).
    private func restartEngine(attempt: Int = 0) {
        guard isListening, !audioEngine.isRunning else { return }
        do {
            try configureAudioSession()
            try installEngineAndStart()
        } catch {
            print("[VoiceCommand] engine restart failed (attempt \(attempt + 1)): \(error)")
            guard attempt < 5 else { return }
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(700))
                self?.restartEngine(attempt: attempt + 1)
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

    // MARK: - Recognition task

    private func startNewTask(recognizer: SFSpeechRecognizer) {
        taskGeneration += 1
        let generation = taskGeneration
        recognitionTask?.cancel()
        recognitionRequest = nil
        processedWordCount = 0

        // If a sound effect or speech synthesis killed the engine, revive it now.
        restartEngine()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // .search optimizes for short phrases/keywords rather than long dictation.
        request.taskHint = .search
        // Priming the recognizer with expected words dramatically improves
        // first-attempt accuracy and reduces latency for these specific terms.
        request.contextualStrings = [
            "next", "back", "previous", "forward",
            "pause", "stop", "hold",
            "play", "resume", "continue"
        ]
        // Do NOT set requiresOnDeviceRecognition — cloud recognition returns
        // partial results faster and is more accurate for keyword spotting.
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self, self.taskGeneration == generation else { return }
                if let result { self.handleResult(result) }
                if error != nil || result?.isFinal == true {
                    guard self.isListening else { return }
                    self.startNewTask(recognizer: recognizer)
                }
            }
        }
    }

    private func handleResult(_ result: SFSpeechRecognitionResult) {
        let segments = result.bestTranscription.segments
        // Cloud recognition returns all timestamps as 0.0, so we track by index.
        // When the recognizer revises backwards (segment count shrinks), reset the
        // cursor so we don't get permanently stuck ahead of the real count.
        if segments.count < processedWordCount {
            processedWordCount = segments.count
            return
        }
        guard segments.count > processedWordCount else { return }
        let newSegments = segments[processedWordCount...]
        processedWordCount = segments.count
        let newWords = newSegments.map { $0.substring.lowercased() }
        print("[VoiceCommand] heard: \(newWords.joined(separator: " "))")
        for word in newWords {
            detectCommand(from: word)
        }
        let newText = newWords.joined(separator: " ")
        if !newText.isEmpty {
            // Signal active speech so music can be ducked
            isSpeaking = true
            speakingResetTask?.cancel()
            speakingResetTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                self?.isSpeaking = false
            }
        }
    }

    private func detectCommand(from word: String) {
        let command: VoiceCommand
        switch word {
        case "next", "forward":             command = .next
        case "back", "previous":            command = .previous
        case "pause", "stop", "hold":       command = .pause
        case "play", "resume", "continue":  command = .resume
        default:
            print("[VoiceCommand] no match: \"\(word)\"")
            return
        }
        guard Date().timeIntervalSince(lastCommandTime) >= debounceDuration else {
            print("[VoiceCommand] debounced: \"\(word)\"")
            return
        }
        lastCommandTime = Date()
        print("[VoiceCommand] command fired: \(command)")
        onCommand?(command)
    }
}
