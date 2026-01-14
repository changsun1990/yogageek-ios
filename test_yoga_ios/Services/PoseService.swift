//
//  PoseService.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/13/26.
//

import Foundation
import FirebaseFirestore

class PoseService {
    private let db = Firestore.firestore()
    private let collectionName = "poses"

    func fetchPoses() async throws -> [Pose] {
        let snapshot = try await db.collection(collectionName).getDocuments()

        let poses = snapshot.documents.compactMap { document -> Pose? in
            let data = document.data()

            guard let nameEnglish = data["nameEnglish"] as? String,
                  let nameSanskrit = data["nameSanskrit"] as? String,
                  let description = data["description"] as? String,
                  let categoryString = data["category"] as? String,
                  let difficultyString = data["difficulty"] as? String,
                  let imageURL = data["imageURL"] as? String else {
                return nil
            }

            let exampleCues = data["exampleCues"] as? [String] ?? []
            let benefits = data["benefits"] as? [String] ?? []

            let category = PoseCategory(rawValue: categoryString) ?? .standing
            let difficulty = PoseDifficulty(rawValue: difficultyString) ?? .beginner

            return Pose(
                id: document.documentID,
                nameEnglish: nameEnglish,
                nameSanskrit: nameSanskrit,
                description: description,
                exampleCues: exampleCues,
                benefits: benefits,
                imageURL: imageURL,
                category: category,
                difficulty: difficulty
            )
        }

        return poses
    }

    func addPose(_ pose: Pose) async throws {
        let data: [String: Any] = [
            "nameEnglish": pose.nameEnglish,
            "nameSanskrit": pose.nameSanskrit,
            "description": pose.description,
            "exampleCues": pose.exampleCues,
            "benefits": pose.benefits,
            "imageURL": pose.imageURL,
            "category": pose.category.rawValue,
            "difficulty": pose.difficulty.rawValue
        ]

        try await db.collection(collectionName).document(pose.id).setData(data)
    }
}
