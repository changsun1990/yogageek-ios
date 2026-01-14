//
//  MainTabView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var poseViewModel = PoseViewModel()
    @State private var sequenceViewModel = SequenceViewModel()

    var body: some View {
        TabView {
            Tab("Explore", systemImage: "square.grid.2x2") {
                ExploreView(poseViewModel: poseViewModel, sequenceViewModel: sequenceViewModel)
            }

            Tab("Sequences", systemImage: "list.bullet.rectangle") {
                SequenceListView(viewModel: sequenceViewModel, poses: poseViewModel.poses)
            }
        }
    }
}

#Preview {
    MainTabView()
}
