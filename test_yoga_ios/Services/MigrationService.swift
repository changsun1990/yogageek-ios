//
//  MigrationService.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import Foundation
import FirebaseFirestore

class MigrationService {
    static let shared = MigrationService()
    private let db = Firestore.firestore()
    private let migrationKey = "firestore_migration_completed_v1"

    private init() {}

    var needsMigration: Bool {
        !UserDefaults.standard.bool(forKey: migrationKey)
    }

    func migrateIfNeeded(userId: String) async throws {
        guard needsMigration else { return }
        try await migrate(userId: userId)
    }

    private func migrate(userId: String) async throws {
        let batch = db.batch()

        // Migrate sequences from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "yoga_sequences"),
           let sequences = try? JSONDecoder().decode([YogaSequence].self, from: data) {
            for sequence in sequences {
                let docRef = db.collection("user_sequences").document(sequence.id)
                let seqData = SequenceService.encodeSequence(sequence, userId: userId)
                batch.setData(seqData, forDocument: docRef)
            }
        }

        // Migrate groups from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "yoga_groups"),
           let groups = try? JSONDecoder().decode([String].self, from: data) {
            for group in groups {
                let docRef = db.collection("user_groups").document()
                batch.setData([
                    "userId": userId,
                    "name": group,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: docRef)
            }
        }

        try await batch.commit()
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
