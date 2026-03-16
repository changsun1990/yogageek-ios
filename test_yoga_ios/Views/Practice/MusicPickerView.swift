//
//  MusicPickerView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/20/26.
//

import SwiftUI
import MusicKit

struct MusicPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var musicManager: MusicManager

    @State private var selectedTab: MusicServiceTab = .appleMusic

    enum MusicServiceTab: String, CaseIterable {
        case appleMusic = "Apple Music"
        case spotify = "Spotify"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Service picker
                Picker("Music Service", selection: $selectedTab) {
                    ForEach(MusicServiceTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Content based on selected tab
                switch selectedTab {
                case .appleMusic:
                    appleMusicContent
                case .spotify:
                    spotifyContent
                        .onAppear { musicManager.refreshSpotifyStatus() }
                }
            }
            .navigationTitle("Choose Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Apple Music

    private var appleMusicContent: some View {
        Group {
            if !musicManager.appleMusicAuthorized {
                appleMusicAuthPrompt
            } else if musicManager.isLoadingPlaylists {
                ProgressView("Loading playlists...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let playlists = musicManager.appleMusicPlaylists, !playlists.isEmpty {
                appleMusicPlaylistList(playlists: playlists)
            } else {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "No Playlists",
                        systemImage: "music.note.list",
                        description: Text("Make sure you have playlists in your Apple Music library.")
                    )

                    Button {
                        Task {
                            await musicManager.loadAppleMusicPlaylists()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .task {
            if musicManager.appleMusicAuthorized {
                await musicManager.loadAppleMusicPlaylists()
            }
        }
    }

    private var appleMusicAuthPrompt: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "music.note.house")
                .font(.system(size: 60))
                .foregroundStyle(Color.yogaPrimary)

            Text("Connect Apple Music")
                .font(.yogaTitle(22))

            Text("Access your playlists to play music during yoga practice.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await musicManager.requestAppleMusicAuth()
                }
            } label: {
                Label("Allow Access", systemImage: "checkmark.circle")
                    .font(.yogaHeadline())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.yogaPrimary)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    private func appleMusicPlaylistList(playlists: MusicItemCollection<Playlist>) -> some View {
        List(playlists) { playlist in
            Button {
                Task {
                    await musicManager.playAppleMusicPlaylist(playlist)
                    dismiss()
                }
            } label: {
                HStack(spacing: 12) {
                    // Playlist artwork
                    if let artwork = playlist.artwork {
                        ArtworkImage(artwork, width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "music.note.list")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, height: 50)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(playlist.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if let description = playlist.shortDescription, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.yogaPrimary)
                }
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // MARK: - Spotify

    private var spotifyContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Spotify connection status
                spotifyHeader

                Divider()
                    .padding(.horizontal)

                // Preset yoga playlists
                VStack(alignment: .leading, spacing: 12) {
                    Text("Yoga Playlists")
                        .font(.yogaHeadline())
                        .padding(.horizontal)

                    ForEach(MusicManager.spotifyYogaPresets) { preset in
                        Button {
                            musicManager.openSpotifyPlaylist(preset.uri)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: preset.icon)
                                    .font(.title3)
                                    .foregroundStyle(Color.yogaPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.yogaPrimary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    Text(preset.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()
                    .padding(.horizontal)

                // Open Spotify button
                Button {
                    musicManager.openSpotify()
                    dismiss()
                } label: {
                    Label("Open Spotify to Choose Music", systemImage: "arrow.up.right.circle")
                        .font(.yogaHeadline())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.114, green: 0.725, blue: 0.329)) // Spotify green
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private var spotifyHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.tv")
                .font(.system(size: 40))
                .foregroundStyle(Color(red: 0.114, green: 0.725, blue: 0.329))

            if musicManager.spotifyInstalled {
                Text("Spotify is installed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Select a preset playlist or open Spotify to choose your own music. It will play in the background during practice.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("Spotify Not Installed")
                    .font(.yogaHeadline())

                Text("Install Spotify from the App Store to play Spotify music during practice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    MusicPickerView(musicManager: MusicManager.shared)
}
