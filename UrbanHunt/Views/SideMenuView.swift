//
//  SideMenuView.swift
//  UrbanHunt
//
//  Side menu with user profile
//

import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isShowing: Bool
    @State private var showEditProfile = false
    @State private var showMyChallenges = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Dimmed background
            if isShowing {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
            }

            // Side menu
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with profile
                    VStack(alignment: .leading, spacing: 16) {
                        // Profile picture
                        if let pictureUrl = authViewModel.currentUser?.pictureUrl,
                           let url = URL(string: pictureUrl) {
                            CachedAsyncImage(
                                url: url,
                                content: { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                },
                                placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        )
                                }
                            )
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }

                        // Name
                        Text(authViewModel.currentUser?.name ?? "User")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        // Email
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                    Divider()

                    // Menu items
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showEditProfile = true
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.circle")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .frame(width: 24)
                                Text("profile".localized)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }

                        Divider()
                            .padding(.leading, 24)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showMyChallenges = true
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "map")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .frame(width: 24)
                                Text("my_challenges".localized)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }

                        Divider()
                            .padding(.leading, 24)

                        Button(action: {
                            // Settings action
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showSettings = true
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "gear")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .frame(width: 24)
                                Text("settings".localized)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }

                        Divider()
                            .padding(.leading, 24)

                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                Text("sign_out".localized)
                                    .font(.body)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .background(Color(uiColor: .systemBackground))
                .offset(x: isShowing ? 0 : -UIScreen.main.bounds.width * 0.7)

                Spacer()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showMyChallenges) {
            MyChallengesView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}