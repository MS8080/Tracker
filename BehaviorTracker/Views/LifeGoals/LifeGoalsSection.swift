import SwiftUI
import AVFoundation
import AudioToolbox

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

private struct CompletedItemRow: View {
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
                        Text("•")
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

// MARK: - Celebration Sound Player

final class CelebrationSoundPlayer {
    static let shared = CelebrationSoundPlayer()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func playSuccess() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1407)
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
            ForEach(confettiPieces) { piece in
                ConfettiView(piece: piece)
            }

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
            generateConfetti()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }

    private func generateConfetti() {
        let colors: [Color] = [.yellow, .pink, .orange, .green, .blue, .purple, .red]
        for i in 0..<50 {
            confettiPieces.append(ConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .yellow,
                startX: CGFloat.random(in: 0...1),
                startY: -0.1,
                endX: CGFloat.random(in: -0.3...1.3),
                endY: CGFloat.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...720),
                delay: Double.random(in: 0...0.5),
                size: CGFloat.random(in: 6...12)
            ))
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let startX, startY, endX, endY: CGFloat
    let rotation, delay: Double
    let size: CGFloat
}

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
                    withAnimation(.easeOut(duration: 2.5).delay(piece.delay)) {
                        animate = true
                    }
                }
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
