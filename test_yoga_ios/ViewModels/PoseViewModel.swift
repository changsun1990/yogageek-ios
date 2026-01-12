//
//  PoseViewModel.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import Foundation
import SwiftUI

@Observable
class PoseViewModel {
    var poses: [Pose] = []
    var searchText: String = ""
    var selectedCategory: PoseCategory?
    var selectedDifficulty: PoseDifficulty?

    var filteredPoses: [Pose] {
        var result = poses

        if !searchText.isEmpty {
            result = result.filter { pose in
                pose.nameEnglish.localizedCaseInsensitiveContains(searchText) ||
                pose.nameSanskrit.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }

        return result
    }

    init() {
        loadPoses()
    }

    func loadPoses() {
        poses = MockPoseData.poses
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDifficulty = nil
    }
}
