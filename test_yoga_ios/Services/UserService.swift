//
//  UserService.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import Foundation
import FirebaseFirestore

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    private let collectionName = "users"
    private var listener: ListenerRegistration?

    private init() {}

    // MARK: - Real-time Listener

    func startListening(userId: String, onChange: @escaping (UserProfile?) -> Void) {
        stopListening()
        listener = db.collection(collectionName).document(userId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else {
                    onChange(nil)
                    return
                }
                let profile = UserService.parseProfile(from: data, id: userId)
                onChange(profile)
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Save Profile

    func saveProfile(_ profile: UserProfile, userId: String) async throws {
        let data = UserService.encodeProfile(profile)
        try await db.collection(collectionName).document(userId).setData(data, merge: true)
    }

    // MARK: - Fetch Profile (one-time)

    func fetchProfile(userId: String) async throws -> UserProfile? {
        let snapshot = try await db.collection(collectionName).document(userId).getDocument()
        guard let data = snapshot.data() else { return nil }
        return UserService.parseProfile(from: data, id: userId)
    }

    // MARK: - Interaction Updates

    func addLikedSequence(_ sequenceId: String, userId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "likedSequenceIds": FieldValue.arrayUnion([sequenceId])
        ])
    }

    func removeLikedSequence(_ sequenceId: String, userId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "likedSequenceIds": FieldValue.arrayRemove([sequenceId])
        ])
    }

    func addSavedSequence(_ sequenceId: String, userId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "savedSequenceIds": FieldValue.arrayUnion([sequenceId])
        ])
    }

    func removeSavedSequence(_ sequenceId: String, userId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "savedSequenceIds": FieldValue.arrayRemove([sequenceId])
        ])
    }

    func addLikedPost(_ postId: String, userId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "likedPostIds": FieldValue.arrayUnion([postId])
        ])
    }

    func removeLikedPost(_ postId: String, userId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "likedPostIds": FieldValue.arrayRemove([postId])
        ])
    }

    // MARK: - Parsing

    static func parseProfile(from data: [String: Any], id: String) -> UserProfile {
        let profile = UserProfile()
        profile.id = id
        profile.displayName = data["displayName"] as? String ?? ""
        profile.bio = data["bio"] as? String ?? ""
        profile.yogaExperienceLevel = YogaExperienceLevel(rawValue: data["yogaExperienceLevel"] as? String ?? "") ?? .beginner
        profile.yearsOfPractice = data["yearsOfPractice"] as? Int ?? 0
        profile.favoriteStyles = (data["favoriteStyles"] as? [String] ?? []).compactMap { YogaStyle(rawValue: $0) }
        profile.goals = (data["goals"] as? [String] ?? []).compactMap { YogaGoal(rawValue: $0) }
        profile.preferredPracticeTimes = (data["preferredPracticeTimes"] as? [String] ?? []).compactMap { PracticeTime(rawValue: $0) }
        profile.profileImageName = data["profileImageName"] as? String ?? "person.circle.fill"
        profile.totalPracticeMinutes = data["totalPracticeMinutes"] as? Int ?? 0
        profile.sequencesCreated = data["sequencesCreated"] as? Int ?? 0
        profile.sequencesShared = data["sequencesShared"] as? Int ?? 0
        profile.likedSequenceIds = Set(data["likedSequenceIds"] as? [String] ?? [])
        profile.savedSequenceIds = Set(data["savedSequenceIds"] as? [String] ?? [])
        profile.commentedSequenceIds = Set(data["commentedSequenceIds"] as? [String] ?? [])
        profile.likedPostIds = Set(data["likedPostIds"] as? [String] ?? [])
        profile.commentedPostIds = Set(data["commentedPostIds"] as? [String] ?? [])

        if let timestamp = data["joinedDate"] as? Timestamp {
            profile.joinedDate = timestamp.dateValue()
        }

        return profile
    }

    static func encodeProfile(_ profile: UserProfile) -> [String: Any] {
        return [
            "displayName": profile.displayName,
            "bio": profile.bio,
            "yogaExperienceLevel": profile.yogaExperienceLevel.rawValue,
            "yearsOfPractice": profile.yearsOfPractice,
            "favoriteStyles": profile.favoriteStyles.map { $0.rawValue },
            "goals": profile.goals.map { $0.rawValue },
            "preferredPracticeTimes": profile.preferredPracticeTimes.map { $0.rawValue },
            "profileImageName": profile.profileImageName,
            "totalPracticeMinutes": profile.totalPracticeMinutes,
            "sequencesCreated": profile.sequencesCreated,
            "sequencesShared": profile.sequencesShared,
            "likedSequenceIds": Array(profile.likedSequenceIds),
            "savedSequenceIds": Array(profile.savedSequenceIds),
            "commentedSequenceIds": Array(profile.commentedSequenceIds),
            "likedPostIds": Array(profile.likedPostIds),
            "commentedPostIds": Array(profile.commentedPostIds),
            "joinedDate": Timestamp(date: profile.joinedDate),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
}
