//
//  ExploreView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct ExploreView: View {
    @State private var viewModel = PoseViewModel()
    var sequenceViewModel: SequenceViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.filteredPoses) { pose in
                        NavigationLink(value: pose) {
                            PoseCardView(pose: pose)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
            .searchable(text: $viewModel.searchText, prompt: "Search poses")
            .navigationDestination(for: Pose.self) { pose in
                PoseDetailView(pose: pose, sequenceViewModel: sequenceViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Category") {
                            Button("All Categories") {
                                viewModel.selectedCategory = nil
                            }
                            ForEach(PoseCategory.allCases, id: \.self) { category in
                                Button {
                                    viewModel.selectedCategory = category
                                } label: {
                                    HStack {
                                        Text(category.displayName)
                                        if viewModel.selectedCategory == category {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        Section("Difficulty") {
                            Button("All Levels") {
                                viewModel.selectedDifficulty = nil
                            }
                            ForEach(PoseDifficulty.allCases, id: \.self) { difficulty in
                                Button {
                                    viewModel.selectedDifficulty = difficulty
                                } label: {
                                    HStack {
                                        Text(difficulty.displayName)
                                        if viewModel.selectedDifficulty == difficulty {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        if viewModel.selectedCategory != nil || viewModel.selectedDifficulty != nil {
                            Section {
                                Button("Clear Filters", role: .destructive) {
                                    viewModel.clearFilters()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: filterApplied ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .overlay {
                if viewModel.filteredPoses.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
        }
    }

    private var filterApplied: Bool {
        viewModel.selectedCategory != nil || viewModel.selectedDifficulty != nil
    }
}

#Preview {
    ExploreView(sequenceViewModel: SequenceViewModel())
}
