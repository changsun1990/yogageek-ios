//
//  Sequence.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import Foundation

struct YogaSequence: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String
    var sections: [YogaSection]
    var group: String
    let createdAt: Date
    var updatedAt: Date
    var targetDuration: Int // seconds, user-settable sequence-level duration (default 0)
    var isTemplate: Bool

    var totalDuration: Int {
        let computed = sections.reduce(0) { $0 + $1.effectiveDuration }
        return computed > 0 ? computed : targetDuration
    }

    var totalPoseCount: Int {
        sections.reduce(0) { $0 + $1.poses.count }
    }

    init(id: String = UUID().uuidString, name: String = "", description: String = "", sections: [YogaSection] = [], group: String = "My Sequences", createdAt: Date = Date(), updatedAt: Date = Date(), targetDuration: Int = 0, isTemplate: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.sections = sections
        self.group = group
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.targetDuration = targetDuration
        self.isTemplate = isTemplate
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, sections, group, createdAt, updatedAt, targetDuration, isTemplate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        sections = try container.decode([YogaSection].self, forKey: .sections)
        group = try container.decode(String.self, forKey: .group)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        targetDuration = try container.decodeIfPresent(Int.self, forKey: .targetDuration) ?? 0
        isTemplate = try container.decodeIfPresent(Bool.self, forKey: .isTemplate) ?? false
    }
}

struct YogaSection: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var poses: [PoseEntry]
    var sectionDuration: Int? // seconds, optional override for the whole section

    /// Sum of individual pose durations (ignoring section override)
    var poseDuration: Int {
        poses.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    /// Effective duration: section override if set, otherwise sum of pose durations
    var effectiveDuration: Int {
        if let sectionDuration { return sectionDuration }
        return poseDuration
    }

    init(id: String = UUID().uuidString, name: String = "New Section", poses: [PoseEntry] = [], sectionDuration: Int? = nil) {
        self.id = id
        self.name = name
        self.poses = poses
        self.sectionDuration = sectionDuration
    }

    enum CodingKeys: String, CodingKey {
        case id, name, poses, sectionDuration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        poses = try container.decode([PoseEntry].self, forKey: .poses)
        sectionDuration = try container.decodeIfPresent(Int.self, forKey: .sectionDuration)
    }
}

struct PoseEntry: Identifiable, Codable, Hashable {
    let id: String
    let poseId: String
    var customCues: [String]
    var notes: String
    var duration: Int? // seconds, nil means no specific duration
    var customName: String? // for user-created poses not in the library
    var breath: String // breathing instruction (e.g. "Inhale arms up, exhale fold")

    init(id: String = UUID().uuidString, poseId: String, customCues: [String] = [], notes: String = "", duration: Int? = nil, customName: String? = nil, breath: String = "") {
        self.id = id
        self.poseId = poseId
        self.customCues = customCues
        self.notes = notes
        self.duration = duration
        self.customName = customName
        self.breath = breath
    }
}
