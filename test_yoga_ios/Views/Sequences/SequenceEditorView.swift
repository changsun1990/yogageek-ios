//
//  SequenceEditorView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct SequenceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SequenceViewModel
    let poses: [Pose]

    @State var sequence: YogaSequence
    let isNew: Bool

    @State private var showingPosePicker = false
    @State private var targetSectionIndex: Int?
    @State private var showingPractice = false

    var body: some View {
        NavigationStack {
            editorContent
                .background(Color(.systemGroupedBackground))
                .navigationTitle(isNew ? "New Sequence" : "Edit Sequence")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveSequence()
                        }
                        .fontWeight(.semibold)
                    }
                }
                .sheet(isPresented: $showingPosePicker) {
                    PosePickerView(poses: poses) { pose in
                        addPoseToSection(pose)
                    }
                }
                .fullScreenCover(isPresented: $showingPractice) {
                    PracticeView(sequence: sequence, poses: poses)
                }
        }
    }

    private var editorContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                sequenceInfoSection
                summarySection
                sectionsView
                practiceButton
            }
            .padding()
        }
    }

    private var sequenceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Sequence Name", text: $sequence.name)
                .font(.title2)
                .fontWeight(.bold)

            TextField("Description (optional)", text: $sequence.description, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var summarySection: some View {
        HStack(spacing: 20) {
            SummaryItem(
                icon: "rectangle.stack",
                value: "\(sequence.sections.count)",
                label: "Sections"
            )
            SummaryItem(
                icon: "figure.yoga",
                value: "\(sequence.totalPoseCount)",
                label: "Poses"
            )
            SummaryItem(
                icon: "clock",
                value: formattedTotalDuration,
                label: "Duration"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sectionsView: some View {
        VStack(spacing: 16) {
            ForEach($sequence.sections) { $section in
                SectionEditorView(
                    section: $section,
                    poses: poses,
                    onDelete: {
                        withAnimation {
                            sequence.sections.removeAll { $0.id == section.id }
                        }
                    },
                    onAddPose: {
                        if let idx = sequence.sections.firstIndex(where: { $0.id == section.id }) {
                            targetSectionIndex = idx
                            showingPosePicker = true
                        }
                    }
                )
            }

            Button {
                withAnimation {
                    sequence.sections.append(YogaSection())
                }
            } label: {
                Label("Add Section", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private var practiceButton: some View {
        if sequence.totalPoseCount > 0 {
            Button {
                showingPractice = true
            } label: {
                Label("Start Practice", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var formattedTotalDuration: String {
        let totalSeconds = sequence.totalDuration
        let minutes = totalSeconds / 60
        if minutes < 1 {
            return "\(totalSeconds)s"
        }
        return "\(minutes) min"
    }

    private func addPoseToSection(_ pose: Pose) {
        guard let index = targetSectionIndex, index < sequence.sections.count else { return }
        let poseEntry = PoseEntry(poseId: pose.id)
        withAnimation {
            sequence.sections[index].poses.append(poseEntry)
        }
    }

    private func saveSequence() {
        if isNew {
            viewModel.addSequence(sequence)
        } else {
            viewModel.updateSequence(sequence)
        }
        dismiss()
    }
}

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SequenceEditorView(
        viewModel: SequenceViewModel(),
        poses: MockPoseData.poses,
        sequence: YogaSequence(
            name: "Morning Flow",
            sections: [
                YogaSection(name: "Warm Up", poses: [
                    PoseEntry(poseId: "mountain"),
                    PoseEntry(poseId: "cat-cow")
                ])
            ]
        ),
        isNew: false
    )
}
