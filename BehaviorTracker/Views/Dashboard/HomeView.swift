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
                        GreetingSection(
                            greeting: viewModel.greeting,
                            firstName: viewModel.userFirstName
                        )

                        SpecialTodaySection(
                            specialNote: $specialNote,
                            theme: theme,
                            onSave: saveSpecialNote,
                            isFocused: $isNoteFieldFocused
                        )

                        if viewModel.currentStreak > 0 {
                            StreakCard(streak: viewModel.currentStreak, theme: theme)
                        }

                        if viewModel.hasTodayEntries {
                            DaySummaryButton(entryCount: viewModel.todayEntryCount) {
                                showingSlideshow = true
                                HapticFeedback.medium.trigger()
                            }
                        }

                        if let recentContext = viewModel.recentContext {
                            RecentContextCard(context: recentContext, theme: theme)
                        }

                        if !viewModel.memories.isEmpty {
                            MemoriesSection(memories: viewModel.memories, theme: theme)
                        }

                        CurrentSetupCard()
                        LifeGoalsSection()
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
                        SavedMessageBanner(theme: theme) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showingSavedMessage = false
                            }
                        }
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

    // MARK: - Actions

    private func saveSpecialNote() {
        guard !specialNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        viewModel.saveSpecialNote(specialNote)
        specialNote = ""
        isNoteFieldFocused = false
        HapticFeedback.success.trigger()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingSavedMessage = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                showingSavedMessage = false
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
