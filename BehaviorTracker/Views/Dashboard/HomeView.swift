import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var showingProfile: Bool
    @State private var specialNote: String = ""
    @State private var showingSlideshow = false
    @State private var showingSavedMessage = false
    @FocusState private var isNoteFieldFocused: Bool

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        greetingSection
                        specialTodaySection

                        // Streak card if user has been active
                        if viewModel.currentStreak > 0 {
                            streakCard
                        }

                        if viewModel.hasTodayEntries {
                            daySummaryButton
                        }

                        if let recentContext = viewModel.recentContext {
                            recentContextCard(recentContext)
                        }

                        if !viewModel.memories.isEmpty {
                            memoriesSection
                        }

                        CurrentSetupCard()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.lg)
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    HapticFeedback.light.trigger()
                    await viewModel.refresh()
                }

                // Success message overlay
                if showingSavedMessage {
                    VStack {
                        savedMessageBanner
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .fullScreenCover(isPresented: $showingSlideshow) {
                DaySlideshowView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: Spacing.xl) {
            StreakCounter(
                currentStreak: viewModel.currentStreak,
                targetStreak: 7,
                theme: theme
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Tracking Streak")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Keep it up! You've been tracking for \(viewModel.currentStreak) days in a row.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.currentStreak >= 7 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Weekly goal reached!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme, interactive: true)
    }

    // MARK: - Day Summary Button

    private var daySummaryButton: some View {
        Button {
            showingSlideshow = true
            HapticFeedback.medium.trigger()
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: TouchTarget.recommended, height: TouchTarget.recommended)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Day So Far")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Tap to see a summary")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.trailing, 4)
            }
            .padding(Spacing.lg)
            .frame(minHeight: TouchTarget.recommended)
            .cardStyle(theme: theme, interactive: false)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let firstName = viewModel.userFirstName {
                Text("\(viewModel.greeting), \(firstName)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } else {
                Text("\(viewModel.greeting)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - What's Special Today

    private var specialTodaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What's special today?")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.7))

            HStack {
                TextField("A thought, a moment, anything...", text: $specialNote)
                    .textFieldStyle(.plain)
                    .focused($isNoteFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveSpecialNote()
                    }

                if !specialNote.isEmpty {
                    Button {
                        saveSpecialNote()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(theme.primaryColor)
                    }
                }
            }
            .padding(Spacing.md)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        }
    }

    private func saveSpecialNote() {
        guard !specialNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        viewModel.saveSpecialNote(specialNote)
        specialNote = ""
        isNoteFieldFocused = false
        HapticFeedback.success.trigger()

        // Show success message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingSavedMessage = true
        }

        // Hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                showingSavedMessage = false
            }
        }
    }

    // MARK: - Saved Message Banner

    private var savedMessageBanner: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.25))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved to Journal!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("More than one thing might make today special")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showingSavedMessage = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(Spacing.lg)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.primaryColor.opacity(0.5),
                                    theme.primaryColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.plusLighter)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2),
                                    theme.primaryColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: theme.primaryColor.opacity(0.4), radius: 20, x: 0, y: 8)
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    // MARK: - Recent Context

    private func recentContextCard(_ context: RecentContext) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: context.icon)
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }
                
                Text("Recently")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Text(context.message)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))

            if let timeAgo = context.timeAgo {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    // MARK: - Memories Section

    private var memoriesSection: some View {
        ForEach(viewModel.memories, id: \.id) { memory in
            memoryCard(memory)
        }
    }

    private func memoryCard(_ memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.mint.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundStyle(.mint)
                }
                
                Text(memory.timeframe)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Text(memory.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg) 
        .cardStyle(theme: theme)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
