//
//  GuidedSequenceBuilderView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/28/26.
//

import SwiftUI

enum GuidedBuilderStep: Int, CaseIterable {
    case chooseStartingPoint
    case selectPoses
    case selectDuration
    case buildSections
}

enum StartingPointChoice: String, CaseIterable {
    case category = "Category"
    case peakPoses = "Peak Poses"
}

enum ClassDuration: Int, CaseIterable {
    case fifteen = 15
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case seventyFive = 75

    var displayName: String {
        "\(rawValue) min"
    }
}

struct GuidedSequenceBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SequenceViewModel
    let poses: [Pose]
    var groupName: String = "My Sequences"
    var onSave: (() -> Void)?

    @State private var currentStep: GuidedBuilderStep = .chooseStartingPoint
    @State private var startingPointChoice: StartingPointChoice?
    @State private var selectedCategory: PoseCategory?
    @State private var selectedPoses: Set<String> = []
    @State private var selectedDuration: ClassDuration?
    @State private var sequence: YogaSequence
    @State private var currentSectionIndex: Int = 0
    @State private var showingPosePicker = false
    @State private var sequenceName: String = ""
    @State private var selectedPoseForDetail: Pose?
    @State private var cachedRecommendedPoses: [Pose] = []

    private let sectionNames = ["Beginning", "Flow 1", "Flow 2", "Ending"]

    init(viewModel: SequenceViewModel, poses: [Pose], groupName: String = "My Sequences", onSave: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.poses = poses
        self.groupName = groupName
        self.onSave = onSave
        _sequence = State(initialValue: YogaSequence(group: groupName))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator

                // Content based on current step
                Group {
                    switch currentStep {
                    case .chooseStartingPoint:
                        startingPointView
                    case .selectPoses:
                        selectPosesView
                    case .selectDuration:
                        selectDurationView
                    case .buildSections:
                        buildSectionsView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if currentStep == .buildSections {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveSequence()
                        }
                        .fontWeight(.semibold)
                        .disabled(sequenceName.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showingPosePicker) {
                PosePickerView(poses: poses) { pose in
                    addPoseToCurrentSection(pose)
                }
            }
            .sheet(item: $selectedPoseForDetail) { pose in
                PoseDetailSheet(pose: pose) {
                    addPoseToCurrentSection(pose)
                    selectedPoseForDetail = nil
                }
            }
            .onChange(of: currentSectionIndex) { _, _ in
                updateRecommendedPoses()
            }
        }
    }

    private var navigationTitle: String {
        switch currentStep {
        case .chooseStartingPoint:
            return "Start With"
        case .selectPoses:
            return startingPointChoice == .peakPoses ? "Select Peak Poses" : "Select Category"
        case .selectDuration:
            return "Class Duration"
        case .buildSections:
            return "Build Sections"
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(GuidedBuilderStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color(.systemGray4))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Step 1: Choose Starting Point

    private var startingPointView: some View {
        VStack(spacing: 24) {
            Text("How would you like to begin building your sequence?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 20)

            VStack(spacing: 16) {
                StartingPointButton(
                    icon: "figure.yoga",
                    title: "By Category",
                    description: "Choose poses from a specific category like Standing, Seated, or Balance",
                    isSelected: startingPointChoice == .category
                ) {
                    startingPointChoice = .category
                }

                StartingPointButton(
                    icon: "star.fill",
                    title: "By Peak Poses",
                    description: "Start with advanced poses and build your sequence around them",
                    isSelected: startingPointChoice == .peakPoses
                ) {
                    startingPointChoice = .peakPoses
                }
            }
            .padding(.horizontal)

            Spacer()

            Button {
                withAnimation {
                    currentStep = .selectPoses
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(startingPointChoice != nil ? Color.accentColor : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(startingPointChoice == nil)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Step 2: Select Poses

    private var selectPosesView: some View {
        VStack(spacing: 0) {
            if startingPointChoice == .category {
                categorySelectionView
            } else {
                peakPosesSelectionView
            }
        }
    }

    private var categorySelectionView: some View {
        VStack(spacing: 16) {
            Text("Select a category to focus on")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(PoseCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            poseCount: poses.filter { $0.categories.contains(category.rawValue) }.count
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }

            navigationButtons
        }
    }

    private var peakPosesSelectionView: some View {
        VStack(spacing: 16) {
            Text("Select one or more advanced poses for your peak")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(advancedPoses) { pose in
                        PoseSelectionRow(
                            pose: pose,
                            isSelected: selectedPoses.contains(pose.id)
                        ) {
                            togglePoseSelection(pose.id)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if !selectedPoses.isEmpty {
                Text("\(selectedPoses.count) pose\(selectedPoses.count > 1 ? "s" : "") selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            navigationButtons
        }
    }

    private var advancedPoses: [Pose] {
        poses.filter { $0.difficulty == .advanced }
    }

    private func togglePoseSelection(_ poseId: String) {
        if selectedPoses.contains(poseId) {
            selectedPoses.remove(poseId)
        } else {
            selectedPoses.insert(poseId)
        }
    }

    // MARK: - Step 3: Select Duration

    private var selectDurationView: some View {
        VStack(spacing: 24) {
            Text("How long will your class be?")
                .font(.headline)
                .padding(.top, 20)

            VStack(spacing: 12) {
                ForEach(ClassDuration.allCases, id: \.self) { duration in
                    DurationButton(
                        duration: duration,
                        isSelected: selectedDuration == duration
                    ) {
                        selectedDuration = duration
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            navigationButtons
        }
    }

    // MARK: - Step 4: Build Sections

    private var buildSectionsView: some View {
        VStack(spacing: 0) {
            // Sequence name input
            TextField("Sequence Name", text: $sequenceName)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
                .background(Color(.systemBackground))

            Divider()

            // Info banner
            if currentSectionIndex == 2 && startingPointChoice == .peakPoses {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Your peak poses have been added to Flow 2. You can adjust them anytime.")
                        .font(.caption)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
            }

            // Section tabs
            sectionTabs

            // Current section content
            currentSectionContent

            Spacer()

            // Bottom navigation
            sectionNavigationButtons
        }
    }

    private var sectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Button {
                        currentSectionIndex = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(sectionNames[index])
                                .font(.subheadline)
                                .fontWeight(currentSectionIndex == index ? .semibold : .regular)

                            Text("\(sequence.sections[safe: index]?.poses.count ?? 0) poses")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(currentSectionIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(currentSectionIndex == index ? Color.accentColor : .primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var currentSectionContent: some View {
        VStack(spacing: 16) {
            if let section = sequence.sections[safe: currentSectionIndex] {
                if section.poses.isEmpty {
                    ContentUnavailableView(
                        "No Poses Yet",
                        systemImage: "figure.yoga",
                        description: Text("Add poses to \(sectionNames[currentSectionIndex])")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(section.poses) { poseEntry in
                                if let pose = poses.first(where: { $0.id == poseEntry.poseId }) {
                                    PoseRowInSection(
                                        pose: pose,
                                        onTap: {
                                            selectedPoseForDetail = pose
                                        },
                                        onDelete: {
                                            removePoseFromSection(poseEntry.id)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Recommended poses
            recommendedPosesSection
        }
        .padding(.top)
    }

    private var recommendedPosesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggested Poses")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Browse All") {
                    showingPosePicker = true
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cachedRecommendedPoses.prefix(6)) { pose in
                        RecommendedPoseCard(
                            pose: pose,
                            onTap: {
                                selectedPoseForDetail = pose
                            },
                            onAdd: {
                                addPoseToCurrentSection(pose)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }

    private func generateRecommendedPoses() -> [Pose] {
        // Return random poses based on section
        let sectionPoses: [Pose]

        switch currentSectionIndex {
        case 0: // Beginning - easy poses
            sectionPoses = poses.filter { $0.difficulty == .beginner }
        case 1, 2: // Flow sections - mix based on selected category or all
            if let category = selectedCategory {
                sectionPoses = poses.filter { $0.categories.contains(category.rawValue) }
            } else {
                sectionPoses = poses.filter { $0.difficulty != .advanced }
            }
        case 3: // Ending - restorative/seated poses
            sectionPoses = poses.filter {
                $0.categories.contains(PoseCategory.restorative.rawValue) ||
                $0.categories.contains(PoseCategory.seated.rawValue)
            }
        default:
            sectionPoses = poses
        }

        return Array(sectionPoses.shuffled().prefix(10))
    }

    private func updateRecommendedPoses() {
        cachedRecommendedPoses = generateRecommendedPoses()
    }

    private var sectionNavigationButtons: some View {
        HStack(spacing: 16) {
            if currentSectionIndex > 0 {
                Button {
                    withAnimation {
                        currentSectionIndex -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if currentSectionIndex < 3 {
                Button {
                    withAnimation {
                        currentSectionIndex += 1
                    }
                } label: {
                    HStack {
                        Text("Next Section")
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation {
                    goToPreviousStep()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                withAnimation {
                    goToNextStep()
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canProceed ? Color.accentColor : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canProceed)
        }
        .padding()
    }

    private var canProceed: Bool {
        switch currentStep {
        case .chooseStartingPoint:
            return startingPointChoice != nil
        case .selectPoses:
            if startingPointChoice == .category {
                return selectedCategory != nil
            } else {
                return !selectedPoses.isEmpty
            }
        case .selectDuration:
            return selectedDuration != nil
        case .buildSections:
            return true
        }
    }

    private func goToPreviousStep() {
        if let previousStep = GuidedBuilderStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previousStep
        }
    }

    private func goToNextStep() {
        if let nextStep = GuidedBuilderStep(rawValue: currentStep.rawValue + 1) {
            if nextStep == .buildSections {
                initializeSections()
            }
            currentStep = nextStep
        }
    }

    private func initializeSections() {
        // Create 4 sections
        var sections: [YogaSection] = sectionNames.map { YogaSection(name: $0) }

        // If peak poses were selected, add them to Flow 2 (index 2)
        if startingPointChoice == .peakPoses {
            let peakPoseEntries = selectedPoses.map { PoseEntry(poseId: $0) }
            sections[2].poses = peakPoseEntries
        }

        sequence = YogaSequence(sections: sections)

        // Initialize recommended poses for the first section
        updateRecommendedPoses()
    }

    private func addPoseToCurrentSection(_ pose: Pose) {
        guard currentSectionIndex < sequence.sections.count else { return }
        let poseEntry = PoseEntry(poseId: pose.id)
        withAnimation {
            sequence.sections[currentSectionIndex].poses.append(poseEntry)
        }
    }

    private func removePoseFromSection(_ poseEntryId: String) {
        guard currentSectionIndex < sequence.sections.count else { return }
        withAnimation {
            sequence.sections[currentSectionIndex].poses.removeAll { $0.id == poseEntryId }
        }
    }

    private func saveSequence() {
        sequence.name = sequenceName
        viewModel.addSequence(sequence)
        onSave?()
        dismiss()
    }
}

// MARK: - Helper Views

struct StartingPointButton: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryButton: View {
    let category: PoseCategory
    let isSelected: Bool
    let poseCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(category.displayName)
                    .font(.headline)

                Text("\(poseCount) poses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PoseSelectionRow: View {
    let pose: Pose
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: pose.imageURL)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(pose.nameEnglish)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(pose.nameSanskrit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct DurationButton: View {
    let duration: ClassDuration
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(duration.displayName)
                    .font(.headline)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PoseRowInSection: View {
    let pose: Pose
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Tappable area for details
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: pose.imageURL)
                        .font(.title3)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pose.nameEnglish)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(pose.categoriesDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RecommendedPoseCard: View {
    let pose: Pose
    let onTap: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Tappable area for details
            Button(action: onTap) {
                VStack(spacing: 8) {
                    Image(systemName: pose.imageURL)
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(pose.nameEnglish)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .buttonStyle(.plain)

            // Add button
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    GuidedSequenceBuilderView(viewModel: SequenceViewModel(), poses: MockPoseData.poses)
}
