//
//  NewSequenceOptionsView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/28/26.
//

import SwiftUI

enum SequenceCreationOption: Identifiable {
    case guided
    case selfCreate
    case copyExisting

    var id: Self { self }
}

struct NewSequenceOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SequenceViewModel
    let poses: [Pose]
    var groupName: String = "My Sequences"
    var communityViewModel: CommunityViewModel?

    @State private var selectedOption: SequenceCreationOption?
    @State private var shouldDismissAfterSave = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("How would you like to create your sequence?")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                VStack(spacing: 16) {
                    // Option 1: Guided
                    OptionCard(
                        icon: "wand.and.stars",
                        title: "Guided Creation",
                        description: "Let the app guide you step by step based on category or peak poses",
                        isComingSoon: false
                    ) {
                        selectedOption = .guided
                    }

                    // Option 2: Self-create
                    OptionCard(
                        icon: "square.and.pencil",
                        title: "Build From Scratch",
                        description: "Create your own sections and add poses manually",
                        isComingSoon: false
                    ) {
                        selectedOption = .selfCreate
                    }

                    // Option 3: Copy from existing
                    OptionCard(
                        icon: "doc.on.doc",
                        title: "Copy From Existing",
                        description: "Start with sections from your existing sequences",
                        isComingSoon: false
                    ) {
                        selectedOption = .copyExisting
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("New Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(item: $selectedOption, onDismiss: {
                if shouldDismissAfterSave {
                    dismiss()
                }
            }) { option in
                switch option {
                case .guided:
                    GuidedSequenceBuilderView(
                        viewModel: viewModel,
                        poses: poses,
                        groupName: groupName,
                        onSave: {
                            shouldDismissAfterSave = true
                        }
                    )
                case .selfCreate:
                    SequenceEditorView(
                        viewModel: viewModel,
                        poses: poses,
                        communityViewModel: communityViewModel,
                        sequence: viewModel.createNewSequence(inGroup: groupName),
                        isNew: true,
                        onSave: {
                            shouldDismissAfterSave = true
                        }
                    )
                case .copyExisting:
                    CopyFromExistingView(
                        viewModel: viewModel,
                        poses: poses,
                        groupName: groupName,
                        communityViewModel: communityViewModel,
                        onSave: {
                            shouldDismissAfterSave = true
                        }
                    )
                }
            }
        }
    }
}

struct OptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isComingSoon: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(isComingSoon ? Color.secondary : Color.yogaPrimary)
                    .frame(width: 50, height: 50)
                    .background(isComingSoon ? Color(.systemGray5) : Color.yogaPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(isComingSoon ? .secondary : .primary)

                        if isComingSoon {
                            Text("Coming Soon")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if !isComingSoon {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.yogaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isComingSoon)
    }
}

#Preview {
    NewSequenceOptionsView(viewModel: SequenceViewModel(), poses: MockPoseData.poses)
}
