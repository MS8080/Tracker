import SwiftUI

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Int
    let theme: AppTheme

    var body: some View {
        HStack(spacing: Spacing.xl) {
            StreakCounter(
                currentStreak: streak,
                targetStreak: 7,
                theme: theme
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Tracking Streak")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .capsuleLabel(theme: theme, style: .title)

                Text("Keep it up! You've been tracking for \(streak) days in a row.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                if streak >= 7 {
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
}

// MARK: - Day Summary Button

struct DaySummaryButton: View {
    let entryCount: Int
    let action: () -> Void

    private var subtitle: String {
        if entryCount == 1 {
            return "1 moment witnessed"
        } else {
            return "\(entryCount) moments witnessed"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: TouchTarget.recommended, height: TouchTarget.recommended)

                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your day so far")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    Spacer()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(Spacing.lg)
            .frame(minHeight: TouchTarget.recommended)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.3), .blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .cyan.opacity(0.15), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Greeting Section

struct GreetingSection: View {
    let greeting: String
    let firstName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let firstName = firstName {
                Text("\(greeting), \(firstName)!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } else {
                Text("\(greeting)!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Special Today Section

struct SpecialTodaySection: View {
    @Binding var specialNote: String
    let theme: AppTheme
    let onSave: () -> Void
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What's special today?")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.7))

            HStack {
                TextField("A thought, a moment, anything...", text: $specialNote)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(onSave)

                if !specialNote.isEmpty {
                    Button(action: onSave) {
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
}

// MARK: - Saved Message Banner

struct SavedMessageBanner: View {
    let theme: AppTheme
    let onDismiss: () -> Void

    var body: some View {
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

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(Spacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(theme.primaryColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}

// MARK: - Recent Context Card

struct RecentContextCard: View {
    let context: RecentContext
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: context.icon)
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                Text("Earlier Today")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .capsuleLabel(theme: theme, style: .title)

            // Time reference as header
            if let timeAgo = context.timeAgo {
                Text(timeAgo.capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Main message - what happened
            Text(context.message)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))

            // Insight if available
            if let preview = context.journalPreview, !preview.isEmpty {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }
}

// MARK: - Memory Card

struct MemoryCard: View {
    let memory: Memory
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(.mint)
                Text(memory.timeframe)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .capsuleLabel(theme: theme, style: .title)

            Text(memory.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }
}

// MARK: - Memories Section

struct MemoriesSection: View {
    let memories: [Memory]
    let theme: AppTheme

    var body: some View {
        ForEach(memories, id: \.id) { memory in
            MemoryCard(memory: memory, theme: theme)
        }
    }
}
