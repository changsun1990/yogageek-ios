//
//  PoseDetailView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct PoseDetailView: View {
    let pose: Pose
    var sequenceViewModel: SequenceViewModel

    @State private var showingAddToSequence = false
    @State private var showingConfirmation = false
    @State private var confirmationMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image
                VStack(spacing: 16) {
                    Image(systemName: pose.imageURL)
                        .font(.system(size: 100))
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

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
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Description", systemImage: "text.alignleft")

                    Text(pose.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Example Cues
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Example Cues", systemImage: "quote.bubble")

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(pose.exampleCues.enumerated()), id: \.offset) { index, cue in
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

                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Benefits", systemImage: "heart")

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(pose.benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)

                                Text(benefit)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddToSequence) {
            AddToSequenceView(pose: pose, viewModel: sequenceViewModel) { sequenceName, sectionName in
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

#Preview {
    NavigationStack {
        PoseDetailView(pose: MockPoseData.poses[0], sequenceViewModel: SequenceViewModel())
    }
}
