//
//  HomeView.swift
//  UrbanHunt
//
//  Home screen with user profile and challenges
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var showCreateChallenge = false
    @State private var showSideMenu = false
    @State private var showCountryFilter = false
    @State private var showCityFilter = false
    @State private var showStatusFilter = false

    var body: some View {
        LocalizedView {
            content
        }
    }

    private var statusFilterText: String {
        guard let status = viewModel.selectedStatus else {
            return "all_statuses".localized
        }
        switch status {
        case .draft:
            return "draft".localized
        case .active:
            return "status_active".localized
        case .completed:
            return "status_completed".localized
        case .archived:
            return "status_archived".localized
        }
    }

    private func statusText(_ status: Challenge.ChallengeStatus) -> String {
        switch status {
        case .draft:
            return "draft".localized
        case .active:
            return "status_active".localized
        case .completed:
            return "status_completed".localized
        case .archived:
            return "status_archived".localized
        }
    }

    private var content: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    // Top bar with burger menu and add button
                    HStack(spacing: 12) {
                        // Burger menu button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSideMenu = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                        }

                        Spacer()

                        // App title
                        Text("Urban Hunt")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Spacer()

                        // Add challenge button
                        Button(action: {
                            showCreateChallenge = true
                        }) {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(uiColor: .systemBackground))

                    Divider()

                    // Filters section
                    VStack(spacing: 12) {
                        FlowLayout(spacing: 12) {
                            // Country filter
                            Button(action: {
                                showCountryFilter = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "globe")
                                        .font(.caption)
                                    Text(viewModel.selectedCountry ?? "all_countries".localized)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(8)
                            }

                            // City filter
                            Button(action: {
                                showCityFilter = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "building.2")
                                        .font(.caption)
                                    Text(viewModel.selectedCity ?? "all_cities".localized)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(8)
                            }
                            .disabled(viewModel.selectedCountry == nil)
                            .opacity(viewModel.selectedCountry == nil ? 0.5 : 1.0)

                            // Status filter
                            Button(action: {
                                showStatusFilter = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "flag")
                                        .font(.caption)
                                    Text(statusFilterText)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(8)
                            }

                            // Clear filters button
                            if viewModel.selectedCountry != nil || viewModel.selectedCity != nil || viewModel.selectedStatus != nil {
                                Button(action: {
                                    Task {
                                        await viewModel.clearFilters()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle")
                                            .font(.caption)
                                        Text("clear".localized)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemBackground))

                    Divider()

                    // Challenges list
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                            Button("Retry") {
                                Task {
                                    await viewModel.loadChallenges()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.challenges.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("no_challenges_yet".localized)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.challenges) { challenge in
                                    ChallengeCard(challenge: challenge, viewModel: viewModel)
                                        .environmentObject(authViewModel)
                                        .onAppear {
                                            // Load more when reaching last item
                                            if challenge.id == viewModel.challenges.last?.id {
                                                Task {
                                                    await viewModel.loadMoreChallenges()
                                                }
                                            }
                                        }
                                }

                                // Loading indicator at bottom
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding()
                        }
                        .background(Color(uiColor: .systemBackground))
                        .refreshable {
                            await viewModel.refreshChallenges()
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .task {
                    await viewModel.loadChallenges()
                }
                .sheet(isPresented: $showCreateChallenge) {
                    CreateChallengeView(onChallengeCreated: { newChallenge in
                        // Add new challenge to the top of the list
                        viewModel.addNewChallenge(newChallenge)
                    })
                    .environmentObject(authViewModel)
                }
                .sheet(isPresented: $showCountryFilter) {
                    CountryFilterSheet(
                        countries: viewModel.availableCountries,
                        selectedCountry: viewModel.selectedCountry,
                        onSelect: { country in
                            showCountryFilter = false
                            Task {
                                await viewModel.filterByCountry(country)
                            }
                        }
                    )
                }
                .sheet(isPresented: $showCityFilter) {
                    CityFilterSheet(
                        cities: viewModel.availableCities,
                        selectedCity: viewModel.selectedCity,
                        onSelect: { city in
                            showCityFilter = false
                            Task {
                                await viewModel.filterByCity(city)
                            }
                        }
                    )
                }
                .sheet(isPresented: $showStatusFilter) {
                    StatusFilterSheet(
                        selectedStatus: viewModel.selectedStatus,
                        onSelect: { status in
                            showStatusFilter = false
                            Task {
                                await viewModel.filterByStatus(status)
                            }
                        }
                    )
                }
            }
            .disabled(showSideMenu)

            // Side menu overlay
            SideMenuView(isShowing: $showSideMenu)
                .environmentObject(authViewModel)
        }
    }
}

// FlowLayout for wrapping filters
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// Country Filter Sheet
struct CountryFilterSheet: View {
    let countries: [String]
    let selectedCountry: String?
    let onSelect: (String?) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                // "All Countries" option
                Button(action: {
                    onSelect(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("all_countries".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCountry == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Individual countries
                ForEach(countries.sorted(), id: \.self) { country in
                    Button(action: {
                        onSelect(country)
                        dismiss()
                    }) {
                        HStack {
                            Text(country)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCountry == country {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("filter_by_country".localized)
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

// City Filter Sheet
struct CityFilterSheet: View {
    let cities: [String]
    let selectedCity: String?
    let onSelect: (String?) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                // "All Cities" option
                Button(action: {
                    onSelect(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("all_cities".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCity == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Individual cities
                ForEach(cities.sorted(), id: \.self) { city in
                    Button(action: {
                        onSelect(city)
                        dismiss()
                    }) {
                        HStack {
                            Text(city)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCity == city {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("filter_by_city".localized)
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

// Status Filter Sheet
struct StatusFilterSheet: View {
    let selectedStatus: Challenge.ChallengeStatus?
    let onSelect: (Challenge.ChallengeStatus?) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                // "All Statuses" option
                Button(action: {
                    onSelect(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("all_statuses".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedStatus == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Active
                Button(action: {
                    onSelect(.active)
                    dismiss()
                }) {
                    HStack {
                        Text("status_active".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedStatus == .active {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Completed
                Button(action: {
                    onSelect(.completed)
                    dismiss()
                }) {
                    HStack {
                        Text("status_completed".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedStatus == .completed {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("filter_by_status".localized)
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

// Challenge card with creator info
struct ChallengeCard: View {
    let challenge: Challenge
    let viewModel: ChallengesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showHints = false
    @State private var showComments = false
    @State private var showUserProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Creator on left, Location on right
            HStack(alignment: .top) {
                // Creator info (left)
                Button(action: {
                    if challenge.createdBy != nil {
                        showUserProfile = true
                    }
                }) {
                    HStack(spacing: 8) {
                        // Profile picture
                        if let creator = challenge.creator {
                            CachedAsyncImage(
                                url: URL(string: creator.pictureUrl ?? ""),
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
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())

                            Text(creator.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                )

                            Text("unknown_user".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(challenge.createdBy == nil)

                Spacer()

                // Location info (right)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(challenge.country)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(challenge.cityName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Challenge title
            Text(challenge.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)

            // Prize photo (if available)
            if let prizePhotoUrl = challenge.prizePhotoUrl {
                CachedAsyncImage(
                    url: URL(string: prizePhotoUrl),
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                ProgressView()
                            )
                    }
                )
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            // Bottom row: Status and metadata
            HStack {
                // Status badge
                Text(statusText)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(12)

                Spacer()

                // Date
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Next hint date (if available)
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

            Divider()

            // Action buttons
            HStack(spacing: 0) {
                // Hints button
                Button(action: {
                    showHints = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb")
                            .font(.subheadline)
                        Text("hints".localized)
                            .font(.subheadline)
                        if let hints = challenge.hints, !hints.isEmpty {
                            Text("(\(hints.count))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Divider()
                    .frame(height: 20)

                // Comments button
                Button(action: {
                    showComments = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.subheadline)
                        Text("comments".localized)
                            .font(.subheadline)
                        if let count = challenge.commentsCount, count > 0 {
                            Text("(\(count))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showHints) {
            HintsView(challenge: challenge)
        }
        .sheet(isPresented: $showComments) {
            CommentsView(
                challengeId: challenge.id,
                onCommentCountChanged: { newCount in
                    viewModel.updateCommentCount(for: challenge.id, newCount: newCount)
                }
            )
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showUserProfile) {
            if let createdBy = challenge.createdBy {
                UserProfileView(userId: createdBy)
            }
        }
    }

    private var statusText: String {
        switch challenge.status {
        case .draft:
            return "draft".localized
        case .active:
            return "status_active".localized
        case .completed:
            return "status_completed".localized
        case .archived:
            return "status_archived".localized
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

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: challenge.createdAt, relativeTo: Date())
    }

    private func formatNextHintDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}