//
//  PoseDetailView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct PoseDetailView: View {
    let pose: Pose
    let poses: [Pose]
    var sequenceViewModel: SequenceViewModel

    @State private var showingAddToSequence = false
    @State private var showingConfirmation = false
    @State private var confirmationMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image
                VStack(spacing: 16) {
                    PoseImageView(imageURL: pose.imageURL, size: nil, maxSize: 300, cornerRadius: 16)
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text(pose.nameEnglish)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(pose.nameSanskrit)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Label(pose.category.displayName, systemImage: "tag")
                        Label(pose.difficulty.displayName, systemImage: "chart.bar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Add to Sequence Button
                    Button {
                        showingAddToSequence = true
                    } label: {
                        Label("Add to Sequence", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                Divider()

                // Description
                if !pose.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Description", systemImage: "text.alignleft")

                        Text(pose.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Benefits
                if !pose.benefit.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Benefits", systemImage: "heart.fill")

                        Text(pose.benefit)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Muscle Groups
                if !pose.muscleGroup.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Muscle Groups", systemImage: "figure.strengthtraining.traditional")

                        Text(pose.muscleGroup)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Mechanics
                if !pose.mechanics.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Mechanics", systemImage: "gearshape.2")

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
                    .padding(.horizontal)
                }

                // Sample Cues
                if !pose.sampleCues.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Teaching Cues", systemImage: "quote.bubble")

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(pose.sampleCues.enumerated()), id: \.offset) { index, cue in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())

                                    Text(cue)
                                        .font(.body)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Variations
                if !pose.variations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Variations", systemImage: "arrow.triangle.branch")

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(pose.variations, id: \.self) { variation in
                                if let matchingPose = findPose(named: variation) {
                                    // Tappable variation - links to existing pose
                                    NavigationLink(value: matchingPose) {
                                        HStack(alignment: .center, spacing: 12) {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color.accentColor)

                                            Text(variation)
                                                .font(.body)
                                                .foregroundStyle(.primary)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(10)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // Non-tappable variation - not in Firestore
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundStyle(Color.accentColor)
                                            .padding(.top, 6)

                                        Text(variation)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer().frame(height: 32)
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddToSequence) {
            AddToSequenceView(pose: pose, poses: poses, viewModel: sequenceViewModel) { sequenceName, sectionName in
                confirmationMessage = "Added to \(sectionName) in \(sequenceName)"
                showingConfirmation = true
            }
        }
        .overlay(alignment: .top) {
            if showingConfirmation {
                confirmationBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showingConfirmation = false
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: showingConfirmation)
    }

    // Find a pose by name (case-insensitive, partial match)
    private func findPose(named name: String) -> Pose? {
        let lowercasedName = name.lowercased()
        return poses.first { pose in
            pose.nameEnglish.lowercased() == lowercasedName ||
            pose.nameEnglish.lowercased().contains(lowercasedName) ||
            lowercasedName.contains(pose.nameEnglish.lowercased())
        }
    }

    private var confirmationBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)

            Text(confirmationMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding()
        .background(Color.green)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}

struct MechanicsRow: View {
    let title: String
    let content: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        PoseDetailView(pose: MockPoseData.poses[0], poses: MockPoseData.poses, sequenceViewModel: SequenceViewModel())
    }
}
