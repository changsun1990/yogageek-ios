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
            VStack(spacing: 0) {
                // Filter chips below search
                filterChipsRow

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
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                poseViewModel.refresh()
            }
            .navigationTitle("Explore")
            .searchable(text: $poseViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search poses")
            .navigationDestination(for: Pose.self) { pose in
                PoseDetailView(pose: pose, poses: poseViewModel.poses, sequenceViewModel: sequenceViewModel)
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

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category Filter
                Menu {
                    Button {
                        poseViewModel.selectedCategory = nil
                    } label: {
                        HStack {
                            Text("All")
                            if poseViewModel.selectedCategory == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

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
                } label: {
                    FilterChip(
                        title: poseViewModel.selectedCategory?.displayName ?? "Category",
                        isActive: poseViewModel.selectedCategory != nil
                    )
                }

                // Difficulty Filter
                Menu {
                    Button {
                        poseViewModel.selectedDifficulty = nil
                    } label: {
                        HStack {
                            Text("All")
                            if poseViewModel.selectedDifficulty == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

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
                } label: {
                    FilterChip(
                        title: poseViewModel.selectedDifficulty?.displayName ?? "Difficulty",
                        isActive: poseViewModel.selectedDifficulty != nil
                    )
                }

                // Clear filters button
                if poseViewModel.selectedCategory != nil || poseViewModel.selectedDifficulty != nil {
                    Button {
                        poseViewModel.clearFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
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

struct FilterChip: View {
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor : Color(.systemGray5))
        .foregroundStyle(isActive ? .white : .primary)
        .clipShape(Capsule())
    }
}

#Preview {
    ExploreView(poseViewModel: PoseViewModel(), sequenceViewModel: SequenceViewModel())
}
