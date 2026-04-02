//
//  CommentsView.swift
//  UrbanHunt
//
//  View to display challenge comments
//

import SwiftUI

struct CommentsView: View {
    let challengeId: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var newCommentText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Button("Retry") {
                            loadComments()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("no_comments_yet".localized)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(comments) { comment in
                                CommentCard(comment: comment)
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                // Comment input
                HStack(spacing: 12) {
                    TextField("add_comment".localized, text: $newCommentText)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(20)

                    Button(action: {
                        sendComment()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(newCommentText.isEmpty ? .gray : .blue)
                    }
                    .disabled(newCommentText.isEmpty || isLoading)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("comments".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                loadComments()
            }
        }
    }

    private func loadComments() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                comments = try await APIService.shared.getComments(challengeId: challengeId)
                print("✅ Loaded \(comments.count) comments")
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("❌ Error loading comments: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to load comments"
                    isLoading = false
                }
            }
        }
    }

    private func sendComment() {
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let comment = try await APIService.shared.createComment(
                    challengeId: challengeId,
                    content: text
                )
                print("✅ Comment created: \(comment.id)")

                await MainActor.run {
                    newCommentText = ""
                    isLoading = false
                    loadComments() // Reload comments
                }
            } catch {
                print("❌ Error creating comment: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to send comment"
                    isLoading = false
                }
            }
        }
    }
}

struct CommentCard: View {
    let comment: Comment
    @State private var authorPictureUrl: String?
    @State private var showUserProfile = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar - tappable
            Button(action: {
                showUserProfile = true
            }) {
                CachedAsyncImage(
                    url: URL(string: authorPictureUrl ?? ""),
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
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            )
                    }
                )
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Button(action: {
                        showUserProfile = true
                    }) {
                        Text(comment.authorName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    Text(formatDate(comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            loadAuthorInfo()
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(userId: comment.authorId)
        }
    }

    private func loadAuthorInfo() {
        Task {
            do {
                let userSummary = try await APIService.shared.getUserById(userId: comment.authorId)
                await MainActor.run {
                    authorPictureUrl = userSummary.pictureUrl
                }
            } catch {
                print("❌ Error loading author info: \(error)")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    CommentsView(challengeId: "123")
}