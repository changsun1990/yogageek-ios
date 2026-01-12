//
//  PoseEntryRowView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct PoseEntryRowView: View {
    @Binding var poseEntry: PoseEntry
    let pose: Pose?
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                Image(systemName: pose?.imageURL ?? "questionmark.circle")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(pose?.nameEnglish ?? "Unknown Pose")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(pose?.nameSanskrit ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Duration picker
                Menu {
                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { seconds in
                        Button("\(seconds)s") {
                            poseEntry.duration = seconds
                        }
                    }
                } label: {
                    Text("\(poseEntry.duration)s")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // Custom cues
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Cues")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Add custom cues...", text: Binding(
                            get: { poseEntry.customCues.joined(separator: ", ") },
                            set: { poseEntry.customCues = $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
                        ), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Add notes...", text: $poseEntry.notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                    }

                    // Delete button
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Remove from Section", systemImage: "trash")
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    List {
        PoseEntryRowView(
            poseEntry: .constant(PoseEntry(poseId: "mountain", duration: 30)),
            pose: MockPoseData.poses[0],
            onDelete: {}
        )
    }
}
