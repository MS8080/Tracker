import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    let style: IllustrationStyle

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    enum IllustrationStyle {
        case simple      // Just the icon
        case decorated   // Icon with decorative background
        case animated    // Icon with subtle animation
    }

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        style: IllustrationStyle = .decorated
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Illustration
            illustrationView

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button {
                    HapticFeedback.medium.trigger()
                    action()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.primaryColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: theme.primaryColor.opacity(0.3), radius: 6, y: 3)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var illustrationView: some View {
        switch style {
        case .simple:
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(theme.primaryColor.opacity(0.5))

        case .decorated:
            ZStack {
                // Outer decorative ring
                Circle()
                    .stroke(theme.primaryColor.opacity(0.1), lineWidth: 2)
                    .frame(width: 140, height: 140)

                // Middle decorative ring
                Circle()
                    .stroke(theme.primaryColor.opacity(0.15), lineWidth: 1)
                    .frame(width: 110, height: 110)

                // Background circle
                Circle()
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(width: 100, height: 100)

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.primaryColor.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                // Main icon
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(theme.primaryColor.opacity(0.7))

                // Decorative sparkles
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.primaryColor.opacity(0.4))
                        .offset(
                            x: CGFloat([-50, 55, -40][index]),
                            y: CGFloat([-35, 10, 45][index])
                        )
                }
            }

        case .animated:
            AnimatedEmptyStateIcon(icon: icon, theme: theme)
        }
    }
}

// MARK: - Animated Empty State Icon

private struct AnimatedEmptyStateIcon: View {
    let icon: String
    let theme: AppTheme
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Pulsing outer ring
            Circle()
                .stroke(theme.primaryColor.opacity(0.2), lineWidth: 2)
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .opacity(isAnimating ? 0.5 : 1.0)

            // Background circle
            Circle()
                .fill(theme.primaryColor.opacity(0.1))
                .frame(width: 100, height: 100)

            // Main icon with gentle bounce
            Image(systemName: icon)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(theme.primaryColor.opacity(0.7))
                .offset(y: isAnimating ? -3 : 0)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty state for journal entries
    static func noJournalEntries(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "book.closed.fill",
            title: "No Journal Entries",
            message: "Start documenting your thoughts and experiences",
            actionTitle: "Write First Entry",
            action: action,
            style: .decorated
        )
    }

    /// Empty state for patterns
    static func noPatterns(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "brain.head.profile",
            title: "No Patterns Yet",
            message: "Write journal entries and analyze them to discover patterns",
            actionTitle: action != nil ? "Analyze Entries" : nil,
            action: action,
            style: .decorated
        )
    }

    /// Empty state for medications
    static func noMedications(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "pills.fill",
            title: "No Medications",
            message: "Track your medications and supplements here",
            actionTitle: "Add Medication",
            action: action,
            style: .decorated
        )
    }

    /// Empty state for goals
    static func noGoals(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "target",
            title: "No Goals Set",
            message: "Set goals to track your progress and achievements",
            actionTitle: "Add Goal",
            action: action,
            style: .decorated
        )
    }

    /// Empty state for search results
    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No entries found for \"\(query)\"",
            style: .simple
        )
    }

    /// Empty state for calendar day
    static func noEventsToday() -> EmptyStateView {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "Nothing Logged",
            message: "No entries or events for this day",
            style: .simple
        )
    }
}

#Preview("Decorated Style") {
    ZStack {
        AppTheme.purple.gradient
            .ignoresSafeArea()

        EmptyStateView(
            icon: "tray.fill",
            title: "No Entries Yet",
            message: "Start tracking your patterns by logging your first entry",
            actionTitle: "Log First Entry",
            action: { },
            style: .decorated
        )
    }
}

#Preview("Simple Style") {
    ZStack {
        AppTheme.blue.gradient
            .ignoresSafeArea()

        EmptyStateView.noSearchResults(query: "meditation")
    }
}

#Preview("Animated Style") {
    ZStack {
        AppTheme.green.gradient
            .ignoresSafeArea()

        EmptyStateView(
            icon: "sparkles",
            title: "Analyzing...",
            message: "Please wait while we process your data",
            style: .animated
        )
    }
}
