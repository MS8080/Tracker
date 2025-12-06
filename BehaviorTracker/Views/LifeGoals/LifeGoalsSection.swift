import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Life Goals Section for Home View

struct LifeGoalsSection: View {
    @StateObject private var viewModel = LifeGoalsViewModel()
    @ThemeWrapper var theme

    var body: some View {
        ZStack {
            VStack(spacing: Spacing.md) {
                // Goals Section
                GoalsSectionCard(viewModel: viewModel, theme: theme)

                // Struggles Section
                StrugglesSectionCard(viewModel: viewModel, theme: theme)

                // Wishlist Section
                WishlistSectionCard(viewModel: viewModel, theme: theme)

                // Add buttons
                addButtonsRow
            }

            // Celebration overlay
            if viewModel.showCelebration, let item = viewModel.celebratingItem {
                CelebrationOverlay(itemTitle: item.title)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showCelebration)
    }

    // MARK: - Add Buttons

    private var addButtonsRow: some View {
        HStack(spacing: Spacing.md) {
            AddItemButton(
                label: "Goal",
                icon: "plus.circle.fill",
                color: .orange
            ) {
                viewModel.showingAddGoal = true
                HapticFeedback.light.trigger()
            }

            AddItemButton(
                label: "Struggle",
                icon: "plus.circle.fill",
                color: .red
            ) {
                viewModel.showingAddStruggle = true
                HapticFeedback.light.trigger()
            }

            AddItemButton(
                label: "Wish",
                icon: "plus.circle.fill",
                color: .pink
            ) {
                viewModel.showingAddWishlistItem = true
                HapticFeedback.light.trigger()
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

// MARK: - Add Item Button

private struct AddItemButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(color.opacity(0.15))
                .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Goals Section Card

private struct GoalsSectionCard: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            SectionHeader(
                icon: "flag.fill",
                iconColor: .orange,
                title: "Goals",
                badge: viewModel.overdueGoalsCount > 0 ? "\(viewModel.overdueGoalsCount) overdue" : nil,
                badgeColor: .red,
                theme: theme
            ) {
                NavigationLink {
                    GoalsListView(viewModel: viewModel)
                } label: {
                    Text("See all")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            if !viewModel.goals.isEmpty {
                Divider()
                    .background(.white.opacity(0.1))
                    .padding(.horizontal, Spacing.lg)

                // Goal rows
                VStack(spacing: 0) {
                    ForEach(viewModel.goals.prefix(3)) { goal in
                        GoalRowView(goal: goal, viewModel: viewModel, theme: theme)

                        if goal.id != viewModel.goals.prefix(3).last?.id {
                            Divider()
                                .background(.white.opacity(0.08))
                                .padding(.leading, 56)
                        }
                    }
                }
            } else {
                EmptyStateRow(message: "No active goals", icon: "flag")
            }
        }
        .cardStyle(theme: theme)
    }
}

// MARK: - Struggles Section Card

private struct StrugglesSectionCard: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            SectionHeader(
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Struggles",
                badge: viewModel.severeStrugglesCount > 0 ? "\(viewModel.severeStrugglesCount) severe" : nil,
                badgeColor: .purple,
                theme: theme
            ) {
                NavigationLink {
                    StrugglesListView(viewModel: viewModel)
                } label: {
                    Text("See all")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            if !viewModel.struggles.isEmpty {
                Divider()
                    .background(.white.opacity(0.1))
                    .padding(.horizontal, Spacing.lg)

                // Struggle rows
                VStack(spacing: 0) {
                    ForEach(viewModel.struggles.prefix(3)) { struggle in
                        StruggleRowView(struggle: struggle, viewModel: viewModel, theme: theme)

                        if struggle.id != viewModel.struggles.prefix(3).last?.id {
                            Divider()
                                .background(.white.opacity(0.08))
                                .padding(.leading, 56)
                        }
                    }
                }
            } else {
                EmptyStateRow(message: "No active struggles", icon: "heart")
            }
        }
        .cardStyle(theme: theme)
    }
}

// MARK: - Wishlist Section Card

private struct WishlistSectionCard: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            SectionHeader(
                icon: "gift.fill",
                iconColor: .pink,
                title: "Wishlist",
                badge: nil,
                badgeColor: .clear,
                theme: theme
            ) {
                NavigationLink {
                    WishlistListView(viewModel: viewModel)
                } label: {
                    Text("See all")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            if !viewModel.wishlistItems.isEmpty {
                Divider()
                    .background(.white.opacity(0.1))
                    .padding(.horizontal, Spacing.lg)

                // Wishlist rows
                VStack(spacing: 0) {
                    ForEach(viewModel.wishlistItems.prefix(3)) { item in
                        WishlistRowView(item: item, viewModel: viewModel, theme: theme)

                        if item.id != viewModel.wishlistItems.prefix(3).last?.id {
                            Divider()
                                .background(.white.opacity(0.08))
                                .padding(.leading, 56)
                        }
                    }
                }
            } else {
                EmptyStateRow(message: "Your wishlist is empty", icon: "gift")
            }
        }
        .cardStyle(theme: theme)
    }
}

// MARK: - Section Header

private struct SectionHeader<TrailingContent: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let badge: String?
    let badgeColor: Color
    let theme: AppTheme
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()

            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.2))
                    .cornerRadius(CornerRadius.sm)
            }

            trailingContent()
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Empty State Row

private struct EmptyStateRow: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 24)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Goal Row View (Apple Reminders Style)

struct GoalRowView: View {
    let goal: Goal
    @ObservedObject var viewModel: LifeGoalsViewModel
    let theme: AppTheme
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Circular checkbox (Apple Reminders style)
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
                        .frame(width: 24, height: 24)

                    if goal.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    if goal.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                    Text(goal.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .strikethrough(goal.isCompleted, color: .white.opacity(0.5))
                        .lineLimit(1)
                }

                if goal.progress > 0 && goal.progress < 1.0 {
                    ProgressView(value: goal.progress)
                        .tint(.orange)
                        .frame(maxWidth: 120)
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

            // Priority indicator
            Image(systemName: goal.displayIcon)
                .font(.caption)
                .foregroundStyle(priorityColor(goal.priorityLevel))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
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
        case .low: return .green
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
            // Intensity indicator circle
            Circle()
                .fill(intensityColor(struggle.intensityLevel))
                .frame(width: 12, height: 12)
                .padding(.leading, 6)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    if struggle.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                    }
                    Text(struggle.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                HStack(spacing: Spacing.xs) {
                    Text(struggle.intensityLevel.displayName)
                        .font(.caption)
                        .foregroundStyle(intensityColor(struggle.intensityLevel))

                    if let category = struggle.categoryType {
                        Text("• \(category.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            // Category icon
            Image(systemName: struggle.displayIcon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
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
            // Circular checkbox with celebration trigger
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimating = true
                }

                // Play celebration sound and trigger haptic
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
                        .frame(width: 24, height: 24)

                    if item.isAcquired {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(isAnimating ? 1.3 : 1.0)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.pink)
                    }
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
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

            // Priority stars
            HStack(spacing: 2) {
                ForEach(0..<Int(item.priorityLevel.rawValue), id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
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

// MARK: - Celebration Sound Player

final class CelebrationSoundPlayer {
    static let shared = CelebrationSoundPlayer()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func playSuccess() {
        // Try system sound first
        #if os(iOS)
        AudioServicesPlaySystemSound(1407) // Celebration sound
        #endif
    }
}

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    let itemTitle: String
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Confetti
            ForEach(confettiPieces) { piece in
                ConfettiView(piece: piece)
            }

            // Celebration message
            if showContent {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 10)

                    Text("You got it!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(itemTitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .padding(Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.5), .pink.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
        .onAppear {
            // Generate confetti
            generateConfetti()

            // Show content with delay
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }

    private func generateConfetti() {
        let colors: [Color] = [.yellow, .pink, .orange, .green, .blue, .purple, .red]

        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .yellow,
                startX: CGFloat.random(in: 0...1),
                startY: -0.1,
                endX: CGFloat.random(in: -0.3...1.3),
                endY: CGFloat.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...720),
                delay: Double.random(in: 0...0.5),
                size: CGFloat.random(in: 6...12)
            )
            confettiPieces.append(piece)
        }
    }
}

// MARK: - Confetti Piece Model

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let delay: Double
    let size: CGFloat
}

// MARK: - Confetti View

struct ConfettiView: View {
    let piece: ConfettiPiece
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2)
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size * 1.5)
                .position(
                    x: geometry.size.width * (animate ? piece.endX : piece.startX),
                    y: geometry.size.height * (animate ? piece.endY : piece.startY)
                )
                .rotationEffect(.degrees(animate ? piece.rotation : 0))
                .opacity(animate ? 0 : 1)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 2.5)
                        .delay(piece.delay)
                    ) {
                        animate = true
                    }
                }
        }
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
