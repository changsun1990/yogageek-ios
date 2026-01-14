//
//  PoseImageView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/13/26.
//

import SwiftUI

struct PoseImageView: View {
    let imageURL: String
    var size: CGFloat = 80
    var cornerRadius: CGFloat = 12

    private var isWebURL: Bool {
        imageURL.hasPrefix("http://") || imageURL.hasPrefix("https://")
    }

    var body: some View {
        if isWebURL {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipped()
                case .failure:
                    fallbackImage
                @unknown default:
                    fallbackImage
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            // SF Symbol
            Image(systemName: imageURL)
                .font(.system(size: size * 0.5))
                .foregroundStyle(.tint)
                .frame(width: size, height: size)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    private var fallbackImage: some View {
        Image(systemName: "figure.yoga")
            .font(.system(size: size * 0.5))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 20) {
        PoseImageView(imageURL: "figure.yoga", size: 100)
        PoseImageView(imageURL: "https://example.com/image.jpg", size: 100)
    }
}
