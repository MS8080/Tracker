import SwiftUI

struct LoggingView: View {
    @StateObject private var viewModel = LoggingViewModel()
    @State private var selectedCategory: PatternCategory?
    @State private var showingFeelingFinder = false
    @State private var searchText = ""
    @Binding var showingProfile: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    /// Filter categories based on search text
    private var filteredCategories: [PatternCategory] {
        if searchText.isEmpty {
            return PatternCategory.allCases
        }
        return PatternCategory.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Check if "Guided" should show based on search
    private var showGuided: Bool {
        searchText.isEmpty || "guided".localizedCaseInsensitiveContains(searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        searchBar

                        if !viewModel.favoritePatterns.isEmpty && searchText.isEmpty {
                            favoritesSection
                        }
                        allCategoriesView
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.lg)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log")
            .toolbar {
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
        .sheet(isPresented: $showingFeelingFinder) {
            FeelingFinderView()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.6))

            TextField("Search categories...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Favorites")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: Spacing.md) {
                ForEach(viewModel.favoritePatterns, id: \.self) { patternTypeString in
                    if let patternType = PatternType(rawValue: patternTypeString) {
                        QuickLogButton(patternType: patternType) {
                            Task {
                                _ = await viewModel.quickLog(patternType: patternType)
                            }
                        }
                    }
                }
            }
        }
    }

    private var allCategoriesView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if filteredCategories.isEmpty && !showGuided {
                // No results
                VStack(spacing: Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No categories found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                // 2-column grid layout - compact to fit all on screen
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md)
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(filteredCategories, id: \.self) { category in
                        CategoryGridButton(category: category) {
                            selectedCategory = category
                        }
                    }

                    if showGuided {
                        FeelingFinderGridButton {
                            showingFeelingFinder = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LoggingView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
