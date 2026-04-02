//
//  LoginView.swift
//  UrbanHunt
//
//  Login screen with Google Sign-In only
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Urban Hunt")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("welcome_urban_hunt".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Sign-In Button
            VStack(spacing: 16) {
                Text("Sign in to continue")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Google Sign-In Button
                Button(action: {
                    authViewModel.signInWithGoogle()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)

                        Text("sign_in_with_google".localized)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .disabled(authViewModel.isLoading)
            }
            .padding(.horizontal, 32)

            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            // Loading Indicator
            if authViewModel.isLoading {
                ProgressView()
                    .padding()
            }

            Spacer()
                .frame(height: 50)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}