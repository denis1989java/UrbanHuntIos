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
    @Published var errorMessage: String?

    @Published var selectedCountry: String?
    @Published var selectedCity: String?

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

        do {
            allChallenges = try await APIService.shared.getChallenges()
            print("✅ Loaded \(allChallenges.count) challenges")
            applyFilters()
            isLoading = false
        } catch {
            print("❌ Error loading challenges: \(error)")
            errorMessage = "Failed to load challenges"
            isLoading = false
        }
    }

    func refreshChallenges() async {
        await loadChallenges()
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

    func clearFilters() async {
        selectedCountry = nil
        selectedCity = nil
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

        challenges = filtered
        print("🔍 Filtered to \(challenges.count) challenges (country: \(selectedCountry ?? "all"), city: \(selectedCity ?? "all"))")
    }
}