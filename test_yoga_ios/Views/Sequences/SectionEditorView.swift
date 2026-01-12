//
//  SectionEditorView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct SectionEditorView: View {
    @Binding var section: YogaSection
    let onDelete: () -> Void
    let onAddPose: () -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    TextField("Section Name", text: $section.name)
                        .font(.headline)
                        .onTapGesture {} // Prevent collapse when editing

                    Spacer()

                    Text("\(section.poses.count) poses")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formattedDuration)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(Color(.systemGray6))
            }
            .buttonStyle(.plain)

            // Section content
            if isExpanded {
                VStack(spacing: 0) {
                    if section.poses.isEmpty {
                        VStack(spacing: 8) {
                            Text("No poses yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button {
                                onAddPose()
                            } label: {
                                Label("Add Pose", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach($section.poses) { $poseEntry in
                            PoseEntryRowView(
                                poseEntry: $poseEntry,
                                pose: MockPoseData.poses.first { $0.id == poseEntry.poseId },
                                onDelete: {
                                    withAnimation {
                                        section.poses.removeAll { $0.id == poseEntry.id }
                                    }
                                }
                            )
                            .padding(.horizontal)

                            if poseEntry.id != section.poses.last?.id {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                        .onMove { from, to in
                            section.poses.move(fromOffsets: from, toOffset: to)
                        }

                        Divider()

                        Button {
                            onAddPose()
                        } label: {
                            Label("Add Pose", systemImage: "plus")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }

                    Divider()

                    // Delete section button
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Section", systemImage: "trash")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
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

    private var formattedDuration: String {
        let totalSeconds = section.duration
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SectionEditorView(
                section: .constant(YogaSection(
                    name: "Warm Up",
                    poses: [
                        PoseEntry(poseId: "mountain"),
                        PoseEntry(poseId: "cat-cow")
                    ]
                )),
                onDelete: {},
                onAddPose: {}
            )

            SectionEditorView(
                section: .constant(YogaSection(name: "Empty Section")),
                onDelete: {},
                onAddPose: {}
            )
        }
        .padding()
    }
}
