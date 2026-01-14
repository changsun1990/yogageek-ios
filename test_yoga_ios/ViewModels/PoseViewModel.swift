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
    var isLoading: Bool = false
    var errorMessage: String?

    private let poseService = PoseService()

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
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let firestorePoses = try await poseService.fetchPoses()
                await MainActor.run {
                    if firestorePoses.isEmpty {
                        // Fallback to mock data if Firestore is empty
                        self.poses = MockPoseData.poses
                    } else {
                        self.poses = firestorePoses
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to mock data on error
                    self.poses = MockPoseData.poses
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                print("Error fetching poses: \(error)")
            }
        }
    }

    func refresh() {
        loadPoses()
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDifficulty = nil
    }
}
