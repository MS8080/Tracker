import SwiftUI

// MARK: - Category Button (List style)

struct CategoryButton: View {
    let category: PatternCategory
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }

            HapticFeedback.medium.trigger()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: Spacing.lg) {
                // Icon
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(category.color)
                    .symbolEffect(.bounce, value: isPressed)
                    .frame(width: 44, height: 44)

                // Text
                Text(category.rawValue)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CardText.muted)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .cardStyle(theme: theme)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Feeling Finder Category Button (List style)

struct FeelingFinderCategoryButton: View {
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }

            HapticFeedback.medium.trigger()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        } label: {
            HStack(spacing: Spacing.lg) {
                // Icon
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.mint)
                    .frame(width: 44, height: 44)

                // Text
                Text("Guided")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CardText.muted)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .cardStyle(theme: theme)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Quick Log Button

struct QuickLogButton: View {
    let patternType: PatternType
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }

            HapticFeedback.light.trigger()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: patternType.category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(patternType.category.color)

                Text(patternType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(theme.primaryColor)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Category Grid Button (2-column grid style)

struct CategoryGridButton: View {
    let category: PatternCategory
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }

            HapticFeedback.medium.trigger()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: Spacing.sm) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(category.color.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: category.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(category.color)
                        .symbolEffect(.bounce, value: isPressed)
                }

                // Category name
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 115)
            .cardStyle(theme: theme, cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
    }
}

// MARK: - Feeling Finder Grid Button (2-column grid style)

struct FeelingFinderGridButton: View {
    let action: () -> Void

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }

            HapticFeedback.medium.trigger()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        } label: {
            VStack(spacing: Spacing.sm) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.mint.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.mint)
                        .symbolEffect(.bounce, value: isPressed)
                }

                // Label
                Text("Guided")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 115)
            .cardStyle(theme: theme, cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
    }
}

// MARK: - Previews

#Preview("CategoryButton") {
    CategoryButton(category: .sensory, action: {})
        .padding()
}

#Preview("CategoryGridButton") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        CategoryGridButton(category: .sensory, action: {})
        CategoryGridButton(category: .social, action: {})
        FeelingFinderGridButton(action: {})
    }
    .padding()
}

#Preview("QuickLogButton") {
    QuickLogButton(patternType: .sensoryOverload, action: {})
        .padding()
}
