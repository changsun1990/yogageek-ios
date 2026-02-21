//
//  PosePickerView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct PosePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let poses: [Pose]
    let onSelect: (Pose) -> Void

    @State private var searchText = ""
    @State private var selectedPoseForDetail: Pose?
    @State private var showingConfirmation = false
    @State private var addedPoseName = ""

    private var filteredPoses: [Pose] {
        if searchText.isEmpty {
            return poses
        }
        return poses.filter { pose in
            pose.nameEnglish.localizedCaseInsensitiveContains(searchText) ||
            pose.nameSanskrit.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredPoses) { pose in
                PosePickerRow(
                    pose: pose,
                    onTap: {
                        selectedPoseForDetail = pose
                    },
                    onAdd: {
                        addPose(pose)
                    }
                )
            }
            .navigationTitle("Add Pose")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search poses")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPoseForDetail) { pose in
                PoseDetailSheet(pose: pose) {
                    addPose(pose)
                    selectedPoseForDetail = nil
                }
            }
            .overlay(alignment: .bottom) {
                if showingConfirmation {
                    confirmationBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: showingConfirmation)
        }
    }

    private func addPose(_ pose: Pose) {
        onSelect(pose)
        addedPoseName = pose.nameEnglish
        showingConfirmation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingConfirmation = false
            }
        }
    }

    private var confirmationBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)

            Text("\(addedPoseName) added")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding()
        .background(Color.green)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .yogaFloatingShadow()
        .padding()
    }
}

struct PosePickerRow: View {
    let pose: Pose
    let onTap: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Tappable area for details
            Button(action: onTap) {
                HStack(spacing: 12) {
                    PoseImageView(imageURL: pose.imageURL, size: 44, cornerRadius: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pose.nameEnglish)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text(pose.nameSanskrit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(pose.categoriesDisplayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)

            // Add button
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.yogaPrimary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Pose Detail Sheet for Picker

struct PoseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let pose: Pose
    let onAdd: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero section
                    VStack(spacing: 16) {
                        PoseImageView(imageURL: pose.imageURL, size: 150, cornerRadius: 16)

                        VStack(spacing: 4) {
                            Text(pose.nameEnglish)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(pose.nameSanskrit)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            Label(pose.categoriesDisplayName, systemImage: "tag")
                            Label(pose.difficulty.displayName, systemImage: "chart.bar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    // Benefits
                    if !pose.benefit.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Benefits")
                                .font(.yogaHeadline())

                            Text(pose.benefit)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Muscle Groups
                    if !pose.muscleGroup.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Muscle Groups")
                                .font(.yogaHeadline())

                            Text(pose.muscleGroup)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Mechanics
                    if !pose.mechanics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mechanics")
                                .font(.yogaHeadline())

                            VStack(alignment: .leading, spacing: 12) {
                                if !pose.mechanics.alignmentPrinciple.isEmpty {
                                    MechanicsRow(title: "Alignment Principle", content: pose.mechanics.alignmentPrinciple, icon: "arrow.up.and.down.and.arrow.left.and.right")
                                }
                                if !pose.mechanics.keyEngagement.isEmpty {
                                    MechanicsRow(title: "Key Engagement", content: pose.mechanics.keyEngagement, icon: "figure.strengthtraining.functional")
                                }
                                if !pose.mechanics.commonCorrection.isEmpty {
                                    MechanicsRow(title: "Common Correction", content: pose.mechanics.commonCorrection, icon: "exclamationmark.triangle")
                                }
                            }
                        }
                    }

                    // Sample Cues
                    if !pose.sampleCues.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Teaching Cues")
                                .font(.yogaHeadline())

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(pose.sampleCues.enumerated()), id: \.offset) { index, cue in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Color.yogaPrimary)
                                            .clipShape(Circle())

                                        Text(cue)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }

                    // Variations
                    if !pose.variations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Variations")
                                .font(.yogaHeadline())

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(pose.variations, id: \.self) { variation in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundStyle(Color.yogaPrimary)
                                            .padding(.top, 6)

                                        Text(variation)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Pose Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onAdd()
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onAdd()
                } label: {
                    Label("Add to Section", systemImage: "plus.circle.fill")
                        .font(.yogaHeadline())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yogaPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}

#Preview {
    PosePickerView(poses: MockPoseData.poses) { pose in
        print("Selected: \(pose.nameEnglish)")
    }
}
