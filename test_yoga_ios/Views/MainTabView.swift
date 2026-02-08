//
//  MainTabView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

enum AppTab: String, CaseIterable {
    case explore = "Explore"
    case mySequences = "My Sequences"
    case community = "Community"
    case profile = "Profile"
}

struct MainTabView: View {
    @State private var poseViewModel = PoseViewModel()
    @State private var sequenceViewModel = SequenceViewModel()
    @State private var userProfile = UserProfile.mock
    @State private var selectedTab: AppTab = .explore

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "square.grid.2x2", value: .explore) {
                ExploreView(poseViewModel: poseViewModel, sequenceViewModel: sequenceViewModel)
            }

            Tab("My Sequences", systemImage: "list.bullet.rectangle", value: .mySequences) {
                SequenceListView(viewModel: sequenceViewModel, poses: poseViewModel.poses)
            }

            Tab("Community", systemImage: "person.3", value: .community) {
                CommunityView(sequenceViewModel: sequenceViewModel, poses: poseViewModel.poses, userProfile: userProfile)
            }

            Tab("Profile", systemImage: "person.circle", value: .profile) {
                ProfileView(userProfile: userProfile, sequenceViewModel: sequenceViewModel, onNavigateToSequences: {
                    selectedTab = .mySequences
                })
            }
        }
    }
}

#Preview {
    MainTabView()
}
