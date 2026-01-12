//
//  PracticeViewModel.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import Foundation
import SwiftUI
import AVFoundation

@Observable
class PracticeViewModel {
    // Practice data
    let sequence: YogaSequence
    private(set) var flattenedPoses: [(sectionName: String, poseEntry: PoseEntry, pose: Pose?)] = []

    // Current state
    var currentIndex: Int = 0
    var timeRemaining: Int = 0
    var isPlaying: Bool = false
    var isComplete: Bool = false
    var audioEnabled: Bool = true

    // Timer
    private var timer: Timer?

    // Audio
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

    // Computed properties
    var currentSectionName: String {
        guard currentIndex < flattenedPoses.count else { return "" }
        return flattenedPoses[currentIndex].sectionName
    }

    var currentPoseEntry: PoseEntry? {
        guard currentIndex < flattenedPoses.count else { return nil }
        return flattenedPoses[currentIndex].poseEntry
    }

    var currentPose: Pose? {
        guard currentIndex < flattenedPoses.count else { return nil }
        return flattenedPoses[currentIndex].pose
    }

    var progress: Double {
        guard let entry = currentPoseEntry, entry.duration > 0 else { return 0 }
        return Double(entry.duration - timeRemaining) / Double(entry.duration)
    }

    var totalPoses: Int {
        flattenedPoses.count
    }

    var currentPoseNumber: Int {
        currentIndex + 1
    }

    var hasNext: Bool {
        currentIndex < flattenedPoses.count - 1
    }

    var hasPrevious: Bool {
        currentIndex > 0
    }

    init(sequence: YogaSequence, startAtSection: Int? = nil) {
        self.sequence = sequence
        flattenPoses()
        setupAudioSession()

        if let sectionIndex = startAtSection, sectionIndex < sequence.sections.count {
            // Find the first pose index for this section
            let sectionName = sequence.sections[sectionIndex].name
            if let index = flattenedPoses.firstIndex(where: { $0.sectionName == sectionName }) {
                currentIndex = index
            }
        }

        if let entry = currentPoseEntry {
            timeRemaining = entry.duration
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func flattenPoses() {
        flattenedPoses = []
        for section in sequence.sections {
            for poseEntry in section.poses {
                let pose = MockPoseData.poses.first { $0.id == poseEntry.poseId }
                flattenedPoses.append((sectionName: section.name, poseEntry: poseEntry, pose: pose))
            }
        }
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard !isComplete else { return }
        isPlaying = true
        announcePose()
        startTimer()
    }

    func pause() {
        isPlaying = false
        stopTimer()
    }

    func next() {
        guard hasNext else {
            complete()
            return
        }
        stopTimer()
        currentIndex += 1
        if let entry = currentPoseEntry {
            timeRemaining = entry.duration
        }
        playChime()
        if isPlaying {
            announcePose()
            startTimer()
        }
    }

    func previous() {
        guard hasPrevious else { return }
        stopTimer()
        currentIndex -= 1
        if let entry = currentPoseEntry {
            timeRemaining = entry.duration
        }
        playChime()
        if isPlaying {
            announcePose()
            startTimer()
        }
    }

    func restart() {
        stopTimer()
        currentIndex = 0
        isComplete = false
        if let entry = currentPoseEntry {
            timeRemaining = entry.duration
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard timeRemaining > 0 else {
            next()
            return
        }
        timeRemaining -= 1

        if timeRemaining == 0 {
            // Small delay before moving to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.next()
            }
        }
    }

    private func complete() {
        isPlaying = false
        isComplete = true
        stopTimer()
        playCompletionSound()
    }

    // MARK: - Audio

    private func announcePose() {
        guard audioEnabled, let pose = currentPose else { return }

        // Stop any current speech
        speechSynthesizer.stopSpeaking(at: .immediate)

        // Create utterance with pose name
        let utterance = AVSpeechUtterance(string: pose.nameEnglish)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 0.8

        speechSynthesizer.speak(utterance)
    }

    private func playChime() {
        guard audioEnabled else { return }
        // Play system sound for pose transition
        AudioServicesPlaySystemSound(1057) // Tink sound
    }

    private func playCompletionSound() {
        guard audioEnabled else { return }
        // Play completion sound
        AudioServicesPlaySystemSound(1025) // Positive sound
    }

    func toggleAudio() {
        audioEnabled.toggle()
        if !audioEnabled {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    deinit {
        stopTimer()
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
