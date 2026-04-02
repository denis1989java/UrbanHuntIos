//
//  SettingsView.swift
//  UrbanHunt
//
//  Settings screen
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var locales: [AppLocale] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                // Theme Section
                Section {
                    ForEach([AppTheme.system, AppTheme.light, AppTheme.dark], id: \.self) { theme in
                        Button(action: {
                            themeManager.currentTheme = theme
                        }) {
                            HStack {
                                Text(themeDisplayName(theme))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("theme".localized)
                        .textCase(nil)
                }

                // Language Section
                Section {
                    ForEach(locales) { locale in
                        Button(action: {
                            localizationManager.currentLanguage = locale.code
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(locale.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(locale.nativeName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if localizationManager.currentLanguage == locale.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("language".localized)
                        .textCase(nil)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear(perform: loadLocales)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }

    private func themeDisplayName(_ theme: AppTheme) -> String {
        switch theme {
        case .system:
            return "theme_system".localized
        case .light:
            return "theme_light".localized
        case .dark:
            return "theme_dark".localized
        }
    }

    private func loadLocales() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                locales = try await APIService.shared.getLocales()
                print("✅ Loaded \(locales.count) locales")
                isLoading = false
            } catch {
                print("❌ Error loading locales: \(error)")
                errorMessage = "failed_to_load_locales".localized
                isLoading = false
            }
        }
    }
}

#Preview {
    SettingsView()
}