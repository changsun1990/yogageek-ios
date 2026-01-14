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

    init(sequence: YogaSequence, poses: [Pose], startAtSection: Int? = nil) {
        _viewModel = State(initialValue: PracticeViewModel(sequence: sequence, poses: poses, startAtSection: startAtSection))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isComplete {
                    completionView
                } else {
                    practiceContent
                }
            }
            .navigationTitle(viewModel.sequence.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleAudio()
                    } label: {
                        Image(systemName: viewModel.audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                }
            }
        }
    }

    private var practiceContent: some View {
        VStack(spacing: 24) {
            // Section & Progress indicator
            VStack(spacing: 8) {
                Text(viewModel.currentSectionName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Pose \(viewModel.currentPoseNumber) of \(viewModel.totalPoses)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Current pose display
            if let pose = viewModel.currentPose {
                poseDisplay(pose: pose)
            }

            Spacer()

            // Timer
            TimerView(
                timeRemaining: viewModel.timeRemaining,
                totalTime: viewModel.currentPoseEntry?.duration ?? 30,
                isPlaying: viewModel.isPlaying
            )

            Spacer()

            // Controls
            controlsView
        }
        .padding()
    }

    private func poseDisplay(pose: Pose) -> some View {
        VStack(spacing: 16) {
            PoseImageView(imageURL: pose.imageURL, size: 120, cornerRadius: 16)

            VStack(spacing: 4) {
                Text(pose.nameEnglish)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(pose.nameSanskrit)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Show custom cues if available
            if let entry = viewModel.currentPoseEntry, !entry.customCues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.customCues, id: \.self) { cue in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.secondary)
                                .padding(.top, 6)
                            Text(cue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var controlsView: some View {
        HStack(spacing: 40) {
            // Previous button
            Button {
                viewModel.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundStyle(viewModel.hasPrevious ? .primary : .tertiary)
            }
            .disabled(!viewModel.hasPrevious)

            // Play/Pause button
            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
            }

            // Next button
            Button {
                viewModel.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundStyle(viewModel.hasNext ? .primary : .tertiary)
            }
            .disabled(!viewModel.hasNext)
        }
        .padding(.bottom, 20)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Practice Complete!")
                .font(.title)
                .fontWeight(.bold)

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
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
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
