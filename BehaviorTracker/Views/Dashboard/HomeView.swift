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
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.black.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(theme.primaryColor.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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

// MARK: - Profile Button

struct ProfileButton: View {
    @Binding var showingProfile: Bool
    #if os(iOS)
    @State private var profileImage: UIImage?
    #elseif os(macOS)
    @State private var profileImage: NSImage?
    #endif

    @ThemeWrapper var theme

    var body: some View {
        Button {
            showingProfile = true
        } label: {
            if let profileImage = profileImage {
                #if os(iOS)
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                #elseif os(macOS)
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                #endif
            } else {
                Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .onAppear {
            loadProfileImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileUpdated)) { _ in
            loadProfileImage()
        }
    }

    private func loadProfileImage() {
        if let profile = DataController.shared.getCurrentUserProfile() {
            profileImage = profile.profileImage
        }
    }
}

// MARK: - Day Slideshow View

struct DaySlideshowView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HomeViewModel

    @ThemeWrapper var theme

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Day Summary")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding()

                if viewModel.isGeneratingSlides {
                    Spacer()
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)

                        Text("Generating summary...")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                } else if let error = viewModel.slidesError {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                await viewModel.generateAISlides()
                            }
                        } label: {
                            Text("Retry")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.15))
                                )
                        }
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else if !viewModel.todaySlides.isEmpty {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            ForEach(Array(viewModel.todaySlides.enumerated()), id: \.element.id) { index, slide in
                                slideCard(slide, index: index)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .task {
            if viewModel.todaySlides.isEmpty && !viewModel.isGeneratingSlides {
                await viewModel.generateAISlides()
            }
        }
    }

    private func slideCard(_ slide: DaySummarySlide, index: Int) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: slide.icon)
                .font(.title2)
                .foregroundStyle(slide.color)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(slide.color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(slide.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)

                Text(slide.detail)
                    .font(.subheadline)
                    .foregroundStyle(CardText.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
