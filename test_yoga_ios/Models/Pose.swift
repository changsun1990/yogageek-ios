//
//  Pose.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import Foundation

struct Pose: Identifiable, Codable, Hashable {
    let id: String
    let nameEnglish: String
    let nameSanskrit: String
    let description: String
    let exampleCues: [String]
    let benefits: [String]
    let imageURL: String
    let category: PoseCategory
    let difficulty: PoseDifficulty
}

enum PoseCategory: String, Codable, CaseIterable {
    case standing = "standing"
    case seated = "seated"
    case balance = "balance"
    case inversion = "inversion"
    case prone = "prone"
    case supine = "supine"
    case hipOpener = "hip_opener"
    case allFours = "all_fours"
    case armBalance = "arm_balance"

    var displayName: String {
        switch self {
        case .standing: return "Standing"
        case .seated: return "Seated"
        case .balance: return "Balance"
        case .inversion: return "Inversion"
        case .prone: return "Prone"
        case .supine: return "Supine"
        case .hipOpener: return "Hip Opener"
        case .allFours: return "All Fours"
        case .armBalance: return "Arm Balance"
        }
    }
}

enum PoseDifficulty: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        rawValue.capitalized
    }
}
