//
//  SequenceListView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct SequenceListView: View {
    var viewModel: SequenceViewModel
    let poses: [Pose]
    var communityViewModel: CommunityViewModel
    @State private var showingNewGroup = false
    @State private var newGroupName = ""
    @State private var expandedGroups: Set<String> = []
    @State private var sequenceToEdit: YogaSequence?
    @State private var sequenceToShare: YogaSequence?
    @State private var showingShareSheet = false
    @State private var groupForNewSequence: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.allGroups.isEmpty {
                    ContentUnavailableView(
                        "No Groups Yet",
                        systemImage: "folder",
                        description: Text("Create a group to organize your yoga sequences.")
                    )
                } else {
                    List {
                        ForEach(viewModel.allGroups, id: \.self) { group in
                            Section {
                                // Group header as expandable button
                                Button {
                                    withAnimation {
                                        if expandedGroups.contains(group) {
                                            expandedGroups.remove(group)
                                        } else {
                                            expandedGroups.insert(group)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: expandedGroups.contains(group) ? "folder.fill" : "folder")
                                            .font(.title2)
                                            .foregroundStyle(Color.accentColor)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(group)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

                                            let count = viewModel.sequences.filter { $0.group == group }.count
                                            Text("\(count) sequence\(count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: expandedGroups.contains(group) ? "chevron.down" : "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteGroup(group)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                // Expanded content - sequences
                                if expandedGroups.contains(group) {
                                    let groupSequences = viewModel.sequences
                                        .filter { $0.group == group }
                                        .sorted { $0.updatedAt > $1.updatedAt }

                                    ForEach(groupSequences) { sequence in
                                        Button {
                                            sequenceToEdit = sequence
                                        } label: {
                                            SequenceCardView(sequence: sequence)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.leading, 20)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                viewModel.deleteSequence(sequence)
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
                                                viewModel.deleteSequence(sequence)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }

                                    // Add sequence button inside the group
                                    Button {
                                        groupForNewSequence = group
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(Color.accentColor)
                                            Text("Add Sequence")
                                                .foregroundStyle(Color.accentColor)
                                        }
                                        .padding(.leading, 20)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Sequences")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewGroup = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .alert("New Group", isPresented: $showingNewGroup) {
                TextField("Group Name", text: $newGroupName)
                Button("Cancel", role: .cancel) {
                    newGroupName = ""
                }
                Button("Create") {
                    if !newGroupName.isEmpty {
                        viewModel.addGroup(newGroupName)
                        expandedGroups.insert(newGroupName)
                    }
                    newGroupName = ""
                }
            } message: {
                Text("Enter a name for the new group")
            }
            .sheet(item: $groupForNewSequence) { groupName in
                NewSequenceOptionsView(
                    viewModel: viewModel,
                    poses: poses,
                    groupName: groupName,
                    communityViewModel: communityViewModel
                )
            }
            .sheet(item: $sequenceToEdit) { sequence in
                SequenceEditorView(
                    viewModel: viewModel,
                    poses: poses,
                    communityViewModel: communityViewModel,
                    sequence: sequence,
                    isNew: false
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let sequence = sequenceToShare {
                    ShareSequenceView(sequence: sequence, communityViewModel: communityViewModel) {
                        showingShareSheet = false
                    }
                }
            }
        }
    }
}

#Preview {
    SequenceListView(viewModel: SequenceViewModel(), poses: MockPoseData.poses, communityViewModel: CommunityViewModel())
}
