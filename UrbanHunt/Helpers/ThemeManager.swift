//
//  ThemeManager.swift
//  UrbanHunt
//
//  Manager for app theme (light/dark mode)
//

import Foundation
import SwiftUI
import Combine

enum AppTheme: String {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
            applyTheme()
        }
    }

    private init() {
        // Load saved theme or use system default
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
        applyTheme()
    }

    func applyTheme() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }

            for window in windowScene.windows {
                switch self.currentTheme {
                case .light:
                    window.overrideUserInterfaceStyle = .light
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                case .system:
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
    }
}