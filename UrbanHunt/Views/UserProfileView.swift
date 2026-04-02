//
//  UserProfileView.swift
//  UrbanHunt
//
//  View-only user profile screen
//

import SwiftUI

struct UserProfileView: View {
    let userId: String
    @Environment(\.dismiss) var dismiss
    @State private var userInfo: UserSummary?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Button("Retry") {
                            loadUserInfo()
                        }
                    }
                } else if let user = userInfo {
                    ScrollView {
                        VStack(spacing: 32) {
                            // --- Profile Picture Section ---
                            VStack(spacing: 12) {
                                CachedAsyncImage(
                                    url: URL(string: user.pictureUrl ?? ""),
                                    content: { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    },
                                    placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                )
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())

                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // --- Info Section ---
                            VStack(spacing: 20) {
                                infoField(title: "name".localized, value: user.name)

                                if let socialMediaUrl = user.socialMediaUrl, !socialMediaUrl.isEmpty {
                                    socialMediaField(title: "social_media_link".localized, url: socialMediaUrl)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            loadUserInfo()
        }
    }

    private func infoField(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(value)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private func socialMediaField(title: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            Link(destination: URL(string: url) ?? URL(string: "https://")!) {
                HStack {
                    Text(url)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    private func loadUserInfo() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let user = try await APIService.shared.getUserById(userId: userId)
                await MainActor.run {
                    userInfo = user
                    isLoading = false
                }
            } catch {
                print("❌ Error loading user info: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to load user profile"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    UserProfileView(userId: "test-user-id")
}