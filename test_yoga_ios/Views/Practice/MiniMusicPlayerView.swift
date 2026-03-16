//
//  MiniMusicPlayerView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/20/26.
//

import SwiftUI

struct MiniMusicPlayerView: View {
    var musicManager: MusicManager
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Service icon
                serviceIcon

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(musicManager.currentTrackName.isEmpty ? "Now Playing" : musicManager.currentTrackName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if !musicManager.currentArtistName.isEmpty {
                        Text(musicManager.currentArtistName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Play/Pause
                Button {
                    Task {
                        await musicManager.togglePlayPause()
                    }
                } label: {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                // Skip
                if musicManager.activeService == .appleMusic {
                    Button {
                        Task {
                            await musicManager.skipNext()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.caption)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.yogaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .yogaCardShadow()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var serviceIcon: some View {
        switch musicManager.activeService {
        case .appleMusic:
            Image(systemName: "music.note")
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .spotify:
            Image(systemName: "music.note.tv")
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color(red: 0.114, green: 0.725, blue: 0.329))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .none:
            EmptyView()
        }
    }
}

#Preview {
    VStack {
        MiniMusicPlayerView(
            musicManager: MusicManager.shared,
            onTap: {}
        )
        .padding()
    }
    .background(Color.yogaSurface)
}
