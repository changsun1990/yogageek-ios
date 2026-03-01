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
    var size: CGFloat = 200

    private var scale: CGFloat { size / 200 }

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12 * scale)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.yogaPrimary,
                    style: StrokeStyle(lineWidth: 12 * scale, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Time display
            VStack(spacing: 4 * scale) {
                Text(formattedTime)
                    .font(.system(size: 48 * scale, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(isPlaying ? "remaining" : "paused")
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
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
