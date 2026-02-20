//
//  CopyFromExistingView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/29/26.
//

import SwiftUI

struct CopyFromExistingView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SequenceViewModel
    let poses: [Pose]
    var groupName: String = "My Sequences"
    var communityViewModel: CommunityViewModel?
    var onSave: (() -> Void)?

    @State private var selectedSections: [SelectedSection] = []
    @State private var sequenceName: String = ""
    @State private var showingEditor = false

    struct SelectedSection: Identifiable, Hashable {
        let id = UUID()
        let sourceSequenceId: String
        let sourceSequenceName: String
        let section: YogaSection
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.sequences.isEmpty {
                    emptyStateView
                } else {
                    selectionView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Copy Sections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        showingEditor = true
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedSections.isEmpty)
                }
            }
            .fullScreenCover(isPresented: $showingEditor) {
                SequenceEditorView(
                    viewModel: viewModel,
                    poses: poses,
                    communityViewModel: communityViewModel,
                    sequence: createSequenceFromSelection(),
                    isNew: true,
                    onSave: {
                        onSave?()
                        dismiss()
                    }
                )
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Sequences Yet",
            systemImage: "doc.on.doc",
            description: Text("Create a sequence first, then you can copy sections from it.")
        )
    }

    private var selectionView: some View {
        VStack(spacing: 0) {
            // Instructions
            Text("Select sections to copy into your new sequence")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()

            // Selection summary
            if !selectedSections.isEmpty {
                selectionSummary
            }

            // Sequences list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.sequences) { sequence in
                        ExistingSequenceCard(
                            sequence: sequence,
                            selectedSections: $selectedSections
                        )
                    }
                }
                .padding()
            }
        }
    }

    private var selectionSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(selectedSections.count) section\(selectedSections.count > 1 ? "s" : "") selected")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button("Clear All") {
                    withAnimation {
                        selectedSections.removeAll()
                    }
                }
                .font(.subheadline)
            }

            // Show selected section names
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedSections) { selection in
                        HStack(spacing: 4) {
                            Text(selection.section.name)
                                .font(.caption)

                            Button {
                                withAnimation {
                                    selectedSections.removeAll { $0.id == selection.id }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func createSequenceFromSelection() -> YogaSequence {
        // Create new sections from selected ones (with new IDs)
        let copiedSections = selectedSections.map { selection in
            YogaSection(
                name: selection.section.name,
                poses: selection.section.poses.map { pose in
                    PoseEntry(
                        poseId: pose.poseId,
                        customCues: pose.customCues,
                        notes: pose.notes,
                        duration: pose.duration
                    )
                }
            )
        }

        return YogaSequence(
            name: sequenceName.isEmpty ? "Copied Sequence" : sequenceName,
            sections: copiedSections,
            group: groupName
        )
    }
}

struct ExistingSequenceCard: View {
    let sequence: YogaSequence
    @Binding var selectedSections: [CopyFromExistingView.SelectedSection]

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Sequence header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(sequence.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("\(sequence.sections.count) sections • \(sequence.totalPoseCount) poses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Select all button
                    Button {
                        toggleAllSections()
                    } label: {
                        Text(allSectionsSelected ? "Deselect All" : "Select All")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(.plain)

            // Sections list
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(sequence.sections) { section in
                        SectionSelectionRow(
                            section: section,
                            sequenceId: sequence.id,
                            sequenceName: sequence.name,
                            isSelected: isSectionSelected(section),
                            onToggle: {
                                toggleSection(section)
                            }
                        )

                        if section.id != sequence.sections.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    private var allSectionsSelected: Bool {
        sequence.sections.allSatisfy { section in
            isSectionSelected(section)
        }
    }

    private func isSectionSelected(_ section: YogaSection) -> Bool {
        selectedSections.contains { $0.section.id == section.id && $0.sourceSequenceId == sequence.id }
    }

    private func toggleSection(_ section: YogaSection) {
        withAnimation {
            if isSectionSelected(section) {
                selectedSections.removeAll { $0.section.id == section.id && $0.sourceSequenceId == sequence.id }
            } else {
                let selection = CopyFromExistingView.SelectedSection(
                    sourceSequenceId: sequence.id,
                    sourceSequenceName: sequence.name,
                    section: section
                )
                selectedSections.append(selection)
            }
        }
    }

    private func toggleAllSections() {
        withAnimation {
            if allSectionsSelected {
                // Deselect all sections from this sequence
                selectedSections.removeAll { $0.sourceSequenceId == sequence.id }
            } else {
                // Select all sections from this sequence
                for section in sequence.sections {
                    if !isSectionSelected(section) {
                        let selection = CopyFromExistingView.SelectedSection(
                            sourceSequenceId: sequence.id,
                            sourceSequenceName: sequence.name,
                            section: section
                        )
                        selectedSections.append(selection)
                    }
                }
            }
        }
    }
}

struct SectionSelectionRow: View {
    let section: YogaSection
    let sequenceId: String
    let sequenceName: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text("\(section.poses.count) poses • \(formattedDuration)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    private var formattedDuration: String {
        let totalSeconds = section.duration
        let minutes = totalSeconds / 60
        if minutes > 0 {
            return "\(minutes) min"
        }
        return "\(totalSeconds)s"
    }
}

#Preview {
    CopyFromExistingView(viewModel: SequenceViewModel(), poses: MockPoseData.poses)
}
