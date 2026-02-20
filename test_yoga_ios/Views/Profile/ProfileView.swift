//
//  ProfileView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/30/26.
//

import SwiftUI
import FirebaseAuth

// MARK: - Profile View

struct ProfileView: View {
    @Bindable var userProfile: UserProfile
    var communityViewModel: CommunityViewModel?
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

    private var mySharedSequences: [SharedSequence] {
        guard let userId = authViewModel?.currentUser?.uid else { return [] }
        return communityViewModel?.sharedSequences.filter { $0.authorId == userId } ?? []
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
                EditProfileView(userProfile: userProfile, authViewModel: authViewModel)
            }
            .sheet(isPresented: $showingLikedSequences) {
                ActivityDetailView(
                    title: "Liked Sequences",
                    icon: "heart.fill",
                    iconColor: .red,
                    sequenceIds: userProfile.likedSequenceIds,
                    allSequences: communityViewModel?.sharedSequences ?? []
                )
            }
            .sheet(isPresented: $showingSavedSequences) {
                ActivityDetailView(
                    title: "Saved Sequences",
                    icon: "bookmark.fill",
                    iconColor: Color.accentColor,
                    sequenceIds: userProfile.savedSequenceIds,
                    allSequences: communityViewModel?.sharedSequences ?? []
                )
            }
            .sheet(isPresented: $showingCommentedSequences) {
                ActivityDetailView(
                    title: "Commented Sequences",
                    icon: "bubble.right.fill",
                    iconColor: .green,
                    sequenceIds: userProfile.commentedSequenceIds,
                    allSequences: communityViewModel?.sharedSequences ?? []
                )
            }
            .sheet(isPresented: $showingLikedDiscussions) {
                DiscussionActivityDetailView(
                    title: "Liked Discussions",
                    icon: "heart.fill",
                    iconColor: .red,
                    postIds: userProfile.likedPostIds,
                    allPosts: communityViewModel?.posts ?? []
                )
            }
            .sheet(isPresented: $showingCommentedDiscussions) {
                DiscussionActivityDetailView(
                    title: "Commented Discussions",
                    icon: "bubble.right.fill",
                    iconColor: .green,
                    postIds: userProfile.commentedPostIds,
                    allPosts: communityViewModel?.posts ?? []
                )
            }
            .sheet(isPresented: $showingSharedSequences) {
                SharedSequencesDetailView(sharedSequences: mySharedSequences)
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
                    value: "\(mySharedSequences.count)",
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
    let allSequences: [SharedSequence]

    private var filteredSequences: [SharedSequence] {
        allSequences.filter { sequenceIds.contains($0.id) }
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

                Label("\(sequence.likesCount)", systemImage: "heart.fill")
                    .foregroundStyle(.red)

                Label("\(sequence.savesCount)", systemImage: "bookmark.fill")
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
    let allPosts: [CommunityPost]

    private var filteredPosts: [CommunityPost] {
        allPosts.filter { postIds.contains($0.id) }
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
    var authViewModel: AuthViewModel?

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

        // Save to Firestore
        if let userId = authViewModel?.currentUser?.uid {
            Task {
                try? await UserService.shared.saveProfile(userProfile, userId: userId)
            }
        }

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
    ProfileView(userProfile: UserProfile())
}
