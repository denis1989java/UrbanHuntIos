//
//  APIService.swift
//  UrbanHunt
//
//  Service for backend API calls
//

import Foundation
import FirebaseAuth

class APIService {
    static let shared = APIService()

    private let baseURL = Config.apiBaseURL

    private init() {}

    // MARK: - Auth

    func syncUser() async throws -> User {
        print("🔄 APIService.syncUser called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/auth/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("🌐 Making sync request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Sync response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Sync response body: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder.apiDecoder.decode(User.self, from: data)
    }

    func updateProfile(name: String, pictureUrl: String?, socialMediaUrl: String?) async throws -> User {
        print("🔄 APIService.updateProfile called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/auth/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any?] = [
            "name": name,
            "pictureUrl": pictureUrl,
            "socialMediaUrl": socialMediaUrl
        ]

        let jsonBody = body.compactMapValues { $0 }
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)

        if let httpBody = request.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder.apiDecoder.decode(User.self, from: data)
    }

    // MARK: - Helper

    func getCountries() async throws -> [Country] {
        print("🔄 APIService.getCountries called")

        let url = URL(string: "\(baseURL)/countries")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Country].self, from: data)
    }

    func getLocales() async throws -> [AppLocale] {
        print("🔄 APIService.getLocales called")

        let url = URL(string: "\(baseURL)/locales")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode([AppLocale].self, from: data)
    }

    func createChallenge(title: String, description: String, country: String, cityName: String, prizePhotoUrl: String? = nil) async throws -> Challenge {
        print("🔄 APIService.createChallenge called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/challenges")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "title": title,
            "description": description,
            "country": country,
            "cityName": cityName
        ]

        if let prizePhotoUrl = prizePhotoUrl {
            body["prizePhotoUrl"] = prizePhotoUrl
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }

        guard httpResponse.statusCode == 201 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")

            // Try to parse error message from server
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let errorMessage = json["error"] {
                throw APIError.serverError(errorMessage)
            }

            throw APIError.invalidResponse
        }

        return try JSONDecoder.apiDecoder.decode(Challenge.self, from: data)
    }

    func addHint(challengeId: String, content: String, link: String?, publishedAt: Date) async throws -> Challenge {
        print("🔄 APIService.addHint called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/challenges/\(challengeId)/hints")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Format date as UTC in "yyyy-MM-dd'T'HH:mm:ss" format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let publishedAtString = dateFormatter.string(from: publishedAt)

        let body: [String: Any] = [
            "content": content,
            "link": link as Any,
            "publishedAt": publishedAtString
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")

            // Try to parse error message from server
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let errorMessage = json["error"] {
                throw APIError.serverError(errorMessage)
            }

            throw APIError.invalidResponse
        }

        return try JSONDecoder.apiDecoder.decode(Challenge.self, from: data)
    }

    func getChallenges() async throws -> [Challenge] {
        print("🔄 APIService.getChallenges called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/challenges")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body preview: \(responseString.prefix(200))...")
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder.apiDecoder.decode([Challenge].self, from: data)
    }

    func checkVersion() async throws -> VersionCheckResponse {
        print("🔄 APIService.checkVersion called")

        // Get app version from Info.plist
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            throw APIError.invalidResponse
        }

        let url = URL(string: "\(baseURL)/version/check")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = VersionCheckRequest(platform: "ios", version: appVersion)
        request.httpBody = try JSONEncoder().encode(body)

        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 Version check body: \(bodyString)")
        }

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Version check response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Version check response body: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(VersionCheckResponse.self, from: data)
    }

    func getComments(challengeId: String) async throws -> [Comment] {
        print("🔄 APIService.getComments called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/challenges/\(challengeId)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder.apiDecoder.decode([Comment].self, from: data)
    }

    func createComment(challengeId: String, content: String) async throws -> Comment {
        print("🔄 APIService.createComment called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/challenges/\(challengeId)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "content": content
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 201 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")

            // Try to parse error message from server
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let errorMessage = json["error"] {
                throw APIError.serverError(errorMessage)
            }

            throw APIError.invalidResponse
        }

        return try JSONDecoder.apiDecoder.decode(Comment.self, from: data)
    }

    func getUserById(userId: String) async throws -> UserSummary {
        print("🔄 APIService.getUserById called")

        guard let token = try await getFirebaseToken() else {
            print("❌ No Firebase token")
            throw APIError.noToken
        }

        let url = URL(string: "\(baseURL)/users/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🌐 Making request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ Bad status code: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(UserSummary.self, from: data)
    }

    // MARK: - Helper

    private func getFirebaseToken() async throws -> String? {
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }
        // The method was renamed from `idToken()` to `getIDToken()`.
        return try await currentUser.getIDToken()
    }
}

enum APIError: Error {
    case noToken
    case invalidResponse
    case decodingError
    case serverError(String)

    var localizedDescription: String {
        switch self {
        case .noToken:
            return "No authentication token available"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return message
        }
    }
}
