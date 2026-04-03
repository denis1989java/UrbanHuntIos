//
//  EditChallengeView.swift
//  UrbanHunt
//
//  Edit challenge screen
//

import SwiftUI
import PhotosUI

struct EditChallengeView: View {
    let challenge: Challenge
    let onChallengeUpdated: ((Challenge) -> Void)?
    let onChallengeDeleted: (() -> Void)?

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var country: String = ""
    @State private var cityName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var showActivateConfirmation = false
    @State private var hasUnsavedChanges = false
    @State private var showUnsavedChangesAlert = false

    @State private var countries: [Country] = []
    @State private var selectedCountry: Country?
    @State private var availableCities: [String] = []
    @State private var showCountryPicker = false
    @State private var showCityPicker = false
    @State private var showAddHint = false
    @State private var existingHints: [HintWithId] = []
    @State private var prizePhotoItem: PhotosPickerItem?
    @State private var prizePhoto: UIImage?
    @State private var prizePhotoUrl: String?
    @State private var editMode: EditMode = .inactive
    @State private var editingHintId: UUID?
    @State private var hintsModified = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            formFields
                            actionButtons
                        }
                        .padding()
                    }
                }

                errorMessageView
            }
            .navigationTitle("edit_challenge".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }

                if challenge.status == .draft {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if hasUnsavedChanges {
                                showUnsavedChangesAlert = true
                            } else {
                                showActivateConfirmation = true
                            }
                        }) {
                            Text("activate".localized)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerSheet(
                    countries: countries,
                    selectedCountry: $selectedCountry,
                    onSelect: { country in
                        let previousCountry = self.country
                        self.country = country.name
                        self.availableCities = country.cities
                        self.selectedCountry = country

                        // Reset city if country changed
                        if previousCountry != country.name {
                            self.cityName = ""
                        }

                        checkForUnsavedChanges()
                        showCountryPicker = false
                    }
                )
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerSheet(
                    cities: availableCities,
                    selectedCity: $cityName,
                    onSelect: { city in
                        self.cityName = city
                        checkForUnsavedChanges()
                        showCityPicker = false
                    }
                )
            }
            .sheet(isPresented: $showAddHint) {
                AddHintView(
                    challengeId: challenge.id,
                    currentHintCount: existingHints.count,
                    onHintAdded: { hint in
                        existingHints.append(HintWithId(hint: hint))
                        hintsModified = true
                        checkForUnsavedChanges()
                        showAddHint = false
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { editingHintId != nil },
                set: { if !$0 { editingHintId = nil } }
            )) {
                if let hintId = editingHintId,
                   let hintWithId = existingHints.first(where: { $0.id == hintId }),
                   let index = existingHints.firstIndex(where: { $0.id == hintId }) {
                    EditExistingHintSheet(
                        hint: hintWithId.hint,
                        onSave: { content, publishDate in
                            existingHints[index] = HintWithId(
                                id: hintWithId.id,
                                hint: Hint(
                                    content: content,
                                    link: hintWithId.hint.link,
                                    publishedAt: publishDate
                                )
                            )
                            hintsModified = true
                            checkForUnsavedChanges()
                            editingHintId = nil
                        },
                        onDelete: {
                            existingHints.remove(at: index)
                            hintsModified = true
                            checkForUnsavedChanges()
                            editingHintId = nil
                        },
                        onCancel: {
                            editingHintId = nil
                        }
                    )
                }
            }
            .modifier(AlertsModifier(
                showUnsavedChangesAlert: $showUnsavedChangesAlert,
                showActivateConfirmation: $showActivateConfirmation,
                showDeleteConfirmation: $showDeleteConfirmation,
                onSaveAndActivate: { Task { await saveAndActivate() } },
                onActivate: { Task { await activateChallenge() } },
                onDelete: { Task { await deleteChallenge() } }
            ))
            .onAppear {
                loadInitialData()
                loadCountries()
            }
        }
    }

    private var formFields: some View {
        VStack(spacing: 24) {
            statusDisplay
            countryPicker
            cityPicker
            titleField
            prizePhotoSection
            hintsSection
        }
    }

    private var countryPicker: some View {
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
    }

    private var cityPicker: some View {
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
    }

    private var titleField: some View {
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
                    let maxLength = 100
                    if newValue.count > maxLength {
                        let truncated = newValue.prefix(maxLength)
                        title = String(truncated)
                    }
                    checkForUnsavedChanges()
                }
        }
    }

    private var statusDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("status".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(statusText)
                .font(.body)
                .foregroundColor(statusColor)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
        }
    }

    private var prizePhotoSection: some View {
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
                    } else if let prizePhotoUrl = prizePhotoUrl, !prizePhotoUrl.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: prizePhotoUrl),
                            content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            },
                            placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            }
                        )

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
                        checkForUnsavedChanges()
                    }
                }
            }
        }
    }

    private var hintsSection: some View {
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

            if existingHints.isEmpty {
                Text("no_hints_added".localized)
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
            } else {
                List {
                    ForEach(existingHints) { hintWithId in
                        let index = existingHints.firstIndex(where: { $0.id == hintWithId.id }) ?? 0
                        HStack(alignment: .top, spacing: 12) {
                            if let link = hintWithId.hint.link, !link.isEmpty, let url = URL(string: link) {
                                CachedAsyncImage(
                                    url: url,
                                    content: { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    },
                                    placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(6)
                                            .overlay(
                                                ProgressView()
                                            )
                                    }
                                )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Hint \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if let publishedAt = hintWithId.hint.publishedAt {
                                        Text(formatDate(publishedAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if !hintWithId.hint.content.isEmpty {
                                    Text(hintWithId.hint.content)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editMode == .inactive {
                                editingHintId = hintWithId.id
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
                                if let index = existingHints.firstIndex(where: { $0.id == hintWithId.id }) {
                                    existingHints.remove(at: index)
                                    hintsModified = true
                                    checkForUnsavedChanges()
                                }
                            } label: {
                                Label("delete".localized, systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    .onMove { from, to in
                        existingHints.move(fromOffsets: from, toOffset: to)
                        hintsModified = true
                        checkForUnsavedChanges()
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat(existingHints.count) * 85)
                .scrollDisabled(true)
                .environment(\.editMode, $editMode)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            saveButton

            if challenge.status != .archived {
                deleteButton
            }
        }
    }

    private var saveButton: some View {
        Button(action: {
            Task {
                await saveChanges()
            }
        }) {
            Text("save_changes".localized)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasUnsavedChanges && isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(isLoading || !hasUnsavedChanges || !isFormValid)
    }

    private var deleteButton: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            Text("delete_challenge".localized)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
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

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !country.trimmingCharacters(in: .whitespaces).isEmpty &&
        !cityName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadInitialData() {
        title = challenge.title
        country = challenge.country
        cityName = challenge.cityName
        existingHints = (challenge.hints ?? []).map { HintWithId(hint: $0) }
        prizePhotoUrl = challenge.prizePhotoUrl
    }

    private func loadCountries() {
        Task {
            do {
                countries = try await APIService.shared.getCountries()
                selectedCountry = countries.first { $0.name == country }
                if let selectedCountry = selectedCountry {
                    availableCities = selectedCountry.cities
                }
            } catch {
                print("❌ Error loading countries: \(error)")
            }
        }
    }

    private func checkForUnsavedChanges() {
        let titleChanged = title != challenge.title
        let countryChanged = country != challenge.country
        let cityChanged = cityName != challenge.cityName
        let prizePhotoChanged = prizePhoto != nil
        hasUnsavedChanges = titleChanged || countryChanged || cityChanged || prizePhotoChanged || hintsModified
    }

    private func saveChanges() async {
        isLoading = true
        errorMessage = nil

        do {
            var finalPrizePhotoUrl = challenge.prizePhotoUrl

            // Upload new prize photo if selected
            if let prizePhoto = prizePhoto {
                print("⬆️ Uploading prize photo...")
                finalPrizePhotoUrl = try await StorageService.shared.uploadPrizePhoto(
                    challengeId: challenge.id,
                    image: prizePhoto
                )
                print("✅ Prize photo uploaded: \(finalPrizePhotoUrl ?? "")")
            }

            let updatedChallenge = try await APIService.shared.updateChallenge(
                challengeId: challenge.id,
                title: title.trimmingCharacters(in: .whitespaces),
                country: country.trimmingCharacters(in: .whitespaces),
                cityName: cityName.trimmingCharacters(in: .whitespaces),
                prizePhotoUrl: finalPrizePhotoUrl
            )

            await MainActor.run {
                isLoading = false
                hasUnsavedChanges = false
                prizePhotoUrl = finalPrizePhotoUrl
                self.prizePhoto = nil
                onChallengeUpdated?(updatedChallenge)
            }
        } catch {
            print("❌ Error saving changes: \(error)")
            await MainActor.run {
                if let apiError = error as? APIError {
                    errorMessage = apiError.localizedDescription
                } else {
                    errorMessage = "Failed to save changes"
                }
                isLoading = false
            }
        }
    }

    private func saveAndActivate() async {
        await saveChanges()
        if !hasUnsavedChanges {
            await activateChallenge()
        }
    }

    private func activateChallenge() async {
        isLoading = true
        errorMessage = nil

        do {
            let updatedChallenge = try await APIService.shared.updateChallengeStatus(
                challengeId: challenge.id,
                status: .active
            )

            await MainActor.run {
                isLoading = false
                onChallengeUpdated?(updatedChallenge)
                dismiss()
            }
        } catch {
            print("❌ Error activating challenge: \(error)")
            await MainActor.run {
                errorMessage = "Failed to activate challenge"
                isLoading = false
            }
        }
    }

    private func deleteChallenge() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await APIService.shared.updateChallengeStatus(
                challengeId: challenge.id,
                status: .archived
            )

            await MainActor.run {
                isLoading = false
                onChallengeDeleted?()
                dismiss()
            }
        } catch {
            print("❌ Error deleting challenge: \(error)")
            await MainActor.run {
                errorMessage = "Failed to delete challenge"
                isLoading = false
            }
        }
    }
}

struct AlertsModifier: ViewModifier {
    @Binding var showUnsavedChangesAlert: Bool
    @Binding var showActivateConfirmation: Bool
    @Binding var showDeleteConfirmation: Bool
    let onSaveAndActivate: () -> Void
    let onActivate: () -> Void
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("unsaved_changes".localized, isPresented: $showUnsavedChangesAlert) {
                Button("cancel".localized, role: .cancel) { }
                Button("save_and_activate".localized, action: onSaveAndActivate)
            } message: {
                Text("save_changes_before_activate".localized)
            }
            .alert("activate_challenge".localized, isPresented: $showActivateConfirmation) {
                Button("cancel".localized, role: .cancel) { }
                Button("activate".localized, action: onActivate)
            } message: {
                Text("activate_challenge_message".localized)
            }
            .alert("delete_challenge".localized, isPresented: $showDeleteConfirmation) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive, action: onDelete)
            } message: {
                Text("delete_challenge_message".localized)
            }
    }
}

struct HintWithId: Identifiable {
    let id: UUID
    let hint: Hint

    init(hint: Hint) {
        self.id = UUID()
        self.hint = hint
    }

    init(id: UUID, hint: Hint) {
        self.id = id
        self.hint = hint
    }
}

struct EditExistingHintSheet: View {
    let hint: Hint
    let onSave: (String, Date) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var content: String
    @State private var publishDate: Date
    @State private var publishImmediately: Bool
    @State private var showDatePicker = false

    init(hint: Hint, onSave: @escaping (String, Date) -> Void, onDelete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.hint = hint
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _content = State(initialValue: hint.content)
        _publishDate = State(initialValue: hint.publishedAt ?? Date())
        _publishImmediately = State(initialValue: abs((hint.publishedAt ?? Date()).timeIntervalSinceNow) < 60)
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

                    // Show media if exists
                    if let link = hint.link, !link.isEmpty, let url = URL(string: link) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("media_optional".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)

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
                                onSave(content, finalDate)
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
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

