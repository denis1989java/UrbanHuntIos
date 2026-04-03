//
//  Challenge.swift
//  UrbanHunt
//
//  Challenge model
//

import Foundation

struct Challenge: Identifiable, Codable {
    let id: String
    let title: String
    let status: ChallengeStatus
    let country: String
    let cityName: String
    let createdBy: String?
    let creator: UserSummary?
    let prizePhotoUrl: String?
    let createdAt: Date
    let hints: [Hint]?
    let completion: Completion?
    let commentsCount: Int?
    let nextHintDate: Date?

    enum ChallengeStatus: String, Codable {
        case draft = "DRAFT"
        case active = "ACTIVE"
        case completed = "COMPLETED"
        case archived = "ARCHIVED"
    }
}

struct UserSummary: Codable {
    let email: String
    let name: String
    let pictureUrl: String?
    let socialMediaUrl: String?
}

struct Hint: Codable {
    let content: String
    let link: String?
    let publishedAt: Date?
}

struct Completion: Codable {
    let userId: String
    let userName: String
    let completedAt: Date
    let proofPhotoUrl: String?
}