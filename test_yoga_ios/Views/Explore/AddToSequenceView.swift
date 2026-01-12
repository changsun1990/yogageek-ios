//
//  AddToSequenceView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct AddToSequenceView: View {
    @Environment(\.dismiss) private var dismiss
    let pose: Pose
    var viewModel: SequenceViewModel
    var onAdded: ((String, String) -> Void)? // (sequenceName, sectionName)

    @State private var selectedSequenceId: String?
    @State private var selectedSectionId: String?
    @State private var showingNewSequence = false

    var selectedSequence: YogaSequence? {
        viewModel.sequences.first { $0.id == selectedSequenceId }
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.sequences.isEmpty {
                    emptyState
                } else {
                    sequenceSelectionSection
                    if selectedSequence != nil {
                        sectionSelectionSection
                    }
                }
            }
            .navigationTitle("Add to Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPoseToSequence()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedSequenceId == nil || selectedSectionId == nil)
                }
            }
            .sheet(isPresented: $showingNewSequence) {
                SequenceEditorView(
                    viewModel: viewModel,
                    sequence: viewModel.createNewSequence(),
                    isNew: true
                )
            }
        }
    }

    private var emptyState: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("No Sequences Yet")
                    .font(.headline)

                Text("Create a sequence first to add poses to it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showingNewSequence = true
                } label: {
                    Label("Create Sequence", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    private var sequenceSelectionSection: some View {
        Section {
            ForEach(viewModel.sequences) { sequence in
                Button {
                    selectedSequenceId = sequence.id
                    // Auto-select first section if available
                    selectedSectionId = sequence.sections.first?.id
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sequence.name.isEmpty ? "Untitled" : sequence.name)
                                .foregroundStyle(.primary)
                            Text("\(sequence.sections.count) sections, \(sequence.totalPoseCount) poses")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedSequenceId == sequence.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }

            Button {
                showingNewSequence = true
            } label: {
                Label("Create New Sequence", systemImage: "plus")
            }
        } header: {
            Text("Select Sequence")
        }
    }

    private var sectionSelectionSection: some View {
        Section {
            if let sequence = selectedSequence {
                if sequence.sections.isEmpty {
                    Text("No sections in this sequence")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sequence.sections) { section in
                        Button {
                            selectedSectionId = section.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(section.name)
                                        .foregroundStyle(.primary)
                                    Text("\(section.poses.count) poses")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selectedSectionId == section.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Select Section")
        }
    }

    private func addPoseToSequence() {
        guard let sequenceId = selectedSequenceId,
              let sectionId = selectedSectionId,
              var sequence = viewModel.sequences.first(where: { $0.id == sequenceId }),
              let sectionIndex = sequence.sections.firstIndex(where: { $0.id == sectionId }) else {
            return
        }

        let sequenceName = sequence.name.isEmpty ? "Untitled" : sequence.name
        let sectionName = sequence.sections[sectionIndex].name

        let poseEntry = PoseEntry(poseId: pose.id)
        sequence.sections[sectionIndex].poses.append(poseEntry)
        viewModel.updateSequence(sequence)

        onAdded?(sequenceName, sectionName)
        dismiss()
    }
}

#Preview {
    AddToSequenceView(
        pose: MockPoseData.poses[0],
        viewModel: SequenceViewModel()
    )
}
