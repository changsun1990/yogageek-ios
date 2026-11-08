//
//  AudioSessionQueue.swift
//  test_yoga_ios
//

import AVFoundation

/// Audio session changes wait on the system's audio server, which can take long enough to
/// freeze the screen, so they run here instead: off the main thread, one at a time, in order
nonisolated enum AudioSessionQueue {
    private static let queue = DispatchQueue(label: "changsun.test-yoga-ios.audio-session", qos: .userInitiated)

    /// Makes the change without waiting for it
    static func enqueue(_ change: @escaping @Sendable (AVAudioSession) throws -> Void) {
        queue.async {
            do {
                try change(.sharedInstance())
            } catch {
                print("[AudioSession] change failed: \(error)")
            }
        }
    }

    /// Makes the change and waits for it, for work that needs the session ready first
    static func perform(_ change: @escaping @Sendable (AVAudioSession) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                continuation.resume(with: Result { try change(.sharedInstance()) })
            }
        }
    }
}
