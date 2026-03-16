//
//  HomeView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/20/26.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    var authViewModel: AuthViewModel?
    var sequenceViewModel: SequenceViewModel
    var poseViewModel: PoseViewModel
    var communityViewModel: CommunityViewModel
    @Bindable var userProfile: UserProfile
    @Binding var selectedTab: AppTab

    @State private var showingNewSequenceOptions = false
    @State private var sequenceToEdit: YogaSequence?
    @State private var selectedSharedSequence: SharedSequence?
    @State private var selectedPost: CommunityPost?

    private var userName: String {
        if let name = authViewModel?.currentUser?.displayName, !name.isEmpty {
            return name.components(separatedBy: " ").first ?? name
        }
        return "Yogi"
    }

    private var recentSequences: [YogaSequence] {
        Array(
            sequenceViewModel.sequences
                .sorted { $0.updatedAt > $1.updatedAt }
                .prefix(10)
        )
    }

    /// Unique poses from the user's sequences, ordered by most recently used
    private var posesFromSequences: [Pose] {
        var seen = Set<String>()
        var result: [Pose] = []
        let sortedSequences = sequenceViewModel.sequences.sorted { $0.updatedAt > $1.updatedAt }
        for sequence in sortedSequences {
            for poseEntry in sequence.sections.flatMap(\.poses) {
                guard !seen.contains(poseEntry.poseId) else { continue }
                seen.insert(poseEntry.poseId)
                if let pose = poseViewModel.poses.first(where: { $0.id == poseEntry.poseId }) {
                    result.append(pose)
                }
                if result.count >= 15 { return result }
            }
        }
        return result
    }

    private var recentCommunitySequences: [SharedSequence] {
        Array(
            communityViewModel.sharedSequences
                .sorted { $0.sharedAt > $1.sharedAt }
                .prefix(10)
        )
    }

    private var recentDiscussions: [CommunityPost] {
        Array(
            communityViewModel.posts
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(6)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroBanner

                    if !recentSequences.isEmpty {
                        recentSequencesSection
                    }

                    if !posesFromSequences.isEmpty {
                        yourPosesSection
                    }

                    if !recentCommunitySequences.isEmpty {
                        communitySequencesSection
                    }

                    if !recentDiscussions.isEmpty {
                        discussionsSection
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .yogaScreenBackground()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Pose.self) { pose in
                PoseDetailView(pose: pose, poses: poseViewModel.poses, sequenceViewModel: sequenceViewModel)
            }
            .sheet(isPresented: $showingNewSequenceOptions) {
                NewSequenceOptionsView(
                    viewModel: sequenceViewModel,
                    poses: poseViewModel.poses,
                    communityViewModel: communityViewModel
                )
            }
            .sheet(item: $sequenceToEdit) { sequence in
                SequenceEditorView(
                    viewModel: sequenceViewModel,
                    poses: poseViewModel.poses,
                    communityViewModel: communityViewModel,
                    sequence: sequence,
                    isNew: false
                )
            }
            .sheet(item: $selectedSharedSequence) { sequence in
                SharedSequenceDetailView(
                    sharedSequence: sequence,
                    communityViewModel: communityViewModel,
                    poses: poseViewModel.poses,
                    isLiked: userProfile.likedSequenceIds.contains(sequence.id),
                    isSaved: userProfile.savedSequenceIds.contains(sequence.id),
                    onLike: { communityViewModel.toggleLike(sequenceId: sequence.id, userProfile: userProfile) },
                    onSave: { communityViewModel.toggleSave(sequenceId: sequence.id, userProfile: userProfile) },
                    onSaveToSequences: { savedSequence, groupName in
                        if !sequenceViewModel.allGroups.contains(groupName) && !groupName.isEmpty {
                            sequenceViewModel.addGroup(groupName)
                        }
                        sequenceViewModel.addSequence(savedSequence)
                    },
                    availableGroups: sequenceViewModel.allGroups,
                    userProfile: userProfile
                )
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(
                    post: post,
                    communityViewModel: communityViewModel,
                    onClose: { selectedPost = nil },
                    userProfile: userProfile
                )
            }
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                // Welcome chip
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("Welcome back, \(userName)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.yogaPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yogaPrimary.opacity(0.12))
                .clipShape(Capsule())

                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Design your perfect")
                        .font(.yogaTitle(26))
                        .foregroundStyle(.primary)

                    Text("yoga flow")
                        .font(.yogaAccent(28))
                        .italic()
                        .foregroundStyle(Color.yogaPrimary)
                }

                // Subtitle
                Text("Create, manage, and practice beautiful yoga sequences with our intuitive drag-and-drop builder.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // CTA button
                Button {
                    showingNewSequenceOptions = true
                } label: {
                    Label("Create Sequence", systemImage: "plus")
                        .font(.yogaHeadline())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.yogaPrimary)
                        .clipShape(Capsule())
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Decorative element
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yogaPrimary.opacity(0.15),
                            Color.yogaSecondary.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .offset(x: 50, y: 50)
        }
        .background(Color.yogaHeroBanner)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .yogaCardShadow()
        .padding(.horizontal)
    }

    // MARK: - Recent Sequences

    private var recentSequencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sequences")
                    .font(.yogaTitle(20))
                Spacer()
                Button("View all") {
                    selectedTab = .mySequences
                }
                .font(.subheadline)
                .foregroundStyle(Color.yogaPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(recentSequences) { sequence in
                        RecentSequenceCard(
                            sequence: sequence,
                            poses: poseViewModel.poses
                        )
                        .onTapGesture {
                            sequenceToEdit = sequence
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Your Poses

    private var yourPosesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Poses")
                    .font(.yogaTitle(20))
                Spacer()
                Button("Explore all") {
                    selectedTab = .explore
                }
                .font(.subheadline)
                .foregroundStyle(Color.yogaPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(posesFromSequences) { pose in
                        NavigationLink(value: pose) {
                            HomePoseCard(pose: pose)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Community Sequences

    private var communitySequencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Community Sequences")
                    .font(.yogaTitle(20))
                Spacer()
                Button("View all") {
                    selectedTab = .community
                }
                .font(.subheadline)
                .foregroundStyle(Color.yogaPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(recentCommunitySequences) { shared in
                        HomeCommunityCard(sharedSequence: shared)
                            .onTapGesture {
                                selectedSharedSequence = shared
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Discussions

    private var discussionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Discussions")
                    .font(.yogaTitle(20))
                Spacer()
                Button("View all") {
                    selectedTab = .community
                }
                .font(.subheadline)
                .foregroundStyle(Color.yogaPrimary)
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(recentDiscussions) { post in
                    HomeDiscussionRow(post: post)
                        .onTapGesture {
                            selectedPost = post
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Recent Sequence Card

struct RecentSequenceCard: View {
    let sequence: YogaSequence
    let poses: [Pose]

    private var firstPoseImage: String? {
        guard let firstPoseId = sequence.sections.flatMap(\.poses).first?.poseId else {
            return nil
        }
        return poses.first { $0.id == firstPoseId }?.imageURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let imageURL = firstPoseImage, imageURL.hasPrefix("http") {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 180, height: 110)
                                .clipped()
                        default:
                            gradientPlaceholder
                        }
                    }
                } else {
                    gradientPlaceholder
                }

                Text("\(sequence.totalPoseCount) poses")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
            }
            .frame(width: 180, height: 110)

            VStack(alignment: .leading, spacing: 4) {
                Text(sequence.name.isEmpty ? "Untitled Sequence" : sequence.name)
                    .font(.yogaHeadline(14))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(sequence.sections.count) sections", systemImage: "rectangle.stack")
                    Label(formattedDuration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .frame(width: 180)
        .background(Color.yogaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .yogaCardShadow()
    }

    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: [
                Color.yogaPrimary.opacity(0.25),
                Color.yogaSecondary.opacity(0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(width: 180, height: 110)
        .overlay {
            Image(systemName: "figure.yoga")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var formattedDuration: String {
        let minutes = sequence.totalDuration / 60
        if minutes < 1 {
            return "\(sequence.totalDuration)s"
        }
        return "\(minutes)m"
    }
}

// MARK: - Home Pose Card

struct HomePoseCard: View {
    let pose: Pose

    var body: some View {
        VStack(spacing: 8) {
            PoseImageView(imageURL: pose.imageURL, size: 70, cornerRadius: 14)

            Text(pose.nameEnglish)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding(10)
        .background(Color.yogaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .yogaCardShadow()
    }
}

// MARK: - Home Community Sequence Card

struct HomeCommunityCard: View {
    let sharedSequence: SharedSequence

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sharedSequence.sequence.name)
                .font(.yogaHeadline(14))
                .lineLimit(1)

            Text("by \(sharedSequence.authorName)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if !sharedSequence.sequence.description.isEmpty {
                Text(sharedSequence.sequence.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                Label("\(sharedSequence.sequence.totalPoseCount)", systemImage: "figure.yoga")
                Label("\(sharedSequence.likesCount)", systemImage: "heart")
                Label("\(sharedSequence.commentsCount)", systemImage: "bubble.right")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: 200, alignment: .leading)
        .background(Color.yogaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .yogaCardShadow()
    }
}

// MARK: - Home Discussion Row

struct HomeDiscussionRow: View {
    let post: CommunityPost

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.title3)
                .foregroundStyle(Color.yogaPrimary)
                .frame(width: 36, height: 36)
                .background(Color.yogaPrimary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("by \(post.authorName)")
                    Text("\u{2022}")
                    Label("\(post.repliesCount)", systemImage: "bubble.right")
                    Label("\(post.likesCount)", systemImage: "heart")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.yogaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .yogaCardShadow()
    }
}

#Preview {
    HomeView(
        authViewModel: nil,
        sequenceViewModel: SequenceViewModel(),
        poseViewModel: PoseViewModel(),
        communityViewModel: CommunityViewModel(),
        userProfile: UserProfile(),
        selectedTab: .constant(.home)
    )
}
