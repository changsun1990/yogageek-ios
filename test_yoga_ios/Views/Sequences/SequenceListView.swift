//
//  SequenceListView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct SequenceListView: View {
    var viewModel: SequenceViewModel
    let poses: [Pose]
    @State private var showingNewSequence = false
    @State private var sequenceToEdit: YogaSequence?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sequences.isEmpty {
                    ContentUnavailableView(
                        "No Sequences Yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Create your first yoga sequence to get started.")
                    )
                } else {
                    List {
                        ForEach(viewModel.sequences) { sequence in
                            Button {
                                sequenceToEdit = sequence
                            } label: {
                                SequenceCardView(sequence: sequence)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            viewModel.deleteSequence(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Sequences")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewSequence = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewSequence) {
                SequenceEditorView(
                    viewModel: viewModel,
                    poses: poses,
                    sequence: viewModel.createNewSequence(),
                    isNew: true
                )
            }
            .sheet(item: $sequenceToEdit) { sequence in
                SequenceEditorView(
                    viewModel: viewModel,
                    poses: poses,
                    sequence: sequence,
                    isNew: false
                )
            }
        }
    }
}

#Preview {
    SequenceListView(viewModel: SequenceViewModel(), poses: MockPoseData.poses)
}
