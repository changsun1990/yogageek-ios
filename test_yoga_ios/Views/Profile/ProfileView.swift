//
//  ProfileView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/30/26.
//

import SwiftUI

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
    @State private var userProfile = UserProfile.mock
    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Stats
                    statsSection

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
                    Button {
                        showingEditProfile = true
                    } label: {
                        Text("Edit")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(userProfile: $userProfile)
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: userProfile.profileImageName)
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 4) {
                Text(userProfile.displayName.isEmpty ? "Yoga Practitioner" : userProfile.displayName)
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
            StatCard(
                icon: "rectangle.stack.fill",
                value: "\(userProfile.sequencesCreated)",
                label: "Created"
            )

            StatCard(
                icon: "square.and.arrow.up.fill",
                value: "\(userProfile.sequencesShared)",
                label: "Shared"
            )

            StatCard(
                icon: "clock.fill",
                value: formatMinutes(userProfile.totalPracticeMinutes),
                label: "Practice"
            )
        }
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
    @Binding var userProfile: UserProfile

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
    ProfileView()
}
