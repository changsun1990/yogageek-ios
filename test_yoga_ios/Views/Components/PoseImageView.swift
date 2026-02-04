//
//  PoseImageView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/13/26.
//

import SwiftUI

struct PoseImageView: View {
    let imageURL: String
    var size: CGFloat? = 80
    var maxSize: CGFloat? = nil
    var cornerRadius: CGFloat = 12

    private var isWebURL: Bool {
        imageURL.hasPrefix("http://") || imageURL.hasPrefix("https://")
    }

    private var effectiveSize: CGFloat { size ?? 80 }

    var body: some View {
        Group {
            if isWebURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: effectiveSize, height: effectiveSize)
                    case .success(let image):
                        applyImageModifiers(to: image)
                    case .failure:
                        symbolImage("figure.yoga", color: .secondary)
                    @unknown default:
                        symbolImage("figure.yoga", color: .secondary)
                    }
                }
            } else {
                symbolImage(imageURL, color: .tint)
            }
        }
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
