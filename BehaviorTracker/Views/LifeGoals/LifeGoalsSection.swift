import SwiftUI

// MARK: - Life Goals Section (Apple Reminders Style)

struct LifeGoalsSection: View {
    @StateObject private var viewModel = LifeGoalsViewModel()
    @StateObject private var remindersService = RemindersService.shared
    @AppStorage("lifeGoalsSectionExpanded") private var isExpanded = true
    @Namespace private var heroAnimation
    @State private var showingSyncSettings = false
    @ThemeWrapper var theme

    var body: some View {
        ZStack {
            VStack(spacing: Spacing.md) {
                // Header with collapse toggle
                sectionHeader

                // Collapsible content
                if isExpanded {
                    // Demo mode indicator
                    if viewModel.isDemoMode {
                        demoModeIndicator
                    }

                    // List cards grid (Apple Reminders style)
                    cardsGrid

                    // Add Item button
                    AddListButton(viewModel: viewModel)
                }
            }

            // Celebration overlay
            if viewModel.showCelebration, let item = viewModel.celebratingItem {
                CelebrationOverlay(itemTitle: item.title)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showCelebration)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Button {
                HapticFeedback.light.trigger()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                        .font(.title2)
                        .foregroundStyle(theme.primaryColor)

                    Text("My Lists")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    // Total count badge
                    let totalCount = viewModel.goalsCount + viewModel.strugglesCount + viewModel.wishlistCount
                    if totalCount > 0 {
                        Text("\(totalCount)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.1), in: Capsule())
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Sync button
            Button {
                HapticFeedback.light.trigger()
                showingSyncSettings = true
            } label: {
                Image(systemName: remindersService.isSyncEnabled ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle")
                    .font(.title2)
                    .foregroundStyle(remindersService.isSyncEnabled ? .green : .white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.sm)
        .sheet(isPresented: $showingSyncSettings) {
            RemindersSyncSettingsView(remindersService: remindersService, viewModel: viewModel)
        }
    }

    // MARK: - Demo Mode Indicator

    private var demoModeIndicator: some View {
        HStack {
            Image(systemName: "play.rectangle.fill")
                .foregroundStyle(.orange)
            Text("Demo Mode - Sample Data")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.2), in: Capsule())
    }

    // MARK: - Cards Grid

    private var cardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.md),
            GridItem(.flexible(), spacing: Spacing.md)
        ], spacing: Spacing.md) {
            // Goals Card
            HeroReminderCard(
                title: "Goals",
                count: viewModel.goalsCount,
                icon: "flag.fill",
                color: .orange,
                cardID: "goals",
                namespace: heroAnimation
            ) {
                GoalsListView(viewModel: viewModel)
            }

            // Struggles Card
            HeroReminderCard(
                title: "Struggles",
                count: viewModel.strugglesCount,
                icon: "exclamationmark.triangle.fill",
                color: .red,
                cardID: "struggles",
                namespace: heroAnimation
            ) {
                StrugglesListView(viewModel: viewModel)
            }

            // Wishlist Card
            HeroReminderCard(
                title: "Wishlist",
                count: viewModel.wishlistCount,
                icon: "gift.fill",
                color: .pink,
                cardID: "wishlist",
                namespace: heroAnimation
            ) {
                WishlistListView(viewModel: viewModel)
            }

            // Completed Card
            HeroReminderCard(
                title: "Completed",
                count: viewModel.completedCount,
                icon: "checkmark.circle.fill",
                color: .green,
                cardID: "completed",
                namespace: heroAnimation
            ) {
                CompletedListView(viewModel: viewModel)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Hero Reminder Card

private struct HeroReminderCard<Destination: View>: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let cardID: String
    let namespace: Namespace.ID
    @ViewBuilder let destination: () -> Destination
    @ThemeWrapper var theme

    var body: some View {
        NavigationLink {
            destination()
                .navigationTransition(.zoom(sourceID: cardID, in: namespace))
        } label: {
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
        .matchedTransitionSource(id: cardID, in: namespace)
        .buttonStyle(ScaleButtonStyle())
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

// MARK: - Reminders Sync Settings View

struct RemindersSyncSettingsView: View {
    @ObservedObject var remindersService: RemindersService
    @ObservedObject var viewModel: LifeGoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Error banner
                        if let error = remindersService.lastError {
                            errorBanner(error)
                        }

                        // Sync status banner
                        if let message = remindersService.syncStatus.message {
                            syncStatusBanner(message)
                        }

                        // Sync toggle card
                        syncToggleCard

                        // Status card
                        statusCard

                        // Sync now button
                        if remindersService.isSyncEnabled && remindersService.isAuthorized {
                            syncNowButton
                        }

                        // Info section
                        infoSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Reminders Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func errorBanner(_ error: RemindersService.RemindersError) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            Button {
                remindersService.clearError()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
        .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private func syncStatusBanner(_ message: String) -> some View {
        HStack {
            if case .syncing = remindersService.syncStatus {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.8)
            } else if case .success = remindersService.syncStatus {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.white)
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.8), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var statusColor: Color {
        switch remindersService.syncStatus {
        case .idle: return .clear
        case .syncing: return .blue
        case .success: return .green
        case .failed: return .orange
        }
    }

    private var syncToggleCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundStyle(theme.primaryColor)

                Text("Sync with Apple Reminders")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Toggle("", isOn: $remindersService.isSyncEnabled)
                    .labelsHidden()
                    .onChange(of: remindersService.isSyncEnabled) { _, newValue in
                        if newValue && !remindersService.isAuthorized {
                            Task {
                                _ = await remindersService.requestAccess()
                            }
                        }
                    }
            }

            Text("Sync your Goals, Wishlist, and Struggles with Apple Reminders app")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: remindersService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(remindersService.isAuthorized ? .green : .red)

                Text(remindersService.isAuthorized ? "Reminders Access Granted" : "Reminders Access Required")
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                if !remindersService.isAuthorized {
                    Button("Grant") {
                        Task {
                            _ = await remindersService.requestAccess()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.primaryColor)
                }
            }

            if remindersService.isSyncEnabled && remindersService.isAuthorized {
                Divider()
                    .background(.white.opacity(0.1))

                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Lists: Tracker Goals, Tracker Wishlist, Tracker Struggles")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private var isSyncing: Bool {
        if case .syncing = remindersService.syncStatus { return true }
        return false
    }

    private var syncNowButton: some View {
        Button {
            HapticFeedback.medium.trigger()
            Task {
                await remindersService.performFullSync(
                    goals: viewModel.goals,
                    wishlistItems: viewModel.wishlistItems,
                    struggles: viewModel.struggles
                )
                if case .success = remindersService.syncStatus {
                    HapticFeedback.success.trigger()
                } else {
                    HapticFeedback.error.trigger()
                }
            }
        } label: {
            HStack {
                if isSyncing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(isSyncing ? "Syncing..." : "Sync Now")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(theme.primaryColor, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .disabled(isSyncing)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("How it works")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                infoRow(icon: "plus.circle", text: "New items sync to Apple Reminders")
                infoRow(icon: "checkmark.circle", text: "Completing items marks them done in Reminders")
                infoRow(icon: "trash", text: "Deleted items are removed from Reminders")
                infoRow(icon: "icloud", text: "Works with iCloud synced reminders")
            }
        }
        .padding()
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
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
