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
                    VStack(spacing: Spacing.lg) {
                        searchBar

                        if !viewModel.favoritePatterns.isEmpty && searchText.isEmpty {
                            favoritesSection
                        }
                        allCategoriesView
                    }
                    .padding()
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
                .foregroundStyle(.secondary)

            TextField("Search categories...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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
                            _ = viewModel.quickLog(patternType: patternType)
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
                // 2-column grid layout
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
            
            HapticFeedback.medium.trigger()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: Spacing.lg) {
                // Icon
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(category.color)
                    .symbolEffect(.bounce, value: isPressed)
                    .frame(width: 44, height: 44)

                // Text
                Text(category.rawValue)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CardText.muted)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .cardStyle(theme: theme)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
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
            HStack(spacing: Spacing.lg) {
                // Icon
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.mint)
                    .frame(width: 44, height: 44)

                // Text
                Text("Guided")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CardText.muted)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .cardStyle(theme: theme)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
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
                    .foregroundStyle(CardText.body)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(theme.primaryColor)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Grid Button Components (2x4 layout)

struct CategoryGridButton: View {
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

            HapticFeedback.medium.trigger()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: Spacing.sm) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(category.color.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: category.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(category.color)
                        .symbolEffect(.bounce, value: isPressed)
                }

                // Category name
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 115)
            .cardStyle(theme: theme, cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
    }
}

struct FeelingFinderGridButton: View {
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
            VStack(spacing: Spacing.sm) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.mint.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.mint)
                        .symbolEffect(.bounce, value: isPressed)
                }

                // Label
                Text("Guided")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 115)
            .cardStyle(theme: theme, cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
    }
}

#Preview {
    LoggingView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
