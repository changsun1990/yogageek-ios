//
//  CommunityViewModel.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import Foundation

@Observable
@MainActor
class CommunityViewModel: @unchecked Sendable {
    var sharedSequences: [SharedSequence] = []
    var posts: [CommunityPost] = []
    var commentsCache: [String: [SequenceComment]] = [:]
    var repliesCache: [String: [SequenceComment]] = [:]

    private var userId: String?
    private var userName: String?

    // MARK: - Listening

    func startListening(userId: String, userName: String) {
        self.userId = userId
        self.userName = userName

        SequenceService.shared.startListeningToSharedSequences { [weak self] sequences in
            Task { @MainActor in
                self?.sharedSequences = sequences
            }
        }

        CommunityService.shared.startListeningToPosts { [weak self] posts in
            Task { @MainActor in
                self?.posts = posts
            }
        }
    }

    func stopListening() {
        SequenceService.shared.stopListeningToSharedSequences()
        CommunityService.shared.stopListeningToPosts()
        SequenceService.shared.stopAllCommentListeners()
        CommunityService.shared.stopAllReplyListeners()
        sharedSequences = []
        posts = []
        commentsCache = [:]
        repliesCache = [:]
        userId = nil
        userName = nil
    }

    // MARK: - Share Sequence

    func shareSequence(_ sequence: YogaSequence, description: String) async throws {
        guard let userId, let userName else { return }
        _ = try await SequenceService.shared.shareSequence(
            sequence,
            authorId: userId,
            authorName: userName,
            description: description
        )
    }

    // MARK: - Likes/Saves

    func toggleLike(sequenceId: String, userProfile: UserProfile) {
        guard let userId else { return }
        let isLiked = userProfile.likedSequenceIds.contains(sequenceId)
        // Optimistic update
        if isLiked {
            userProfile.likedSequenceIds.remove(sequenceId)
        } else {
            userProfile.likedSequenceIds.insert(sequenceId)
        }
        Task {
            try? await SequenceService.shared.toggleLike(sequenceId: sequenceId, increment: !isLiked)
            if isLiked {
                try? await UserService.shared.removeLikedSequence(sequenceId, userId: userId)
            } else {
                try? await UserService.shared.addLikedSequence(sequenceId, userId: userId)
            }
        }
    }

    func toggleSave(sequenceId: String, userProfile: UserProfile) {
        guard let userId else { return }
        let isSaved = userProfile.savedSequenceIds.contains(sequenceId)
        // Optimistic update
        if isSaved {
            userProfile.savedSequenceIds.remove(sequenceId)
        } else {
            userProfile.savedSequenceIds.insert(sequenceId)
        }
        Task {
            try? await SequenceService.shared.toggleSave(sequenceId: sequenceId, increment: !isSaved)
            if isSaved {
                try? await UserService.shared.removeSavedSequence(sequenceId, userId: userId)
            } else {
                try? await UserService.shared.addSavedSequence(sequenceId, userId: userId)
            }
        }
    }

    // MARK: - Comments

    func loadComments(for sequenceId: String) {
        SequenceService.shared.startListeningToComments(sequenceId: sequenceId) { [weak self] comments in
            Task { @MainActor in
                self?.commentsCache[sequenceId] = comments
            }
        }
    }

    func unloadComments(for sequenceId: String) {
        SequenceService.shared.stopListeningToComments(sequenceId: sequenceId)
        commentsCache.removeValue(forKey: sequenceId)
    }

    func addComment(sequenceId: String, content: String, parentCommentId: String? = nil) {
        guard let userId, let userName else { return }
        Task {
            try? await SequenceService.shared.addComment(
                sequenceId: sequenceId,
                authorId: userId,
                authorName: userName,
                content: content,
                parentCommentId: parentCommentId
            )
        }
    }

    // MARK: - Posts

    func createPost(title: String, content: String) {
        guard let userId, let userName else { return }
        Task {
            try? await CommunityService.shared.createPost(
                authorId: userId,
                authorName: userName,
                title: title,
                content: content
            )
        }
    }

    func togglePostLike(postId: String, userProfile: UserProfile) {
        guard let userId else { return }
        let isLiked = userProfile.likedPostIds.contains(postId)
        // Optimistic update
        if isLiked {
            userProfile.likedPostIds.remove(postId)
        } else {
            userProfile.likedPostIds.insert(postId)
        }
        Task {
            try? await CommunityService.shared.togglePostLike(postId: postId, increment: !isLiked)
            if isLiked {
                try? await UserService.shared.removeLikedPost(postId, userId: userId)
            } else {
                try? await UserService.shared.addLikedPost(postId, userId: userId)
            }
        }
    }

    // MARK: - Replies

    func loadReplies(for postId: String) {
        CommunityService.shared.startListeningToReplies(postId: postId) { [weak self] replies in
            Task { @MainActor in
                self?.repliesCache[postId] = replies
            }
        }
    }

    func unloadReplies(for postId: String) {
        CommunityService.shared.stopListeningToReplies(postId: postId)
        repliesCache.removeValue(forKey: postId)
    }

    func addReply(postId: String, content: String) {
        guard let userId, let userName else { return }
        Task {
            try? await CommunityService.shared.addReply(
                postId: postId,
                authorId: userId,
                authorName: userName,
                content: content
            )
        }
    }
}
