//
//  AuthViewModel.swift
//  UrbanHunt
//
//  Authentication view model
//

import SwiftUI
import Combine
import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false

    init() {
        // Check if user is already logged in
        if let firebaseUser = Auth.auth().currentUser {
            self.isAuthenticated = true
            self.currentUser = User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                name: firebaseUser.displayName ?? "",
                pictureUrl: firebaseUser.photoURL?.absoluteString,
                socialMediaUrl: nil, // This is likely a custom field from your backend
                provider: firebaseUser.providerData.first?.providerID,
                createdAt: firebaseUser.metadata.creationDate,
                lastLoginAt: firebaseUser.metadata.lastSignInDate
            )

            // Sync with backend
            Task {
                await syncWithBackend()
            }
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Failed to get Firebase client ID"
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Get the root view controller from the first window scene
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            errorMessage = "Failed to get root view controller"
            isLoading = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Failed to get user token"
                self.isLoading = false
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            self.signInWithCredential(credential)
        }
    }

    // MARK: - Common Sign-In

    private func signInWithCredential(_ credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }

            guard let firebaseUser = result?.user else {
                self.errorMessage = "Failed to get user data"
                self.isLoading = false
                return
            }

            self.currentUser = User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                name: firebaseUser.displayName ?? "",
                pictureUrl: firebaseUser.photoURL?.absoluteString,
                socialMediaUrl: nil, // This is likely a custom field from your backend
                provider: firebaseUser.providerData.first?.providerID,
                createdAt: firebaseUser.metadata.creationDate,
                lastLoginAt: firebaseUser.metadata.lastSignInDate
            )
            self.isAuthenticated = true
            self.isLoading = false

            // Sync with backend
            Task {
                await self.syncWithBackend()
            }
        }
    }

    private func syncWithBackend() async {
        // This function will sync the Firebase user with your backend.
        do {
            let syncedUser = try await APIService.shared.syncUser()
            self.currentUser = syncedUser
        } catch {
            print("Failed to sync with backend: \(error.localizedDescription)")
            // self.errorMessage = "Failed to sync user data. Please try again."
        }
    }
    
    // MARK: - Profile Management
    
    func updateProfileImage(newImage: UIImage) async {
        isLoading = true
        errorMessage = nil

        guard let userId = currentUser?.id else {
            errorMessage = "User not found."
            isLoading = false
            return
        }

        do {
            // 1. Upload new image to Storage
            let newPictureUrl = try await StorageService.shared.uploadProfilePicture(userId: userId, image: newImage)
            
            // 2. Update backend with the new URL
            let updatedUser = try await APIService.shared.updateProfile(
                name: self.currentUser?.name ?? "", // Use existing name
                pictureUrl: newPictureUrl,
                socialMediaUrl: self.currentUser?.socialMediaUrl // Use existing social media URL
            )
            
            // 3. Update local state
            self.currentUser = updatedUser
            print("✅ Profile image updated successfully.")
            
        } catch {
            print("❌ Error updating profile image: \(error.localizedDescription)")
            self.errorMessage = "Failed to update profile image. Please try again."
        }

        isLoading = false
    }

    func updateUserProfile(name: String, socialMediaUrl: String) async {
        let trimmedSocialUrl = socialMediaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prevent update if nothing changed
        guard name != currentUser?.name || (trimmedSocialUrl.isEmpty ? nil : trimmedSocialUrl) != currentUser?.socialMediaUrl else {
            print("No changes to save.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedUser = try await APIService.shared.updateProfile(
                name: name,
                pictureUrl: self.currentUser?.pictureUrl, // Pass existing picture URL
                socialMediaUrl: trimmedSocialUrl.isEmpty ? nil : trimmedSocialUrl
            )

            // Update local state
            self.currentUser = updatedUser
            print("✅ Profile text fields updated successfully.")

        } catch {
            print("❌ Error updating profile text fields: \(error.localizedDescription)")
            self.errorMessage = "Failed to save profile. Please try again."
        }
        
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
