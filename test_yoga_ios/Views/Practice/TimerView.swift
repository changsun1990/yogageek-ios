//
//  TimerView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI

struct TimerView: View {
    let timeRemaining: Int
    let totalTime: Int
    let isPlaying: Bool

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Time display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(isPlaying ? "remaining" : "paused")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
    }

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)"
    }
}

#Preview {
    VStack(spacing: 40) {
        TimerView(timeRemaining: 25, totalTime: 30, isPlaying: true)
        TimerView(timeRemaining: 90, totalTime: 120, isPlaying: false)
    }
}
