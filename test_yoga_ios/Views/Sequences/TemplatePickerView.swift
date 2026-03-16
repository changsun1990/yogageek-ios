//
//  TemplatePickerView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SequenceViewModel
    let poses: [Pose]
    var groupName: String = "My Sequences"
    var communityViewModel: CommunityViewModel?
    var onSave: (() -> Void)?

    @State private var selectedTemplate: YogaSequence?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates Yet",
                        systemImage: "bookmark",
                        description: Text("Save a sequence as a template to use it here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.templates) { template in
                            Button {
                                selectedTemplate = template
                            } label: {
                                SequenceCardView(sequence: template)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteSequence(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(item: $selectedTemplate) { template in
                SequenceEditorView(
                    viewModel: viewModel,
                    poses: poses,
                    communityViewModel: communityViewModel,
                    sequence: viewModel.createFromTemplate(template, inGroup: groupName),
                    isNew: true,
                    onSave: {
                        onSave?()
                        dismiss()
                    }
                )
            }
        }
    }
}

#Preview {
    TemplatePickerView(viewModel: SequenceViewModel(), poses: MockPoseData.poses)
}
