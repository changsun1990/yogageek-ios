//
//  ProfileView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/30/26.
//

import SwiftUI
import FirebaseAuth

// MARK: - User Profile Model

@Observable
class UserProfile {
    var id: String = UUID().uuidString
    var displayName: String = ""
    var bio: String = ""
    var yogaExperienceLevel: YogaExperienceLevel = .beginner
    var yearsOfPractice: Int = 0
    var favoriteStyles: [YogaStyle] = []
    var goals: [YogaGoal] = []
    var preferredPracticeTimes: [PracticeTime] = []
    var profileImageName: String = "person.circle.fill"
    var joinedDate: Date = Date()
    var sequencesCreated: Int = 0
    var sequencesShared: Int = 0
    var totalPracticeMinutes: Int = 0

    // Community interaction tracking
    var likedSequenceIds: Set<String> = [] {
        didSet { saveCommunityData() }
    }
    var savedSequenceIds: Set<String> = [] {
        didSet { saveCommunityData() }
    }
    var commentedSequenceIds: Set<String> = [] {
        didSet { saveCommunityData() }
    }
    var likedPostIds: Set<String> = [] {
        didSet { saveCommunityData() }
    }
    var commentedPostIds: Set<String> = [] {
        didSet { saveCommunityData() }
    }
    var sharedSequences: [SharedSequence] = [] {
        didSet { saveCommunityData() }
    }

    private let communityDataKey = "user_community_data"

    init() {
        loadCommunityData()
    }

    private func saveCommunityData() {
        let data = CommunityData(
            likedSequenceIds: Array(likedSequenceIds),
            savedSequenceIds: Array(savedSequenceIds),
            commentedSequenceIds: Array(commentedSequenceIds),
            likedPostIds: Array(likedPostIds),
            commentedPostIds: Array(commentedPostIds),
            sharedSequences: sharedSequences
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: communityDataKey)
        }
    }

    private func loadCommunityData() {
        guard let data = UserDefaults.standard.data(forKey: communityDataKey),
              let decoded = try? JSONDecoder().decode(CommunityData.self, from: data) else {
            return
        }
        likedSequenceIds = Set(decoded.likedSequenceIds)
        savedSequenceIds = Set(decoded.savedSequenceIds)
        commentedSequenceIds = Set(decoded.commentedSequenceIds)
        likedPostIds = Set(decoded.likedPostIds)
        commentedPostIds = Set(decoded.commentedPostIds)
        sharedSequences = decoded.sharedSequences
    }

    static var mock: UserProfile {
        let profile = UserProfile()
        profile.displayName = "Yoga Enthusiast"
        profile.bio = "Passionate about yoga and mindfulness. Love exploring new sequences and sharing with the community."
        profile.yogaExperienceLevel = .intermediate
        profile.yearsOfPractice = 3
        profile.favoriteStyles = [.vinyasa, .hatha, .yin]
        profile.goals = [.flexibility, .stressRelief, .strength]
        profile.preferredPracticeTimes = [.morning, .evening]
        profile.sequencesCreated = 5
        profile.sequencesShared = 2
        profile.totalPracticeMinutes = 1250
        return profile
    }
}

// Helper struct for encoding/decoding community data
private struct CommunityData: Codable {
    let likedSequenceIds: [String]
    let savedSequenceIds: [String]
    let commentedSequenceIds: [String]
    let likedPostIds: [String]
    let commentedPostIds: [String]
    let sharedSequences: [SharedSequence]
}

enum YogaExperienceLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .beginner: return "New to yoga, learning the basics"
        case .intermediate: return "Comfortable with common poses"
        case .advanced: return "Experienced with challenging poses"
        case .expert: return "Teaching-level expertise"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "leaf"
        case .intermediate: return "leaf.fill"
        case .advanced: return "star"
        case .expert: return "star.fill"
        }
    }
}

enum YogaStyle: String, CaseIterable, Identifiable {
    case vinyasa = "Vinyasa"
    case hatha = "Hatha"
    case ashtanga = "Ashtanga"
    case yin = "Yin"
    case restorative = "Restorative"
    case power = "Power"
    case bikram = "Bikram"
    case kundalini = "Kundalini"
    case iyengar = "Iyengar"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .vinyasa: return "wind"
        case .hatha: return "sun.max"
        case .ashtanga: return "flame"
        case .yin: return "moon"
        case .restorative: return "leaf"
        case .power: return "bolt"
        case .bikram: return "thermometer.sun"
        case .kundalini: return "sparkles"
        case .iyengar: return "ruler"
        }
    }
}

enum YogaGoal: String, CaseIterable, Identifiable {
    case flexibility = "Flexibility"
    case strength = "Strength"
    case balance = "Balance"
    case stressRelief = "Stress Relief"
    case mindfulness = "Mindfulness"
    case weightLoss = "Weight Loss"
    case betterSleep = "Better Sleep"
    case painRelief = "Pain Relief"
    case energy = "Energy"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .flexibility: return "figure.flexibility"
        case .strength: return "figure.strengthtraining.traditional"
        case .balance: return "figure.stand"
        case .stressRelief: return "brain.head.profile"
        case .mindfulness: return "heart.circle"
        case .weightLoss: return "figure.run"
        case .betterSleep: return "moon.zzz"
        case .painRelief: return "bandage"
        case .energy: return "bolt.heart"
        }
    }
}

enum PracticeTime: String, CaseIterable, Identifiable {
    case earlyMorning = "Early Morning"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    var id: String { rawValue }

    var timeRange: String {
        switch self {
        case .earlyMorning: return "5-7 AM"
        case .morning: return "7-10 AM"
        case .afternoon: return "12-5 PM"
        case .evening: return "5-8 PM"
        case .night: return "8-11 PM"
        }
    }

    var icon: String {
        switch self {
        case .earlyMorning: return "sunrise"
        case .morning: return "sun.horizon"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .night: return "moon.stars"
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @Bindable var userProfile: UserProfile
    var sequenceViewModel: SequenceViewModel?
    var authViewModel: AuthViewModel?
    var onNavigateToSequences: (() -> Void)?

    @State private var showingEditProfile = false
    @State private var selectedActivityTab: ActivityTab = .sequences
    @State private var showingLikedSequences = false
    @State private var showingSavedSequences = false
    @State private var showingCommentedSequences = false
    @State private var showingLikedDiscussions = false
    @State private var showingCommentedDiscussions = false
    @State private var showingSharedSequences = false
    @State private var showingSignOutConfirmation = false

    enum ActivityTab: String, CaseIterable {
        case sequences = "Sequences"
        case discussions = "Discussions"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Stats
                    statsSection

                    // Community Activity section
                    communityActivitySection

                    // Experience
                    experienceSection

                    // Favorite styles
                    stylesSection

                    // Goals
                    goalsSection

                    // Practice times
                    practiceTimesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditProfile = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        if authViewModel != nil {
                            Divider()

                            Button(role: .destructive) {
                                showingSignOutConfirmation = true
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authViewModel?.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(userProfile: userProfile)
            }
            .sheet(isPresented: $showingLikedSequences) {
                ActivityDetailView(
                    title: "Liked Sequences",
                    icon: "heart.fill",
                    iconColor: .red,
                    sequenceIds: userProfile.likedSequenceIds
                )
            }
            .sheet(isPresented: $showingSavedSequences) {
                ActivityDetailView(
                    title: "Saved Sequences",
                    icon: "bookmark.fill",
                    iconColor: Color.accentColor,
                    sequenceIds: userProfile.savedSequenceIds
                )
            }
            .sheet(isPresented: $showingCommentedSequences) {
                ActivityDetailView(
                    title: "Commented Sequences",
                    icon: "bubble.right.fill",
                    iconColor: .green,
                    sequenceIds: userProfile.commentedSequenceIds
                )
            }
            .sheet(isPresented: $showingLikedDiscussions) {
                DiscussionActivityDetailView(
                    title: "Liked Discussions",
                    icon: "heart.fill",
                    iconColor: .red,
                    postIds: userProfile.likedPostIds
                )
            }
            .sheet(isPresented: $showingCommentedDiscussions) {
                DiscussionActivityDetailView(
                    title: "Commented Discussions",
                    icon: "bubble.right.fill",
                    iconColor: .green,
                    postIds: userProfile.commentedPostIds
                )
            }
            .sheet(isPresented: $showingSharedSequences) {
                SharedSequencesDetailView(sharedSequences: userProfile.sharedSequences)
            }
        }
    }

    private var displayName: String {
        // First try Firebase user's display name, then fall back to userProfile
        if let firebaseName = authViewModel?.currentUser?.displayName, !firebaseName.isEmpty {
            return firebaseName
        }
        return userProfile.displayName.isEmpty ? "Yoga Practitioner" : userProfile.displayName
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: userProfile.profileImageName)
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 4) {
                    Image(systemName: userProfile.yogaExperienceLevel.icon)
                    Text(userProfile.yogaExperienceLevel.rawValue)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if userProfile.yearsOfPractice > 0 {
                    Text("\(userProfile.yearsOfPractice) years of practice")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !userProfile.bio.isEmpty {
                Text(userProfile.bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            Button {
                onNavigateToSequences?()
            } label: {
                StatCard(
                    icon: "rectangle.stack.fill",
                    value: "\(sequenceViewModel?.sequences.count ?? 0)",
                    label: "Created"
                )
            }
            .buttonStyle(.plain)

            Button {
                showingSharedSequences = true
            } label: {
                StatCard(
                    icon: "square.and.arrow.up.fill",
                    value: "\(userProfile.sharedSequences.count)",
                    label: "Shared"
                )
            }
            .buttonStyle(.plain)

            StatCard(
                icon: "clock.fill",
                value: formatMinutes(userProfile.totalPracticeMinutes),
                label: "Practice"
            )
        }
    }

    private var communityActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Activity")
                .font(.headline)

            // Tab picker
            Picker("Activity Type", selection: $selectedActivityTab) {
                ForEach(ActivityTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            if selectedActivityTab == .sequences {
                sequenceActivitySection
            } else {
                discussionActivitySection
            }
        }
    }

    private var sequenceActivitySection: some View {
        VStack(spacing: 12) {
            // Liked sequences
            Button {
                showingLikedSequences = true
            } label: {
                ActivityRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Liked Sequences",
                    count: userProfile.likedSequenceIds.count
                )
            }
            .buttonStyle(.plain)

            // Saved sequences
            Button {
                showingSavedSequences = true
            } label: {
                ActivityRow(
                    icon: "bookmark.fill",
                    iconColor: Color.accentColor,
                    title: "Saved Sequences",
                    count: userProfile.savedSequenceIds.count
                )
            }
            .buttonStyle(.plain)

            // Commented sequences
            Button {
                showingCommentedSequences = true
            } label: {
                ActivityRow(
                    icon: "bubble.right.fill",
                    iconColor: .green,
                    title: "Commented Sequences",
                    count: userProfile.commentedSequenceIds.count
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var discussionActivitySection: some View {
        VStack(spacing: 12) {
            // Liked discussions
            Button {
                showingLikedDiscussions = true
            } label: {
                ActivityRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Liked Discussions",
                    count: userProfile.likedPostIds.count
                )
            }
            .buttonStyle(.plain)

            // Commented discussions
            Button {
                showingCommentedDiscussions = true
            } label: {
                ActivityRow(
                    icon: "bubble.right.fill",
                    iconColor: .green,
                    title: "Commented Discussions",
                    count: userProfile.commentedPostIds.count
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Experience Level")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: userProfile.yogaExperienceLevel.icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfile.yogaExperienceLevel.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(userProfile.yogaExperienceLevel.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var stylesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorite Styles")
                .font(.headline)

            if userProfile.favoriteStyles.isEmpty {
                Text("No styles selected yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(userProfile.favoriteStyles) { style in
                        HStack(spacing: 4) {
                            Image(systemName: style.icon)
                            Text(style.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals")
                .font(.headline)

            if userProfile.goals.isEmpty {
                Text("No goals set yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(userProfile.goals) { goal in
                        HStack(spacing: 12) {
                            Image(systemName: goal.icon)
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 32)

                            Text(goal.rawValue)
                                .font(.subheadline)

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var practiceTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferred Practice Times")
                .font(.headline)

            if userProfile.preferredPracticeTimes.isEmpty {
                Text("No times selected yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                HStack(spacing: 12) {
                    ForEach(userProfile.preferredPracticeTimes) { time in
                        VStack(spacing: 4) {
                            Image(systemName: time.icon)
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)

                            Text(time.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)

                            Text(time.timeRange)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let icon: String
    let iconColor: Color
    let sequenceIds: Set<String>

    // Get sequences from mock data that match the IDs
    private var filteredSequences: [SharedSequence] {
        SharedSequence.mockData.filter { sequenceIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSequences.isEmpty {
                    ContentUnavailableView(
                        "No \(title) Yet",
                        systemImage: icon,
                        description: Text("Sequences you \(title.lowercased().replacingOccurrences(of: " sequences", with: "")) will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSequences) { sharedSequence in
                                ActivitySequenceCard(sequence: sharedSequence)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
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

struct ActivitySequenceCard: View {
    let sequence: SharedSequence

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sequence.sequence.name)
                        .font(.headline)

                    Text("by \(sequence.authorName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

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

                Label("\(sequence.likes)", systemImage: "heart.fill")
                    .foregroundStyle(.red)

                Label("\(sequence.saves)", systemImage: "bookmark.fill")
                    .foregroundStyle(Color.accentColor)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Discussion Activity Detail View

struct DiscussionActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let icon: String
    let iconColor: Color
    let postIds: Set<String>

    // Get posts from mock data that match the IDs
    private var filteredPosts: [CommunityPost] {
        CommunityPost.mockData.filter { postIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredPosts.isEmpty {
                    ContentUnavailableView(
                        "No \(title) Yet",
                        systemImage: icon,
                        description: Text("Discussions you \(title.lowercased().replacingOccurrences(of: " discussions", with: "")) will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPosts) { post in
                                ActivityPostCard(post: post)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
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

struct ActivityPostCard: View {
    let post: CommunityPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.title)
                .font(.headline)

            Text(post.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

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
    }
}

// MARK: - Shared Sequences Detail View

struct SharedSequencesDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let sharedSequences: [SharedSequence]

    var body: some View {
        NavigationStack {
            Group {
                if sharedSequences.isEmpty {
                    ContentUnavailableView(
                        "No Shared Sequences Yet",
                        systemImage: "square.and.arrow.up",
                        description: Text("Sequences you share with the community will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sharedSequences) { sharedSequence in
                                ActivitySequenceCard(sequence: sharedSequence)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Shared Sequences")
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, containerWidth: bounds.width).offsets

        for (subview, offset) in zip(subviews, offsets) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (offsets, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    var userProfile: UserProfile

    @State private var editedName: String = ""
    @State private var editedBio: String = ""
    @State private var editedLevel: YogaExperienceLevel = .beginner
    @State private var editedYears: Int = 0
    @State private var editedStyles: Set<YogaStyle> = []
    @State private var editedGoals: Set<YogaGoal> = []
    @State private var editedTimes: Set<PracticeTime> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Display Name", text: $editedName)

                    TextField("Bio", text: $editedBio, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Experience") {
                    Picker("Level", selection: $editedLevel) {
                        ForEach(YogaExperienceLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }

                    Stepper("Years of Practice: \(editedYears)", value: $editedYears, in: 0...50)
                }

                Section("Favorite Styles") {
                    ForEach(YogaStyle.allCases) { style in
                        Button {
                            toggleStyle(style)
                        } label: {
                            HStack {
                                Image(systemName: style.icon)
                                    .frame(width: 24)
                                Text(style.rawValue)
                                Spacer()
                                if editedStyles.contains(style) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Section("Goals") {
                    ForEach(YogaGoal.allCases) { goal in
                        Button {
                            toggleGoal(goal)
                        } label: {
                            HStack {
                                Image(systemName: goal.icon)
                                    .frame(width: 24)
                                Text(goal.rawValue)
                                Spacer()
                                if editedGoals.contains(goal) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Section("Preferred Practice Times") {
                    ForEach(PracticeTime.allCases) { time in
                        Button {
                            toggleTime(time)
                        } label: {
                            HStack {
                                Image(systemName: time.icon)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(time.rawValue)
                                    Text(time.timeRange)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if editedTimes.contains(time) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    private func loadProfile() {
        editedName = userProfile.displayName
        editedBio = userProfile.bio
        editedLevel = userProfile.yogaExperienceLevel
        editedYears = userProfile.yearsOfPractice
        editedStyles = Set(userProfile.favoriteStyles)
        editedGoals = Set(userProfile.goals)
        editedTimes = Set(userProfile.preferredPracticeTimes)
    }

    private func saveProfile() {
        userProfile.displayName = editedName
        userProfile.bio = editedBio
        userProfile.yogaExperienceLevel = editedLevel
        userProfile.yearsOfPractice = editedYears
        userProfile.favoriteStyles = Array(editedStyles)
        userProfile.goals = Array(editedGoals)
        userProfile.preferredPracticeTimes = Array(editedTimes)
        dismiss()
    }

    private func toggleStyle(_ style: YogaStyle) {
        if editedStyles.contains(style) {
            editedStyles.remove(style)
        } else {
            editedStyles.insert(style)
        }
    }

    private func toggleGoal(_ goal: YogaGoal) {
        if editedGoals.contains(goal) {
            editedGoals.remove(goal)
        } else {
            editedGoals.insert(goal)
        }
    }

    private func toggleTime(_ time: PracticeTime) {
        if editedTimes.contains(time) {
            editedTimes.remove(time)
        } else {
            editedTimes.insert(time)
        }
    }
}

#Preview {
    ProfileView(userProfile: UserProfile.mock)
}
