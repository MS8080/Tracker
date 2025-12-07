import SwiftUI

// MARK: - Goal Row View (Apple Reminders Style)

struct GoalRowView: View {
    let goal: Goal
    @ObservedObject var viewModel: LifeGoalsViewModel
    let theme: AppTheme
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Circular checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                viewModel.toggleGoalComplete(goal)
                HapticFeedback.success.trigger()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(goal.isCompleted ? Color.green : priorityColor(goal.priorityLevel).opacity(0.5), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if goal.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.xs) {
                    if goal.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                    Text(goal.title)
                        .font(.body)
                        .foregroundStyle(.white)
                        .strikethrough(goal.isCompleted, color: .white.opacity(0.5))
                        .lineLimit(1)
                }

                if let notes = goal.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                if let dueDate = goal.formattedDueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(dueDate)
                            .font(.caption)
                    }
                    .foregroundStyle(goal.isOverdue ? .red : .white.opacity(0.5))
                }
            }

            Spacer()

            // Priority flag
            if goal.priorityLevel != .low {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(priorityColor(goal.priorityLevel))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                viewModel.toggleGoalPin(goal)
                HapticFeedback.light.trigger()
            } label: {
                Label(goal.isPinned ? "Unpin" : "Pin", systemImage: goal.isPinned ? "pin.slash" : "pin")
            }

            Button(role: .destructive) {
                viewModel.deleteGoal(goal)
                HapticFeedback.warning.trigger()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func priorityColor(_ priority: Goal.Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Struggle Row View

struct StruggleRowView: View {
    let struggle: Struggle
    @ObservedObject var viewModel: LifeGoalsViewModel
    let theme: AppTheme

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Intensity indicator
            Circle()
                .fill(intensityColor(struggle.intensityLevel))
                .frame(width: 12, height: 12)
                .padding(.leading, 5)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.xs) {
                    if struggle.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                    }
                    Text(struggle.title)
                        .font(.body)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                HStack(spacing: Spacing.xs) {
                    Text(struggle.intensityLevel.displayName)
                        .font(.caption)
                        .foregroundStyle(intensityColor(struggle.intensityLevel))

                    if let category = struggle.categoryType {
                        Text(".")
                            .foregroundStyle(.white.opacity(0.3))
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            Image(systemName: struggle.displayIcon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                viewModel.toggleStrugglePin(struggle)
                HapticFeedback.light.trigger()
            } label: {
                Label(struggle.isPinned ? "Unpin" : "Pin", systemImage: struggle.isPinned ? "pin.slash" : "pin")
            }

            Button {
                viewModel.resolveStruggle(struggle)
                HapticFeedback.success.trigger()
            } label: {
                Label("Mark Resolved", systemImage: "checkmark.circle")
            }

            Button(role: .destructive) {
                viewModel.deleteStruggle(struggle)
                HapticFeedback.warning.trigger()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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

// MARK: - Wishlist Row View

struct WishlistRowView: View {
    let item: WishlistItem
    @ObservedObject var viewModel: LifeGoalsViewModel
    let theme: AppTheme
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Circular checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimating = true
                }

                if !item.isAcquired {
                    CelebrationSoundPlayer.shared.playSuccess()
                    HapticFeedback.success.trigger()
                } else {
                    HapticFeedback.light.trigger()
                }

                viewModel.toggleWishlistAcquired(item)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(item.isAcquired ? Color.green : Color.pink.opacity(0.5), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if item.isAcquired {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(isAnimating ? 1.3 : 1.0)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.xs) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.pink)
                    }
                    Text(item.title)
                        .font(.body)
                        .foregroundStyle(.white)
                        .strikethrough(item.isAcquired, color: .white.opacity(0.5))
                        .lineLimit(1)
                }

                if let category = item.categoryType {
                    Text(category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            // Priority indicator (stars or flag)
            if item.priorityLevel.rawValue > 1 {
                HStack(spacing: 1) {
                    ForEach(0..<min(Int(item.priorityLevel.rawValue), 3), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                viewModel.toggleWishlistPin(item)
                HapticFeedback.light.trigger()
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }

            Button(role: .destructive) {
                viewModel.deleteWishlistItem(item)
                HapticFeedback.warning.trigger()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
