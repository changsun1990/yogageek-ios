//
//  CommunityService.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import Foundation
import FirebaseFirestore

class CommunityService {
    static let shared = CommunityService()
    private let db = Firestore.firestore()
    private var postListener: ListenerRegistration?
    private var replyListeners: [String: ListenerRegistration] = [:]

    private init() {}

    // MARK: - Posts (real-time)

    func startListeningToPosts(onChange: @escaping ([CommunityPost]) -> Void) {
        postListener?.remove()
        postListener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let posts = docs.compactMap { Self.parsePost(from: $0) }
                onChange(posts)
            }
    }

    func stopListeningToPosts() {
        postListener?.remove()
        postListener = nil
    }

    func createPost(authorId: String, authorName: String, title: String, content: String) async throws -> String {
        let docRef = db.collection("posts").document()
        let data: [String: Any] = [
            "authorId": authorId,
            "authorName": authorName,
            "title": title,
            "content": content,
            "createdAt": FieldValue.serverTimestamp(),
            "likesCount": 0,
            "repliesCount": 0
        ]
        try await docRef.setData(data)
        return docRef.documentID
    }

    func togglePostLike(postId: String, increment: Bool) async throws {
        try await db.collection("posts").document(postId).updateData([
            "likesCount": FieldValue.increment(Int64(increment ? 1 : -1))
        ])
    }

    // MARK: - Replies (real-time per post)

    func startListeningToReplies(postId: String, onChange: @escaping ([SequenceComment]) -> Void) {
        replyListeners[postId]?.remove()
        replyListeners[postId] = db.collection("posts")
            .document(postId)
            .collection("replies")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let replies = docs.compactMap { Self.parseReply(from: $0) }
                onChange(replies)
            }
    }

    func stopListeningToReplies(postId: String) {
        replyListeners[postId]?.remove()
        replyListeners.removeValue(forKey: postId)
    }

    func stopAllReplyListeners() {
        replyListeners.values.forEach { $0.remove() }
        replyListeners.removeAll()
    }

    func addReply(postId: String, authorId: String, authorName: String, content: String) async throws {
        let batch = db.batch()

        let replyRef = db.collection("posts")
            .document(postId)
            .collection("replies")
            .document()

        let replyData: [String: Any] = [
            "authorId": authorId,
            "authorName": authorName,
            "content": content,
            "createdAt": FieldValue.serverTimestamp()
        ]
        batch.setData(replyData, forDocument: replyRef)

        // Increment replies counter
        let postRef = db.collection("posts").document(postId)
        batch.updateData(["repliesCount": FieldValue.increment(Int64(1))], forDocument: postRef)

        try await batch.commit()
    }

    // MARK: - Parsing

    static func parsePost(from document: QueryDocumentSnapshot) -> CommunityPost? {
        let data = document.data()
        guard let authorId = data["authorId"] as? String,
              let title = data["title"] as? String,
              let content = data["content"] as? String else { return nil }

        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }

        return CommunityPost(
            id: document.documentID,
            authorId: authorId,
            authorName: data["authorName"] as? String ?? "Unknown",
            title: title,
            content: content,
            createdAt: createdAt,
            likesCount: data["likesCount"] as? Int ?? 0,
            repliesCount: data["repliesCount"] as? Int ?? 0
        )
    }

    static func parseReply(from document: QueryDocumentSnapshot) -> SequenceComment? {
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
            createdAt: createdAt
        )
    }
}
