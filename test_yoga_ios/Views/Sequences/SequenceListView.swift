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
    @State private var sequenceToShare: YogaSequence?
    @State private var showingShareSheet = false

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let index = viewModel.sequences.firstIndex(where: { $0.id == sequence.id }) {
                                        viewModel.deleteSequence(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    sequenceToShare = sequence
                                    showingShareSheet = true
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    sequenceToEdit = sequence
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button {
                                    sequenceToShare = sequence
                                    showingShareSheet = true
                                } label: {
                                    Label("Share to Community", systemImage: "square.and.arrow.up")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    if let index = viewModel.sequences.firstIndex(where: { $0.id == sequence.id }) {
                                        viewModel.deleteSequence(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Sequences")
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
                NewSequenceOptionsView(
                    viewModel: viewModel,
                    poses: poses
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
            .sheet(isPresented: $showingShareSheet) {
                if let sequence = sequenceToShare {
                    ShareSequenceView(sequence: sequence) {
                        showingShareSheet = false
                    }
                }
            }
        }
    }
}

#Preview {
    SequenceListView(viewModel: SequenceViewModel(), poses: MockPoseData.poses)
}
