//
//  SequenceViewModel.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import Foundation
import SwiftUI

@Observable
class SequenceViewModel {
    var sequences: [YogaSequence] = []
    var groups: [String] = []

    private var userId: String?

    var allGroups: [String] {
        // Combine saved groups with groups from sequences
        let sequenceGroups = Set(sequences.map { $0.group })
        let allGroupsSet = Set(groups).union(sequenceGroups)
        return allGroupsSet.sorted()
    }

    init() {}

    // MARK: - Listening

    func startListening(userId: String) {
        self.userId = userId

        SequenceService.shared.startListeningToUserSequences(userId: userId) { [weak self] sequences in
            Task { @MainActor in
                self?.sequences = sequences
            }
        }

        SequenceService.shared.startListeningToGroups(userId: userId) { [weak self] groups in
            Task { @MainActor in
                self?.groups = groups
            }
        }
    }

    func stopListening() {
        SequenceService.shared.stopListeningToUserSequences()
        SequenceService.shared.stopListeningToGroups()
        sequences = []
        groups = []
        userId = nil
    }

    // MARK: - Group Management

    func addGroup(_ name: String) {
        guard let userId, !name.isEmpty, !groups.contains(name) else { return }
        Task {
            do {
                try await SequenceService.shared.addGroup(name, userId: userId)
            } catch {
                print("[SequenceVM] addGroup failed: \(error)")
            }
        }
    }

    func deleteGroup(_ name: String) {
        guard let userId else { return }
        Task {
            try? await SequenceService.shared.deleteGroup(name, userId: userId)
        }
    }

    // MARK: - Sequence Management

    func addSequence(_ sequence: YogaSequence) {
        guard let userId else { return }
        Task {
            try? await SequenceService.shared.addSequence(sequence, userId: userId)
        }
    }

    func updateSequence(_ sequence: YogaSequence) {
        guard let userId else { return }
        Task {
            try? await SequenceService.shared.updateSequence(sequence, userId: userId)
        }
    }

    func deleteSequence(_ sequence: YogaSequence) {
        Task {
            try? await SequenceService.shared.deleteSequence(sequence.id)
        }
    }

    func deleteSequence(at offsets: IndexSet) {
        for index in offsets {
            deleteSequence(sequences[index])
        }
    }

    func createNewSequence(inGroup group: String = "My Sequences") -> YogaSequence {
        YogaSequence(
            name: "New Sequence",
            sections: [YogaSection(name: "Warm Up")],
            group: group
        )
    }

    // MARK: - Template & Copy

    var regularSequences: [YogaSequence] {
        sequences.filter { !$0.isTemplate }
    }

    var templates: [YogaSequence] {
        sequences.filter { $0.isTemplate }
    }

    func duplicateSequence(_ sequence: YogaSequence) {
        let duplicate = YogaSequence(
            name: sequence.name + " (Copy)",
            description: sequence.description,
            sections: copySections(sequence.sections),
            group: sequence.group,
            targetDuration: sequence.targetDuration
        )
        addSequence(duplicate)
    }

    func saveAsTemplate(_ sequence: YogaSequence) {
        let template = YogaSequence(
            name: sequence.name,
            description: sequence.description,
            sections: copySections(sequence.sections),
            group: sequence.group,
            targetDuration: sequence.targetDuration,
            isTemplate: true
        )
        addSequence(template)
    }

    func createFromTemplate(_ template: YogaSequence, inGroup group: String) -> YogaSequence {
        YogaSequence(
            name: "",
            description: template.description,
            sections: copySections(template.sections),
            group: group,
            targetDuration: template.targetDuration
        )
    }

    func copySection(_ section: YogaSection) -> YogaSection {
        YogaSection(
            name: section.name,
            poses: section.poses.map { pose in
                PoseEntry(
                    poseId: pose.poseId,
                    customCues: pose.customCues,
                    notes: pose.notes,
                    duration: pose.duration,
                    customName: pose.customName,
                    breath: pose.breath
                )
            },
            sectionDuration: section.sectionDuration
        )
    }

    func appendSectionToSequence(_ section: YogaSection, sequenceId: String) {
        guard var targetSequence = sequences.first(where: { $0.id == sequenceId }) else { return }
        targetSequence.sections.append(copySection(section))
        updateSequence(targetSequence)
    }

    private func copySections(_ sections: [YogaSection]) -> [YogaSection] {
        sections.map { copySection($0) }
    }

    // Helper to get pose details from pose ID
    func getPose(for poseId: String) -> Pose? {
        MockPoseData.poses.first { $0.id == poseId }
    }
}
