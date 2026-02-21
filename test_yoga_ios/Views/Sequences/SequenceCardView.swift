//
//  SequenceCardView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct SequenceCardView: View {
    let sequence: YogaSequence

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sequence.name.isEmpty ? "Untitled Sequence" : sequence.name)
                .font(.yogaHeadline())
                .lineLimit(1)

            if !sequence.description.isEmpty {
                Text(sequence.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(sequence.sections.count) sections", systemImage: "rectangle.stack")
                Label("\(sequence.totalPoseCount) poses", systemImage: "figure.yoga")
                Label(formattedDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDuration: String {
        let minutes = sequence.totalDuration / 60
        if minutes < 1 {
            return "\(sequence.totalDuration)s"
        } else {
            return "\(minutes) min"
        }
    }
}

#Preview {
    List {
        SequenceCardView(sequence: YogaSequence(
            name: "Morning Flow",
            description: "A gentle morning sequence to wake up the body",
            sections: [
                YogaSection(name: "Warm Up", poses: [
                    PoseEntry(poseId: "mountain"),
                    PoseEntry(poseId: "cat-cow")
                ]),
                YogaSection(name: "Standing", poses: [
                    PoseEntry(poseId: "warrior-1"),
                    PoseEntry(poseId: "warrior-2")
                ])
            ]
        ))
    }
}
