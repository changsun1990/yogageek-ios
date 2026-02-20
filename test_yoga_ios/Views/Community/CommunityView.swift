//
//  CommunityView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/29/26.
//

import SwiftUI

struct CommunityView: View {
    var sequenceViewModel: SequenceViewModel
    var communityViewModel: CommunityViewModel
    let poses: [Pose]
    @Bindable var userProfile: UserProfile

    @State private var selectedSequence: SharedSequence?
    @State private var sequenceToShare: YogaSequence?
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
            .sheet(item: $selectedSequence) { sequence in
                SharedSequenceDetailView(
                    sharedSequence: sequence,
                    communityViewModel: communityViewModel,
                    poses: poses,
                    isLiked: userProfile.likedSequenceIds.contains(sequence.id),
                    isSaved: userProfile.savedSequenceIds.contains(sequence.id),
                    onLike: { communityViewModel.toggleLike(sequenceId: sequence.id, userProfile: userProfile) },
                    onSave: { communityViewModel.toggleSave(sequenceId: sequence.id, userProfile: userProfile) },
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
                ShareSequenceView(sequence: sequence, communityViewModel: communityViewModel) {
                    sequenceToShare = nil
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView(communityViewModel: communityViewModel) {
                    showingNewPost = false
                }
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(
                    post: post,
                    communityViewModel: communityViewModel,
                    onClose: { selectedPost = nil },
                    userProfile: userProfile
                )
            }
            .sheet(isPresented: $showingAllDiscussions) {
                AllDiscussionsView(
                    posts: communityViewModel.posts,
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
                    sequences: communityViewModel.sharedSequences,
                    userProfile: userProfile,
                    onSelectSequence: { sequence in
                        showingAllSequences = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedSequence = sequence
                        }
                    },
                    onLike: { communityViewModel.toggleLike(sequenceId: $0.id, userProfile: userProfile) },
                    onSave: { communityViewModel.toggleSave(sequenceId: $0.id, userProfile: userProfile) }
                )
            }
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

                if !communityViewModel.posts.isEmpty {
                    Text("(\(communityViewModel.posts.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if communityViewModel.posts.count > 5 {
                    Button {
                        showingAllDiscussions = true
                    } label: {
                        Text("See All")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            if communityViewModel.posts.isEmpty {
                Text("No discussions yet. Start a conversation!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(communityViewModel.posts.prefix(5)) { post in
                        CommunityPostCard(post: post) {
                            selectedPost = post
                        }
                    }

                    if communityViewModel.posts.count > 5 {
                        Button {
                            showingAllDiscussions = true
                        } label: {
                            Text("See \(communityViewModel.posts.count - 5) more discussions")
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

                if !communityViewModel.sharedSequences.isEmpty {
                    Text("(\(communityViewModel.sharedSequences.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if communityViewModel.sharedSequences.count > 5 {
                    Button {
                        showingAllSequences = true
                    } label: {
                        Text("See All")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            if communityViewModel.sharedSequences.isEmpty {
                ContentUnavailableView(
                    "No Shared Sequences Yet",
                    systemImage: "person.3",
                    description: Text("Be the first to share a sequence with the community!")
                )
                .frame(minHeight: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(communityViewModel.sharedSequences.prefix(5)) { sequence in
                        CommunitySequenceCard(
                            sequence: sequence,
                            isLiked: userProfile.likedSequenceIds.contains(sequence.id),
                            isSaved: userProfile.savedSequenceIds.contains(sequence.id),
                            onTap: { selectedSequence = sequence },
                            onLike: { communityViewModel.toggleLike(sequenceId: sequence.id, userProfile: userProfile) },
                            onSave: { communityViewModel.toggleSave(sequenceId: sequence.id, userProfile: userProfile) }
                        )
                    }

                    if communityViewModel.sharedSequences.count > 5 {
                        Button {
                            showingAllSequences = true
                        } label: {
                            Text("See \(communityViewModel.sharedSequences.count - 5) more sequences")
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
                    Label("\(sequence.likesCount)", systemImage: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .secondary)
                }
                .buttonStyle(.plain)

                // Save button
                Button(action: onSave) {
                    Label("\(sequence.savesCount)", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isSaved ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)

                // Comments indicator
                Label("\(sequence.commentsCount)", systemImage: "bubble.right")
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
    var communityViewModel: CommunityViewModel
    let onDone: () -> Void

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
        Task {
            try? await communityViewModel.shareSequence(sequence, description: shareDescription)
            await MainActor.run {
                isSharing = false
                onDone()
            }
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
                                    PoseImageView(imageURL: pose.imageURL, size: 24, cornerRadius: 4)

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
    let sharedSequence: SharedSequence
    var communityViewModel: CommunityViewModel
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

    private var comments: [SequenceComment] {
        communityViewModel.commentsCache[sharedSequence.id] ?? []
    }

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
            .onAppear {
                communityViewModel.loadComments(for: sharedSequence.id)
            }
            .onDisappear {
                communityViewModel.unloadComments(for: sharedSequence.id)
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
                    Text("\(sharedSequence.likesCount)")
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
                    Text("\(sharedSequence.savesCount)")
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
                Text("\(sharedSequence.commentsCount)")
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
            if comments.isEmpty {
                Text("No comments yet. Be the first to comment!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(comments) { comment in
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
        communityViewModel.addComment(sequenceId: sharedSequence.id, content: newComment)
        newComment = ""
    }

    private func addReply(to comment: SequenceComment) {
        guard !replyText.isEmpty else { return }
        communityViewModel.addComment(sequenceId: sharedSequence.id, content: replyText, parentCommentId: comment.id)
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
                        PoseImageView(imageURL: pose.imageURL, size: 36, cornerRadius: 8)

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
                    Text("\u{2022}")
                    Text(post.createdAt, style: .relative)

                    Spacer()

                    Label("\(post.likesCount)", systemImage: "heart")
                    Label("\(post.repliesCount)", systemImage: "bubble.right")
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
    var communityViewModel: CommunityViewModel
    let onDone: () -> Void

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
        communityViewModel.createPost(title: title, content: content)
        isPosting = false
        onDone()
    }
}

// MARK: - Post Detail View

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let post: CommunityPost
    var communityViewModel: CommunityViewModel
    let onClose: () -> Void
    var userProfile: UserProfile

    @State private var newReply = ""
    @State private var isLiked = false

    private var replies: [SequenceComment] {
        communityViewModel.repliesCache[post.id] ?? []
    }

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

                            Text("\u{2022}")
                                .foregroundStyle(.secondary)

                            Text(post.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Like button
                        Button {
                            communityViewModel.togglePostLike(postId: post.id, userProfile: userProfile)
                            isLiked.toggle()
                        } label: {
                            Label("\(post.likesCount)", systemImage: isLiked ? "heart.fill" : "heart")
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
                        Text("Replies (\(replies.count))")
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

                        if replies.isEmpty {
                            Text("No replies yet. Be the first to respond!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ForEach(replies) { reply in
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
                communityViewModel.loadReplies(for: post.id)
            }
            .onDisappear {
                communityViewModel.unloadReplies(for: post.id)
            }
        }
    }

    private func addReply() {
        communityViewModel.addReply(postId: post.id, content: newReply)
        userProfile.commentedPostIds.insert(post.id)
        newReply = ""
    }
}

// MARK: - All Discussions View

struct AllDiscussionsView: View {
    @Environment(\.dismiss) private var dismiss
    let posts: [CommunityPost]
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
    CommunityView(sequenceViewModel: SequenceViewModel(), communityViewModel: CommunityViewModel(), poses: [], userProfile: UserProfile())
}
