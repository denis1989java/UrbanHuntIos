//
//  Config.swift
//  UrbanHunt
//
//  Application configuration
//

import Foundation

struct Config {
    // API Configuration
    static let apiBaseURL: String = {
        #if DEBUG
        return "http://localhost:8080/api"
        #else
        return "https://urbanhunt-api.example.com/api" // TODO: Replace with production URL
        #endif
    }()

    // Firebase Storage
    static let storageBucketName = "urbanhunt-491913-media"

    // App Store
    static let appStoreURL = "https://apps.apple.com/app/id123456789" // TODO: Replace with actual App Store ID
}