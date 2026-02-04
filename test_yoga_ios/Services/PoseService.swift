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
    private let collectionName = "new_poses"

    func fetchPoses() async throws -> [Pose] {
        let snapshot = try await db.collection(collectionName).getDocuments()

        let poses = snapshot.documents.compactMap { document -> Pose? in
            let data = document.data()

            guard let nameEnglish = data["nameEnglish"] as? String else { return nil }

            let nameSanskrit = data["nameSunskrit"] as? String ?? ""
            let description = data["description"] as? String ?? ""
            let benefit = data["benefit"] as? String ?? ""
            let muscleGroup = data["muscleGroup"] as? String ?? ""
            let categoryString = data["category"] as? String ?? "standing"
            let difficultyString = data["difficulty"] as? String ?? "beginner"
            let sampleCues = data["sampleCues"] as? [String] ?? []
            let variations = data["variations"] as? [String] ?? []

            let mechanics: PoseMechanics
            if let mechanicsData = data["mechanics"] as? [String: Any] {
                mechanics = PoseMechanics(
                    alignmentPrinciple: mechanicsData["alignment_principle"] as? String ?? "",
                    commonCorrection: mechanicsData["common_correction"] as? String ?? "",
                    keyEngagement: mechanicsData["key_engagement"] as? String ?? ""
                )
            } else {
                mechanics = .empty
            }

            var imageURL = data["imageURL"] as? String ?? "figure.yoga"
            if imageURL.hasPrefix("https://storage.googleapis.com/"),
               let slashIndex = imageURL.dropFirst(32).firstIndex(of: "/") {
                let bucket = String(imageURL.dropFirst(32)[..<slashIndex])
                let path = String(imageURL.dropFirst(32)[imageURL.dropFirst(32).index(after: slashIndex)...])
                let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)?
                    .replacingOccurrences(of: "/", with: "%2F") ?? path
                imageURL = "https://firebasestorage.googleapis.com/v0/b/\(bucket)/o/\(encodedPath)?alt=media"
            }

            let category = PoseCategory(rawValue: categoryString) ?? .standing
            let difficulty = PoseDifficulty(rawValue: difficultyString) ?? .beginner

            return Pose(
                id: document.documentID,
                nameEnglish: nameEnglish,
                nameSanskrit: nameSanskrit,
                description: description,
                benefit: benefit,
                sampleCues: sampleCues,
                mechanics: mechanics,
                muscleGroup: muscleGroup,
                variations: variations,
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
            "benefit": pose.benefit,
            "sampleCues": pose.sampleCues,
            "mechanics": pose.mechanics,
            "muscleGroup": pose.muscleGroup,
            "variations": pose.variations,
            "imageURL": pose.imageURL,
            "category": pose.category.rawValue,
            "difficulty": pose.difficulty.rawValue
        ]

        try await db.collection(collectionName).document(pose.id).setData(data)
    }
}
