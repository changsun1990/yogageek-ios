//
//  SequenceEditorView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct SequenceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SequenceViewModel
    let poses: [Pose]
    var communityViewModel: CommunityViewModel?

    @State var sequence: YogaSequence
    let isNew: Bool
    var onSave: (() -> Void)?

    @State private var showingPosePicker = false
    @State private var targetSectionIndex: Int?
    @State private var showingPractice = false
    @State private var selectedPoseForDetail: Pose?
    @State private var sectionToShare: YogaSection?
    @State private var showingShareSection = false
    @State private var showingShareSequence = false
    @State private var practiceStartSection: Int?
    @State private var showingMusicPicker = false
    @State private var showingDurationEditor = false
    @State private var musicManager = MusicManager.shared
    @State private var sectionToCopyToNew: YogaSection?
    @State private var showingCopySectionToNew = false
    @State private var sectionToCopyToExisting: YogaSection?
    @State private var showingCopySectionToExisting = false

    var body: some View {
        NavigationStack {
            editorContent
                .yogaScreenBackground()
                .navigationTitle(isNew ? "New Sequence" : "Edit Sequence")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 16) {
                            if sequence.totalPoseCount > 0, communityViewModel != nil {
                                Button {
                                    showingShareSequence = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }

                            Button("Save") {
                                saveSequence()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
                .sheet(isPresented: $showingPosePicker) {
                    PosePickerView(poses: poses) { pose in
                        addPoseToSection(pose)
                    }
                }
                .fullScreenCover(isPresented: $showingPractice) {
                    PracticeView(sequence: sequence, poses: poses)
                }
                .fullScreenCover(isPresented: Binding(
                    get: { practiceStartSection != nil },
                    set: { if !$0 { practiceStartSection = nil } }
                )) {
                    PracticeView(sequence: sequence, poses: poses, startAtSection: practiceStartSection)
                }
                .sheet(isPresented: $showingMusicPicker) {
                    MusicPickerView(musicManager: musicManager)
                }
                .sheet(isPresented: $showingDurationEditor) {
                    DurationEditorView(sequence: $sequence)
                }
                .sheet(item: $selectedPoseForDetail) { pose in
                    PoseDetailSheet(pose: pose) {
                        // Just close the detail view, pose is already in section
                        selectedPoseForDetail = nil
                    }
                }
                .sheet(isPresented: $showingShareSection) {
                    if let section = sectionToShare {
                        ShareSectionView(section: section, poses: poses) {
                            showingShareSection = false
                        }
                    }
                }
                .sheet(isPresented: $showingShareSequence) {
                    if let communityViewModel {
                        ShareSequenceView(sequence: sequence, communityViewModel: communityViewModel) {
                            showingShareSequence = false
                        }
                    }
                }
                .fullScreenCover(isPresented: $showingCopySectionToNew) {
                    if let section = sectionToCopyToNew {
                        SequenceEditorView(
                            viewModel: viewModel,
                            poses: poses,
                            communityViewModel: communityViewModel,
                            sequence: YogaSequence(
                                name: "",
                                sections: [viewModel.copySection(section)],
                                group: sequence.group
                            ),
                            isNew: true
                        )
                    }
                }
                .sheet(isPresented: $showingCopySectionToExisting) {
                    if let section = sectionToCopyToExisting {
                        CopySectionToExistingView(
                            section: section,
                            viewModel: viewModel
                        )
                    }
                }
        }
    }

    private var editorContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                sequenceInfoSection
                summarySection
                sectionsView
                practiceButton
            }
            .padding()
        }
    }

    private var sequenceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Sequence Name", text: $sequence.name)
                .font(.title2)
                .fontWeight(.bold)

            TextField("Description (optional)", text: $sequence.description, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.yogaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            SummaryItem(
                icon: "rectangle.stack",
                value: "\(sequence.sections.count)",
                label: "Sections"
            )
            SummaryItem(
                icon: "figure.yoga",
                value: "\(sequence.totalPoseCount)",
                label: "Poses"
            )

            // Tappable Duration
            Button {
                showingDurationEditor = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(Color.yogaPrimary)
                    Text(formattedTotalDuration)
                        .font(.yogaHeadline())
                    HStack(spacing: 2) {
                        Text("Duration")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color.yogaPrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            // Music
            Button {
                showingMusicPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: musicManager.activeService != .none ? "music.note.list" : "music.note")
                        .font(.title2)
                        .foregroundStyle(musicManager.activeService != .none ? Color.yogaPrimary : Color.accentColor)
                    Text(musicManager.activeService != .none ? "Playing" : "Off")
                        .font(.yogaHeadline())
                    HStack(spacing: 2) {
                        Text("Music")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color.yogaPrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.yogaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sectionsView: some View {
        VStack(spacing: 16) {
            ForEach(Array(sequence.sections.enumerated()), id: \.element.id) { index, section in
                SectionEditorView(
                    section: Binding(
                        get: { sequence.sections[index] },
                        set: { sequence.sections[index] = $0 }
                    ),
                    poses: poses,
                    onDelete: {
                        withAnimation {
                            _ = sequence.sections.remove(at: index)
                        }
                    },
                    onAddPose: {
                        targetSectionIndex = index
                        showingPosePicker = true
                    },
                    onPoseTap: { pose in
                        selectedPoseForDetail = pose
                    },
                    onMoveUp: index > 0 ? {
                        withAnimation {
                            sequence.sections.swapAt(index, index - 1)
                        }
                    } : nil,
                    onMoveDown: index < sequence.sections.count - 1 ? {
                        withAnimation {
                            sequence.sections.swapAt(index, index + 1)
                        }
                    } : nil,
                    onShare: {
                        sectionToShare = sequence.sections[index]
                        showingShareSection = true
                    },
                    onPractice: section.poses.isEmpty ? nil : {
                        practiceStartSection = index
                    },
                    onCopyToNew: section.poses.isEmpty ? nil : {
                        sectionToCopyToNew = sequence.sections[index]
                        showingCopySectionToNew = true
                    },
                    onCopyToExisting: section.poses.isEmpty ? nil : {
                        sectionToCopyToExisting = sequence.sections[index]
                        showingCopySectionToExisting = true
                    }
                )
            }

            Button {
                withAnimation {
                    sequence.sections.append(YogaSection())
                }
            } label: {
                Label("Add Section", systemImage: "plus.circle.fill")
                    .font(.yogaHeadline())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private var practiceButton: some View {
        if sequence.totalPoseCount > 0 {
            Button {
                showingPractice = true
            } label: {
                Label("Start Practice", systemImage: "play.fill")
                    .font(.yogaHeadline())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yogaPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var formattedTotalDuration: String {
        let totalSeconds = sequence.totalDuration
        let minutes = totalSeconds / 60
        if minutes < 1 {
            return "\(totalSeconds)s"
        }
        return "\(minutes) min"
    }

    private func addPoseToSection(_ pose: Pose) {
        guard let index = targetSectionIndex, index < sequence.sections.count else { return }
        let isCustom = pose.id.hasPrefix("custom-")
        let poseEntry = PoseEntry(poseId: pose.id, customName: isCustom ? pose.nameEnglish : nil)
        withAnimation {
            sequence.sections[index].poses.append(poseEntry)
        }
    }

    private func saveSequence() {
        if isNew {
            viewModel.addSequence(sequence)
        } else {
            viewModel.updateSequence(sequence)
        }
        onSave?()
        dismiss()
    }
}

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)

            Text(value)
                .font(.yogaHeadline())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SequenceEditorView(
        viewModel: SequenceViewModel(),
        poses: MockPoseData.poses,
        sequence: YogaSequence(
            name: "Morning Flow",
            sections: [
                YogaSection(name: "Warm Up", poses: [
                    PoseEntry(poseId: "mountain"),
                    PoseEntry(poseId: "cat-cow")
                ])
            ]
        ),
        isNew: false
    )
}
