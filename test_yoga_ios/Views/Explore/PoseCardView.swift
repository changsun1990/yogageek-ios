//
//  PoseCardView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct PoseCardView: View {
    let pose: Pose

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: pose.imageURL)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .frame(height: 80)

            VStack(spacing: 4) {
                Text(pose.nameEnglish)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(pose.nameSanskrit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Text(pose.difficulty.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundStyle(difficultyColor)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var difficultyColor: Color {
        switch pose.difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        }
    }
}

#Preview {
    PoseCardView(pose: MockPoseData.poses[0])
        .padding()
        .background(Color(.systemGroupedBackground))
}
