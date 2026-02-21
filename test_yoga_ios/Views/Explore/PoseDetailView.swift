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
    @State private var showingFullscreenImage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image
                VStack(spacing: 16) {
                    PoseImageView(imageURL: pose.imageURL, size: nil, maxSize: 300, cornerRadius: 16)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            showingFullscreenImage = true
                        }

                    VStack(spacing: 4) {
                        Text(pose.nameEnglish)
                            .font(.yogaTitle())

                        Text(pose.nameSanskrit)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Label(pose.categoriesDisplayName, systemImage: "tag")
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
                            .background(Color.yogaPrimary)
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
                                        .background(Color.yogaPrimary)
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
                                                .foregroundStyle(Color.yogaPrimary)

                                            Text(variation)
                                                .font(.body)
                                                .foregroundStyle(.primary)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(10)
                                        .background(Color.yogaCardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // Non-tappable variation - not in Firestore
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundStyle(Color.yogaPrimary)
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
        .fullScreenCover(isPresented: $showingFullscreenImage) {
            FullscreenImageView(imageURL: pose.imageURL, poseName: pose.nameEnglish)
        }
    }

    // Find a pose by name (case-insensitive, partial match), excluding the current pose
    private func findPose(named name: String) -> Pose? {
        let lowercasedName = name.lowercased()
        let currentPoseName = pose.nameEnglish.lowercased()

        // If variation name matches current pose, don't link
        if lowercasedName == currentPoseName ||
           lowercasedName.contains(currentPoseName) ||
           currentPoseName.contains(lowercasedName) {
            return nil
        }

        // Find a different pose that matches
        return poses.first { p in
            p.id != pose.id && (
                p.nameEnglish.lowercased() == lowercasedName ||
                p.nameEnglish.lowercased().contains(lowercasedName) ||
                lowercasedName.contains(p.nameEnglish.lowercased())
            )
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
        .yogaFloatingShadow()
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.yogaHeadline())
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
        .background(Color.yogaPrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FullscreenImageView: View {
    let imageURL: String
    let poseName: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if imageURL.hasPrefix("http://") || imageURL.hasPrefix("https://") {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                scale = lastScale * value
                                            }
                                            .onEnded { _ in
                                                lastScale = scale
                                                if scale < 1.0 {
                                                    withAnimation {
                                                        scale = 1.0
                                                        lastScale = 1.0
                                                    }
                                                }
                                            }
                                    )
                                    .simultaneousGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if scale > 1.0 {
                                                    offset = CGSize(
                                                        width: lastOffset.width + value.translation.width,
                                                        height: lastOffset.height + value.translation.height
                                                    )
                                                }
                                            }
                                            .onEnded { _ in
                                                lastOffset = offset
                                            }
                                    )
                                    .onTapGesture(count: 2) {
                                        withAnimation {
                                            if scale > 1.0 {
                                                scale = 1.0
                                                lastScale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            } else {
                                                scale = 2.0
                                                lastScale = 2.0
                                            }
                                        }
                                    }
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.yoga")
                                        .font(.system(size: 80))
                                        .foregroundStyle(.gray)
                                    Text("Unable to load image")
                                        .foregroundStyle(.gray)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Image(systemName: imageURL)
                            .font(.system(size: 120))
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(poseName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    NavigationStack {
        PoseDetailView(pose: MockPoseData.poses[0], poses: MockPoseData.poses, sequenceViewModel: SequenceViewModel())
    }
}
