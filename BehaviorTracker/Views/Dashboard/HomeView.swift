import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var showingProfile: Bool
    @State private var specialNote: String = ""
    @State private var showingSlideshow = false
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

                        CurrentSetupCard()

                        if viewModel.hasTodayEntries {
                            daySummaryButton
                        }

                        if let recentContext = viewModel.recentContext {
                            recentContextCard(recentContext)
                        }

                        if !viewModel.memories.isEmpty {
                            memoriesSection
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.lg)
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    HapticFeedback.light.trigger()
                    await viewModel.refresh()
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
                    .foregroundStyle(CardText.title)

                Text("Keep it up! You've been tracking for \(viewModel.currentStreak) days in a row.")
                    .font(.subheadline)
                    .foregroundStyle(CardText.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.currentStreak >= 7 {
                    Text("You've reached your weekly goal!")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    // MARK: - Day Summary Button

    private var daySummaryButton: some View {
        Button {
            showingSlideshow = true
            HapticFeedback.medium.trigger()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.cyan)
                    .frame(width: TouchTarget.recommended, height: TouchTarget.recommended)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Day So Far")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(CardText.body)

                    Text("Tap to see a summary")
                        .font(.caption)
                        .foregroundStyle(CardText.caption)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(CardText.muted)
            }
            .padding(Spacing.lg)
            .frame(minHeight: TouchTarget.recommended)
            .cardStyle(theme: theme)
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
        .padding(.top, Spacing.md)
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
    }

    // MARK: - Recent Context

    private func recentContextCard(_ context: RecentContext) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: context.icon)
                    .font(.title3)
                    .foregroundStyle(.yellow)
                Text("Recently")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(CardText.title)
            }

            Text(context.message)
                .font(.body)
                .foregroundStyle(CardText.body)

            if let timeAgo = context.timeAgo {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
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
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                    .foregroundStyle(.mint)
                Text(memory.timeframe)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(CardText.title)
            }

            Text(memory.description)
                .font(.body)
                .foregroundStyle(CardText.body)
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
