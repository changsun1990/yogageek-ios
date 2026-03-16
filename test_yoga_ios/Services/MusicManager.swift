//
//  MusicManager.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/20/26.
//

import Foundation
import MusicKit
import MediaPlayer

enum MusicService: String, CaseIterable {
    case none
    case appleMusic
    case spotify
}

@Observable
class MusicManager {
    static let shared = MusicManager()

    // State
    var activeService: MusicService = .none
    var isPlaying: Bool = false
    var currentTrackName: String = ""
    var currentArtistName: String = ""

    // Apple Music
    var appleMusicAuthorized: Bool = false
    var appleMusicPlaylists: MusicItemCollection<Playlist>?
    var isLoadingPlaylists: Bool = false

    // Spotify
    var spotifyInstalled: Bool = false

    private let appleMusicPlayer = SystemMusicPlayer.shared

    private init() {
        checkAppleMusicAuth()
        checkSpotifyInstalled()
        observeNowPlaying()
    }

    // MARK: - Apple Music Authorization

    private func checkAppleMusicAuth() {
        let status = MusicAuthorization.currentStatus
        appleMusicAuthorized = (status == .authorized)
    }

    func requestAppleMusicAuth() async {
        let status = await MusicAuthorization.request()
        await MainActor.run {
            appleMusicAuthorized = (status == .authorized)
        }
        if status == .authorized {
            await loadAppleMusicPlaylists()
        }
    }

    // MARK: - Apple Music Playlists

    func loadAppleMusicPlaylists() async {
        guard appleMusicAuthorized else { return }
        await MainActor.run { isLoadingPlaylists = true }
        do {
            // Fetch all user library playlists (no sort — lastPlayedDate can cause empty results)
            let request = MusicLibraryRequest<Playlist>()
            let response = try await request.response()
            await MainActor.run {
                appleMusicPlaylists = response.items
                isLoadingPlaylists = false
            }
            print("[MusicManager] Loaded \(response.items.count) playlists")
        } catch {
            print("[MusicManager] Failed to load playlists: \(error)")
            await MainActor.run { isLoadingPlaylists = false }
        }
    }

    // MARK: - Apple Music Playback

    func playAppleMusicPlaylist(_ playlist: Playlist) async {
        do {
            let detailedPlaylist = try await playlist.with([.tracks])
            guard let tracks = detailedPlaylist.tracks, !tracks.isEmpty else {
                print("[MusicManager] No tracks in playlist")
                return
            }
            appleMusicPlayer.queue = SystemMusicPlayer.Queue(for: tracks)
            try await appleMusicPlayer.play()
            await MainActor.run {
                activeService = .appleMusic
                isPlaying = true
                if let firstTrack = tracks.first {
                    currentTrackName = firstTrack.title
                    currentArtistName = firstTrack.artistName
                }
            }
            observeAppleMusicState()
        } catch {
            print("[MusicManager] Playback error: \(error)")
        }
    }

    private func observeAppleMusicState() {
        // Poll the system music player state periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self, self.activeService == .appleMusic else {
                timer.invalidate()
                return
            }
            let playerState = SystemMusicPlayer.shared.state
            self.isPlaying = (playerState.playbackStatus == .playing)
            self.updateNowPlayingInfo()
        }
    }

    // MARK: - Spotify

    func refreshSpotifyStatus() {
        if let url = URL(string: "spotify:") {
            spotifyInstalled = UIApplication.shared.canOpenURL(url)
        }
    }

    private func checkSpotifyInstalled() {
        DispatchQueue.main.async {
            self.refreshSpotifyStatus()
        }
    }

    /// Open a playlist in the Spotify app. Music plays in background.
    /// - Parameter playlistURI: e.g. "spotify:playlist:37i9dQZF1DX9uKNf5jGX6m"
    func openSpotifyPlaylist(_ playlistURI: String) {
        guard let url = URL(string: playlistURI) else { return }
        UIApplication.shared.open(url) { success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.activeService = .spotify
                    self.isPlaying = true
                    self.updateNowPlayingInfo()
                }
            }
        }
    }

    /// Open Spotify app to let user pick music manually
    func openSpotify() {
        if let url = URL(string: "spotify:") {
            UIApplication.shared.open(url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.activeService = .spotify
                self.isPlaying = true
                self.updateNowPlayingInfo()
            }
        }
    }

    // MARK: - Unified Controls

    func play() async {
        switch activeService {
        case .appleMusic:
            try? await appleMusicPlayer.play()
            isPlaying = true
        case .spotify:
            // Spotify is controlled by the Spotify app
            // We can't programmatically play without the SDK
            break
        case .none:
            break
        }
    }

    func pause() {
        switch activeService {
        case .appleMusic:
            appleMusicPlayer.pause()
            isPlaying = false
        case .spotify, .none:
            break
        }
    }

    func togglePlayPause() async {
        if isPlaying {
            pause()
        } else {
            await play()
        }
    }

    func skipNext() async {
        guard activeService == .appleMusic else { return }
        do {
            try await appleMusicPlayer.skipToNextEntry()
            updateNowPlayingInfo()
        } catch {
            print("[MusicManager] Skip error: \(error)")
        }
    }

    func stop() {
        switch activeService {
        case .appleMusic:
            appleMusicPlayer.pause()
        case .spotify, .none:
            break
        }
        isPlaying = false
        activeService = .none
        currentTrackName = ""
        currentArtistName = ""
    }

    // MARK: - Now Playing Info

    private func observeNowPlaying() {
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }

    private func updateNowPlayingInfo() {
        // Check MPNowPlayingInfoCenter for currently playing track
        if let nowPlaying = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem {
            currentTrackName = nowPlaying.title ?? ""
            currentArtistName = nowPlaying.artist ?? ""
        }
    }

    // MARK: - Spotify URL Callback

    func handleSpotifyURL(_ url: URL) {
        // TODO: Implement full SPTAppRemote auth flow when Spotify SDK is added
        // For now, Spotify is controlled via deep links
        guard url.scheme == "yogageek-spotify" else { return }
        activeService = .spotify
        isPlaying = true
    }
}

// MARK: - Preset Spotify Playlists for Yoga

struct SpotifyPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let uri: String
    let icon: String
}

extension MusicManager {
    static let spotifyYogaPresets: [SpotifyPreset] = [
        SpotifyPreset(
            name: "Peaceful Yoga",
            description: "Calm and soothing tracks for yoga practice",
            uri: "spotify:playlist:37i9dQZF1DX9uKNf5jGX6m",
            icon: "leaf"
        ),
        SpotifyPreset(
            name: "Yoga & Meditation",
            description: "Ambient sounds for deep focus",
            uri: "spotify:playlist:37i9dQZF1DWZqd5JICZI0u",
            icon: "sparkles"
        ),
        SpotifyPreset(
            name: "Nature Sounds",
            description: "Natural ambient sounds",
            uri: "spotify:playlist:37i9dQZF1DX4PP3DA4J0N8",
            icon: "cloud.sun"
        ),
    ]
}
