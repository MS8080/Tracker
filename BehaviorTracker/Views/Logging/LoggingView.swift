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

    private var filteredCategories: [PatternCategory] {
        if searchText.isEmpty {
            return PatternCategory.allCases
        }
        return PatternCategory.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredFavorites: [String] {
        if searchText.isEmpty {
            return viewModel.favoritePatterns
        }
        return viewModel.favoritePatterns.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Favorites
                        if !filteredFavorites.isEmpty {
                            favoritesSection
                        }
                        // All categories
                        allCategoriesView
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search categories")
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

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Favorites")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: Spacing.md) {
                ForEach(filteredFavorites, id: \.self) { patternTypeString in
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("All Categories")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: Spacing.md) {
                ForEach(filteredCategories, id: \.self) { category in
                    CategoryButton(category: category) {
                        selectedCategory = category
                    }
                }

                // Feeling Finder - only show when not searching
                if searchText.isEmpty {
                    FeelingFinderCategoryButton {
                        showingFeelingFinder = true
                    }
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
    
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            HapticFeedback.light.trigger()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: Spacing.md) {
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(category.color)
                    .symbolEffect(.bounce, value: isPressed)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct FeelingFinderCategoryButton: View {
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            HapticFeedback.medium.trigger()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        } label: {
            VStack(spacing: Spacing.md) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.mint)

                Text("Guided")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct QuickLogButton: View {
    let patternType: PatternType
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            HapticFeedback.light.trigger()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: Spacing.sm) {
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
                    .foregroundStyle(theme.primaryColor)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
}

#Preview {
    LoggingView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
