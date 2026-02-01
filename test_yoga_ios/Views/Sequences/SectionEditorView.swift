//
//  SectionEditorView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SectionEditorView: View {
    @Binding var section: YogaSection
    let poses: [Pose]
    let onDelete: () -> Void
    let onAddPose: () -> Void
    var onPoseTap: ((Pose) -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onShare: (() -> Void)?

    @State private var isExpanded = true
    @State private var draggingPoseId: String?

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 0) {
                // Expand/collapse button
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 44)
                }
                .buttonStyle(.plain)

                // Section name
                TextField("Section Name", text: $section.name)
                    .font(.headline)

                Spacer()

                // Pose count and duration
                Text("\(section.poses.count) poses")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(formattedDuration)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                    .padding(.leading, 4)

                // Section actions menu
                Menu {
                    if let moveUp = onMoveUp {
                        Button {
                            moveUp()
                        } label: {
                            Label("Move Up", systemImage: "arrow.up")
                        }
                    }
                    if let moveDown = onMoveDown {
                        Button {
                            moveDown()
                        } label: {
                            Label("Move Down", systemImage: "arrow.down")
                        }
                    }

                    if onMoveUp != nil || onMoveDown != nil {
                        Divider()
                    }

                    if let share = onShare, !section.poses.isEmpty {
                        Button {
                            share()
                        } label: {
                            Label("Share Section", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Section", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))

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
                        // Pose list with drag and drop reordering
                        VStack(spacing: 0) {
                            ForEach(Array(section.poses.enumerated()), id: \.element.id) { index, poseEntry in
                                let pose = poses.first { $0.id == poseEntry.poseId }
                                let isFirst = index == 0
                                let isLast = index == section.poses.count - 1

                                PoseRowView(
                                    poseEntry: $section.poses[index],
                                    pose: pose,
                                    onTap: { if let pose { onPoseTap?(pose) } },
                                    onMoveUp: isFirst ? nil : {
                                        if let idx = section.poses.firstIndex(where: { $0.id == poseEntry.id }), idx > 0 {
                                            withAnimation { section.poses.swapAt(idx, idx - 1) }
                                        }
                                    },
                                    onMoveDown: isLast ? nil : {
                                        if let idx = section.poses.firstIndex(where: { $0.id == poseEntry.id }), idx < section.poses.count - 1 {
                                            withAnimation { section.poses.swapAt(idx, idx + 1) }
                                        }
                                    },
                                    onDelete: {
                                        withAnimation { section.poses.removeAll { $0.id == poseEntry.id } }
                                    }
                                )
                                .opacity(draggingPoseId == poseEntry.id ? 0.5 : 1.0)
                                .onDrag {
                                    draggingPoseId = poseEntry.id
                                    return NSItemProvider(object: poseEntry.id as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: PoseDropDelegate(
                                    poseId: poseEntry.id,
                                    poses: $section.poses,
                                    draggingPoseId: $draggingPoseId
                                ))

                                if !isLast {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .padding(.vertical, 8)

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
        if totalSeconds == 0 {
            return "-"
        }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Pose Row View

struct PoseRowView: View {
    @Binding var poseEntry: PoseEntry
    let pose: Pose?
    let onTap: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Tappable pose info
                Button(action: onTap) {
                    HStack(spacing: 12) {
                        PoseImageView(imageURL: pose?.imageURL ?? "questionmark.circle", size: 44, cornerRadius: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pose?.nameEnglish ?? "Unknown Pose")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)

                            Text(pose?.nameSanskrit ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                // Duration picker
                Menu {
                    Button("No duration") {
                        poseEntry.duration = nil
                    }

                    Divider()

                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { seconds in
                        Button("\(seconds)s") {
                            poseEntry.duration = seconds
                        }
                    }
                } label: {
                    Text(poseEntry.duration.map { "\($0)s" } ?? "-")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                // Options menu
                Menu {
                    if let moveUp = onMoveUp {
                        Button {
                            moveUp()
                        } label: {
                            Label("Move Up", systemImage: "arrow.up")
                        }
                    }

                    if let moveDown = onMoveDown {
                        Button {
                            moveDown()
                        } label: {
                            Label("Move Down", systemImage: "arrow.down")
                        }
                    }

                    if onMoveUp != nil || onMoveDown != nil {
                        Divider()
                    }

                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Label(isExpanded ? "Hide Details" : "Show Details", systemImage: isExpanded ? "chevron.up" : "info.circle")
                    }

                    Divider()

                    Button(role: .destructive, action: onDelete) {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 12)

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
                    .padding(.horizontal, 12)

                    // Notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Add notes...", text: $poseEntry.notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

// MARK: - Drop Delegate

struct PoseDropDelegate: DropDelegate {
    let poseId: String
    @Binding var poses: [PoseEntry]
    @Binding var draggingPoseId: String?

    func performDrop(info: DropInfo) -> Bool {
        draggingPoseId = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingId = draggingPoseId,
              draggingId != poseId,
              let fromIndex = poses.firstIndex(where: { $0.id == draggingId }),
              let toIndex = poses.firstIndex(where: { $0.id == poseId }) else {
            return
        }

        withAnimation(.default) {
            poses.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SectionEditorView(
                section: .constant(YogaSection(
                    name: "Warm Up",
                    poses: [
                        PoseEntry(poseId: "mountain-pose"),
                        PoseEntry(poseId: "standing-forward-fold"),
                        PoseEntry(poseId: "downward-facing-dog")
                    ]
                )),
                poses: MockPoseData.poses,
                onDelete: {},
                onAddPose: {},
                onPoseTap: { _ in }
            )

            SectionEditorView(
                section: .constant(YogaSection(name: "Empty Section")),
                poses: MockPoseData.poses,
                onDelete: {},
                onAddPose: {}
            )
        }
        .padding()
    }
}
