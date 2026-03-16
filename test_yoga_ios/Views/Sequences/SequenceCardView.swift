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

            HStack(spacing: 0) {
                Label("\(sequence.sections.count)", systemImage: "rectangle.stack")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Label("\(sequence.totalPoseCount)", systemImage: "figure.yoga")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Label(formattedDuration, systemImage: "clock")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Label(
                    MusicManager.shared.activeService != .none ? "on" : "off",
                    systemImage: MusicManager.shared.activeService != .none ? "music.note.list" : "music.note"
                )
                .foregroundStyle(MusicManager.shared.activeService != .none ? Color.yogaPrimary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
