//
//  Color+Theme.swift
//  UrbanHunt
//
//  Theme-aware colors
//

import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let background = Color(uiColor: .systemBackground)
    let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    let groupedBackground = Color(uiColor: .systemGroupedBackground)
    let text = Color(uiColor: .label)
    let secondaryText = Color(uiColor: .secondaryLabel)
    let separator = Color(uiColor: .separator)
}