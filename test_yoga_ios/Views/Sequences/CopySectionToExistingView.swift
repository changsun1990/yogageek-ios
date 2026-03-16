//
//  CopySectionToExistingView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import SwiftUI

struct CopySectionToExistingView: View {
    @Environment(\.dismiss) private var dismiss
    let section: YogaSection
    var viewModel: SequenceViewModel

    @State private var selectedSequenceId: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.regularSequences.isEmpty {
                    ContentUnavailableView(
                        "No Sequences",
                        systemImage: "doc.on.doc",
                        description: Text("Create a sequence first to copy this section into it.")
                    )
                } else {
                    List {
                        ForEach(viewModel.regularSequences) { sequence in
                            Button {
                                selectedSequenceId = sequence.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sequence.name.isEmpty ? "Untitled" : sequence.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)

                                        Text("\(sequence.sections.count) sections \u{2022} \(sequence.totalPoseCount) poses")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedSequenceId == sequence.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.yogaPrimary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Copy Section To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let seqId = selectedSequenceId {
                            viewModel.appendSectionToSequence(section, sequenceId: seqId)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedSequenceId == nil)
                }
            }
        }
    }
}

#Preview {
    CopySectionToExistingView(
        section: YogaSection(name: "Warm Up", poses: [PoseEntry(poseId: "mountain")]),
        viewModel: SequenceViewModel()
    )
}
