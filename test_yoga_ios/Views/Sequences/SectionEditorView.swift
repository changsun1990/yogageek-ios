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
    var onPractice: (() -> Void)?
    var onCopyToNew: (() -> Void)?
    var onCopyToExisting: (() -> Void)?

    @State private var isExpanded = true
    @State private var draggingPoseId: String?
    @State private var showingDurationInput = false
    @State private var durationMinutesText = ""

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

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDurationInput.toggle()
                        if showingDurationInput {
                            let minutes = (section.sectionDuration ?? section.poseDuration) / 60
                            durationMinutesText = minutes > 0 ? "\(minutes)" : ""
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(formattedDuration)
                            .font(.caption)
                            .fontWeight(section.sectionDuration != nil ? .medium : .regular)
                            .foregroundStyle(section.sectionDuration != nil ? .white : .primary)
                        Image(systemName: "pencil")
                            .font(.system(size: 8))
                            .foregroundStyle(section.sectionDuration != nil ? .white.opacity(0.8) : .secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(section.sectionDuration != nil ? Color.yogaPrimary.opacity(0.85) : Color(.systemGray5))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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

                    if !section.poses.isEmpty {
                        if let practice = onPractice {
                            Button {
                                practice()
                            } label: {
                                Label("Practice Section", systemImage: "play.fill")
                            }
                        }

                        if let share = onShare {
                            Button {
                                share()
                            } label: {
                                Label("Share Section", systemImage: "square.and.arrow.up")
                            }
                        }

                        if let copyToNew = onCopyToNew {
                            Button {
                                copyToNew()
                            } label: {
                                Label("Copy to New Sequence", systemImage: "doc.badge.plus")
                            }
                        }

                        if let copyToExisting = onCopyToExisting {
                            Button {
                                copyToExisting()
                            } label: {
                                Label("Copy to Existing Sequence", systemImage: "arrow.right.doc.on.clipboard")
                            }
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

            // Inline duration editor
            if showingDurationInput {
                sectionDurationEditor
            }

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
                                    onDuplicate: {
                                        let original = poseEntry
                                        let duplicate = PoseEntry(
                                            poseId: original.poseId,
                                            customCues: original.customCues,
                                            notes: original.notes,
                                            duration: original.duration,
                                            customName: original.customName,
                                            breath: original.breath
                                        )
                                        if let idx = section.poses.firstIndex(where: { $0.id == poseEntry.id }) {
                                            withAnimation { section.poses.insert(duplicate, at: idx + 1) }
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

    private var sectionDurationEditor: some View {
        HStack(spacing: 12) {
            // Toggle custom duration
            Toggle(isOn: Binding(
                get: { section.sectionDuration != nil },
                set: { enabled in
                    if enabled {
                        let poseTotal = section.poseDuration
                        section.sectionDuration = poseTotal > 0 ? poseTotal : 300
                        durationMinutesText = "\((section.sectionDuration ?? 300) / 60)"
                    } else {
                        section.sectionDuration = nil
                    }
                }
            )) {
                Text("Custom")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            if section.sectionDuration != nil {
                HStack(spacing: 6) {
                    Button {
                        let current = section.sectionDuration ?? 0
                        section.sectionDuration = max(0, current - 60)
                        durationMinutesText = "\((section.sectionDuration ?? 0) / 60)"
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    TextField("0", text: $durationMinutesText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onChange(of: durationMinutesText) { _, newValue in
                            if let minutes = Int(newValue) {
                                section.sectionDuration = minutes * 60
                            }
                        }

                    Text("min")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        let current = section.sectionDuration ?? 0
                        section.sectionDuration = min(7200, current + 60)
                        durationMinutesText = "\((section.sectionDuration ?? 0) / 60)"
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.yogaPrimary)
                    }
                    .buttonStyle(.plain)
                }
            } else if section.poseDuration > 0 {
                Text("From poses: \(section.poseDuration / 60)m \(section.poseDuration % 60)s")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.yogaPrimary.opacity(0.05))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var formattedDuration: String {
        let totalSeconds = section.effectiveDuration
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
    var onDuplicate: (() -> Void)?
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var durationInputText = ""
    @State private var durationUnit: DurationUnit = .seconds

    enum DurationUnit: String, CaseIterable {
        case seconds = "sec"
        case minutes = "min"
    }

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
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 10) {
                // Tappable pose info
                Button(action: onTap) {
                    HStack(spacing: 12) {
                        if let pose, !pose.imageURL.isEmpty {
                            PoseImageView(imageURL: pose.imageURL, size: 50, cornerRadius: 10)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        } else {
                            Image(systemName: "figure.yoga")
                                .font(.title3)
                                .foregroundStyle(Color.yogaPrimary)
                                .frame(width: 50, height: 50)
                                .background(Color.yogaPrimary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(pose?.nameEnglish ?? poseEntry.customName ?? "Unknown Pose")
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
                            } else if poseEntry.customName != nil {
                                Text("Custom pose")
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

                // Duration badge (read-only, tap row + to edit)
                if poseEntry.duration != nil {
                    Text(durationText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yogaPrimary.opacity(0.85)))
                }

                // Expand/collapse button for details (duration, cues, notes)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                        if isExpanded {
                            syncDurationInput()
                        }
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

                    if let duplicate = onDuplicate {
                        Button { duplicate() } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

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

            // Expanded content - Duration, Cues, Notes
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

                    // Duration section
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Duration", systemImage: "clock")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            TextField("0", text: $durationInputText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 50)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .onChange(of: durationInputText) { _, newValue in
                                    if let value = Int(newValue), value > 0 {
                                        poseEntry.duration = durationUnit == .minutes ? value * 60 : value
                                    } else if newValue.isEmpty {
                                        poseEntry.duration = nil
                                    }
                                }

                            Picker("", selection: $durationUnit) {
                                ForEach(DurationUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                            .onChange(of: durationUnit) { _, newUnit in
                                if let value = Int(durationInputText), value > 0 {
                                    poseEntry.duration = newUnit == .minutes ? value * 60 : value
                                }
                            }

                            Spacer()

                            if poseEntry.duration != nil {
                                Button {
                                    poseEntry.duration = nil
                                    durationInputText = ""
                                } label: {
                                    Text("Clear")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 14)

                    // Breath section
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Breath", systemImage: "wind")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            breathOption("Inhale")
                            breathOption("Exhale")
                        }
                    }
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

    private func breathOption(_ label: String) -> some View {
        let isSelected = poseEntry.breath == label
        return Button {
            poseEntry.breath = isSelected ? "" : label
        } label: {
            HStack(spacing: 4) {
                Image(systemName: label == "Inhale" ? "arrow.down" : "arrow.up")
                    .font(.caption2)
                Text(label)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.yogaPrimary.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? Color.yogaPrimary : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.yogaPrimary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func syncDurationInput() {
        if let d = poseEntry.duration {
            if d >= 60 && d % 60 == 0 {
                durationUnit = .minutes
                durationInputText = "\(d / 60)"
            } else {
                durationUnit = .seconds
                durationInputText = "\(d)"
            }
        } else {
            durationUnit = .seconds
            durationInputText = ""
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
