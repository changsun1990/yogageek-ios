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

    private let storageKey = "yoga_sequences"

    init() {
        loadSequences()
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

    func createNewSequence() -> YogaSequence {
        YogaSequence(
            name: "New Sequence",
            sections: [YogaSection(name: "Warm Up")]
        )
    }

    // Helper to get pose details from pose ID
    func getPose(for poseId: String) -> Pose? {
        MockPoseData.poses.first { $0.id == poseId }
    }
}
