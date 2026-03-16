//
//  DurationEditorView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/21/26.
//

import SwiftUI

struct DurationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sequence: YogaSequence

    private let sequenceDurationOptions: [Int] = [0, 300, 600, 900, 1200, 1800, 2700, 3600]

    var body: some View {
        NavigationStack {
            List {
                // Total duration (read-only)
                Section {
                    HStack {
                        Label("Total Duration", systemImage: "clock.fill")
                        Spacer()
                        Text(formatDuration(sequence.totalDuration))
                            .font(.yogaHeadline())
                            .foregroundStyle(Color.yogaPrimary)
                    }
                }

                // Sequence-level target
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        DurationMinuteInput(seconds: $sequence.targetDuration)
                    }
                } header: {
                    Text("Sequence Duration")
                } footer: {
                    Text("Set a target duration for the whole sequence. This is used when no section or pose durations are set.")
                }

                // Per-section durations
                Section {
                    ForEach(Array(sequence.sections.enumerated()), id: \.element.id) { index, section in
                        SectionDurationRow(
                            section: Binding(
                                get: { sequence.sections[index] },
                                set: { sequence.sections[index] = $0 }
                            )
                        )
                    }
                } header: {
                    Text("Sections")
                } footer: {
                    Text("Toggle custom duration per section. When off, duration is calculated from individual pose durations.")
                }
            }
            .navigationTitle("Duration Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        if totalSeconds == 0 { return "0 min" }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 && seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes) min"
        }
        return "\(seconds)s"
    }
}

// MARK: - Section Duration Row

private struct SectionDurationRow: View {
    @Binding var section: YogaSection

    private var hasCustomDuration: Bool {
        section.sectionDuration != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section name and effective duration
            HStack {
                Text(section.name)
                    .fontWeight(.medium)
                Spacer()
                Text(formatDuration(section.effectiveDuration))
                    .font(.subheadline)
                    .foregroundStyle(hasCustomDuration ? Color.yogaPrimary : .secondary)
            }

            // Toggle for custom duration
            Toggle("Custom duration", isOn: Binding(
                get: { hasCustomDuration },
                set: { enabled in
                    if enabled {
                        // Default to sum of poses or 5 minutes
                        let poseTotal = section.poseDuration
                        section.sectionDuration = poseTotal > 0 ? poseTotal : 300
                    } else {
                        section.sectionDuration = nil
                    }
                }
            ))
            .font(.subheadline)

            if hasCustomDuration {
                // Duration input
                HStack {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DurationMinuteInput(seconds: Binding(
                        get: { section.sectionDuration ?? 0 },
                        set: { section.sectionDuration = $0 }
                    ))
                }

                if section.poseDuration > 0 {
                    Text("Pose durations total: \(formatDuration(section.poseDuration))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else if section.poseDuration > 0 {
                Text("From \(section.poses.count) poses")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("No durations set")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        if totalSeconds == 0 { return "0s" }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 && seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes) min"
        }
        return "\(seconds)s"
    }
}

// MARK: - Duration Minute Input

private struct DurationMinuteInput: View {
    @Binding var seconds: Int
    @State private var minutesText = ""

    var body: some View {
        HStack(spacing: 8) {
            Button {
                seconds = max(0, seconds - 60)
                minutesText = "\(seconds / 60)"
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(seconds <= 0)

            TextField("0", text: $minutesText)
                .font(.subheadline)
                .fontWeight(.medium)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 44)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: minutesText) { _, newValue in
                    if let minutes = Int(newValue) {
                        seconds = min(7200, minutes * 60)
                    } else if newValue.isEmpty {
                        seconds = 0
                    }
                }

            Text("min")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                seconds = min(7200, seconds + 60)
                minutesText = "\(seconds / 60)"
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.yogaPrimary)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            minutesText = seconds > 0 ? "\(seconds / 60)" : "0"
        }
    }
}

#Preview {
    DurationEditorView(
        sequence: .constant(YogaSequence(
            name: "Morning Flow",
            sections: [
                YogaSection(name: "Warm Up", poses: [
                    PoseEntry(poseId: "mountain", duration: 30),
                    PoseEntry(poseId: "cat-cow", duration: 45)
                ]),
                YogaSection(name: "Standing", poses: [
                    PoseEntry(poseId: "warrior-1"),
                    PoseEntry(poseId: "warrior-2")
                ], sectionDuration: 600),
                YogaSection(name: "Cool Down")
            ]
        ))
    )
}
