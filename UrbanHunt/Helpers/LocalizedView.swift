//
//  LocalizedView.swift
//  UrbanHunt
//
//  Wrapper for views that need to update on language change
//

import SwiftUI

struct LocalizedView<Content: View>: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let content: () -> Content

    var body: some View {
        content()
            .id(localizationManager.currentLanguage)
    }
}