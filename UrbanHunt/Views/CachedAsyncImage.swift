//
//  CachedAsyncImage.swift
//  UrbanHunt
//
//  Async image with caching
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var currentURL: URL?

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            if currentURL != url {
                loadImage()
            }
        }
        .onChange(of: url) { _, newURL in
            if currentURL != newURL {
                loadImage()
            }
        }
    }

    private func loadImage() {
        guard let url = url else {
            print("⚠️ CachedAsyncImage: URL is nil")
            currentURL = nil
            image = nil
            return
        }

        currentURL = url
        let urlString = url.absoluteString
        print("🔍 CachedAsyncImage: Loading image from \(urlString)")

        // Check cache first
        if let cachedImage = ImageCache.shared.get(urlString) {
            print("✅ CachedAsyncImage: Found in cache")
            self.image = cachedImage
            return
        }

        print("🌐 CachedAsyncImage: Loading from network...")
        // Load from network
        isLoading = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {
                    print("✅ CachedAsyncImage: Downloaded successfully")
                    ImageCache.shared.set(urlString, image: downloadedImage)
                    await MainActor.run {
                        self.image = downloadedImage
                    }
                } else {
                    print("❌ CachedAsyncImage: Failed to decode image data")
                }
            } catch {
                print("❌ CachedAsyncImage: Failed to load image: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}