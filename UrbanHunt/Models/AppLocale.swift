//
//  Locale.swift
//  UrbanHunt
//
//  Locale model
//

import Foundation

struct AppLocale: Identifiable, Codable {
    let id: String
    let code: String
    let name: String
    let nativeName: String
}