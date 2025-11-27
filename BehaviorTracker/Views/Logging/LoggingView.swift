import SwiftUI
import Speech

struct LoggingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = LoggingViewModel()
    @State private var selectedCategory: PatternCategory?
    @State private var showingQuickLog = false
    @State private var showingCrisisMode = false
    @State private var showingFeelingFinder = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedPatternType: PatternType?
    @Binding var showingProfile: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    // Filter patterns based on search text
    private var filteredPatterns: [PatternType] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return PatternType.allCases.filter { pattern in
            pattern.rawValue.lowercased().contains(query) ||
            pattern.category.rawValue.lowercased().contains(query)
        }
    }

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        // Pull hint when not searching
                        if !isSearching {
                            pullToSearchHint
                        }

                        // Search bar
                        if isSearching {
                            searchBarView
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Search results or normal content
                        if !searchText.isEmpty {
                            searchResultsView
                        } else {
                            // Favorites
                            if !viewModel.favoritePatterns.isEmpty {
                                favoritesSection
                            }
                            // All categories
                            allCategoriesView
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingCrisisMode = true
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .onAppear {
                viewModel.loadFavorites()
                viewModel.loadRecentEntries()
            }
            .task {
                await viewModel.requestHealthKitAuthorization()
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryLoggingView(category: category, viewModel: viewModel)
        }
        .sheet(isPresented: $showingCrisisMode) {
            CrisisModeView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingFeelingFinder) {
            FeelingFinderView()
        }
        .sheet(item: $selectedPatternType) { patternType in
            PatternEntryFormView(
                patternType: patternType,
                viewModel: viewModel,
                onSave: {
                    selectedPatternType = nil
                    withAnimation {
                        searchText = ""
                        isSearching = false
                    }
                }
            )
        }
    }

    // MARK: - Pull to Search Hint
    private var pullToSearchHint: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                isSearching = true
            }
            HapticFeedback.light.trigger()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                Text("Search patterns")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(white: 0.2).opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            // Cancel button to hide search
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    searchText = ""
                    isSearching = false
                }
            } label: {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(white: 0.18).opacity(0.9))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Search Results
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if filteredPatterns.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No patterns found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                Text("\(filteredPatterns.count) results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                LazyVStack(spacing: 8) {
                    ForEach(filteredPatterns) { pattern in
                        SearchResultRow(pattern: pattern) {
                            selectedPatternType = pattern
                        }
                    }
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorites")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                ForEach(viewModel.favoritePatterns, id: \.self) { patternTypeString in
                    if let patternType = PatternType(rawValue: patternTypeString) {
                        QuickLogButton(patternType: patternType) {
                            _ = viewModel.quickLog(patternType: patternType)
                        }
                    }
                }
            }
        }
    }

    private var allCategoriesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Categories")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                ForEach(PatternCategory.allCases, id: \.self) { category in
                    CategoryButton(category: category) {
                        selectedCategory = category
                    }
                }

                // Feeling Finder as 8th category
                FeelingFinderCategoryButton {
                    showingFeelingFinder = true
                }
            }
        }
    }
}

struct CategoryButton: View {
    let category: PatternCategory
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(category.color)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.18).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(category.color.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: category.color.opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct FeelingFinderCategoryButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium.trigger()
            action()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.green)

                Text("Guided")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.18).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.green.opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct QuickLogButton: View {
    let patternType: PatternType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: patternType.category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(patternType.category.color)

                Text(patternType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.18).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(patternType.category.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: patternType.category.color.opacity(0.15), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let pattern: PatternType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: pattern.category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(pattern.category.color)
                    .frame(width: 36)

                // Pattern info
                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(pattern.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.18).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(pattern.category.color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Crisis Mode View

struct CrisisModeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LoggingViewModel
    @State private var selectedAction: CrisisAction?

    enum CrisisAction: String, CaseIterable {
        case meltdown = "Meltdown"
        case shutdown = "Shutdown"
        case overwhelm = "Overwhelmed"
        case needBreak = "Need a Break"

        var icon: String {
            switch self {
            case .meltdown: return "flame.fill"
            case .shutdown: return "poweroff"
            case .overwhelm: return "exclamationmark.triangle.fill"
            case .needBreak: return "pause.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .meltdown: return .red
            case .shutdown: return .purple
            case .overwhelm: return .orange
            case .needBreak: return .blue
            }
        }

        var patternType: PatternType {
            switch self {
            case .meltdown: return .meltdown
            case .shutdown: return .shutdown
            case .overwhelm: return .emotionalOverwhelm
            case .needBreak: return .sensoryRecovery
            }
        }

        var helpText: String {
            switch self {
            case .meltdown: return "It's okay. This will pass. Try to find a quiet space."
            case .shutdown: return "Give yourself permission to rest. You don't have to respond."
            case .overwhelm: return "One thing at a time. What's the smallest next step?"
            case .needBreak: return "Taking breaks is essential, not optional."
            }
        }
    }

    // Warm red gradient for warning feel
    private var warningGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.15, blue: 0.1),
                Color(red: 0.4, green: 0.1, blue: 0.08),
                Color(red: 0.25, green: 0.08, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            warningGradient
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                        .padding(.bottom, 8)

                    Text("What's happening?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Tap to log. Take your time.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 40)

                // Crisis buttons - large, easy to tap
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(CrisisAction.allCases, id: \.self) { action in
                        CrisisButton(action: action, isSelected: selectedAction == action) {
                            selectedAction = action
                            _ = viewModel.quickLog(patternType: action.patternType, intensity: 4)

                            // Show help text briefly then dismiss
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Help text
                if let action = selectedAction {
                    Text(action.helpText)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.2).opacity(0.6))
                        )
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .scale))
                }

                Spacer()

                // Quick exit
                Button {
                    dismiss()
                } label: {
                    Text("I'm okay")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(white: 0.2).opacity(0.6))
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}

struct CrisisButton: View {
    let action: CrisisModeView.CrisisAction
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: action.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(action.color)

                Text(action.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? action.color.opacity(0.3) : .white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isSelected ? action.color : .clear, lineWidth: 3)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    LoggingView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
