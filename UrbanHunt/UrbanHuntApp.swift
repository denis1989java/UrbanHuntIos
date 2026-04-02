import SwiftUI
import Firebase

@main
struct UrbanHuntApp: App {

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Initialize theme
        _ = ThemeManager.shared
        _ = LocalizationManager.shared
    }

    @StateObject private var authViewModel = AuthViewModel()
    @State private var versionCheckCompleted = false
    @State private var updateRequired = false
    @State private var updateMessage = ""
    @State private var latestVersion: String?

    var body: some Scene {
        WindowGroup {
            if updateRequired {
                UpdateRequiredView(message: updateMessage, latestVersion: latestVersion)
            } else if !versionCheckCompleted {
                // Show loading while checking version
                ProgressView()
                    .scaleEffect(1.5)
                    .task {
                        await checkAppVersion()
                    }
            } else if authViewModel.isAuthenticated {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }

    private func checkAppVersion() async {
        do {
            let response = try await APIService.shared.checkVersion()

            print("✅ Version check: supported=\(response.supported), updateRequired=\(response.updateRequired)")

            await MainActor.run {
                if response.updateRequired {
                    updateRequired = true
                    updateMessage = response.updateMessage ?? "please_update_app".localized
                    latestVersion = response.latestVersion
                } else {
                    versionCheckCompleted = true
                }
            }
        } catch {
            print("⚠️ Version check failed: \(error), allowing app to continue")
            // On error, allow app to continue (don't block users)
            await MainActor.run {
                versionCheckCompleted = true
            }
        }
    }
}