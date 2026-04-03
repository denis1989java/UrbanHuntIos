//
//  CreateChallengeView.swift
//  UrbanHunt
//
//  Create challenge screen
//

import SwiftUI
import PhotosUI

struct HintItem: Identifiable {
    let id = UUID()
    let content: String
    let image: UIImage?
    let publishDate: Date
}

struct CreateChallengeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    let onChallengeCreated: ((Challenge) -> Void)?

    @State private var title: String = ""
    @State private var country: String = ""
    @State private var cityName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var countries: [Country] = []
    @State private var selectedCountry: Country?
    @State private var availableCities: [String] = []
    @State private var showCountryPicker = false
    @State private var showCityPicker = false
    @State private var showAddHint = false
    @State private var hints: [HintItem] = []
    @State private var editMode: EditMode = .inactive
    @State private var editingHintId: UUID?
    @State private var prizePhotoItem: PhotosPickerItem?
    @State private var prizePhoto: UIImage?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Country Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("country".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Button(action: {
                            showCountryPicker = true
                        }) {
                            HStack {
                                Text(country.isEmpty ? "select_country".localized : country)
                                    .foregroundColor(country.isEmpty ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // City Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("city".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Button(action: {
                            if !availableCities.isEmpty {
                                showCityPicker = true
                            }
                        }) {
                            HStack {
                                Text(cityName.isEmpty ? "select_city".localized : cityName)
                                    .foregroundColor(cityName.isEmpty ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(availableCities.isEmpty)
                        .opacity(availableCities.isEmpty ? 0.5 : 1.0)
                    }

                    // Challenge Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("challenge_name".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("enter_challenge_title".localized, text: $title)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: title) { _, newValue in
                                if newValue.count > 100 {
                                    title = String(newValue.prefix(100))
                                }
                            }
                    }

                    // Prize Photo Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("prize_photo".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        PhotosPicker(selection: $prizePhotoItem, matching: .images) {
                            HStack {
                                if let image = prizePhoto {
                                    Image(uiImage: image)
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
                                    Text("select_prize_photo".localized)
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
                        .onChange(of: prizePhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    prizePhoto = image
                                }
                            }
                        }
                    }

                    // Hints Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("hints".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                showAddHint = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                    Text("add_hint".localized)
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                            }
                        }

                        if hints.isEmpty {
                            Text("no_hints_added".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            List {
                                ForEach(hints) { hint in
                                    HStack(alignment: .top, spacing: 12) {
                                        if let image = hint.image {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(hint.content)
                                                .font(.body)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Text(formatDate(hint.publishDate))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if editMode == .inactive {
                                            editingHintId = hint.id
                                        }
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        withAnimation {
                                            editMode = .active
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            if let index = hints.firstIndex(where: { $0.id == hint.id }) {
                                                hints.remove(at: index)
                                            }
                                        } label: {
                                            Label("delete".localized, systemImage: "trash")
                                        }
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                    .listRowBackground(Color.clear)
                                }
                                .onMove { from, to in
                                    hints.move(fromOffsets: from, toOffset: to)
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(hints.count) * 85)
                            .scrollDisabled(true)
                            .environment(\.editMode, $editMode)
                        }
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Action Buttons
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

                        Button(action: saveChallenge) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("save".localized)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSave ? Color.primary : Color.gray.opacity(0.4))
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .disabled(!canSave || isLoading)
                    }
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("create_challenge".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                loadCountries()
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerSheet(
                    countries: countries,
                    selectedCountry: $selectedCountry,
                    onSelect: { countryItem in
                        selectedCountry = countryItem
                        country = countryItem.name
                        availableCities = countryItem.cities
                        cityName = ""
                        showCountryPicker = false
                    }
                )
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerSheet(
                    cities: availableCities,
                    selectedCity: $cityName,
                    onSelect: { city in
                        cityName = city
                        showCityPicker = false
                    }
                )
            }
            .sheet(isPresented: $showAddHint) {
                AddHintSheet(onAdd: { content, image, publishDate in
                    print("🔄 Adding hint: \(content)")
                    hints.append(HintItem(content: content, image: image, publishDate: publishDate))
                    print("✅ Total hints: \(hints.count)")
                    showAddHint = false
                })
            }
            .sheet(item: $editingHintId) { hintId in
                if let hintIndex = hints.firstIndex(where: { $0.id == hintId }) {
                    EditHintSheet(
                        hint: hints[hintIndex],
                        onSave: { content, image, publishDate in
                            hints[hintIndex] = HintItem(content: content, image: image, publishDate: publishDate)
                            editingHintId = nil
                        },
                        onDelete: {
                            hints.remove(at: hintIndex)
                            editingHintId = nil
                        },
                        onCancel: {
                            editingHintId = nil
                        }
                    )
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !country.isEmpty &&
        !cityName.isEmpty
    }

    private func loadCountries() {
        Task {
            do {
                countries = try await APIService.shared.getCountries()
                print("✅ Loaded \(countries.count) countries")
            } catch {
                print("❌ Error loading countries: \(error)")
                errorMessage = "Failed to load countries"
            }
        }
    }

    private func saveChallenge() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Upload prize photo first if present
                var prizePhotoUrl: String? = nil
                if let prizeImage = prizePhoto {
                    print("⬆️ Uploading prize photo...")
                    // Use a temporary challenge ID for upload
                    let tempChallengeId = UUID().uuidString
                    prizePhotoUrl = try await StorageService.shared.uploadPrizePhoto(
                        challengeId: tempChallengeId,
                        image: prizeImage
                    )
                    print("✅ Prize photo uploaded: \(prizePhotoUrl ?? "")")
                }

                // Create challenge with prize photo URL
                let challenge = try await APIService.shared.createChallenge(
                    title: title.trimmingCharacters(in: .whitespaces),
                    country: country.trimmingCharacters(in: .whitespaces),
                    cityName: cityName.trimmingCharacters(in: .whitespaces),
                    prizePhotoUrl: prizePhotoUrl
                )

                print("✅ Challenge created: \(challenge.id)")

                // Upload hint media and add hints to challenge
                for (index, hint) in hints.enumerated() {
                    var mediaLink: String? = nil

                    // Upload image if present
                    if let image = hint.image {
                        print("⬆️ Uploading hint \(index) media...")
                        mediaLink = try await StorageService.shared.uploadHintMedia(
                            challengeId: challenge.id,
                            hintIndex: index,
                            image: image
                        )
                        print("✅ Hint \(index) media uploaded: \(mediaLink ?? "")")
                    }

                    // Add hint to challenge with user's selected date (in their timezone)
                    _ = try await APIService.shared.addHint(
                        challengeId: challenge.id,
                        content: hint.content,
                        link: mediaLink,
                        publishedAt: hint.publishDate
                    )
                    print("✅ Hint \(index) added to challenge")
                }

                await MainActor.run {
                    isLoading = false
                    // Notify parent with the new challenge
                    onChallengeCreated?(challenge)
                    dismiss()
                }
            } catch let apiError as APIError {
                print("❌ Error creating challenge: \(apiError)")
                await MainActor.run {
                    // Check if it's a profanity error
                    if case .serverError(let message) = apiError {
                        if message.contains("Inappropriate content") {
                            errorMessage = "inappropriate_content".localized
                        } else if message.contains("must have either") {
                            errorMessage = "hint_requires_content".localized
                        } else {
                            errorMessage = message
                        }
                    } else {
                        errorMessage = apiError.localizedDescription
                    }
                    isLoading = false
                }
            } catch {
                print("❌ Error creating challenge: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    CreateChallengeView(onChallengeCreated: nil)
}

// MARK: - Country Picker Sheet

struct CountryPickerSheet: View {
    let countries: [Country]
    @Binding var selectedCountry: Country?
    let onSelect: (Country) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(countries.sorted { $0.name < $1.name }) { country in
                    Button(action: {
                        onSelect(country)
                    }) {
                        HStack {
                            Text(country.name)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(.plain)
            .navigationTitle("country".localized)
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
}

// MARK: - City Picker Sheet

struct CityPickerSheet: View {
    let cities: [String]
    @Binding var selectedCity: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(cities.sorted(), id: \.self) { city in
                    Button(action: {
                        onSelect(city)
                    }) {
                        HStack {
                            Text(city)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(.plain)
            .navigationTitle("city".localized)
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
}

// MARK: - Add Hint Sheet

struct AddHintSheet: View {
    let onAdd: (String, UIImage?, Date) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var content: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var publishDate = Date()
    @State private var publishImmediately = true
    @State private var showDatePicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hint Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("hint_text".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("enter_hint".localized, text: $content, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Photo/Video Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("media_optional".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                            HStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
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
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImage = image
                                }
                            }
                        }
                    }

                    // Publish Immediately Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("publish_immediately".localized, isOn: $publishImmediately)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Publish Date Picker (only if not immediate)
                    if !publishImmediately {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("publish_date".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    Text(formatDate(publishDate))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Spacer()

                    // Action Buttons
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

                        Button(action: {
                            let finalDate = publishImmediately ? Date() : publishDate
                            onAdd(content, selectedImage, finalDate)
                        }) {
                            Text("add".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canAdd ? Color.primary : Color.gray.opacity(0.4))
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                        }
                        .disabled(!canAdd)
                    }
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
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
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    VStack {
                        DatePicker(
                            "select_date_and_time".localized,
                            selection: $publishDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding()

                        Spacer()

                        Button(action: {
                            showDatePicker = false
                        }) {
                            Text("done".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.primary)
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .navigationTitle("select_date".localized)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showDatePicker = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var canAdd: Bool {
        let hasContent = !content.trimmingCharacters(in: .whitespaces).isEmpty
        let hasImage = selectedImage != nil
        return hasContent || hasImage
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Edit Hint Sheet

struct EditHintSheet: View {
    let hint: HintItem
    let onSave: (String, UIImage?, Date) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var content: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var publishDate: Date
    @State private var publishImmediately: Bool
    @State private var showDatePicker = false

    init(hint: HintItem, onSave: @escaping (String, UIImage?, Date) -> Void, onDelete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.hint = hint
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _content = State(initialValue: hint.content)
        _selectedImage = State(initialValue: hint.image)
        _publishDate = State(initialValue: hint.publishDate)
        _publishImmediately = State(initialValue: abs(hint.publishDate.timeIntervalSinceNow) < 60)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hint Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("hint_text".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("enter_hint".localized, text: $content, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Photo/Video Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("media_optional".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                            HStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
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
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImage = image
                                }
                            }
                        }
                    }

                    // Publish Immediately Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("publish_immediately".localized, isOn: $publishImmediately)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Publish Date Picker (only if not immediate)
                    if !publishImmediately {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("publish_date".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    Text(formatDate(publishDate))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Button(action: onCancel) {
                                Text("cancel".localized)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }

                            Button(action: {
                                let finalDate = publishImmediately ? Date() : publishDate
                                onSave(content, selectedImage, finalDate)
                            }) {
                                Text("save".localized)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(canSave ? Color.primary : Color.gray.opacity(0.4))
                                    .foregroundColor(Color(uiColor: .systemBackground))
                                    .cornerRadius(8)
                            }
                            .disabled(!canSave)
                        }

                        Button(action: onDelete) {
                            Text("delete_hint".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("edit_hint".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    VStack {
                        DatePicker(
                            "select_date_and_time".localized,
                            selection: $publishDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding()

                        Spacer()

                        Button(action: {
                            showDatePicker = false
                        }) {
                            Text("done".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.primary)
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .navigationTitle("select_date".localized)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showDatePicker = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        let hasContent = !content.trimmingCharacters(in: .whitespaces).isEmpty
        let hasImage = selectedImage != nil
        return hasContent || hasImage
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension UUID: Identifiable {
    public var id: UUID { self }
}
