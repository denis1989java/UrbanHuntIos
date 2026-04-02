//
//  Country.swift
//  UrbanHunt
//
//  Country model
//

import Foundation

struct Country: Identifiable, Codable, Hashable {
    let code: String
    let name: String
    let cities: [String]

    var id: String { code }
}