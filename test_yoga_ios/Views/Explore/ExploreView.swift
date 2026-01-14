//
//  ExploreView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct ExploreView: View {
    @Bindable var poseViewModel: PoseViewModel
    var sequenceViewModel: SequenceViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if poseViewModel.isLoading && poseViewModel.poses.isEmpty {
                    loadingView
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(poseViewModel.filteredPoses) { pose in
                            NavigationLink(value: pose) {
                                PoseCardView(pose: pose)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                poseViewModel.refresh()
            }
            .navigationTitle("Explore")
            .searchable(text: $poseViewModel.searchText, prompt: "Search poses")
            .navigationDestination(for: Pose.self) { pose in
                PoseDetailView(pose: pose, poses: poseViewModel.poses, sequenceViewModel: sequenceViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Category") {
                            Button("All Categories") {
                                poseViewModel.selectedCategory = nil
                            }
                            ForEach(PoseCategory.allCases, id: \.self) { category in
                                Button {
                                    poseViewModel.selectedCategory = category
                                } label: {
                                    HStack {
                                        Text(category.displayName)
                                        if poseViewModel.selectedCategory == category {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        Section("Difficulty") {
                            Button("All Levels") {
                                poseViewModel.selectedDifficulty = nil
                            }
                            ForEach(PoseDifficulty.allCases, id: \.self) { difficulty in
                                Button {
                                    poseViewModel.selectedDifficulty = difficulty
                                } label: {
                                    HStack {
                                        Text(difficulty.displayName)
                                        if poseViewModel.selectedDifficulty == difficulty {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        if poseViewModel.selectedCategory != nil || poseViewModel.selectedDifficulty != nil {
                            Section {
                                Button("Clear Filters", role: .destructive) {
                                    poseViewModel.clearFilters()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: filterApplied ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .overlay {
                if poseViewModel.filteredPoses.isEmpty && !poseViewModel.isLoading {
                    if !poseViewModel.searchText.isEmpty {
                        ContentUnavailableView.search(text: poseViewModel.searchText)
                    } else if poseViewModel.errorMessage != nil {
                        ContentUnavailableView(
                            "Error Loading Poses",
                            systemImage: "exclamationmark.triangle",
                            description: Text(poseViewModel.errorMessage ?? "Unknown error")
                        )
                    }
                }
            }
        }
    }

    private var filterApplied: Bool {
        poseViewModel.selectedCategory != nil || poseViewModel.selectedDifficulty != nil
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading poses...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#Preview {
    ExploreView(poseViewModel: PoseViewModel(), sequenceViewModel: SequenceViewModel())
}
