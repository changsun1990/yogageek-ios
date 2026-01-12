//
//  PosePickerView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct PosePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Pose) -> Void

    @State private var searchText = ""

    private var filteredPoses: [Pose] {
        if searchText.isEmpty {
            return MockPoseData.poses
        }
        return MockPoseData.poses.filter { pose in
            pose.nameEnglish.localizedCaseInsensitiveContains(searchText) ||
            pose.nameSanskrit.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredPoses) { pose in
                Button {
                    onSelect(pose)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: pose.imageURL)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pose.nameEnglish)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)

                            Text(pose.nameSanskrit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Text(pose.category.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())

                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("Add Pose")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search poses")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PosePickerView { pose in
        print("Selected: \(pose.nameEnglish)")
    }
}
