import SwiftUI

// MARK: - Life Goals Section (Apple Reminders Style)

struct LifeGoalsSection: View {
    @StateObject private var viewModel = LifeGoalsViewModel()
    @ThemeWrapper var theme

    var body: some View {
        ZStack {
            VStack(spacing: Spacing.lg) {
                // List cards grid (Apple Reminders style)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md)
                ], spacing: Spacing.md) {
                    // Goals Card
                    ReminderListCard(
                        title: "Goals",
                        count: viewModel.goals.filter { !$0.isCompleted }.count,
                        icon: "flag.fill",
                        color: .orange
                    ) {
                        GoalsListView(viewModel: viewModel)
                    }

                    // Struggles Card
                    ReminderListCard(
                        title: "Struggles",
                        count: viewModel.struggles.count,
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    ) {
                        StrugglesListView(viewModel: viewModel)
                    }

                    // Wishlist Card
                    ReminderListCard(
                        title: "Wishlist",
                        count: viewModel.wishlistItems.filter { !$0.isAcquired }.count,
                        icon: "gift.fill",
                        color: .pink
                    ) {
                        WishlistListView(viewModel: viewModel)
                    }

                    // Completed Card
                    ReminderListCard(
                        title: "Completed",
                        count: viewModel.completedCount,
                        icon: "checkmark.circle.fill",
                        color: .green
                    ) {
                        CompletedListView(viewModel: viewModel)
                    }
                }

                // My Lists section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("My Lists")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xs)

                    MyListsContainer {
                        // Goals list row
                        RemindersListRow(
                            title: "Goals",
                            count: viewModel.goals.count,
                            icon: "flag.fill",
                            color: .orange
                        ) {
                            GoalsListView(viewModel: viewModel)
                        }

                        Divider()
                            .background(.white.opacity(0.1))
                            .padding(.leading, 56)

                        // Struggles list row
                        RemindersListRow(
                            title: "Struggles",
                            count: viewModel.struggles.count,
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        ) {
                            StrugglesListView(viewModel: viewModel)
                        }

                        Divider()
                            .background(.white.opacity(0.1))
                            .padding(.leading, 56)

                        // Wishlist row
                        RemindersListRow(
                            title: "Wishlist",
                            count: viewModel.wishlistItems.count,
                            icon: "gift.fill",
                            color: .pink
                        ) {
                            WishlistListView(viewModel: viewModel)
                        }
                    }
                }

                // Add List button
                AddListButton(viewModel: viewModel)
            }

            // Celebration overlay
            if viewModel.showCelebration, let item = viewModel.celebratingItem {
                CelebrationOverlay(itemTitle: item.title)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showCelebration)
    }
}

// MARK: - Reminder List Card (Grid Style)

private struct ReminderListCard<Destination: View>: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    @ViewBuilder let destination: () -> Destination
    @ThemeWrapper var theme

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)

                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Count
                    Text("\(count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.lg)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reminders List Row

private struct RemindersListRow<Destination: View>: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: Spacing.md) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(count)")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - My Lists Container (with glass effect)

private struct MyListsContainer<Content: View>: View {
    @ThemeWrapper var theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .cardStyle(theme: theme, cornerRadius: CornerRadius.lg)
    }
}

// MARK: - Add List Button

private struct AddListButton: View {
    @ObservedObject var viewModel: LifeGoalsViewModel

    var body: some View {
        Menu {
            Button {
                viewModel.showingAddGoal = true
                HapticFeedback.light.trigger()
            } label: {
                Label("New Goal", systemImage: "flag.fill")
            }

            Button {
                viewModel.showingAddStruggle = true
                HapticFeedback.light.trigger()
            } label: {
                Label("New Struggle", systemImage: "exclamationmark.triangle.fill")
            }

            Button {
                viewModel.showingAddWishlistItem = true
                HapticFeedback.light.trigger()
            } label: {
                Label("New Wish", systemImage: "gift.fill")
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add Item")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .sheet(isPresented: $viewModel.showingAddGoal) {
            AddGoalView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddStruggle) {
            AddStruggleView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddWishlistItem) {
            AddWishlistItemView(viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                LifeGoalsSection()
                    .padding()
            }
        }
    }
}
