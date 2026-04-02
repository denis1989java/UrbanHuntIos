//
//  LocalizationManager.swift
//  UrbanHunt
//
//  Manager for app localization
//

import Foundation
import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_locale")
        }
    }

    private init() {
        // Load saved language or use system default
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_locale") {
            self.currentLanguage = savedLanguage
        } else {
            self.currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        }
    }

    func localizedString(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

// Extension for easy usage
extension String {
    var localized: String {
        LocalizationManager.shared.localizedString(self)
    }
}