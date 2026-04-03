//
//  ChallengesViewModel.swift
//  UrbanHunt
//
//  ViewModel for managing challenges list
//

import Foundation
import Combine

@MainActor
class ChallengesViewModel: ObservableObject {
    @Published var allChallenges: [Challenge] = []
    @Published var challenges: [Challenge] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreData = true

    @Published var selectedCountry: String?
    @Published var selectedCity: String?
    @Published var selectedStatus: Challenge.ChallengeStatus?

    // Computed property for available countries
    var availableCountries: [String] {
        let countries = Set(allChallenges.map { $0.country })
        return Array(countries).sorted()
    }

    // Computed property for available cities in selected country
    var availableCities: [String] {
        guard let country = selectedCountry else {
            let cities = Set(allChallenges.map { $0.cityName })
            return Array(cities).sorted()
        }

        let cities = allChallenges
            .filter { $0.country == country }
            .map { $0.cityName }
        return Array(Set(cities)).sorted()
    }

    func loadChallenges() async {
        isLoading = true
        errorMessage = nil
        hasMoreData = true

        do {
            allChallenges = try await APIService.shared.getChallenges(limit: 20)
            print("✅ Loaded \(allChallenges.count) challenges")
            applyFilters()
            isLoading = false
        } catch {
            print("❌ Error loading challenges: \(error)")
            errorMessage = "Failed to load challenges"
            isLoading = false
        }
    }

    func loadMoreChallenges() async {
        guard !isLoadingMore && hasMoreData && !allChallenges.isEmpty else {
            return
        }

        isLoadingMore = true

        do {
            let lastCreatedAt = allChallenges.last?.createdAt
            let newChallenges = try await APIService.shared.getChallenges(limit: 20, lastCreatedAt: lastCreatedAt)
            print("✅ Loaded \(newChallenges.count) more challenges")

            if newChallenges.isEmpty {
                hasMoreData = false
            } else {
                // Filter out duplicates
                let existingIds = Set(allChallenges.map { $0.id })
                let uniqueNewChallenges = newChallenges.filter { !existingIds.contains($0.id) }

                print("🔍 Unique new challenges: \(uniqueNewChallenges.count) out of \(newChallenges.count)")

                if uniqueNewChallenges.isEmpty {
                    // All challenges were duplicates, stop loading
                    hasMoreData = false
                } else {
                    allChallenges.append(contentsOf: uniqueNewChallenges)
                    applyFilters()
                }
            }

            isLoadingMore = false
        } catch {
            print("❌ Error loading more challenges: \(error)")
            isLoadingMore = false
        }
    }

    func refreshChallenges() async {
        allChallenges = []
        await loadChallenges()
    }

    func addNewChallenge(_ challenge: Challenge) {
        // Insert at the beginning (top)
        allChallenges.insert(challenge, at: 0)
        applyFilters()
        print("✅ Added new challenge to top: \(challenge.id)")
    }

    func updateCommentCount(for challengeId: String, newCount: Int) {
        // Update in allChallenges
        if let index = allChallenges.firstIndex(where: { $0.id == challengeId }) {
            var updatedChallenge = allChallenges[index]
            // Create a new challenge with updated count (since Challenge is a struct)
            allChallenges[index] = Challenge(
                id: updatedChallenge.id,
                title: updatedChallenge.title,
                status: updatedChallenge.status,
                country: updatedChallenge.country,
                cityName: updatedChallenge.cityName,
                createdBy: updatedChallenge.createdBy,
                creator: updatedChallenge.creator,
                prizePhotoUrl: updatedChallenge.prizePhotoUrl,
                createdAt: updatedChallenge.createdAt,
                hints: updatedChallenge.hints,
                completion: updatedChallenge.completion,
                commentsCount: newCount,
                nextHintDate: updatedChallenge.nextHintDate
            )
            applyFilters()
            print("✅ Updated comment count for challenge \(challengeId): \(newCount)")
        }
    }

    func filterByCountry(_ country: String?) async {
        selectedCountry = country
        // Reset city when country changes
        selectedCity = nil
        applyFilters()
    }

    func filterByCity(_ city: String?) async {
        selectedCity = city
        applyFilters()
    }

    func filterByStatus(_ status: Challenge.ChallengeStatus?) async {
        selectedStatus = status
        applyFilters()
    }

    func clearFilters() async {
        selectedCountry = nil
        selectedCity = nil
        selectedStatus = nil
        applyFilters()
    }

    private func applyFilters() {
        var filtered = allChallenges

        if let country = selectedCountry {
            filtered = filtered.filter { $0.country == country }
        }

        if let city = selectedCity {
            filtered = filtered.filter { $0.cityName == city }
        }

        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }

        challenges = filtered
        print("🔍 Filtered to \(challenges.count) challenges (country: \(selectedCountry ?? "all"), city: \(selectedCity ?? "all"), status: \(selectedStatus?.rawValue ?? "all"))")
    }
}