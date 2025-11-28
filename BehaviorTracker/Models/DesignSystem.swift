import SwiftUI

// MARK: - Spacing Constants

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
}

// MARK: - Semantic Colors

enum SemanticColor {
    static let primary = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let muted = Color.gray
    static let medication = Color.green
    static let journal = Color.orange
    static let calendar = Color.cyan
    static let ai = Color.purple
}

// MARK: - Themed Icon Component

struct ThemedIcon: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    let backgroundStyle: BackgroundStyle

    enum BackgroundStyle {
        case circle
        case roundedSquare
        case none
    }

    init(systemName: String, color: Color, size: CGFloat = 44, backgroundStyle: BackgroundStyle = .circle) {
        self.systemName = systemName
        self.color = color
        self.size = size
        self.backgroundStyle = backgroundStyle
    }

    var body: some View {
        ZStack {
            switch backgroundStyle {
            case .circle:
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: size, height: size)
            case .roundedSquare:
                RoundedRectangle(cornerRadius: size * 0.25)
                    .fill(color.opacity(0.15))
                    .frame(width: size, height: size)
            case .none:
                EmptyView()
            }

            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ThemedIcon(
                    systemName: icon,
                    color: color,
                    size: 40,
                    backgroundStyle: .roundedSquare
                )

                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(theme.cardBackground)
            )
            .shadow(color: theme.cardShadowColor, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header Component

struct SectionHeaderView: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    let actionTitle: String?

    init(title: String, icon: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(SemanticColor.primary)
                }
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Badge Component

struct BadgeView: View {
    let text: String
    let color: Color
    let icon: String?

    init(text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Info Box Component

struct InfoBox: View {
    let icon: String
    let title: String
    let message: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Loading View Component

struct LoadingView: View {
    let message: String
    let theme: AppTheme

    var body: some View {
        VStack(spacing: Spacing.xl) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primaryColor)

            VStack(spacing: Spacing.sm) {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("This may take a moment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(theme.cardBackground)
                .shadow(color: theme.cardShadowColor, radius: 20, y: 10)
        )
    }
}
