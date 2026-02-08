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

    private let storageKey = "yoga_sequences"
    private let groupsStorageKey = "yoga_groups"

    var allGroups: [String] {
        // Combine saved groups with groups from sequences
        let sequenceGroups = Set(sequences.map { $0.group })
        let allGroupsSet = Set(groups).union(sequenceGroups)
        return allGroupsSet.sorted()
    }

    init() {
        loadGroups()
        loadSequences()
    }

    // MARK: - Group Management

    func loadGroups() {
        guard let data = UserDefaults.standard.data(forKey: groupsStorageKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            groups = []
            return
        }
        groups = decoded
    }

    func saveGroups() {
        guard let encoded = try? JSONEncoder().encode(groups) else { return }
        UserDefaults.standard.set(encoded, forKey: groupsStorageKey)
    }

    func addGroup(_ name: String) {
        guard !name.isEmpty, !groups.contains(name) else { return }
        groups.append(name)
        saveGroups()
    }

    func deleteGroup(_ name: String) {
        // Delete all sequences in the group
        sequences.removeAll { $0.group == name }
        saveSequences()

        // Remove the group
        groups.removeAll { $0 == name }
        saveGroups()
    }

    func loadSequences() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([YogaSequence].self, from: data) else {
            sequences = []
            return
        }
        sequences = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveSequences() {
        guard let encoded = try? JSONEncoder().encode(sequences) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    func addSequence(_ sequence: YogaSequence) {
        sequences.insert(sequence, at: 0)
        saveSequences()
    }

    func updateSequence(_ sequence: YogaSequence) {
        if let index = sequences.firstIndex(where: { $0.id == sequence.id }) {
            var updated = sequence
            updated.updatedAt = Date()
            sequences[index] = updated
            saveSequences()
        }
    }

    func deleteSequence(_ sequence: YogaSequence) {
        sequences.removeAll { $0.id == sequence.id }
        saveSequences()
    }

    func deleteSequence(at offsets: IndexSet) {
        sequences.remove(atOffsets: offsets)
        saveSequences()
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
