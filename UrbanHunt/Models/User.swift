//
//  User.swift
//  UrbanHunt
//
//  User model
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    var name: String
    var pictureUrl: String?
    var socialMediaUrl: String?
    let provider: String?
    let createdAt: Date?
    let lastLoginAt: Date?
}