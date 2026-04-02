//
//  UpdateRequiredView.swift
//  UrbanHunt
//
//  Screen shown when app update is required
//

import SwiftUI

struct UpdateRequiredView: View {
    let message: String
    let latestVersion: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon or update icon
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text("update_required".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let version = latestVersion {
                    Text("latest_version".localized + ": \(version)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Update button
            Button(action: openAppStore) {
                Text("update_now".localized)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private func openAppStore() {
        if let url = URL(string: Config.appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    UpdateRequiredView(
        message: "Please update to the latest version to continue using UrbanHunt",
        latestVersion: "1.2.0"
    )
}