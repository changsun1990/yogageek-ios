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
    @State private var peakPoseTargetSectionIndex: Int?
    @State private var showingPeakSectionPicker = false
    @State private var autoPlacementMessage: String?

    private let sectionNames = ["Integration", "Sun A", "Sun B", "Core", "Standing and Balance", "Hip and Spine", "Surrender"]

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
            .background(Color.yogaSurface)
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
                PosePickerView(
                    poses: poses,
                    onSelect: { pose in
                        addPoseWithAutoPlacement(pose)
                    },
                    allowMultiSelect: true,
                    onSelectMultiple: { selectedPoses in
                        for pose in selectedPoses {
                            addPoseWithAutoPlacement(pose)
                        }
                    }
                )
            }
            .sheet(item: $selectedPoseForDetail) { pose in
                PoseDetailSheet(pose: pose) {
                    addPoseWithAutoPlacement(pose)
                    selectedPoseForDetail = nil
                }
            }
            .sheet(isPresented: $showingPeakSectionPicker) {
                peakSectionPickerView
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
                    .fill(step.rawValue <= currentStep.rawValue ? Color.yogaPrimary : Color(.systemGray4))
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
                .font(.yogaHeadline())
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
                    .font(.yogaHeadline())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(startingPointChoice != nil ? Color.yogaPrimary : Color(.systemGray4))
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
                .font(.yogaHeadline())
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
                .background(Color.yogaCardBackground)

            Divider()

            // Info banner
            if startingPointChoice == .peakPoses,
               let targetIndex = peakPoseTargetSectionIndex,
               currentSectionIndex == targetIndex {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Your peak poses have been added to \(sectionNames[targetIndex]). You can adjust them anytime.")
                        .font(.caption)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
            }

            // Auto-placement toast
            if let message = autoPlacementMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(message)
                        .font(.caption)
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .transition(.opacity)
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
                ForEach(0..<sectionNames.count, id: \.self) { index in
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
                        .background(currentSectionIndex == index ? Color.yogaPrimary.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(currentSectionIndex == index ? Color.yogaPrimary : .primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.yogaCardBackground)
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
                            ForEach(Array(section.poses.enumerated()), id: \.element.id) { index, poseEntry in
                                if let pose = poses.first(where: { $0.id == poseEntry.poseId }) {
                                    PoseRowInSection(
                                        pose: pose,
                                        onTap: {
                                            selectedPoseForDetail = pose
                                        },
                                        onDelete: {
                                            removePoseFromSection(poseEntry.id)
                                        },
                                        onMoveUp: index > 0 ? {
                                            withAnimation {
                                                sequence.sections[currentSectionIndex].poses.swapAt(index, index - 1)
                                            }
                                        } : nil,
                                        onMoveDown: index < section.poses.count - 1 ? {
                                            withAnimation {
                                                sequence.sections[currentSectionIndex].poses.swapAt(index, index + 1)
                                            }
                                        } : nil
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
                                addPoseWithAutoPlacement(pose)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color.yogaCardBackground)
    }

    private func categoriesForSection(_ index: Int) -> [PoseCategory] {
        switch index {
        case 0: return [.seated, .restorative, .prone]          // Integration
        case 1: return [.standing, .forwardBend]                // Sun A
        case 2: return [.standing, .backbend]                   // Sun B
        case 3: return [.core, .prone]                          // Core
        case 4: return [.standing, .balance, .armBalance]       // Standing and Balance
        case 5: return [.hipOpener, .twist, .inversion, .bind]  // Hip and Spine
        case 6: return [.restorative, .seated, .forwardBend]    // Surrender
        default: return PoseCategory.allCases
        }
    }

    private func generateRecommendedPoses() -> [Pose] {
        let sectionCategories = categoriesForSection(currentSectionIndex)
        let categoryStrings = sectionCategories.map { $0.rawValue }

        var sectionPoses: [Pose]
        if let category = selectedCategory {
            sectionPoses = poses.filter { pose in
                pose.categories.contains(category.rawValue) ||
                pose.categories.contains(where: { categoryStrings.contains($0) })
            }
        } else {
            sectionPoses = poses.filter { pose in
                pose.categories.contains(where: { categoryStrings.contains($0) })
            }
        }

        if sectionPoses.count < 6 {
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
                    .font(.yogaHeadline())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if currentSectionIndex < sectionNames.count - 1 {
                Button {
                    withAnimation {
                        currentSectionIndex += 1
                    }
                } label: {
                    HStack {
                        Text("Next Section")
                        Image(systemName: "chevron.right")
                    }
                    .font(.yogaHeadline())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yogaPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color.yogaCardBackground)
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
                .font(.yogaHeadline())
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
                    .font(.yogaHeadline())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canProceed ? Color.yogaPrimary : Color(.systemGray4))
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
                if startingPointChoice == .peakPoses && peakPoseTargetSectionIndex == nil {
                    showingPeakSectionPicker = true
                    return
                }
                initializeSections()
            }
            currentStep = nextStep
        }
    }

    private func initializeSections() {
        var sections: [YogaSection] = sectionNames.map { YogaSection(name: $0) }

        // If peak poses were selected, add them to the chosen section
        if startingPointChoice == .peakPoses, let targetIndex = peakPoseTargetSectionIndex {
            let peakPoseEntries = selectedPoses.map { PoseEntry(poseId: $0) }
            sections[targetIndex].poses = peakPoseEntries
        }

        sequence = YogaSequence(sections: sections, group: groupName)
        updateRecommendedPoses()
    }

    private func addPoseToCurrentSection(_ pose: Pose) {
        guard currentSectionIndex < sequence.sections.count else { return }
        let poseEntry = PoseEntry(poseId: pose.id)
        withAnimation {
            sequence.sections[currentSectionIndex].poses.append(poseEntry)
        }
    }

    private func addPoseWithAutoPlacement(_ pose: Pose) {
        guard startingPointChoice == .category else {
            addPoseToCurrentSection(pose)
            return
        }

        if let autoIndex = bestSectionIndex(for: pose), autoIndex < sequence.sections.count {
            let poseEntry = PoseEntry(poseId: pose.id)
            withAnimation {
                sequence.sections[autoIndex].poses.append(poseEntry)
            }
            if autoIndex != currentSectionIndex {
                autoPlacementMessage = "Added to \(sectionNames[autoIndex])"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { autoPlacementMessage = nil }
                }
            }
        } else {
            addPoseToCurrentSection(pose)
        }
    }

    private func bestSectionIndex(for pose: Pose) -> Int? {
        let categoryToSection: [String: Int] = [
            PoseCategory.seated.rawValue: 0,
            PoseCategory.restorative.rawValue: 6,
            PoseCategory.standing.rawValue: 4,
            PoseCategory.balance.rawValue: 4,
            PoseCategory.core.rawValue: 3,
            PoseCategory.prone.rawValue: 3,
            PoseCategory.hipOpener.rawValue: 5,
            PoseCategory.twist.rawValue: 5,
            PoseCategory.backbend.rawValue: 2,
            PoseCategory.forwardBend.rawValue: 1,
            PoseCategory.chest.rawValue: 2,
            PoseCategory.armBalance.rawValue: 4,
            PoseCategory.inversion.rawValue: 5,
            PoseCategory.bind.rawValue: 5,
        ]

        if let category = selectedCategory, pose.categories.contains(category.rawValue) {
            return categoryToSection[category.rawValue]
        }

        for cat in pose.categories {
            if let sectionIdx = categoryToSection[cat] {
                return sectionIdx
            }
        }

        return nil
    }

    private var peakSectionPickerView: some View {
        NavigationStack {
            List {
                ForEach(Array(sectionNames.enumerated()), id: \.offset) { index, name in
                    Button {
                        peakPoseTargetSectionIndex = index
                        showingPeakSectionPicker = false
                        initializeSections()
                        currentStep = .buildSections
                    } label: {
                        HStack {
                            Text(name)
                                .font(.subheadline)
                            Spacer()
                            if peakPoseTargetSectionIndex == index {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.yogaPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Place Peak Poses In")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private func removePoseFromSection(_ poseEntryId: String) {
        guard currentSectionIndex < sequence.sections.count else { return }
        withAnimation {
            sequence.sections[currentSectionIndex].poses.removeAll { $0.id == poseEntryId }
        }
    }

    private func saveSequence() {
        sequence.name = sequenceName
        if let duration = selectedDuration {
            sequence.targetDuration = duration.rawValue * 60
        }
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
                    .foregroundStyle(isSelected ? Color.yogaPrimary : .secondary)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.yogaPrimary.opacity(0.1) : Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.yogaHeadline())
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.yogaPrimary)
                }
            }
            .padding()
            .background(Color.yogaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.yogaPrimary : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
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
                    .font(.yogaHeadline())

                Text("\(poseCount) poses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.yogaPrimary.opacity(0.1) : Color.yogaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yogaPrimary : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
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
                PoseImageView(imageURL: pose.imageURL, size: 44, cornerRadius: 8)

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
                    .foregroundStyle(isSelected ? Color.yogaPrimary : .secondary)
            }
            .padding()
            .background(Color.yogaCardBackground)
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
                    .font(.yogaHeadline())

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.yogaPrimary)
                }
            }
            .padding()
            .background(isSelected ? Color.yogaPrimary.opacity(0.1) : Color.yogaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yogaPrimary : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PoseRowInSection: View {
    let pose: Pose
    let onTap: () -> Void
    let onDelete: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            // Move up/down buttons
            VStack(spacing: 4) {
                Button {
                    onMoveUp?()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundStyle(onMoveUp != nil ? Color.yogaPrimary : Color(.systemGray4))
                }
                .disabled(onMoveUp == nil)

                Button {
                    onMoveDown?()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(onMoveDown != nil ? Color.yogaPrimary : Color(.systemGray4))
                }
                .disabled(onMoveDown == nil)
            }
            .buttonStyle(.plain)

            // Tappable area for details
            Button(action: onTap) {
                HStack(spacing: 12) {
                    PoseImageView(imageURL: pose.imageURL, size: 40, cornerRadius: 8)

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
        .background(Color.yogaCardBackground)
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
                    PoseImageView(imageURL: pose.imageURL, size: 60, cornerRadius: 12)

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
                    .foregroundStyle(Color.yogaPrimary)
            }
        }
        .frame(width: 100)
        .padding()
        .background(Color.yogaCardBackground)
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
