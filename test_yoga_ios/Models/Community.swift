//
//  Community.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import Foundation

// MARK: - User Profile

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
    var likedSequenceIds: Set<String> = []
    var savedSequenceIds: Set<String> = []
    var commentedSequenceIds: Set<String> = []
    var likedPostIds: Set<String> = []
    var commentedPostIds: Set<String> = []

    init() {}

    func update(from other: UserProfile) {
        id = other.id
        displayName = other.displayName
        bio = other.bio
        yogaExperienceLevel = other.yogaExperienceLevel
        yearsOfPractice = other.yearsOfPractice
        favoriteStyles = other.favoriteStyles
        goals = other.goals
        preferredPracticeTimes = other.preferredPracticeTimes
        profileImageName = other.profileImageName
        joinedDate = other.joinedDate
        sequencesCreated = other.sequencesCreated
        sequencesShared = other.sequencesShared
        totalPracticeMinutes = other.totalPracticeMinutes
        likedSequenceIds = other.likedSequenceIds
        savedSequenceIds = other.savedSequenceIds
        commentedSequenceIds = other.commentedSequenceIds
        likedPostIds = other.likedPostIds
        commentedPostIds = other.commentedPostIds
    }
}

// MARK: - Shared Sequence

struct SharedSequence: Identifiable, Codable {
    let id: String
    let sequence: YogaSequence
    let authorName: String
    let authorId: String
    let sharedAt: Date
    var likesCount: Int
    var savesCount: Int
    var commentsCount: Int

    init(id: String = UUID().uuidString, sequence: YogaSequence, authorName: String, authorId: String, sharedAt: Date = Date(), likesCount: Int = 0, savesCount: Int = 0, commentsCount: Int = 0) {
        self.id = id
        self.sequence = sequence
        self.authorName = authorName
        self.authorId = authorId
        self.sharedAt = sharedAt
        self.likesCount = likesCount
        self.savesCount = savesCount
        self.commentsCount = commentsCount
    }
}

// MARK: - Community Post

struct CommunityPost: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorName: String
    let title: String
    let content: String
    let createdAt: Date
    var likesCount: Int
    var repliesCount: Int

    init(id: String = UUID().uuidString, authorId: String, authorName: String, title: String, content: String, createdAt: Date = Date(), likesCount: Int = 0, repliesCount: Int = 0) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.repliesCount = repliesCount
    }
}

// MARK: - Sequence Comment

struct SequenceComment: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorName: String
    let content: String
    let createdAt: Date
    let parentCommentId: String?
    var replies: [SequenceComment]

    init(id: String = UUID().uuidString, authorId: String, authorName: String, content: String, createdAt: Date = Date(), parentCommentId: String? = nil, replies: [SequenceComment] = []) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = createdAt
        self.parentCommentId = parentCommentId
        self.replies = replies
    }
}

// MARK: - Enums

enum YogaExperienceLevel: String, CaseIterable, Identifiable, Codable {
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

enum YogaStyle: String, CaseIterable, Identifiable, Codable, Hashable {
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

enum YogaGoal: String, CaseIterable, Identifiable, Codable, Hashable {
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

enum PracticeTime: String, CaseIterable, Identifiable, Codable, Hashable {
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
