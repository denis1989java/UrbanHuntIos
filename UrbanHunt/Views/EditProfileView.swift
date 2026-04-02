//
//  EditProfileView.swift
//  UrbanHunt
//
//  Edit profile screen
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    // State for text fields, initialized from view model
    @State private var name: String = ""
    @State private var socialMediaUrl: String = ""
    
    // State for photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    
    // Computed property to detect changes in text fields
    private var hasChanges: Bool {
        let currentName = authViewModel.currentUser?.name ?? ""
        let currentSocial = authViewModel.currentUser?.socialMediaUrl ?? ""
        let trimmedSocial = socialMediaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        return name != currentName || trimmedSocial != currentSocial
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // --- Profile Picture Section ---
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                profileImageView
                            }
                            .onChange(of: selectedPhoto, handlePhotoSelection)
                            
                            Text(authViewModel.currentUser?.email ?? "no-email@example.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // --- Form Section ---
                        VStack(spacing: 20) {
                            formTextField(title: "name".localized, text: $name, placeholder: "enter_your_name".localized)
                                .onChange(of: name) { _, newValue in
                                    if newValue.count > 20 {
                                        name = String(newValue.prefix(20))
                                    }
                                }
                            formTextField(title: "social_media_link".localized, text: $socialMediaUrl, placeholder: "instagram_or_tiktok_url".localized)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                        
                        // --- Action Buttons ---
                        HStack(spacing: 16) {
                            Button(action: { dismiss() }) {
                                Text("cancel".localized)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }

                            Button(action: saveProfileText) {
                                Text("save".localized)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.primary)
                                    .foregroundColor(Color(uiColor: .systemBackground))
                                    .cornerRadius(8)
                            }
                            .disabled(authViewModel.isLoading)
                        }
                        .padding(.top, 16)
                        
                        // --- Error Message ---
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40) // Main padding for top and bottom
                } // End of ScrollView
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .navigationViewStyle(.stack) // Prevents potential layout issues
        .onAppear(perform: loadCurrentProfile)
        .overlay(
            // --- Loading Indicator ---
            Group {
                if authViewModel.isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
    }

    // MARK: - Subviews
    
    @ViewBuilder
    private var profileImageView: some View {
        ZStack {
            // Use CachedAsyncImage to show current profile picture
            CachedAsyncImage(
                url: URL(string: authViewModel.currentUser?.pictureUrl ?? ""),
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                },
                placeholder: {
                    // Placeholder with person icon
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

            // Camera icon overlay
            Circle()
                .fill(.black.opacity(0.4))
                .frame(width: 120, height: 120)

            Image(systemName: "camera.fill")
                .font(.title)
                .foregroundColor(.white)
        }
    }
    
    private func formTextField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            TextField(placeholder, text: text)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Functions

    private func loadCurrentProfile() {
        if let user = authViewModel.currentUser {
            name = user.name
            socialMediaUrl = user.socialMediaUrl ?? ""
        }
    }
    
    private func handlePhotoSelection(_ oldItem: PhotosPickerItem?, newItem: PhotosPickerItem?) {
        Task {
            guard let newItem,
                  let data = try? await newItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }
            // Immediately call the ViewModel to handle upload and update
            await authViewModel.updateProfileImage(newImage: image)
        }
    }
    
    private func saveProfileText() {
        // Guard against saving if there are no changes
        guard hasChanges else {
            print("No changes to save, dismissing.")
            dismiss()
            return
        }

        Task {
            await authViewModel.updateUserProfile(name: name, socialMediaUrl: socialMediaUrl)
            // Dismiss after saving, only if there was no error
            if authViewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

#Preview {
    // Create a mock user for the preview
    let mockAuthViewModel = AuthViewModel()
    let mockUser = User(id: "123", email: "example@email.com", name: "John Doe", pictureUrl: nil, socialMediaUrl: "https://instagram.com/johndoe", provider: "google.com", createdAt: Date(), lastLoginAt: Date())
    mockAuthViewModel.currentUser = mockUser
    
    return EditProfileView()
        .environmentObject(mockAuthViewModel)
}
