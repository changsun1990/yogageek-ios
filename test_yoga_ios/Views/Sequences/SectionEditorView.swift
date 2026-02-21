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
                    .font(.yogaHeadline())

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
                .background(Color.yogaCardBackground)
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

    private var durationText: String {
        if let duration = poseEntry.duration {
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 && seconds > 0 {
                return "\(minutes)m \(seconds)s"
            } else if minutes > 0 {
                return "\(minutes)m"
            }
            return "\(seconds)s"
        }
        return "No time"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 10) {
                // Tappable pose info
                Button(action: onTap) {
                    HStack(spacing: 12) {
                        PoseImageView(imageURL: pose?.imageURL ?? "questionmark.circle", size: 50, cornerRadius: 10)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(pose?.nameEnglish ?? "Unknown Pose")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if let sanskrit = pose?.nameSanskrit, !sanskrit.isEmpty {
                                Text(sanskrit)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .italic()
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Duration badge
                if poseEntry.duration != nil {
                    Text(durationText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.yogaPrimary.opacity(0.85))
                        )
                }

                // Expand/collapse button for details
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isExpanded ? Color.orange : Color.yogaPrimary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)

                // Options menu
                Menu {
                    // Duration options
                    Menu {
                        Button {
                            poseEntry.duration = nil
                        } label: {
                            Label("No duration", systemImage: poseEntry.duration == nil ? "checkmark" : "")
                        }

                        Divider()

                        ForEach([15, 30, 45, 60, 90, 120, 180, 300], id: \.self) { seconds in
                            Button {
                                poseEntry.duration = seconds
                            } label: {
                                let label = seconds < 60 ? "\(seconds) seconds" : "\(seconds / 60) minute\(seconds >= 120 ? "s" : "")"
                                Label(label, systemImage: poseEntry.duration == seconds ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Set Duration", systemImage: "clock")
                    }

                    Divider()

                    if let moveUp = onMoveUp {
                        Button { moveUp() } label: {
                            Label("Move Up", systemImage: "arrow.up")
                        }
                    }

                    if let moveDown = onMoveDown {
                        Button { moveDown() } label: {
                            Label("Move Down", systemImage: "arrow.down")
                        }
                    }

                    if onMoveUp != nil || onMoveDown != nil {
                        Divider()
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("Remove Pose", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Expanded content - Details
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    // Divider with gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color(.systemGray4), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 14)

                    // Custom cues section
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Cues", systemImage: "text.bubble")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField("Add teaching cues...", text: Binding(
                            get: { poseEntry.customCues.joined(separator: ", ") },
                            set: { poseEntry.customCues = $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                        ), axis: .vertical)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 14)

                    // Notes section
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notes", systemImage: "note.text")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField("Add personal notes...", text: $poseEntry.notes, axis: .vertical)
                            .font(.subheadline)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(Color.yogaCardBackground)
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
