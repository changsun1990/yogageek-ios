//
//  SpeechClipService.swift
//  test_yoga_ios
//

import Foundation
import CryptoKit
import FirebaseAuth
import FirebaseAppCheck

/// Natural-voice recordings of practice phrases (pose names and cues), made by the synthesizeSpeech
/// Cloud Function (functions/index.js) and kept on the device so each phrase is fetched only once
actor SpeechClipService {
    static let shared = SpeechClipService()

    /// Matches the voice in functions/index.js; changing it starts a fresh set of recordings
    private static let voice = "en-US-Chirp3-HD-Achernar"
    private static let endpoint = URL(string: "https://us-central1-yogageek.cloudfunctions.net/synthesizeSpeech")!
    /// The most phrases the function accepts in one call
    private static let batchSize = 20

    private let cacheDirectory: URL
    private var pending: Set<String> = []

    init() {
        cacheDirectory = URL.cachesDirectory.appending(path: "speech", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Starts fetching recordings for phrases that aren't on the device yet, in the order given
    func prefetch(_ phrases: [String]) {
        var seen = Set<String>()
        let needed = phrases.filter { seen.insert($0).inserted && !pending.contains($0) && cachedClip(for: $0) == nil }
        guard !needed.isEmpty else { return }
        pending.formUnion(needed)

        for start in stride(from: 0, to: needed.count, by: Self.batchSize) {
            let batch = Array(needed[start..<min(start + Self.batchSize, needed.count)])
            Task {
                do {
                    try await download(batch)
                } catch {
                    print("[SpeechClipService] Fetching recordings failed: \(error)")
                }
                pending.subtract(batch)
            }
        }
    }

    /// The phrase's recording, waiting up to `timeout` while it's being fetched; nil means use the device voice
    func clip(for phrase: String, timeout: Duration) async -> URL? {
        let deadline = ContinuousClock.now + timeout
        while true {
            if let url = cachedClip(for: phrase) {
                return url
            }
            guard pending.contains(phrase), ContinuousClock.now < deadline else { return nil }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private nonisolated func cachedClip(for phrase: String) -> URL? {
        let url = fileURL(for: phrase)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private nonisolated func fileURL(for phrase: String) -> URL {
        let digest = SHA256.hash(data: Data("\(Self.voice)|\(phrase)".utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appending(path: "\(name).mp3")
    }

    private func download(_ phrases: [String]) async throws {
        let urls = try await requestRecordingURLs(for: phrases)
        for (phrase, url) in zip(phrases, urls) {
            guard let url else { continue }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }
            try data.write(to: fileURL(for: phrase), options: .atomic)
        }
    }

    private func requestRecordingURLs(for phrases: [String]) async throws -> [URL?] {
        guard let user = Auth.auth().currentUser else { throw SpeechClipError.notSignedIn }

        var request = URLRequest(url: Self.endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(try await user.getIDToken())", forHTTPHeaderField: "Authorization")
        // The function only answers this app, which keeps others from running up the voice bill
        if let appCheckToken = try? await AppCheck.appCheck().token(forcingRefresh: false) {
            request.setValue(appCheckToken.token, forHTTPHeaderField: "X-Firebase-AppCheck")
        }
        // Callable functions take {"data": ...} and reply with {"result": ...}
        request.httpBody = try JSONEncoder().encode(CallableRequest(data: .init(texts: phrases)))

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw SpeechClipError.badResponse(status, String(decoding: data, as: UTF8.self))
        }
        return try JSONDecoder().decode(CallableResponse.self, from: data).result.urls.map { $0.flatMap(URL.init(string:)) }
    }
}

nonisolated enum SpeechClipError: Error {
    case notSignedIn
    case badResponse(Int, String)
}

private nonisolated struct CallableRequest: Encodable {
    struct Payload: Encodable {
        let texts: [String]
    }
    let data: Payload
}

private nonisolated struct CallableResponse: Decodable {
    struct Result: Decodable {
        let urls: [String?]
    }
    let result: Result
}
