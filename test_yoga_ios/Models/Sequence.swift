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

    var totalDuration: Int {
        sections.reduce(0) { $0 + $1.duration }
    }

    var totalPoseCount: Int {
        sections.reduce(0) { $0 + $1.poses.count }
    }

    init(id: String = UUID().uuidString, name: String = "", description: String = "", sections: [YogaSection] = [], group: String = "My Sequences", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.sections = sections
        self.group = group
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct YogaSection: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var poses: [PoseEntry]

    var duration: Int {
        poses.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    init(id: String = UUID().uuidString, name: String = "New Section", poses: [PoseEntry] = []) {
        self.id = id
        self.name = name
        self.poses = poses
    }
}

struct PoseEntry: Identifiable, Codable, Hashable {
    let id: String
    let poseId: String
    var customCues: [String]
    var notes: String
    var duration: Int? // seconds, nil means no specific duration

    init(id: String = UUID().uuidString, poseId: String, customCues: [String] = [], notes: String = "", duration: Int? = nil) {
        self.id = id
        self.poseId = poseId
        self.customCues = customCues
        self.notes = notes
        self.duration = duration
    }
}
