//
//  PracticeView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct PracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: PracticeViewModel
    @State private var musicManager = MusicManager.shared
    @State private var showingMusicPicker = false
    @State private var goingForward = true
    @State private var voiceService = VoiceCommandService()
    @State private var voiceEnabled = false
    @State private var voiceCommandFeedback: String? = nil
    @State private var showVoiceHelp = false

    init(sequence: YogaSequence, poses: [Pose], startAtSection: Int? = nil) {
        _viewModel = State(initialValue: PracticeViewModel(sequence: sequence, poses: poses, startAtSection: startAtSection))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.yogaSurface.ignoresSafeArea()

                    if viewModel.isComplete {
                        completionView
                    } else if geo.size.width > geo.size.height {
                        landscapeLayout(geo: geo)
                    } else {
                        portraitLayout(geo: geo)
                    }

                    if let feedback = voiceCommandFeedback {
                        VStack {
                            Spacer()
                            Text(feedback)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(.regularMaterial)
                                .clipShape(Capsule())
                                .padding(.bottom, 110)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.prepareSpeech()
            }
            .sheet(isPresented: $showingMusicPicker) {
                MusicPickerView(musicManager: musicManager)
            }
            .sheet(isPresented: $showVoiceHelp) {
                VoiceCommandHelpView()
            }
            .onDisappear {
                viewModel.end()
                voiceService.stop()
                viewModel.readAloud(through: nil)
                if musicManager.activeService == .appleMusic {
                    musicManager.stop()
                }
            }
            .onChange(of: voiceService.isListening) { _, listening in
                // Voice commands turned themselves off, like when speech recognition stopped working
                guard !listening, voiceEnabled else { return }
                voiceEnabled = false
                showVoiceHelp = false
                viewModel.readAloud(through: nil)
                showFeedback("Voice commands aren't available right now")
            }
        }
    }

    // MARK: - Portrait Layout

    private func portraitLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 10)

            progressBar
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            slidingPoseImage
                .frame(height: geo.size.height * 0.47)
                .padding(.horizontal, 20)

            textBlock
                .padding(.horizontal, 28)
                .padding(.top, 22)

            Spacer(minLength: 8)

            if musicManager.activeService != .none {
                MiniMusicPlayerView(musicManager: musicManager) {
                    showingMusicPicker = true
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            controlsRow
                .padding(.bottom, 24)
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            slidingPoseImage
                .padding(.leading, 16)
                .padding(.vertical, 12)
                .frame(width: geo.size.width * 0.55)

            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 8)

                progressBar
                    .padding(.bottom, 12)

                Spacer(minLength: 0)

                textBlock

                Spacer(minLength: 0)

                if musicManager.activeService != .none {
                    MiniMusicPlayerView(musicManager: musicManager) {
                        showingMusicPicker = true
                    }
                    .padding(.bottom, 4)
                }

                controlsRow
                    .padding(.bottom, 8)
            }
            .frame(width: geo.size.width * 0.45)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 0) {
            // Dismiss + auxiliary controls
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    Text("Done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }

                // One choice for what's said out loud, so sound and cues can't conflict
                Menu {
                    Picker("Voice", selection: Binding(get: { viewModel.voice }, set: { viewModel.setVoice($0) })) {
                        ForEach(PracticeVoice.allCases, id: \.self) { voice in
                            Label(voice.title, systemImage: voice.systemImage)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.voice.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Voice: \(viewModel.voice.title)")

                Button { showingMusicPicker = true } label: {
                    Image(systemName: musicManager.activeService != .none ? "music.note.list" : "music.note")
                        .font(.subheadline)
                        .foregroundStyle(musicManager.activeService != .none ? Color.yogaPrimary : .secondary)
                }

                Button { Task { await toggleVoice() } } label: {
                    // A person speaking rather than a microphone: commands are heard, not recorded
                    Image(systemName: voiceEnabled ? "person.wave.2.fill" : "person.wave.2")
                        .font(.subheadline)
                        .foregroundStyle(voiceEnabled ? Color.yogaPrimary : .secondary)
                }
                .accessibilityLabel(voiceEnabled ? "Turn off voice commands" : "Turn on voice commands")
            }

            Spacer()

            // Pose / section counter
            Text(counterText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Timer pill
            timerPill
        }
    }

    private var counterText: String {
        if viewModel.isSectionPractice {
            return "\(viewModel.currentPoseIndexInSection) of \(viewModel.totalPosesInSection)"
        }
        return "\(viewModel.currentPoseNumber) of \(viewModel.totalPoses)"
    }

    @ViewBuilder
    private var timerPill: some View {
        let total = viewModel.sessionTotalDuration
        if total > 0 {
            // Countdown from total session duration
            timerCapsule(seconds: max(0, total - viewModel.sessionTimeElapsed))
        } else {
            // No duration defined — show elapsed time
            timerCapsule(seconds: viewModel.sessionTimeElapsed, countUp: true)
        }
    }

    private func timerCapsule(seconds: Int, countUp: Bool = false) -> some View {
        HStack(spacing: 3) {
            if countUp {
                Image(systemName: "timer")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(formatTime(seconds))
                .font(.subheadline.monospacedDigit())
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(uiColor: .systemGray5))
        .clipShape(Capsule())
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Progress Bar

    private var sequenceProgress: Double {
        guard viewModel.totalPoses > 0 else { return 0 }
        return Double(viewModel.currentPoseNumber) / Double(viewModel.totalPoses)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.yogaPrimary)
                    .frame(width: geo.size.width * sequenceProgress, height: 4)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentIndex)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Sliding Image

    private var slidingPoseImage: some View {
        // GeometryReader gives exact pixel dimensions so the fill image has a
        // concrete frame and doesn't expand the ZStack beyond its container.
        GeometryReader { proxy in
            ZStack {
                Color.yogaCardBackground

                poseImageContent(size: proxy.size)
                    .id(viewModel.currentIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingForward ? .trailing : .leading),
                        removal: .move(edge: goingForward ? .leading : .trailing)
                    ))
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            .animation(.easeInOut(duration: 0.35), value: viewModel.currentIndex)
        }
    }

    @ViewBuilder
    private func poseImageContent(size: CGSize) -> some View {
        if let pose = viewModel.currentPose, !pose.imageURL.isEmpty {
            if pose.imageURL.hasPrefix("http://") || pose.imageURL.hasPrefix("https://") {
                AsyncImage(url: URL(string: pose.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height)
                    case .empty:
                        ProgressView()
                    default:
                        yogaFallbackIcon
                    }
                }
            } else {
                Image(systemName: pose.imageURL)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.yogaPrimary)
                    .padding(32)
            }
        } else {
            yogaFallbackIcon
        }
    }

    private var yogaFallbackIcon: some View {
        Image(systemName: "figure.yoga")
            .font(.system(size: 80, weight: .light))
            .foregroundStyle(Color.yogaPrimary)
    }

    // MARK: - Text Block

    private var textBlock: some View {
        VStack(spacing: 6) {
            // Sanskrit name — tracked uppercase in accent color
            if let sanskrit = viewModel.currentPoseEntry?.displaySanskrit(for: viewModel.currentPose), !sanskrit.isEmpty {
                Text(sanskrit.uppercased())
                    .font(.caption)
                    .kerning(3)
                    .foregroundStyle(Color.yogaPrimary)
            }

            // English name — large, light-weight, serif
            Text(currentPoseName)
                .font(.system(size: 44, weight: .light, design: .serif))
                .minimumScaleFactor(0.55)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .id(viewModel.currentIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.currentIndex)

            // Cue text (user custom cues first, then pose sample cues)
            let cues = activeCues
            if !cues.characters.isEmpty {
                Text(cues)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.top, 6)
            }
        }
    }

    private var currentPoseName: String {
        viewModel.currentPoseEntry?.displayName(for: viewModel.currentPose) ?? ""
    }

    private var activeCues: AttributedString {
        if let entry = viewModel.currentPoseEntry, !entry.customCues.isEmpty {
            return CueMarkdown.attributedString(from: Array(entry.customCues.prefix(2)), separator: " ")
        }
        if let pose = viewModel.currentPose, !pose.sampleCues.isEmpty {
            return AttributedString(pose.sampleCues.prefix(2).joined(separator: " "))
        }
        return AttributedString()
    }

    // MARK: - Controls

    private var controlsRow: some View {
        HStack(spacing: 52) {
            Button {
                goingForward = false
                viewModel.previous()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.hasPrevious ? Color.primary.opacity(0.55) : Color.primary.opacity(0.2))
            }
            .disabled(!viewModel.hasPrevious)

            // Large filled play/pause circle
            Button {
                viewModel.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.yogaPrimary)
                        .frame(width: 72, height: 72)
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
            }

            Button {
                goingForward = true
                viewModel.next()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.hasNext ? Color.primary.opacity(0.55) : Color.primary.opacity(0.2))
            }
            .disabled(!viewModel.hasNext)
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if value.translation.width < 0, viewModel.hasNext {
                    goingForward = true
                    viewModel.next()
                } else if value.translation.width > 0, viewModel.hasPrevious {
                    goingForward = false
                    viewModel.previous()
                }
            }
    }

    // MARK: - Voice Commands

    private func toggleVoice() async {
        if voiceEnabled {
            voiceService.stop()
            voiceEnabled = false
            viewModel.readAloud(through: nil)
        } else {
            let granted = await voiceService.requestPermissions()
            if granted {
                voiceService.onCommand = { command in
                    handleVoiceCommand(command)
                }
                // Pose names and cues keep playing; their words aren't taken as commands
                voiceService.isAppSpeech = { word in
                    viewModel.isSaying(word)
                }
                if await voiceService.start() {
                    voiceEnabled = true
                    showVoiceHelp = true
                    viewModel.readAloud(through: voiceService)
                } else {
                    showFeedback("Voice commands aren't available right now")
                }
            }
        }
    }

    private func handleVoiceCommand(_ command: VoiceCommand) {
        let label: String
        switch command {
        case .next:
            label = "▶ Next"
            goingForward = true
            viewModel.next()
        case .previous:
            label = "◀ Back"
            goingForward = false
            viewModel.previous()
        case .pause:
            label = "⏸ Pause"
            viewModel.pause()
        case .resume:
            label = "▶ Resume"
            viewModel.play()
        }
        showFeedback(label)
    }

    private func showFeedback(_ text: String) {
        withAnimation { voiceCommandFeedback = text }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { voiceCommandFeedback = nil }
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.yogaPrimary)

            Text("Practice Complete")
                .font(.system(size: 40, weight: .light, design: .serif))

            Text("You completed \(viewModel.totalPoses) poses")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.restart()
                } label: {
                    Label("Practice Again", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yogaPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColor: .systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Voice Command Help Sheet

private struct VoiceCommandHelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let commands: [(icon: String, words: String, action: String)] = [
        ("forward.end.fill",  "\"next\" · \"forward\"",               "Advance to next pose"),
        ("backward.end.fill", "\"back\" · \"previous\"",              "Go to previous pose"),
        ("pause.fill",        "\"pause\" · \"hold\" · \"stop\"",      "Pause the timer"),
        ("play.fill",         "\"play\" · \"resume\" · \"continue\"", "Resume the timer"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(uiColor: .systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Image(systemName: "person.wave.2.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.yogaPrimary)
                .padding(.bottom, 8)

            Text("Voice Commands")
                .font(.title3.weight(.semibold))
                .padding(.bottom, 4)

            Text("Say these words while voice commands are on")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

            VStack(spacing: 0) {
                ForEach(commands, id: \.words) { cmd in
                    HStack(spacing: 14) {
                        Image(systemName: cmd.icon)
                            .font(.subheadline)
                            .foregroundStyle(Color.yogaPrimary)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cmd.words)
                                .font(.subheadline.weight(.medium))
                            Text(cmd.action)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    if cmd.words != commands.last?.words {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color.yogaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)

            Label("Your voice is understood on your iPhone. Nothing is recorded or saved.", systemImage: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yogaPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    PracticeView(
        sequence: YogaSequence(
            name: "Morning Flow",
            sections: [
                YogaSection(name: "Warm Up", poses: [
                    PoseEntry(poseId: "mountain", duration: 10),
                    PoseEntry(poseId: "cat-cow", duration: 15)
                ]),
                YogaSection(name: "Standing", poses: [
                    PoseEntry(poseId: "warrior-1", duration: 30),
                    PoseEntry(poseId: "warrior-2", duration: 30)
                ])
            ]
        ),
        poses: MockPoseData.poses
    )
}
