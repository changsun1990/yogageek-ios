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

    // Helper to get pose details from pose ID
    func getPose(for poseId: String) -> Pose? {
        MockPoseData.poses.first { $0.id == poseId }
    }
}
