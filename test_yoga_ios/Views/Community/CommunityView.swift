//
//  CommunityView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/29/26.
//

import SwiftUI

struct CommunityView: View {
    var sequenceViewModel: SequenceViewModel
    let poses: [Pose]
    @Bindable var userProfile: UserProfile

    @State private var communitySequences: [SharedSequence] = []
    @State private var isLoading = false
    @State private var selectedSequence: SharedSequence?
    @State private var sequenceToShare: YogaSequence?
    @State private var communityPosts: [CommunityPost] = CommunityPost.mockData
    @State private var showingNewPost = false
    @State private var selectedPost: CommunityPost?
    @State private var showingAllDiscussions = false
    @State private var showingAllSequences = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Share your sequence section
                    if !sequenceViewModel.sequences.isEmpty {
                        shareSection
                    }

                    // Discussions section
                    discussionsSection

                    // Community sequences
                    communitySection
                }
                .padding()
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if !sequenceViewModel.sequences.isEmpty {
                            Button {
                                // Show sequence picker to share
                                if let firstSequence = sequenceViewModel.sequences.first {
                                    sequenceToShare = firstSequence
                                }
                            } label: {
                                Label("Share Sequence", systemImage: "square.and.arrow.up")
                            }
                        }

                        Button {
                            showingNewPost = true
                        } label: {
                            Label("Start Discussion", systemImage: "text.bubble")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await loadCommunitySequences()
            }
            .task {
                await loadCommunitySequences()
            }
            .sheet(item: $selectedSequence) { sequence in
                SharedSequenceDetailView(
                    sharedSequence: binding(for: sequence),
                    poses: poses,
                    isLiked: userProfile.likedSequenceIds.contains(sequence.id),
                    isSaved: userProfile.savedSequenceIds.contains(sequence.id),
                    onLike: { toggleLike(sequence) },
                    onSave: { toggleSave(sequence) },
                    onSaveToSequences: { savedSequence, groupName in
                        // Add the group if it doesn't exist
                        if !sequenceViewModel.allGroups.contains(groupName) && !groupName.isEmpty {
                            sequenceViewModel.addGroup(groupName)
                        }
                        sequenceViewModel.addSequence(savedSequence)
                    },
                    availableGroups: sequenceViewModel.allGroups,
                    userProfile: userProfile
                )
            }
            .sheet(item: $sequenceToShare) { sequence in
                ShareSequenceView(sequence: sequence) { sharedSequence in
                    // Add the shared sequence to community list
                    communitySequences.insert(sharedSequence, at: 0)
                    // Track in user profile
                    userProfile.sharedSequences.insert(sharedSequence, at: 0)
                    sequenceToShare = nil
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView { post in
                    communityPosts.insert(post, at: 0)
                    showingNewPost = false
                }
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(
                    post: bindingForPost(post),
                    onClose: { selectedPost = nil },
                    userProfile: userProfile
                )
            }
            .sheet(isPresented: $showingAllDiscussions) {
                AllDiscussionsView(
                    posts: $communityPosts,
                    onSelectPost: { post in
                        showingAllDiscussions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedPost = post
                        }
                    },
                    onNewPost: {
                        showingAllDiscussions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingNewPost = true
                        }
                    }
                )
            }
            .sheet(isPresented: $showingAllSequences) {
                AllSequencesView(
                    sequences: communitySequences,
                    userProfile: userProfile,
                    onSelectSequence: { sequence in
                        showingAllSequences = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedSequence = sequence
                        }
                    },
                    onLike: { toggleLike($0) },
                    onSave: { toggleSave($0) }
                )
            }
        }
    }

    private func bindingForPost(_ post: CommunityPost) -> Binding<CommunityPost> {
        Binding(
            get: { communityPosts.first { $0.id == post.id } ?? post },
            set: { newValue in
                if let index = communityPosts.firstIndex(where: { $0.id == post.id }) {
                    communityPosts[index] = newValue
                }
            }
        )
    }

    private func binding(for sequence: SharedSequence) -> Binding<SharedSequence> {
        Binding(
            get: { communitySequences.first { $0.id == sequence.id } ?? sequence },
            set: { newValue in
                if let index = communitySequences.firstIndex(where: { $0.id == sequence.id }) {
                    communitySequences[index] = newValue
                }
            }
        )
    }

    private func toggleLike(_ sequence: SharedSequence) {
        guard let index = communitySequences.firstIndex(where: { $0.id == sequence.id }) else { return }
        if userProfile.likedSequenceIds.contains(sequence.id) {
            userProfile.likedSequenceIds.remove(sequence.id)
            communitySequences[index].likes -= 1
        } else {
            userProfile.likedSequenceIds.insert(sequence.id)
            communitySequences[index].likes += 1
        }
    }

    private func toggleSave(_ sequence: SharedSequence) {
        guard let index = communitySequences.firstIndex(where: { $0.id == sequence.id }) else { return }
        if userProfile.savedSequenceIds.contains(sequence.id) {
            userProfile.savedSequenceIds.remove(sequence.id)
            communitySequences[index].saves -= 1
        } else {
            userProfile.savedSequenceIds.insert(sequence.id)
            communitySequences[index].saves += 1
        }
    }

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Your Sequences")
                .font(.headline)

            Text("Share your yoga sequences with the community")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sequenceViewModel.sequences) { sequence in
                        ShareableSequenceCard(sequence: sequence) {
                            sequenceToShare = sequence
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var discussionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Discussions")
                    .font(.headline)

                if !communityPosts.isEmpty {
                    Text("(\(communityPosts.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if communityPosts.count > 5 {
                    Button {
                        showingAllDiscussions = true
                    } label: {
                        Text("See All")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            if communityPosts.isEmpty {
                Text("No discussions yet. Start a conversation!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(communityPosts.prefix(5)) { post in
                        CommunityPostCard(post: post) {
                            selectedPost = post
                        }
                    }

                    if communityPosts.count > 5 {
                        Button {
                            showingAllDiscussions = true
                        } label: {
                            Text("See \(communityPosts.count - 5) more discussions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Community Sequences")
                    .font(.headline)

                if !communitySequences.isEmpty {
                    Text("(\(communitySequences.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                } else if communitySequences.count > 5 {
                    Button {
                        showingAllSequences = true
                    } label: {
                        Text("See All")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            if communitySequences.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Shared Sequences Yet",
                    systemImage: "person.3",
                    description: Text("Be the first to share a sequence with the community!")
                )
                .frame(minHeight: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(communitySequences.prefix(5)) { sequence in
                        CommunitySequenceCard(
                            sequence: sequence,
                            isLiked: userProfile.likedSequenceIds.contains(sequence.id),
                            isSaved: userProfile.savedSequenceIds.contains(sequence.id),
                            onTap: { selectedSequence = sequence },
                            onLike: { toggleLike(sequence) },
                            onSave: { toggleSave(sequence) }
                        )
                    }

                    if communitySequences.count > 5 {
                        Button {
                            showingAllSequences = true
                        } label: {
                            Text("See \(communitySequences.count - 5) more sequences")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private func loadCommunitySequences() async {
        isLoading = true

        // Simulate loading from server
        // In production, this would fetch from Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Combine user's shared sequences with mock data
        // User's sequences appear first, then mock data
        var allSequences = userProfile.sharedSequences

        // Add mock data, avoiding duplicates
        for mockSequence in SharedSequence.mockData {
            if !allSequences.contains(where: { $0.id == mockSequence.id }) {
                allSequences.append(mockSequence)
            }
        }

        // Sort by shared date (newest first)
        communitySequences = allSequences.sorted { $0.sharedAt > $1.sharedAt }

        isLoading = false
    }
}

// MARK: - Comment Model

struct SequenceComment: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorName: String
    let content: String
    let createdAt: Date
    var replies: [SequenceComment]

    init(id: String = UUID().uuidString, authorId: String, authorName: String, content: String, createdAt: Date = Date(), replies: [SequenceComment] = []) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = createdAt
        self.replies = replies
    }

    static var mockComments: [SequenceComment] {
        [
            SequenceComment(
                id: "comment-1",
                authorId: "user-4",
                authorName: "Alex K.",
                content: "This sequence is amazing! Perfect for my morning routine.",
                createdAt: Date().addingTimeInterval(-3600 * 24),
                replies: [
                    SequenceComment(
                        id: "reply-1",
                        authorId: "user-1",
                        authorName: "Sarah Y.",
                        content: "Thank you! Glad you enjoyed it!",
                        createdAt: Date().addingTimeInterval(-3600 * 12)
                    )
                ]
            ),
            SequenceComment(
                id: "comment-2",
                authorId: "user-5",
                authorName: "Jordan M.",
                content: "How long do you recommend holding each pose?",
                createdAt: Date().addingTimeInterval(-3600 * 48),
                replies: []
            )
        ]
    }
}

// MARK: - Community Post Model

struct CommunityPost: Identifiable {
    let id: String
    let authorId: String
    let authorName: String
    let title: String
    let content: String
    let createdAt: Date
    var replies: [SequenceComment]
    var likes: Int

    init(id: String = UUID().uuidString, authorId: String, authorName: String, title: String, content: String, createdAt: Date = Date(), replies: [SequenceComment] = [], likes: Int = 0) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.replies = replies
        self.likes = likes
    }

    static var mockData: [CommunityPost] {
        [
            CommunityPost(
                id: "post-1",
                authorId: "user-7",
                authorName: "Lisa M.",
                title: "Best poses for lower back pain?",
                content: "I've been dealing with lower back pain from sitting at my desk all day. What poses do you recommend for relief?",
                createdAt: Date().addingTimeInterval(-3600 * 5),
                replies: [
                    SequenceComment(
                        id: "reply-post-1",
                        authorId: "user-2",
                        authorName: "Mike T.",
                        content: "Cat-cow and child's pose have really helped me! Also try gentle twists.",
                        createdAt: Date().addingTimeInterval(-3600 * 2)
                    )
                ],
                likes: 12
            ),
            CommunityPost(
                id: "post-2",
                authorId: "user-8",
                authorName: "David K.",
                title: "Morning vs Evening Practice",
                content: "I'm curious about everyone's experience - do you prefer practicing yoga in the morning or evening? I find morning practice energizes me but evening helps me sleep better.",
                createdAt: Date().addingTimeInterval(-86400 * 2),
                replies: [
                    SequenceComment(
                        id: "reply-post-2a",
                        authorId: "user-1",
                        authorName: "Sarah Y.",
                        content: "Morning for sure! It sets the tone for my whole day.",
                        createdAt: Date().addingTimeInterval(-86400)
                    ),
                    SequenceComment(
                        id: "reply-post-2b",
                        authorId: "user-3",
                        authorName: "Emma L.",
                        content: "I do both! Short energizing flow in the morning and restorative in the evening.",
                        createdAt: Date().addingTimeInterval(-3600 * 12)
                    )
                ],
                likes: 28
            ),
            CommunityPost(
                id: "post-3",
                authorId: "user-9",
                authorName: "Rachel S.",
                title: "How long did it take you to master headstand?",
                content: "I've been practicing for 6 months and still can't do a headstand. Is this normal? Any tips?",
                createdAt: Date().addingTimeInterval(-86400 * 4),
                replies: [],
                likes: 8
            )
        ]
    }
}

// MARK: - Shared Sequence Model

struct SharedSequence: Identifiable, Codable {
    let id: String
    let sequence: YogaSequence
    let authorName: String
    let authorId: String
    let sharedAt: Date
    var likes: Int
    var saves: Int
    var comments: [SequenceComment]

    static var mockData: [SharedSequence] {
        [
            SharedSequence(
                id: "shared-1",
                sequence: YogaSequence(
                    name: "Morning Energy Flow",
                    description: "A gentle 30-minute sequence to start your day with energy and focus.",
                    sections: [
                        YogaSection(name: "Warm Up", poses: [
                            PoseEntry(poseId: "mountain-pose", duration: 60),
                            PoseEntry(poseId: "standing-forward-fold", duration: 45)
                        ]),
                        YogaSection(name: "Sun Salutations", poses: [
                            PoseEntry(poseId: "upward-prayer-pose", duration: 30),
                            PoseEntry(poseId: "standing-forward-fold", duration: 30),
                            PoseEntry(poseId: "downward-facing-dog", duration: 60)
                        ]),
                        YogaSection(name: "Cool Down", poses: [
                            PoseEntry(poseId: "childs-pose", duration: 90)
                        ])
                    ]
                ),
                authorName: "Sarah Y.",
                authorId: "user-1",
                sharedAt: Date().addingTimeInterval(-86400 * 2),
                likes: 42,
                saves: 18,
                comments: SequenceComment.mockComments
            ),
            SharedSequence(
                id: "shared-2",
                sequence: YogaSequence(
                    name: "Hip Opener Journey",
                    description: "Deep hip opening sequence for flexibility and release.",
                    sections: [
                        YogaSection(name: "Preparation", poses: [
                            PoseEntry(poseId: "easy-pose", duration: 120),
                            PoseEntry(poseId: "cat-cow-pose", duration: 60)
                        ]),
                        YogaSection(name: "Deep Stretches", poses: [
                            PoseEntry(poseId: "pigeon-pose", duration: 90),
                            PoseEntry(poseId: "lizard-pose", duration: 60)
                        ])
                    ]
                ),
                authorName: "Mike T.",
                authorId: "user-2",
                sharedAt: Date().addingTimeInterval(-86400 * 5),
                likes: 89,
                saves: 34,
                comments: [
                    SequenceComment(
                        id: "comment-3",
                        authorId: "user-6",
                        authorName: "Casey R.",
                        content: "My hips feel so much better after this!",
                        createdAt: Date().addingTimeInterval(-3600 * 72)
                    )
                ]
            ),
            SharedSequence(
                id: "shared-3",
                sequence: YogaSequence(
                    name: "Stress Relief & Relaxation",
                    description: "Calming sequence to melt away tension after a long day.",
                    sections: [
                        YogaSection(name: "Grounding", poses: [
                            PoseEntry(poseId: "childs-pose", duration: 90),
                            PoseEntry(poseId: "cat-cow-pose", duration: 60)
                        ]),
                        YogaSection(name: "Gentle Flow", poses: [
                            PoseEntry(poseId: "downward-facing-dog", duration: 45),
                            PoseEntry(poseId: "standing-forward-fold", duration: 45)
                        ]),
                        YogaSection(name: "Restoration", poses: [
                            PoseEntry(poseId: "corpse-pose", duration: 180)
                        ])
                    ]
                ),
                authorName: "Emma L.",
                authorId: "user-3",
                sharedAt: Date().addingTimeInterval(-86400),
                likes: 156,
                saves: 67,
                comments: []
            )
        ]
    }
}

// MARK: - Supporting Views

struct ShareableSequenceCard: View {
    let sequence: YogaSequence
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sequence.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            HStack {
                Label("\(sequence.sections.count)", systemImage: "rectangle.stack")
                Label("\(sequence.totalPoseCount)", systemImage: "figure.yoga")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Button(action: onShare) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 140)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CommunitySequenceCard: View {
    let sequence: SharedSequence
    let isLiked: Bool
    let isSaved: Bool
    let onTap: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sequence.sequence.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("by \(sequence.authorName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if !sequence.sequence.description.isEmpty {
                Text(sequence.sequence.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(sequence.sequence.sections.count) sections", systemImage: "rectangle.stack")
                Label("\(sequence.sequence.totalPoseCount) poses", systemImage: "figure.yoga")

                Spacer()

                // Like button
                Button(action: onLike) {
                    Label("\(sequence.likes)", systemImage: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .secondary)
                }
                .buttonStyle(.plain)

                // Save button
                Button(action: onSave) {
                    Label("\(sequence.saves)", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isSaved ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)

                // Comments indicator
                Label("\(sequence.comments.count)", systemImage: "bubble.right")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Share Sequence View

struct ShareSequenceView: View {
    @Environment(\.dismiss) private var dismiss
    let sequence: YogaSequence
    let onShare: (SharedSequence) -> Void

    @State private var isSharing = false
    @State private var shareDescription = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sequence.name)
                            .font(.headline)

                        HStack {
                            Label("\(sequence.sections.count) sections", systemImage: "rectangle.stack")
                            Label("\(sequence.totalPoseCount) poses", systemImage: "figure.yoga")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Sequence")
                }

                Section {
                    TextField("Add a description for the community...", text: $shareDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Description")
                } footer: {
                    Text("Help others understand what this sequence is about")
                }

                Section {
                    Button {
                        shareToCommmunity()
                    } label: {
                        HStack {
                            Spacer()
                            if isSharing {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isSharing ? "Sharing..." : "Share with Community")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isSharing)
                }
            }
            .navigationTitle("Share Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareToCommmunity() {
        isSharing = true

        // Simulate sharing to server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create shared sequence with description
            var sharedSequence = sequence
            if !shareDescription.isEmpty {
                sharedSequence.description = shareDescription
            }

            let newSharedSequence = SharedSequence(
                id: UUID().uuidString,
                sequence: sharedSequence,
                authorName: "You",
                authorId: "current-user",
                sharedAt: Date(),
                likes: 0,
                saves: 0,
                comments: []
            )

            isSharing = false
            onShare(newSharedSequence)
        }
    }
}

// MARK: - Share Section View

struct ShareSectionView: View {
    @Environment(\.dismiss) private var dismiss
    let section: YogaSection
    let poses: [Pose]
    let onShare: () -> Void

    @State private var isSharing = false
    @State private var shareDescription = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.name.isEmpty ? "Untitled Section" : section.name)
                            .font(.headline)

                        HStack {
                            Label("\(section.poses.count) poses", systemImage: "figure.yoga")
                            Label(formattedDuration, systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Section")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(section.poses.prefix(5)) { poseEntry in
                            if let pose = poses.first(where: { $0.id == poseEntry.poseId }) {
                                HStack(spacing: 8) {
                                    Image(systemName: pose.imageURL)
                                        .font(.caption)
                                        .frame(width: 24, height: 24)
                                        .background(Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    Text(pose.nameEnglish)
                                        .font(.subheadline)

                                    Spacer()

                                    if let duration = poseEntry.duration {
                                        Text("\(duration)s")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        if section.poses.count > 5 {
                            Text("+ \(section.poses.count - 5) more poses")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Poses")
                }

                Section {
                    TextField("Add a description for the community...", text: $shareDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Description")
                } footer: {
                    Text("Help others understand what this section is about")
                }

                Section {
                    Button {
                        shareToCommmunity()
                    } label: {
                        HStack {
                            Spacer()
                            if isSharing {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isSharing ? "Sharing..." : "Share Section")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isSharing)
                }
            }
            .navigationTitle("Share Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var formattedDuration: String {
        let totalSeconds = section.duration
        let minutes = totalSeconds / 60
        if minutes > 0 {
            return "\(minutes) min"
        }
        return "\(totalSeconds)s"
    }

    private func shareToCommmunity() {
        isSharing = true

        // Simulate sharing to server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSharing = false
            onShare()
        }
    }
}

// MARK: - Shared Sequence Detail View

struct SharedSequenceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sharedSequence: SharedSequence
    let poses: [Pose]
    let isLiked: Bool
    let isSaved: Bool
    let onLike: () -> Void
    let onSave: () -> Void
    let onSaveToSequences: (YogaSequence, String) -> Void
    let availableGroups: [String]
    var userProfile: UserProfile

    @State private var showingSaveDialog = false
    @State private var showingSaveConfirmation = false
    @State private var selectedGroup: String = ""
    @State private var newComment = ""
    @State private var replyingTo: SequenceComment?
    @State private var replyText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Like/Save actions
                    actionButtons

                    // Sections
                    sectionsView

                    // Comments
                    commentsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sequence Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if selectedGroup.isEmpty && !availableGroups.isEmpty {
                            selectedGroup = availableGroups.first ?? "My Sequences"
                        }
                        showingSaveDialog = true
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if selectedGroup.isEmpty && !availableGroups.isEmpty {
                        selectedGroup = availableGroups.first ?? "My Sequences"
                    }
                    showingSaveDialog = true
                } label: {
                    Label("Save to My Sequences", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showingSaveDialog) {
                SaveToGroupSheet(
                    sequenceName: sharedSequence.sequence.name,
                    availableGroups: availableGroups,
                    selectedGroup: $selectedGroup,
                    onSave: {
                        saveSequence()
                        showingSaveDialog = false
                    },
                    onCancel: {
                        showingSaveDialog = false
                    }
                )
                .presentationDetents([.medium])
            }
            .alert("Saved!", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("This sequence has been added to \"\(selectedGroup)\".")
            }
            .sheet(item: $replyingTo) { comment in
                ReplySheet(comment: comment, replyText: $replyText) {
                    addReply(to: comment)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sharedSequence.sequence.name)
                .font(.title2)
                .fontWeight(.bold)

            Text("by \(sharedSequence.authorName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !sharedSequence.sequence.description.isEmpty {
                Text(sharedSequence.sequence.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            Text(sharedSequence.sharedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Like button
            Button(action: onLike) {
                VStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(isLiked ? .red : .primary)
                    Text("\(sharedSequence.likes)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Save button
            Button(action: onSave) {
                VStack(spacing: 4) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundStyle(isSaved ? Color.accentColor : Color.primary)
                    Text("\(sharedSequence.saves)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Comments count
            VStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .font(.title2)
                Text("\(sharedSequence.comments.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var sectionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sections")
                .font(.headline)

            ForEach(sharedSequence.sequence.sections) { section in
                SharedSectionCard(section: section, poses: poses)
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments")
                .font(.headline)

            // Add comment field
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)

                Button {
                    addComment()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(newComment.isEmpty ? Color.secondary : Color.accentColor)
                }
                .disabled(newComment.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Comments list
            if sharedSequence.comments.isEmpty {
                Text("No comments yet. Be the first to comment!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(sharedSequence.comments) { comment in
                    CommentCard(
                        comment: comment,
                        onReply: { replyingTo = comment }
                    )
                }
            }
        }
    }

    private func saveSequence() {
        let savedSequence = YogaSequence(
            name: sharedSequence.sequence.name,
            description: sharedSequence.sequence.description,
            sections: sharedSequence.sequence.sections,
            group: selectedGroup.isEmpty ? "My Sequences" : selectedGroup
        )
        onSaveToSequences(savedSequence, selectedGroup)
        showingSaveConfirmation = true
    }

    private func addComment() {
        let comment = SequenceComment(
            authorId: "current-user",
            authorName: "You",
            content: newComment
        )
        sharedSequence.comments.insert(comment, at: 0)
        userProfile.commentedSequenceIds.insert(sharedSequence.id)
        newComment = ""
    }

    private func addReply(to comment: SequenceComment) {
        guard !replyText.isEmpty else { return }
        let reply = SequenceComment(
            authorId: "current-user",
            authorName: "You",
            content: replyText
        )
        if let index = sharedSequence.comments.firstIndex(where: { $0.id == comment.id }) {
            sharedSequence.comments[index].replies.append(reply)
        }
        replyText = ""
        replyingTo = nil
    }
}

// MARK: - Comment Card

struct CommentCard: View {
    let comment: SequenceComment
    let onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main comment
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.authorName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(comment.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: onReply) {
                        Text("Reply")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Text(comment.content)
                    .font(.subheadline)
            }

            // Replies
            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(comment.replies) { reply in
                        HStack(alignment: .top, spacing: 8) {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: 2)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(reply.authorName)
                                        .font(.caption)
                                        .fontWeight(.medium)

                                    Text(reply.createdAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Text(reply.content)
                                    .font(.caption)
                            }
                        }
                        .padding(.leading, 32)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Reply Sheet

struct ReplySheet: View {
    @Environment(\.dismiss) private var dismiss
    let comment: SequenceComment
    @Binding var replyText: String
    let onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Original comment
                VStack(alignment: .leading, spacing: 8) {
                    Text("Replying to \(comment.authorName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(comment.content)
                        .font(.subheadline)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Reply field
                TextField("Write your reply...", text: $replyText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                Spacer()
            }
            .padding()
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        replyText = ""
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Reply") {
                        onSubmit()
                    }
                    .disabled(replyText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Shared Section Card

struct SharedSectionCard: View {
    let section: YogaSection
    let poses: [Pose]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(section.poses.count) poses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(section.poses) { poseEntry in
                if let pose = poses.first(where: { $0.id == poseEntry.poseId }) {
                    HStack(spacing: 12) {
                        Image(systemName: pose.imageURL)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pose.nameEnglish)
                                .font(.subheadline)
                            if let duration = poseEntry.duration {
                                Text("\(duration)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Community Post Card

struct CommunityPostCard: View {
    let post: CommunityPost
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text(post.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("by \(post.authorName)")
                    Text("•")
                    Text(post.createdAt, style: .relative)

                    Spacer()

                    Label("\(post.likes)", systemImage: "heart")
                    Label("\(post.replies.count)", systemImage: "bubble.right")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - New Post View

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    let onPost: (CommunityPost) -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var isPosting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What would you like to discuss?", text: $title)
                } header: {
                    Text("Title")
                }

                Section {
                    TextField("Share more details...", text: $content, axis: .vertical)
                        .lineLimit(4...8)
                } header: {
                    Text("Details")
                } footer: {
                    Text("Start a conversation with the community")
                }

                Section {
                    Button {
                        submitPost()
                    } label: {
                        HStack {
                            Spacer()
                            if isPosting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isPosting ? "Posting..." : "Post to Community")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty || isPosting)
                }
            }
            .navigationTitle("Start Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitPost() {
        isPosting = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let post = CommunityPost(
                authorId: "current-user",
                authorName: "You",
                title: title,
                content: content
            )
            onPost(post)
            isPosting = false
        }
    }
}

// MARK: - Post Detail View

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var post: CommunityPost
    let onClose: () -> Void
    var userProfile: UserProfile

    @State private var newReply = ""
    @State private var isLiked = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Post header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title)
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(post.content)
                            .font(.body)

                        HStack {
                            Text("by \(post.authorName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.secondary)

                            Text(post.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Like button
                        Button {
                            isLiked.toggle()
                            post.likes += isLiked ? 1 : -1
                            if isLiked {
                                userProfile.likedPostIds.insert(post.id)
                            } else {
                                userProfile.likedPostIds.remove(post.id)
                            }
                        } label: {
                            Label("\(post.likes)", systemImage: isLiked ? "heart.fill" : "heart")
                                .font(.subheadline)
                                .foregroundStyle(isLiked ? .red : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Replies section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Replies (\(post.replies.count))")
                            .font(.headline)

                        // Add reply field
                        HStack(spacing: 12) {
                            TextField("Write a reply...", text: $newReply, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(1...3)

                            Button {
                                addReply()
                            } label: {
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(newReply.isEmpty ? Color.secondary : Color.accentColor)
                            }
                            .disabled(newReply.isEmpty)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if post.replies.isEmpty {
                            Text("No replies yet. Be the first to respond!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ForEach(post.replies) { reply in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.secondary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(reply.authorName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)

                                            Text(reply.createdAt, style: .relative)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                    }

                                    Text(reply.content)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onClose()
                    }
                }
            }
            .onAppear {
                isLiked = userProfile.likedPostIds.contains(post.id)
            }
        }
    }

    private func addReply() {
        let reply = SequenceComment(
            authorId: "current-user",
            authorName: "You",
            content: newReply
        )
        post.replies.insert(reply, at: 0)
        userProfile.commentedPostIds.insert(post.id)
        newReply = ""
    }
}

// MARK: - All Discussions View

struct AllDiscussionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var posts: [CommunityPost]
    let onSelectPost: (CommunityPost) -> Void
    let onNewPost: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(posts) { post in
                        CommunityPostCard(post: post) {
                            onSelectPost(post)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("All Discussions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onNewPost()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - All Sequences View

struct AllSequencesView: View {
    @Environment(\.dismiss) private var dismiss
    let sequences: [SharedSequence]
    var userProfile: UserProfile
    let onSelectSequence: (SharedSequence) -> Void
    let onLike: (SharedSequence) -> Void
    let onSave: (SharedSequence) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sequences) { sequence in
                        CommunitySequenceCard(
                            sequence: sequence,
                            isLiked: userProfile.likedSequenceIds.contains(sequence.id),
                            isSaved: userProfile.savedSequenceIds.contains(sequence.id),
                            onTap: { onSelectSequence(sequence) },
                            onLike: { onLike(sequence) },
                            onSave: { onSave(sequence) }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("All Sequences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Save To Group Sheet

struct SaveToGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let sequenceName: String
    let availableGroups: [String]
    @Binding var selectedGroup: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var newGroupName = ""
    @State private var showingNewGroup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Sequence info
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.largeTitle)
                        .foregroundStyle(Color.accentColor)

                    Text("Save to My Sequences")
                        .font(.headline)

                    Text("\"\(sequenceName)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Group selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select a group")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if availableGroups.isEmpty {
                        Text("No groups available. The sequence will be saved to \"My Sequences\".")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(availableGroups, id: \.self) { group in
                                    GroupSelectionRow(
                                        groupName: group,
                                        isSelected: selectedGroup == group,
                                        onTap: { selectedGroup = group }
                                    )
                                }

                                // Add new group button
                                Button {
                                    showingNewGroup = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                        Text("Create New Group")
                                            .foregroundStyle(Color.accentColor)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Save button
                Button {
                    onSave()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Save Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("New Group", isPresented: $showingNewGroup) {
                TextField("Group Name", text: $newGroupName)
                Button("Cancel", role: .cancel) {
                    newGroupName = ""
                }
                Button("Create") {
                    if !newGroupName.isEmpty {
                        selectedGroup = newGroupName
                    }
                    newGroupName = ""
                }
            } message: {
                Text("Enter a name for the new group")
            }
        }
    }
}

struct GroupSelectionRow: View {
    let groupName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                Text(groupName)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CommunityView(sequenceViewModel: SequenceViewModel(), poses: MockPoseData.poses, userProfile: UserProfile.mock)
}
