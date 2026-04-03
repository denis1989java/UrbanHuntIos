//
//  HintsView.swift
//  UrbanHunt
//
//  View to display challenge hints
//

import SwiftUI

struct HintsView: View {
    let challenge: Challenge
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if let hints = challenge.hints, !hints.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(Array(hints.enumerated()), id: \.offset) { index, hint in
                                HintCard(hint: hint, number: index + 1)
                            }
                        }
                        .padding()
                    }
                } else {
                    // No hints state
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("no_hints_added".localized)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("hints".localized)
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
    }
}

struct HintCard: View {
    let hint: Hint
    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hint number and date
            HStack {
                Text("Hint #\(number)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Spacer()

                if let publishedAt = hint.publishedAt {
                    Text(formatDate(publishedAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Hint content
            Text(hint.content)
                .font(.body)
                .foregroundColor(.primary)

            // Media if available
            if let link = hint.link, let url = URL(string: link) {
                CachedAsyncImage(
                    url: url,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .cornerRadius(8)
                            .overlay(
                                ProgressView()
                            )
                    }
                )
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HintsView(challenge: Challenge(
        id: "1",
        title: "Test Challenge",
        status: .active,
        country: "Spain",
        cityName: "Barcelona",
        createdBy: nil,
        creator: nil,
        prizePhotoUrl: nil,
        createdAt: Date(),
        hints: [
            Hint(content: "Look for the red door", link: nil, publishedAt: Date())
        ],
        completion: nil,
        commentsCount: 0,
        nextHintDate: nil
    ))
}