import SwiftUI

// MARK: - Completed List View

struct CompletedListView: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    @ThemeWrapper var theme

    var completedGoals: [Goal] {
        viewModel.goals.filter { $0.isCompleted }
    }

    var acquiredItems: [WishlistItem] {
        viewModel.wishlistItems.filter { $0.isAcquired }
    }

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if completedGoals.isEmpty && acquiredItems.isEmpty {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))

                            Text("No completed items yet")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        // Completed Goals
                        if !completedGoals.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Goals")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, Spacing.xs)

                                VStack(spacing: 0) {
                                    ForEach(completedGoals) { goal in
                                        CompletedItemRow(
                                            title: goal.title,
                                            icon: "flag.fill",
                                            color: .orange,
                                            onUncomplete: {
                                                viewModel.toggleGoalComplete(goal)
                                            }
                                        )

                                        if goal.id != completedGoals.last?.id {
                                            Divider()
                                                .background(.white.opacity(0.1))
                                                .padding(.leading, 56)
                                        }
                                    }
                                }
                                .cardStyle(theme: theme, cornerRadius: CornerRadius.lg)
                            }
                        }

                        // Acquired Wishlist Items
                        if !acquiredItems.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Wishlist")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, Spacing.xs)

                                VStack(spacing: 0) {
                                    ForEach(acquiredItems) { item in
                                        CompletedItemRow(
                                            title: item.title,
                                            icon: "gift.fill",
                                            color: .pink,
                                            onUncomplete: {
                                                viewModel.toggleWishlistAcquired(item)
                                            }
                                        )

                                        if item.id != acquiredItems.last?.id {
                                            Divider()
                                                .background(.white.opacity(0.1))
                                                .padding(.leading, 56)
                                        }
                                    }
                                }
                                .cardStyle(theme: theme, cornerRadius: CornerRadius.lg)
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .navigationTitle("Completed")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Completed Item Row

struct CompletedItemRow: View {
    let title: String
    let icon: String
    let color: Color
    let onUncomplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checked circle
            Button(action: onUncomplete) {
                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
                .strikethrough(true, color: .white.opacity(0.3))

            Spacer()

            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color.opacity(0.5))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
    }
}
