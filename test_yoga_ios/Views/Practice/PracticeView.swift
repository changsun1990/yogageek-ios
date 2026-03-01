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
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingMusicPicker) {
                MusicPickerView(musicManager: musicManager)
            }
            .onDisappear {
                if musicManager.activeService == .appleMusic {
                    musicManager.stop()
                }
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
                }

                Button { viewModel.toggleAudio() } label: {
                    Image(systemName: viewModel.audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button { showingMusicPicker = true } label: {
                    Image(systemName: musicManager.activeService != .none ? "music.note.list" : "music.note")
                        .font(.subheadline)
                        .foregroundStyle(musicManager.activeService != .none ? Color.yogaPrimary : .secondary)
                }
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
        switch viewModel.currentTimingMode {
        case .perPose:
            return "\(viewModel.currentPoseNumber) of \(viewModel.totalPoses)"
        case .sectionLevel, .flow:
            return "Section \(viewModel.currentSectionIndex + 1) of \(viewModel.totalSections)"
        }
    }

    @ViewBuilder
    private var timerPill: some View {
        if viewModel.currentTimingMode == .perPose && viewModel.currentPoseIsTimed {
            timerCapsule(seconds: viewModel.timeRemaining)
        } else if viewModel.currentTimingMode == .sectionLevel {
            timerCapsule(seconds: viewModel.sectionTimeRemaining)
        } else {
            Image(systemName: "infinity")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(uiColor: .systemGray5))
                .clipShape(Capsule())
        }
    }

    private func timerCapsule(seconds: Int) -> some View {
        Text(formatTime(seconds))
            .font(.subheadline.monospacedDigit())
            .fontWeight(.medium)
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
            if let sanskrit = viewModel.currentPose?.nameSanskrit, !sanskrit.isEmpty {
                Text(sanskrit.uppercased())
                    .font(.caption)
                    .kerning(3)
                    .foregroundStyle(Color.yogaPrimary)
            }

            // English name — large, light-weight, serif
            Text(currentPoseName)
                .font(.system(size: 44, weight: .light, design: .serif))
                .multilineTextAlignment(.center)
                .id(viewModel.currentIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.currentIndex)

            // Cue text (user custom cues first, then pose sample cues)
            let cues = activeCues
            if !cues.isEmpty {
                Text(cues.joined(separator: " "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.top, 6)
            }
        }
    }

    private var currentPoseName: String {
        viewModel.currentPose?.nameEnglish
            ?? viewModel.currentPoseEntry?.customName
            ?? ""
    }

    private var activeCues: [String] {
        if let entry = viewModel.currentPoseEntry, !entry.customCues.isEmpty {
            return Array(entry.customCues.prefix(2))
        }
        if let pose = viewModel.currentPose, !pose.sampleCues.isEmpty {
            return Array(pose.sampleCues.prefix(2))
        }
        return []
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
