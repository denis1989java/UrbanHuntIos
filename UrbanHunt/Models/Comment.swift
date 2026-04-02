//
//  Comment.swift
//  UrbanHunt
//
//  Comment model
//

import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let challengeId: String
    let authorId: String
    let authorName: String
    let content: String
    let createdAt: Date
}