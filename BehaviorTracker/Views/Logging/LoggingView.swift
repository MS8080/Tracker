import SwiftUI

struct LoggingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = LoggingViewModel()
    @State private var selectedCategory: PatternCategory?
    @State private var showingQuickLog = false
    @Binding var showingProfile: Bool

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.favoritePatterns.isEmpty {
                        allCategoriesView
                    } else {
                        favoritesSection
                        allCategoriesView
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Log Pattern")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .onAppear {
                viewModel.loadFavorites()
            }
            .task {
                await viewModel.requestHealthKitAuthorization()
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryLoggingView(category: category, viewModel: viewModel)
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
                            viewModel.quickLog(patternType: patternType)
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
            }
        }
    }
}

struct CategoryButton: View {
    let category: PatternCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(category.color)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
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
                    .font(.system(size: 20))
                    .foregroundStyle(patternType.category.color)

                Text(patternType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoggingView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
