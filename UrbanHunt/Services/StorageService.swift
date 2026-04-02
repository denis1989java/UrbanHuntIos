//
//  StorageService.swift
//  UrbanHunt
//
//  Service for Cloud Storage operations
//

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    static let shared = StorageService()

    private let storage = Storage.storage()
    private let bucketName = Config.storageBucketName

    private init() {}

    func uploadProfilePicture(userId: String, image: UIImage) async throws -> String {
        print("🔄 StorageService: Starting upload...")

        // Resize image to max 512x512 for profile pictures
        let resizedImage = image.resized(to: CGSize(width: 512, height: 512))

        // Compress with lower quality for smaller file size
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.6) else {
            print("❌ StorageService: Failed to convert image to JPEG")
            throw StorageError.invalidImage
        }

        print("📦 Image data size: \(imageData.count) bytes (\(imageData.count / 1024) KB)")

        // Use fixed filename to overwrite previous profile picture
        let fileName = "profiles/\(userId)/profile.jpg"
        print("📁 Upload path: \(fileName)")

        // Use default bucket reference
        let storageRef = storage.reference().child(fileName)
        print("🔗 Storage ref: \(storageRef.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        // Set cache control to allow caching but revalidate
        metadata.cacheControl = "public, max-age=3600"

        print("⬆️ Uploading...")
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        print("✅ Upload complete")

        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await storageRef.downloadURL()

        // Add timestamp to URL to bust cache when image changes
        // Use & since Firebase URL already has query parameters
        let urlWithTimestamp = downloadURL.absoluteString + "&t=\(Int(Date().timeIntervalSince1970))"
        print("✅ Download URL: \(urlWithTimestamp)")
        return urlWithTimestamp
    }

    func uploadHintMedia(challengeId: String, hintIndex: Int, image: UIImage) async throws -> String {
        print("🔄 StorageService: Starting hint media upload...")

        // Resize image to max 1024x1024 for hint images
        let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))

        // Compress with medium quality
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ StorageService: Failed to convert image to JPEG")
            throw StorageError.invalidImage
        }

        print("📦 Image data size: \(imageData.count) bytes (\(imageData.count / 1024) KB)")

        // Create unique filename for hint media
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "hints/\(challengeId)/hint_\(hintIndex)_\(timestamp).jpg"
        print("📁 Upload path: \(fileName)")

        let storageRef = storage.reference().child(fileName)
        print("🔗 Storage ref: \(storageRef.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=86400"

        print("⬆️ Uploading...")
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        print("✅ Upload complete")

        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await storageRef.downloadURL()
        print("✅ Download URL: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    func uploadPrizePhoto(challengeId: String, image: UIImage) async throws -> String {
        print("🔄 StorageService: Starting prize photo upload...")

        // Resize image to max 1024x1024 for prize photos
        let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))

        // Compress with medium quality
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ StorageService: Failed to convert image to JPEG")
            throw StorageError.invalidImage
        }

        print("📦 Image data size: \(imageData.count) bytes (\(imageData.count / 1024) KB)")

        // Create filename for prize photo
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "prizes/\(challengeId)/prize_\(timestamp).jpg"
        print("📁 Upload path: \(fileName)")

        let storageRef = storage.reference().child(fileName)
        print("🔗 Storage ref: \(storageRef.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=86400"

        print("⬆️ Uploading...")
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        print("✅ Upload complete")

        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await storageRef.downloadURL()
        print("✅ Download URL: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Use smaller ratio to fit within target size
        let scaleFactor = min(widthRatio, heightRatio)

        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}

enum StorageError: Error {
    case invalidImage
    case uploadFailed

    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .uploadFailed:
            return "Failed to upload image"
        }
    }
}