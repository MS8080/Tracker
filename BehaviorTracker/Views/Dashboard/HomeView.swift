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

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Warm greeting with name
                        greetingSection

                        // What's special today? - quick note
                        specialTodaySection

                        // Day Summary button (only if there are entries today)
                        if viewModel.hasTodayEntries {
                            daySummaryButton
                        }

                        // What's been happening (contextual, not stats)
                        if let recentContext = viewModel.recentContext {
                            recentContextCard(recentContext)
                        }

                        // Memories - familiar moments
                        if !viewModel.memories.isEmpty {
                            memoriesSection
                        }
                    }
                    .padding()
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

    // MARK: - Day Summary Button

    private var daySummaryButton: some View {
        Button {
            showingSlideshow = true
            HapticFeedback.medium.trigger()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.primaryColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Day So Far")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Tap to see a summary")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.lg)
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
            } else {
                Text("\(viewModel.greeting)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
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
                .foregroundStyle(.secondary)

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
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(theme.cardBorderColor, lineWidth: 1)
            )
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
                    .foregroundStyle(context.color)
                Text("Recently")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(context.color)
            }

            Text(context.message)
                .font(.body)
                .foregroundStyle(.primary)

            if let timeAgo = context.timeAgo {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    // MARK: - Memories Section

    private var memoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(viewModel.memories, id: \.id) { memory in
                memoryCard(memory)
            }
        }
    }

    private func memoryCard(_ memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(memory.timeframe)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(theme.primaryColor)

            Text(memory.description)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }
}

// MARK: - Profile Button

struct ProfileButton: View {
    @Binding var showingProfile: Bool
    @ObservedObject private var dataController = DataController.shared

    @ThemeWrapper var theme

    var body: some View {
        Button {
            showingProfile = true
        } label: {
            if let profile = dataController.getCurrentUserProfile(),
               let profileImage = profile.profileImage {
                #if os(iOS)
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primaryColor.opacity(0.5), lineWidth: 2)
                    )
                #elseif os(macOS)
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primaryColor.opacity(0.5), lineWidth: 2)
                    )
                #endif
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.primaryColor)
            }
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
                // Header
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
                    // Loading state
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
                    // Error state
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
                    // Cards scroll view
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
            // Icon
            Image(systemName: slide.icon)
                .font(.title2)
                .foregroundStyle(slide.color)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(slide.color.opacity(0.15))
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(slide.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(slide.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
