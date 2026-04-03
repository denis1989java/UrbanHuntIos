//
//  MyChallengesView.swift
//  UrbanHunt
//
//  View to display user's created challenges
//

import SwiftUI

struct MyChallengesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var challenges: [Challenge] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasMoreData = true
    @State private var errorMessage: String?
    @State private var showCreateChallenge = false
    @State private var selectedChallenge: Challenge?
    @State private var showEditChallenge = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await loadChallenges()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if challenges.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "map")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("no_challenges_yet".localized)
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("create_first_challenge".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(challenges) { challenge in
                                Button(action: {
                                    selectedChallenge = challenge
                                    showEditChallenge = true
                                }) {
                                    MyChallengeCard(challenge: challenge)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onAppear {
                                    if challenge.id == challenges.last?.id {
                                        Task {
                                            await loadMoreChallenges()
                                        }
                                    }
                                }
                            }

                            if isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding()
                    }
                    .background(Color(uiColor: .systemBackground))
                }
            }
            .navigationTitle("my_challenges".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateChallenge = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView(onChallengeCreated: { newChallenge in
                    // Insert new challenge at the beginning
                    challenges.insert(newChallenge, at: 0)
                })
            }
            .sheet(isPresented: $showEditChallenge) {
                if let challenge = selectedChallenge {
                    EditChallengeView(
                        challenge: challenge,
                        onChallengeUpdated: { updatedChallenge in
                            // Update challenge in list
                            if let index = challenges.firstIndex(where: { $0.id == updatedChallenge.id }) {
                                challenges[index] = updatedChallenge
                            }
                        },
                        onChallengeDeleted: {
                            // Remove challenge from list
                            challenges.removeAll { $0.id == selectedChallenge?.id }
                        }
                    )
                }
            }
            .onAppear {
                Task {
                    await loadChallenges()
                }
            }
        }
    }

    private func loadChallenges() async {
        isLoading = true
        errorMessage = nil
        hasMoreData = true

        do {
            challenges = try await APIService.shared.getMyChallenges(limit: 20)
            print("✅ Loaded \(challenges.count) my challenges")
            await MainActor.run {
                isLoading = false
            }
        } catch {
            print("❌ Error loading my challenges: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load challenges"
                isLoading = false
            }
        }
    }

    private func loadMoreChallenges() async {
        guard !isLoadingMore && hasMoreData && !challenges.isEmpty else {
            return
        }

        isLoadingMore = true

        do {
            let lastCreatedAt = challenges.last?.createdAt
            let newChallenges = try await APIService.shared.getMyChallenges(limit: 20, lastCreatedAt: lastCreatedAt)
            print("✅ Loaded \(newChallenges.count) more my challenges")

            await MainActor.run {
                if newChallenges.isEmpty {
                    hasMoreData = false
                } else {
                    let existingIds = Set(challenges.map { $0.id })
                    let uniqueNewChallenges = newChallenges.filter { !existingIds.contains($0.id) }

                    if uniqueNewChallenges.isEmpty {
                        hasMoreData = false
                    } else {
                        challenges.append(contentsOf: uniqueNewChallenges)
                    }
                }
                isLoadingMore = false
            }
        } catch {
            print("❌ Error loading more my challenges: \(error)")
            await MainActor.run {
                isLoadingMore = false
            }
        }
    }
}

struct MyChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Status badge and Location
            HStack(alignment: .top) {
                statusBadge

                Spacer()

                // Location in top right
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(challenge.cityName), \(challenge.country)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Title
            Text(challenge.title)
                .font(.headline)
                .foregroundColor(.primary)

            // Date and comments
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formatDate(challenge.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(challenge.commentsCount ?? 0)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Next hint date
            if let nextHintDate = challenge.nextHintDate, challenge.status != .completed {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("next_hint".localized)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text(formatNextHintDate(nextHintDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
                .foregroundColor(statusColor)
            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .cornerRadius(8)
    }

    private var statusIcon: String {
        switch challenge.status {
        case .draft:
            return "doc.text"
        case .active:
            return "checkmark.circle"
        case .completed:
            return "trophy"
        case .archived:
            return "archivebox"
        }
    }

    private var statusText: String {
        switch challenge.status {
        case .draft:
            return "draft".localized
        case .active:
            return "active".localized
        case .completed:
            return "completed".localized
        case .archived:
            return "archived".localized
        }
    }

    private var statusColor: Color {
        switch challenge.status {
        case .draft:
            return .orange
        case .active:
            return .green
        case .completed:
            return .blue
        case .archived:
            return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatNextHintDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    MyChallengesView()
}