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
    let benefit: String
    let sampleCues: [String]
    let mechanics: PoseMechanics
    let muscleGroup: String
    let variations: [String]
    let imageURL: String
    let categories: [String]
    let difficulty: PoseDifficulty

    var categoriesDisplayName: String {
        categories.joined(separator: ", ")
    }
}

struct PoseMechanics: Codable, Hashable {
    let alignmentPrinciple: String
    let commonCorrection: String
    let keyEngagement: String

    static let empty = PoseMechanics(alignmentPrinciple: "", commonCorrection: "", keyEngagement: "")

    var isEmpty: Bool {
        alignmentPrinciple.isEmpty && commonCorrection.isEmpty && keyEngagement.isEmpty
    }
}

enum PoseCategory: String, CaseIterable {
    case armBalance = "Arm Balance"
    case twist = "Twist"
    case backbend = "Backbend"
    case forwardBend = "Forward Bend"
    case balance = "Balance"
    case hipOpener = "Hip Opener"
    case chest = "Chest"
    case core = "Core"
    case seated = "Seated"
    case inversion = "Inversion"
    case prone = "Prone"
    case bind = "Bind"
    case standing = "Standing"
    case restorative = "Restorative"

    var displayName: String {
        rawValue
    }
}

enum PoseDifficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var displayName: String {
        rawValue
    }
}
