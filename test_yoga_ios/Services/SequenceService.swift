//
//  SequenceService.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import Foundation
import FirebaseFirestore

class SequenceService {
    static let shared = SequenceService()
    private let db = Firestore.firestore()
    private var sequenceListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    private var sharedSequenceListener: ListenerRegistration?
    private var commentListeners: [String: ListenerRegistration] = [:]

    private init() {}

    // MARK: - Private Sequences (real-time)

    func startListeningToUserSequences(userId: String, onChange: @escaping ([YogaSequence]) -> Void) {
        sequenceListener?.remove()
        sequenceListener = db.collection("user_sequences")
            .whereField("userId", isEqualTo: userId)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("[SequenceService] user_sequences listener error: \(error)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                let sequences = docs.compactMap { Self.parseSequence(from: $0) }
                onChange(sequences)
            }
    }

    func stopListeningToUserSequences() {
        sequenceListener?.remove()
        sequenceListener = nil
    }

    func addSequence(_ sequence: YogaSequence, userId: String) async throws {
        let data = Self.encodeSequence(sequence, userId: userId)
        try await db.collection("user_sequences").document(sequence.id).setData(data)
    }

    func updateSequence(_ sequence: YogaSequence, userId: String) async throws {
        var data = Self.encodeSequence(sequence, userId: userId)
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await db.collection("user_sequences").document(sequence.id).setData(data)
    }

    func deleteSequence(_ sequenceId: String) async throws {
        try await db.collection("user_sequences").document(sequenceId).delete()
    }

    // MARK: - Groups (real-time)

    func startListeningToGroups(userId: String, onChange: @escaping ([String]) -> Void) {
        groupListener?.remove()
        groupListener = db.collection("user_groups")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("[SequenceService] user_groups listener error: \(error)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                let groups = docs.compactMap { $0.data()["name"] as? String }
                onChange(groups)
            }
    }

    func stopListeningToGroups() {
        groupListener?.remove()
        groupListener = nil
    }

    func addGroup(_ name: String, userId: String) async throws {
        try await db.collection("user_groups").document().setData([
            "userId": userId,
            "name": name,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func deleteGroup(_ name: String, userId: String) async throws {
        let batch = db.batch()

        // Delete all sequences in the group
        let sequenceSnapshot = try await db.collection("user_sequences")
            .whereField("userId", isEqualTo: userId)
            .whereField("group", isEqualTo: name)
            .getDocuments()
        for doc in sequenceSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        // Delete the group document
        let groupSnapshot = try await db.collection("user_groups")
            .whereField("userId", isEqualTo: userId)
            .whereField("name", isEqualTo: name)
            .getDocuments()
        for doc in groupSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        try await batch.commit()
    }

    // MARK: - Shared Sequences (real-time)

    func startListeningToSharedSequences(onChange: @escaping ([SharedSequence]) -> Void) {
        sharedSequenceListener?.remove()
        sharedSequenceListener = db.collection("shared_sequences")
            .order(by: "sharedAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let sequences = docs.compactMap { Self.parseSharedSequence(from: $0) }
                onChange(sequences)
            }
    }

    func stopListeningToSharedSequences() {
        sharedSequenceListener?.remove()
        sharedSequenceListener = nil
    }

    func shareSequence(_ sequence: YogaSequence, authorId: String, authorName: String, description: String) async throws -> String {
        var sharedSequence = sequence
        if !description.isEmpty {
            sharedSequence.description = description
        }

        let docRef = db.collection("shared_sequences").document()
        let data: [String: Any] = [
            "sequence": Self.encodeSequenceMap(sharedSequence),
            "authorId": authorId,
            "authorName": authorName,
            "sharedAt": FieldValue.serverTimestamp(),
            "likesCount": 0,
            "savesCount": 0,
            "commentsCount": 0
        ]
        try await docRef.setData(data)
        return docRef.documentID
    }

    // MARK: - Likes/Saves (atomic counters)

    func toggleLike(sequenceId: String, increment: Bool) async throws {
        try await db.collection("shared_sequences").document(sequenceId).updateData([
            "likesCount": FieldValue.increment(Int64(increment ? 1 : -1))
        ])
    }

    func toggleSave(sequenceId: String, increment: Bool) async throws {
        try await db.collection("shared_sequences").document(sequenceId).updateData([
            "savesCount": FieldValue.increment(Int64(increment ? 1 : -1))
        ])
    }

    // MARK: - Comments (real-time per sequence)

    func startListeningToComments(sequenceId: String, onChange: @escaping ([SequenceComment]) -> Void) {
        commentListeners[sequenceId]?.remove()
        commentListeners[sequenceId] = db.collection("shared_sequences")
            .document(sequenceId)
            .collection("comments")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let flatComments = docs.compactMap { Self.parseComment(from: $0) }
                onChange(Self.buildCommentTree(from: flatComments))
            }
    }

    func stopListeningToComments(sequenceId: String) {
        commentListeners[sequenceId]?.remove()
        commentListeners.removeValue(forKey: sequenceId)
    }

    func stopAllCommentListeners() {
        commentListeners.values.forEach { $0.remove() }
        commentListeners.removeAll()
    }

    func addComment(sequenceId: String, authorId: String, authorName: String, content: String, parentCommentId: String?) async throws {
        let batch = db.batch()

        let commentRef = db.collection("shared_sequences")
            .document(sequenceId)
            .collection("comments")
            .document()

        var commentData: [String: Any] = [
            "authorId": authorId,
            "authorName": authorName,
            "content": content,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let parentId = parentCommentId {
            commentData["parentCommentId"] = parentId
        }
        batch.setData(commentData, forDocument: commentRef)

        // Increment comments counter
        let sequenceRef = db.collection("shared_sequences").document(sequenceId)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(1))], forDocument: sequenceRef)

        try await batch.commit()
    }

    // MARK: - Parsing Helpers

    static func parseSequence(from document: QueryDocumentSnapshot) -> YogaSequence? {
        let data = document.data()
        guard let name = data["name"] as? String else { return nil }

        let sections = (data["sections"] as? [[String: Any]] ?? []).compactMap { sectionData -> YogaSection? in
            guard let sectionId = sectionData["id"] as? String,
                  let sectionName = sectionData["name"] as? String else { return nil }

            let poses = (sectionData["poses"] as? [[String: Any]] ?? []).compactMap { poseData -> PoseEntry? in
                guard let poseEntryId = poseData["id"] as? String,
                      let poseId = poseData["poseId"] as? String else { return nil }
                return PoseEntry(
                    id: poseEntryId,
                    poseId: poseId,
                    customCues: poseData["customCues"] as? [String] ?? [],
                    notes: poseData["notes"] as? String ?? "",
                    duration: poseData["duration"] as? Int
                )
            }
            return YogaSection(id: sectionId, name: sectionName, poses: poses)
        }

        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }

        let updatedAt: Date
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }

        return YogaSequence(
            id: document.documentID,
            name: name,
            description: data["description"] as? String ?? "",
            sections: sections,
            group: data["group"] as? String ?? "My Sequences",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func parseSharedSequence(from document: QueryDocumentSnapshot) -> SharedSequence? {
        let data = document.data()
        guard let sequenceMap = data["sequence"] as? [String: Any],
              let authorId = data["authorId"] as? String else { return nil }

        let sequence = parseSequenceFromMap(sequenceMap)

        let sharedAt: Date
        if let timestamp = data["sharedAt"] as? Timestamp {
            sharedAt = timestamp.dateValue()
        } else {
            sharedAt = Date()
        }

        return SharedSequence(
            id: document.documentID,
            sequence: sequence,
            authorName: data["authorName"] as? String ?? "Unknown",
            authorId: authorId,
            sharedAt: sharedAt,
            likesCount: data["likesCount"] as? Int ?? 0,
            savesCount: data["savesCount"] as? Int ?? 0,
            commentsCount: data["commentsCount"] as? Int ?? 0
        )
    }

    static func parseComment(from document: QueryDocumentSnapshot) -> SequenceComment? {
        let data = document.data()
        guard let authorId = data["authorId"] as? String,
              let content = data["content"] as? String else { return nil }

        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }

        return SequenceComment(
            id: document.documentID,
            authorId: authorId,
            authorName: data["authorName"] as? String ?? "Unknown",
            content: content,
            createdAt: createdAt,
            parentCommentId: data["parentCommentId"] as? String
        )
    }

    static func buildCommentTree(from flatComments: [SequenceComment]) -> [SequenceComment] {
        let topLevel = flatComments.filter { $0.parentCommentId == nil }
        return topLevel.map { comment in
            var c = comment
            c.replies = flatComments.filter { $0.parentCommentId == comment.id }
                .sorted { $0.createdAt < $1.createdAt }
            return c
        }
    }

    // MARK: - Encoding Helpers

    static func encodeSequence(_ sequence: YogaSequence, userId: String) -> [String: Any] {
        var data = encodeSequenceMap(sequence)
        data["userId"] = userId
        return data
    }

    static func encodeSequenceMap(_ sequence: YogaSequence) -> [String: Any] {
        let sections: [[String: Any]] = sequence.sections.map { section in
            let poses: [[String: Any]] = section.poses.map { pose in
                var poseData: [String: Any] = [
                    "id": pose.id,
                    "poseId": pose.poseId,
                    "customCues": pose.customCues,
                    "notes": pose.notes
                ]
                if let duration = pose.duration {
                    poseData["duration"] = duration
                }
                return poseData
            }
            return [
                "id": section.id,
                "name": section.name,
                "poses": poses
            ]
        }

        return [
            "name": sequence.name,
            "description": sequence.description,
            "sections": sections,
            "group": sequence.group,
            "createdAt": Timestamp(date: sequence.createdAt),
            "updatedAt": Timestamp(date: sequence.updatedAt)
        ]
    }

    private static func parseSequenceFromMap(_ data: [String: Any]) -> YogaSequence {
        let sections = (data["sections"] as? [[String: Any]] ?? []).compactMap { sectionData -> YogaSection? in
            guard let sectionId = sectionData["id"] as? String,
                  let sectionName = sectionData["name"] as? String else { return nil }

            let poses = (sectionData["poses"] as? [[String: Any]] ?? []).compactMap { poseData -> PoseEntry? in
                guard let poseEntryId = poseData["id"] as? String,
                      let poseId = poseData["poseId"] as? String else { return nil }
                return PoseEntry(
                    id: poseEntryId,
                    poseId: poseId,
                    customCues: poseData["customCues"] as? [String] ?? [],
                    notes: poseData["notes"] as? String ?? "",
                    duration: poseData["duration"] as? Int
                )
            }
            return YogaSection(id: sectionId, name: sectionName, poses: poses)
        }

        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }

        let updatedAt: Date
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }

        return YogaSequence(
            name: data["name"] as? String ?? "",
            description: data["description"] as? String ?? "",
            sections: sections,
            group: data["group"] as? String ?? "My Sequences",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
