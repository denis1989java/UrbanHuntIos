//
//  AppVersion.swift
//  UrbanHunt
//
//  App version models
//

import Foundation

struct VersionCheckRequest: Codable {
    let platform: String
    let version: String
}

struct VersionCheckResponse: Codable {
    let supported: Bool
    let updateRequired: Bool
    let latestVersion: String?
    let updateMessage: String?
}