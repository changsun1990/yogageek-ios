//
//  PoseImageView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/13/26.
//

import SwiftUI
import UIKit

struct PoseImageView: View {
    let imageURL: String
    var size: CGFloat? = 80
    var maxSize: CGFloat? = nil
    var cornerRadius: CGFloat = 12

    @State private var uiImage: UIImage?
    @State private var didFail = false

    private var isWebURL: Bool {
        imageURL.hasPrefix("http://") || imageURL.hasPrefix("https://")
    }

    private var effectiveSize: CGFloat { size ?? 80 }

    var body: some View {
        Group {
            if isWebURL {
                if let uiImage {
                    applyImageModifiers(to: Image(uiImage: uiImage))
                } else if didFail {
                    symbolImage("figure.yoga", color: .secondary)
                } else {
                    ProgressView()
                        .frame(width: effectiveSize, height: effectiveSize)
                }
            } else {
                symbolImage(imageURL, color: .tint)
            }
        }
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: imageURL) {
            await loadImageIfNeeded()
        }
    }

    // Grid views mount many of these at once; the default AsyncImage has no
    // cache and never retries, so a transient failure under that concurrent
    // load gets stuck on the fallback icon forever. This loads from a shared
    // cache and retries transient failures a couple of times before giving up.
    private func loadImageIfNeeded() async {
        guard isWebURL, let url = URL(string: imageURL) else { return }
        uiImage = nil
        didFail = false

        if let cached = await ImageCache.shared.image(for: url) {
            uiImage = cached
            return
        }

        let maxAttempts = 3
        for attempt in 0..<maxAttempts {
            if Task.isCancelled { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await ImageCache.shared.insert(image, for: url)
                    if !Task.isCancelled {
                        uiImage = image
                    }
                    return
                }
            } catch {
                if Task.isCancelled { return }
            }
            if attempt < maxAttempts - 1 {
                try? await Task.sleep(for: .milliseconds(400 * (attempt + 1)))
            }
        }
        if !Task.isCancelled {
            didFail = true
        }
    }

    @ViewBuilder
    private func applyImageModifiers(to image: Image) -> some View {
        let resized = image.resizable().aspectRatio(contentMode: .fit)
        if let size = size {
            resized.frame(width: size, height: size)
        } else if let maxSize = maxSize {
            resized.frame(maxWidth: maxSize, maxHeight: maxSize)
        } else {
            resized
        }
    }

    private func symbolImage(_ name: String, color: some ShapeStyle) -> some View {
        Image(systemName: name)
            .font(.system(size: effectiveSize * 0.5))
            .foregroundStyle(color)
            .frame(width: effectiveSize, height: effectiveSize)
    }
}

#Preview {
    VStack(spacing: 20) {
        PoseImageView(imageURL: "figure.yoga", size: 100)
        PoseImageView(imageURL: "https://example.com/image.jpg", size: 100)
    }
}
