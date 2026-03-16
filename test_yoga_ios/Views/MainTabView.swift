//
//  MainTabView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI
import FirebaseAuth

enum AppTab: String, CaseIterable {
    case home = "Home"
    case explore = "Explore"
    case mySequences = "My Sequences"
    case community = "Community"
    case profile = "Profile"
}

struct MainTabView: View {
    var authViewModel: AuthViewModel?
    @State private var poseViewModel = PoseViewModel()
    @State private var sequenceViewModel = SequenceViewModel()
    @State private var communityViewModel = CommunityViewModel()
    @State private var userProfile = UserProfile()
    @State private var selectedTab: AppTab = .home
    @State private var hasStartedListeners = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(
                    authViewModel: authViewModel,
                    sequenceViewModel: sequenceViewModel,
                    poseViewModel: poseViewModel,
                    communityViewModel: communityViewModel,
                    userProfile: userProfile,
                    selectedTab: $selectedTab
                )
            }

            Tab("Explore", systemImage: "square.grid.2x2", value: .explore) {
                ExploreView(poseViewModel: poseViewModel, sequenceViewModel: sequenceViewModel)
            }

            Tab("My Sequences", systemImage: "list.bullet.rectangle", value: .mySequences) {
                SequenceListView(viewModel: sequenceViewModel, poses: poseViewModel.poses, communityViewModel: communityViewModel)
            }

            Tab("Community", systemImage: "person.3", value: .community) {
                CommunityView(
                    sequenceViewModel: sequenceViewModel,
                    communityViewModel: communityViewModel,
                    poses: poseViewModel.poses,
                    userProfile: userProfile
                )
            }

            Tab("Profile", systemImage: "person.circle", value: .profile) {
                ProfileView(
                    userProfile: userProfile,
                    communityViewModel: communityViewModel,
                    sequenceViewModel: sequenceViewModel,
                    authViewModel: authViewModel,
                    onNavigateToSequences: {
                        selectedTab = .mySequences
                    }
                )
            }
        }
        .task {
            await setupListeners()
        }
    }

    private func setupListeners() async {
        guard !hasStartedListeners,
              let user = authViewModel?.currentUser else { return }
        hasStartedListeners = true

        let userId = user.uid
        let displayName = user.displayName ?? "Yoga Practitioner"

        // Run migration if needed
        do {
            try await MigrationService.shared.migrateIfNeeded(userId: userId)
        } catch {
            print("[MainTabView] Migration failed: \(error)")
        }

        // Start all listeners
        sequenceViewModel.startListening(userId: userId)
        communityViewModel.startListening(userId: userId, userName: displayName)

        UserService.shared.startListening(userId: userId) { profile in
            Task { @MainActor in
                if let profile {
                    userProfile.update(from: profile)
                } else {
                    // First sign-in: save initial profile
                    let newProfile = UserProfile()
                    newProfile.id = userId
                    newProfile.displayName = displayName
                    do {
                        try await UserService.shared.saveProfile(newProfile, userId: userId)
                    } catch {
                        print("[MainTabView] Save initial profile failed: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
