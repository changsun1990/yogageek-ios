//
//  PracticeViewModel.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import Foundation
import SwiftUI
import AVFoundation

/// What practice says out loud
enum PracticeVoice: String, CaseIterable {
    case silent
    case poseNames
    case namesAndCues

    var title: String {
        switch self {
        case .silent: "Silent"
        case .poseNames: "Pose Names"
        case .namesAndCues: "Pose Names & Cues"
        }
    }

    var systemImage: String {
        switch self {
        case .silent: "speaker.slash.fill"
        case .poseNames: "speaker.wave.1.fill"
        case .namesAndCues: "speaker.wave.3.fill"
        }
    }
}

enum TimingMode {
    case perPose      // individual pose timers
    case sectionLevel // one timer for the whole section, all poses visible
    case flow         // no timer, poses scroll slowly
}

@Observable
class PracticeViewModel {
    // Practice data
    let sequence: YogaSequence
    let poses: [Pose]
    let isSectionPractice: Bool
    private(set) var flattenedPoses: [(sectionName: String, poseEntry: PoseEntry, pose: Pose?)] = []
    /// Effective section durations (may include distributed sequence target)
    private var effectiveSectionDurations: [String: Int] = [:]

    // Current state
    var currentIndex: Int = 0
    var timeRemaining: Int = 0
    var sectionTimeRemaining: Int = 0
    /// Total seconds elapsed while playing — never resets between poses.
    var sessionTimeElapsed: Int = 0
    var isPlaying: Bool = false
    var isComplete: Bool = false
    /// Remembered between sessions
    private(set) var voice = PracticeVoice(rawValue: UserDefaults.standard.string(forKey: PracticeViewModel.voiceKey) ?? "") ?? .poseNames
    var audioEnabled: Bool { voice != .silent }
    var readCuesEnabled: Bool { voice == .namesAndCues }

    private static let voiceKey = "practiceVoice"

    // Timer
    private var timer: Timer?

    // Audio
    private let speaker = PhraseSpeaker()
    private var audioPlayer: AVAudioPlayer?

    /// Fallback duration (seconds) for poses in a perPose section that have no
    /// explicit duration set. Keeps auto-play flowing instead of getting stuck.
    private static let defaultPoseDuration = 30

    // MARK: - Timing Mode

    var currentTimingMode: TimingMode {
        timingModeForSection(currentSectionName)
    }

    func timingModeForSection(_ sectionName: String) -> TimingMode {
        guard let section = sequence.sections.first(where: { $0.name == sectionName }) else { return .flow }
        // If any pose in the section has an explicit duration → perPose
        if section.poses.contains(where: { $0.duration != nil }) {
            return .perPose
        }
        // If section has a duration (set or distributed from sequence) → sectionLevel
        if effectiveSectionDurations[section.id] != nil || section.sectionDuration != nil {
            return .sectionLevel
        }
        // No duration anywhere → flow
        return .flow
    }

    // MARK: - Computed Properties

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

    var upcomingPose: Pose? {
        guard currentIndex + 1 < flattenedPoses.count else { return nil }
        return flattenedPoses[currentIndex + 1].pose
    }

    var currentPoseIsTimed: Bool {
        currentTimingMode == .perPose && durationForPose(at: currentIndex) > 0
    }

    var currentPoseTotalDuration: Int {
        durationForPose(at: currentIndex)
    }

    var progress: Double {
        let duration = durationForPose(at: currentIndex)
        guard duration > 0 else { return 0 }
        return Double(duration - timeRemaining) / Double(duration)
    }

    /// All poses in the current section (for section-level and flow display)
    var currentSectionPoses: [(poseEntry: PoseEntry, pose: Pose?)] {
        let sectionName = currentSectionName
        return flattenedPoses
            .filter { $0.sectionName == sectionName }
            .map { (poseEntry: $0.poseEntry, pose: $0.pose) }
    }

    /// Total duration of the whole session, used for the session countdown.
    /// Priority: sequence.targetDuration → sum of pose durations → sum of section durations.
    var sessionTotalDuration: Int {
        if sequence.targetDuration > 0 { return sequence.targetDuration }
        let poseDurations = flattenedPoses.reduce(0) { $0 + ($1.poseEntry.duration ?? 0) }
        if poseDurations > 0 { return poseDurations }
        return sequence.sections.reduce(0) {
            $0 + (effectiveSectionDurations[$1.id] ?? $1.sectionDuration ?? 0)
        }
    }

    /// The section-level total duration
    var sectionTotalDuration: Int {
        guard let section = sequence.sections.first(where: { $0.name == currentSectionName }) else { return 0 }
        return effectiveSectionDurations[section.id] ?? section.sectionDuration ?? 0
    }

    var sectionProgress: Double {
        let total = sectionTotalDuration
        guard total > 0 else { return 0 }
        return Double(total - sectionTimeRemaining) / Double(total)
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

    var currentSectionIndex: Int {
        let name = currentSectionName
        return sequence.sections.firstIndex(where: { $0.name == name }) ?? 0
    }

    var totalSections: Int {
        sequence.sections.count
    }

    /// 1-based pose number within the current section
    var currentPoseIndexInSection: Int {
        let name = currentSectionName
        let sectionIndices = flattenedPoses.indices.filter { flattenedPoses[$0].sectionName == name }
        return (sectionIndices.firstIndex(of: currentIndex) ?? 0) + 1
    }

    var totalPosesInSection: Int {
        currentSectionPoses.count
    }

    var hasNextSection: Bool {
        currentSectionIndex < sequence.sections.count - 1
    }

    var hasPreviousSection: Bool {
        currentSectionIndex > 0
    }

    // MARK: - Init

    init(sequence: YogaSequence, poses: [Pose], startAtSection: Int? = nil) {
        self.sequence = sequence
        self.poses = poses
        self.isSectionPractice = startAtSection != nil
        distributeSequenceDuration()
        flattenPoses()
        setupAudioSession()

        if let sectionIndex = startAtSection, sectionIndex < sequence.sections.count {
            let sectionName = sequence.sections[sectionIndex].name
            if let index = flattenedPoses.firstIndex(where: { $0.sectionName == sectionName }) {
                currentIndex = index
            }
        }

        initializeTimers()
    }

    private func initializeTimers() {
        let mode = currentTimingMode
        switch mode {
        case .perPose:
            timeRemaining = durationForPose(at: currentIndex)
        case .sectionLevel:
            sectionTimeRemaining = sectionTotalDuration
        case .flow:
            break
        }
    }

    /// If sequence has targetDuration and no sections/poses have durations,
    /// distribute evenly across sections as implicit sectionDuration.
    private func distributeSequenceDuration() {
        guard sequence.targetDuration > 0 else { return }
        let allSectionsEmpty = sequence.sections.allSatisfy { section in
            section.sectionDuration == nil && section.poses.allSatisfy { $0.duration == nil }
        }
        guard allSectionsEmpty else { return }

        let nonEmptySections = sequence.sections.filter { !$0.poses.isEmpty }
        guard !nonEmptySections.isEmpty else { return }

        let perSection = sequence.targetDuration / nonEmptySections.count
        for section in nonEmptySections {
            effectiveSectionDurations[section.id] = perSection
        }
    }

    private func setupAudioSession() {
        AudioSessionQueue.enqueue { session in
            // Don't downgrade from .playAndRecord — VoiceCommandService may have
            // already configured the session for recording. SwiftUI re-creates view
            // structs on every @Observable change, causing this init to run on
            // discarded instances; resetting the category here would break the mic.
            guard session.category != .playAndRecord else { return }
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        }
    }

    private func flattenPoses() {
        flattenedPoses = []
        for section in sequence.sections {
            for poseEntry in section.poses {
                let pose = poses.first { $0.id == poseEntry.poseId }
                flattenedPoses.append((sectionName: section.name, poseEntry: poseEntry, pose: pose))
            }
        }
    }

    /// Returns the pose's own explicit duration, or 0.
    /// Does NOT distribute section duration to individual poses.
    private func durationForPose(at index: Int) -> Int {
        guard index < flattenedPoses.count else { return 0 }
        let entry = flattenedPoses[index].poseEntry
        return entry.duration ?? 0
    }

    // MARK: - Playback Controls

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
        switch currentTimingMode {
        case .perPose:
            if !currentPoseIsTimed {
                // Pose has no explicit duration — use the default so playback
                // doesn't get stuck waiting for a manual tap.
                timeRemaining = Self.defaultPoseDuration
            }
            startTimer()
        case .sectionLevel:
            startTimer()
        case .flow:
            startTimer() // needed for session elapsed tracking
        }
    }

    func pause() {
        isPlaying = false
        stopTimer()
        // Don't keep reading cues while paused; resuming announces the pose again
        speaker.stop()
    }

    func next() {
        nextPose()
    }

    func previous() {
        previousPose()
    }

    private func nextPose() {
        guard currentIndex < flattenedPoses.count - 1 else {
            complete()
            return
        }
        stopTimer()
        currentIndex += 1
        timeRemaining = durationForPose(at: currentIndex)
        playChime()

        // Check if we entered a new section with different timing mode
        let newMode = currentTimingMode
        if isPlaying {
            announcePose()
            switch newMode {
            case .perPose:
                if !currentPoseIsTimed {
                    // No explicit duration — use the default so playback keeps flowing.
                    timeRemaining = Self.defaultPoseDuration
                }
                startTimer()
            case .sectionLevel:
                sectionTimeRemaining = sectionTotalDuration
                startTimer()
            case .flow:
                break
            }
        } else if newMode == .sectionLevel {
            sectionTimeRemaining = sectionTotalDuration
        }
    }

    func nextSection() {
        guard hasNextSection else {
            complete()
            return
        }
        stopTimer()
        let nextSectionIdx = currentSectionIndex + 1
        let nextSectionName = sequence.sections[nextSectionIdx].name
        if let poseIdx = flattenedPoses.firstIndex(where: { $0.sectionName == nextSectionName }) {
            currentIndex = poseIdx
        }
        playChime()

        let newMode = currentTimingMode
        switch newMode {
        case .sectionLevel:
            sectionTimeRemaining = sectionTotalDuration
            if isPlaying { startTimer() }
        case .perPose:
            timeRemaining = durationForPose(at: currentIndex)
            if isPlaying {
                if !currentPoseIsTimed { timeRemaining = Self.defaultPoseDuration }
                startTimer()
            }
        case .flow:
            break
        }
        if isPlaying { announcePose() }
    }

    func previousSection() {
        guard hasPreviousSection else { return }
        stopTimer()
        let prevSectionIdx = currentSectionIndex - 1
        let prevSectionName = sequence.sections[prevSectionIdx].name
        if let poseIdx = flattenedPoses.firstIndex(where: { $0.sectionName == prevSectionName }) {
            currentIndex = poseIdx
        }
        playChime()

        let newMode = currentTimingMode
        switch newMode {
        case .sectionLevel:
            sectionTimeRemaining = sectionTotalDuration
            if isPlaying { startTimer() }
        case .perPose:
            timeRemaining = durationForPose(at: currentIndex)
            if isPlaying {
                if !currentPoseIsTimed { timeRemaining = Self.defaultPoseDuration }
                startTimer()
            }
        case .flow:
            break
        }
        if isPlaying { announcePose() }
    }

    private func previousPose() {
        guard currentIndex > 0 else { return }
        stopTimer()
        currentIndex -= 1
        timeRemaining = durationForPose(at: currentIndex)
        playChime()

        let newMode = currentTimingMode
        if isPlaying {
            announcePose()
            switch newMode {
            case .perPose:
                if !currentPoseIsTimed {
                    timeRemaining = Self.defaultPoseDuration
                }
                startTimer()
            case .sectionLevel:
                sectionTimeRemaining = sectionTotalDuration
                startTimer()
            case .flow:
                break
            }
        } else if newMode == .sectionLevel {
            sectionTimeRemaining = sectionTotalDuration
        }
    }

    func restart() {
        stopTimer()
        currentIndex = 0
        isComplete = false
        sessionTimeElapsed = 0
        initializeTimers()
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
        sessionTimeElapsed += 1
        switch currentTimingMode {
        case .perPose:
            tickPose()
        case .sectionLevel:
            tickSection()
        case .flow:
            break
        }
    }

    private func tickPose() {
        guard timeRemaining > 0 else {
            nextPose()
            return
        }
        timeRemaining -= 1
        if timeRemaining == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.nextPose()
            }
        }
    }

    private func tickSection() {
        guard sectionTimeRemaining > 0 else {
            nextSection()
            return
        }
        sectionTimeRemaining -= 1
        if sectionTimeRemaining == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.nextSection()
            }
        }
    }

    private func complete() {
        isPlaying = false
        isComplete = true
        stopTimer()
        // Nothing more to read, like the rest of the last pose's cues
        speaker.stop()
        playCompletionSound()
    }

    /// Stops the timer and anything being read, for when practice is closed
    func end() {
        isPlaying = false
        stopTimer()
        speaker.stop()
    }

    // MARK: - Audio

    private func announcePose() {
        guard audioEnabled, currentPoseEntry != nil else { return }
        var phrases = [spokenName(at: currentIndex)]
        if readCuesEnabled {
            phrases += cuesForSpeech(at: currentIndex)
        }
        speaker.speak(phrases)
    }

    /// Whether practice itself just said `word` (like "back" in a cue), so voice commands can ignore it
    func isSaying(_ word: String) -> Bool {
        speaker.isSaying(word)
    }

    /// Reads pose names and cues through voice commands' audio while they're on, so the microphone
    /// can tell them from the user (nil once voice commands are off)
    func readAloud(through voiceCommands: VoiceCommandService?) {
        speaker.voiceCommands = voiceCommands
    }

    /// Fetches natural-voice recordings for everything practice will say, starting with the current pose
    func prepareSpeech() async {
        let upcoming = Array(flattenedPoses.indices.dropFirst(currentIndex)) + Array(flattenedPoses.indices.prefix(currentIndex))
        var phrases: [String] = []
        for index in upcoming {
            phrases.append(spokenName(at: index))
            if readCuesEnabled {
                phrases += cuesForSpeech(at: index)
            }
        }
        await SpeechClipService.shared.prefetch(phrases)
    }

    /// The user's cues for a pose, or the library cues when they haven't written any, as plain text
    private func cuesForSpeech(at index: Int) -> [String] {
        guard index < flattenedPoses.count else { return [] }
        let (_, entry, pose) = flattenedPoses[index]
        let cues = entry.customCues.isEmpty
            ? pose?.sampleCues ?? []
            : entry.customCues.map { String(CueMarkdown.attributedString(from: [$0], separator: "").characters) }
        return cues
            .map { cue in
                // Bullets are for the eye, not the voice
                let trimmed = cue.trimmingCharacters(in: .whitespaces)
                return trimmed.hasPrefix("•") ? trimmed.dropFirst().trimmingCharacters(in: .whitespaces) : trimmed
            }
            .filter { !$0.isEmpty }
            .map(Self.spoken)
    }

    private func spokenName(at index: Int) -> String {
        Self.spoken(flattenedPoses[index].poseEntry.displayName(for: flattenedPoses[index].pose))
    }

    /// How a name or cue is said aloud: "Warrior I" as "Warrior one" rather than the letter I
    private static func spoken(_ text: String) -> String {
        let numbers = ["I": "one", "II": "two", "III": "three", "IV": "four"]
        // A numeral right after a capitalized word, like "Twist II", but not "I'm"
        return text.replacing(#/\b([A-Z][\w'’]*) (IV|III|II|I)\b(?![\w'’])/#) { match in
            "\(match.1) \(numbers[String(match.2)] ?? String(match.2))"
        }
    }

    private func playChime() {
        guard audioEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    private func playCompletionSound() {
        guard audioEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    func setVoice(_ newVoice: PracticeVoice) {
        let addsCues = newVoice == .namesAndCues && voice != .namesAndCues
        voice = newVoice
        UserDefaults.standard.set(newVoice.rawValue, forKey: Self.voiceKey)

        guard addsCues else {
            // Stop anything that's no longer wanted, like cues mid-sentence
            if newVoice != .namesAndCues {
                speaker.stop()
            }
            return
        }
        Task { await prepareSpeech() }
        if isPlaying {
            // Read the current pose's cues now rather than waiting for the next pose
            speaker.speak(cuesForSpeech(at: currentIndex))
        }
    }

    deinit {
        stopTimer()
        speaker.stop()
    }
}
