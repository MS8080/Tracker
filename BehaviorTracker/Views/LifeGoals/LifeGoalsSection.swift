import SwiftUI

// MARK: - Life Goals Section for Home View

struct LifeGoalsSection: View {
    @StateObject private var viewModel = LifeGoalsViewModel()
    @ThemeWrapper var theme

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Goals Section
            if !viewModel.goals.isEmpty {
                goalsCard
            }

            // Struggles Section
            if !viewModel.struggles.isEmpty {
                strugglesCard
            }

            // Wishlist Section
            if !viewModel.wishlistItems.isEmpty {
                wishlistCard
            }

            // Add buttons when empty or for quick add
            addButtonsRow
        }
    }

    // MARK: - Goals Card

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text("Goals")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                if viewModel.overdueGoalsCount > 0 {
                    Text("\(viewModel.overdueGoalsCount) overdue")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.2))
                        .cornerRadius(CornerRadius.sm)
                }

                NavigationLink {
                    GoalsListView(viewModel: viewModel)
                } label: {
                    Text("See all")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .capsuleLabel(theme: theme, style: .title)

            ForEach(viewModel.goals.prefix(3)) { goal in
                GoalRowView(goal: goal, viewModel: viewModel)
            }
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    // MARK: - Struggles Card

    private var strugglesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                Text("Current Struggles")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                if viewModel.severeStrugglesCount > 0 {
                    Text("\(viewModel.severeStrugglesCount) severe")
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(.purple.opacity(0.2))
                        .cornerRadius(CornerRadius.sm)
                }

                NavigationLink {
                    StrugglesListView(viewModel: viewModel)
                } label: {
                    Text("See all")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .capsuleLabel(theme: theme, style: .title)

            ForEach(viewModel.struggles.prefix(3)) { struggle in
                StruggleRowView(struggle: struggle, viewModel: viewModel)
            }
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    // MARK: - Wishlist Card

    private var wishlistCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundStyle(.pink)
                Text("Wishlist")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                NavigationLink {
                    WishlistListView(viewModel: viewModel)
                } label: {
                    Text("See all")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .capsuleLabel(theme: theme, style: .title)

            ForEach(viewModel.wishlistItems.prefix(3)) { item in
                WishlistRowView(item: item, viewModel: viewModel)
            }
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    // MARK: - Add Buttons

    private var addButtonsRow: some View {
        HStack(spacing: Spacing.md) {
            Button {
                viewModel.showingAddGoal = true
                HapticFeedback.light.trigger()
            } label: {
                Label("Goal", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.orange.opacity(0.15))
                    .cornerRadius(CornerRadius.md)
            }

            Button {
                viewModel.showingAddStruggle = true
                HapticFeedback.light.trigger()
            } label: {
                Label("Struggle", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.red.opacity(0.15))
                    .cornerRadius(CornerRadius.md)
            }

            Button {
                viewModel.showingAddWishlistItem = true
                HapticFeedback.light.trigger()
            } label: {
                Label("Wish", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.pink)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.pink.opacity(0.15))
                    .cornerRadius(CornerRadius.md)
            }
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

// MARK: - Row Views

struct GoalRowView: View {
    let goal: Goal
    @ObservedObject var viewModel: LifeGoalsViewModel
    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
                viewModel.toggleGoalComplete(goal)
                HapticFeedback.success.trigger()
            } label: {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(goal.isCompleted ? .green : .white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .strikethrough(goal.isCompleted)

                if goal.progress > 0 && goal.progress < 1.0 {
                    ProgressView(value: goal.progress)
                        .tint(.orange)
                }

                if let dueDate = goal.formattedDueDate {
                    Text("Due: \(dueDate)")
                        .font(.caption)
                        .foregroundStyle(goal.isOverdue ? .red : .white.opacity(0.6))
                }
            }

            Spacer()

            Image(systemName: goal.displayIcon)
                .font(.caption)
                .foregroundStyle(priorityColor(goal.priorityLevel))
        }
        .padding(Spacing.sm)
        .background(.white.opacity(0.05))
        .cornerRadius(CornerRadius.sm)
    }

    private func priorityColor(_ priority: Goal.Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct StruggleRowView: View {
    let struggle: Struggle
    @ObservedObject var viewModel: LifeGoalsViewModel
    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(intensityColor(struggle.intensityLevel))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(struggle.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                HStack(spacing: Spacing.xs) {
                    Text(struggle.intensityLevel.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    if !struggle.triggersList.isEmpty {
                        Text("- \(struggle.triggersList.first ?? "")")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: struggle.displayIcon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(Spacing.sm)
        .background(.white.opacity(0.05))
        .cornerRadius(CornerRadius.sm)
    }

    private func intensityColor(_ intensity: Struggle.Intensity) -> Color {
        switch intensity {
        case .mild: return .green
        case .moderate: return .yellow
        case .significant: return .orange
        case .severe: return .red
        case .overwhelming: return .purple
        }
    }
}

struct WishlistRowView: View {
    let item: WishlistItem
    @ObservedObject var viewModel: LifeGoalsViewModel
    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
                viewModel.toggleWishlistAcquired(item)
                HapticFeedback.success.trigger()
            } label: {
                Image(systemName: item.isAcquired ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isAcquired ? .green : .white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .strikethrough(item.isAcquired)

                if let category = item.categoryType {
                    Text(category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            HStack(spacing: 2) {
                ForEach(0..<item.priorityLevel.rawValue, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(Spacing.sm)
        .background(.white.opacity(0.05))
        .cornerRadius(CornerRadius.sm)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            LifeGoalsSection()
                .padding()
        }
    }
}
