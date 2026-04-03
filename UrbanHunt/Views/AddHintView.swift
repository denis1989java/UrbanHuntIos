//
//  AddHintView.swift
//  UrbanHunt
//
//  Add hint to challenge
//

import SwiftUI
import PhotosUI

struct AddHintView: View {
    let challengeId: String
    let currentHintCount: Int
    let onHintAdded: ((Hint) -> Void)?

    @Environment(\.dismiss) var dismiss
    @State private var hintText: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isPublishImmediately = true
    @State private var publishDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            hintTextField
                            photoPickerSection
                            publishSection
                            addButton
                        }
                        .padding()
                    }
                }

                errorMessageView
            }
            .navigationTitle("add_hint".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private var hintTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("hint_text".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            TextEditor(text: $hintText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: hintText) { _, newValue in
                    let maxLength = 500
                    if newValue.count > maxLength {
                        hintText = String(newValue.prefix(maxLength))
                    }
                }
        }
    }

    private var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("media_optional".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    if let photoData = photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text("photo_selected".localized)
                                .foregroundColor(.primary)
                            Text("tap_to_change".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                        Text("select_photo_or_video".localized)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 80)
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var publishSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isPublishImmediately) {
                Text("publish_immediately".localized)
                    .font(.subheadline)
            }

            if !isPublishImmediately {
                VStack(alignment: .leading, spacing: 8) {
                    Text("publish_date".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    DatePicker(
                        "select_date_and_time".localized,
                        selection: $publishDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: {
            Task {
                await addHint()
            }
        }) {
            Text("add".localized)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(isLoading || !isFormValid)
    }

    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .padding()
        }
    }

    private var isFormValid: Bool {
        !hintText.trimmingCharacters(in: .whitespaces).isEmpty || photoData != nil
    }

    private func addHint() async {
        isLoading = true
        errorMessage = nil

        do {
            var photoUrl: String? = nil

            // Upload photo if selected
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData) {
                photoUrl = try await StorageService.shared.uploadHintMedia(
                    challengeId: challengeId,
                    hintIndex: currentHintCount,
                    image: uiImage
                )
            }

            // Determine publish date
            let finalPublishDate = isPublishImmediately ? Date() : publishDate

            // Add hint via API
            let updatedChallenge = try await APIService.shared.addHint(
                challengeId: challengeId,
                content: hintText.trimmingCharacters(in: .whitespaces),
                link: photoUrl,
                publishedAt: finalPublishDate
            )

            // Find the newly added hint
            if let hints = updatedChallenge.hints,
               let newHint = hints.last {
                await MainActor.run {
                    isLoading = false
                    onHintAdded?(newHint)
                    dismiss()
                }
            }
        } catch {
            print("❌ Error adding hint: \(error)")
            await MainActor.run {
                if let apiError = error as? APIError {
                    errorMessage = apiError.localizedDescription
                } else {
                    errorMessage = "Failed to add hint"
                }
                isLoading = false
            }
        }
    }
}
