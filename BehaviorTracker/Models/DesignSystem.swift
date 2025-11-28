import SwiftUI

// MARK: - Spacing Constants

/// Consistent spacing scale used throughout the app
/// Based on 4pt grid system for visual harmony
enum Spacing {
    /// 4pt - Tight spacing for inline elements, icons
    static let xs: CGFloat = 4
    /// 8pt - Small gaps between related elements
    static let sm: CGFloat = 8
    /// 12pt - Default spacing for most content
    static let md: CGFloat = 12
    /// 16pt - Section content, card padding
    static let lg: CGFloat = 16
    /// 20pt - Between major sections
    static let xl: CGFloat = 20
    /// 24pt - Large section breaks
    static let xxl: CGFloat = 24
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    /// 12pt - Small elements like badges, chips
    static let sm: CGFloat = 12
    /// 16pt - Buttons, small cards, input fields
    static let md: CGFloat = 16
    /// 20pt - Standard cards
    static let lg: CGFloat = 20
}

// MARK: - Semantic Colors

enum SemanticColor {
    // Primary actions & navigation
    static let primary = Color.blue

    // Success states, positive indicators
    static let success = Color.green

    // Warnings, attention needed
    static let warning = Color.orange

    // Errors, destructive actions
    static let error = Color.red

    // Secondary/muted elements
    static let muted = Color.gray

    // Feature-specific colors (use sparingly)
    static let medication = Color.green
    static let journal = Color.orange
    static let calendar = Color.cyan
    static let ai = Color.purple
}

// MARK: - Font Weights
/// Hierarchy: .bold (titles) > .semibold (card titles) > .medium (labels) > .regular (body)
enum AppFontWeight {
    /// For body text, descriptions
    static let regular: Font.Weight = .regular
    /// For labels, buttons, secondary headings
    static let medium: Font.Weight = .medium
    /// For card titles, section headers
    static let semibold: Font.Weight = .semibold
    /// For main screen titles only
    static let bold: Font.Weight = .bold
}

// MARK: - Icon Guidelines
/// Icon Usage:
/// - Use .fill variants for: indicators, selected states, primary feature icons
/// - Use outline variants for: navigation (chevron), toolbar actions (xmark, checkmark)
/// - Consistent sizing: .title3 for card icons, .title2 for feature icons, .caption for badges

// MARK: - Typography Extensions

extension View {
    func cardTitle() -> some View {
        self
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
    }
    
    func cardSubtitle() -> some View {
        self
            .font(.callout)
            .foregroundStyle(.secondary)
    }
    
    func metadataText() -> some View {
        self
            .font(.caption)
            .foregroundStyle(.tertiary)
    }
    
    func emphasizedBody() -> some View {
        self
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.primary.opacity(0.9))
    }
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

// MARK: - AppTheme Extensions

extension AppTheme {
    var accentLight: Color {
        primaryColor.opacity(0.15)
    }
    
    var accentMedium: Color {
        primaryColor.opacity(0.3)
    }
    
    /// Get themed background color for different categories
    func iconBackground(for category: String) -> Color {
        switch category.lowercased() {
        case "health", "medication", "pills":
            return .purple.opacity(0.15)
        case "mood", "feeling":
            return .yellow.opacity(0.15)
        case "sleep", "rest":
            return .indigo.opacity(0.15)
        case "energy", "activity":
            return .orange.opacity(0.15)
        case "social":
            return .pink.opacity(0.15)
        case "work", "productivity":
            return .blue.opacity(0.15)
        default:
            return primaryColor.opacity(0.15)
        }
    }
    
    /// Get themed color for different categories
    func iconColor(for category: String) -> Color {
        switch category.lowercased() {
        case "health", "medication", "pills":
            return .purple
        case "mood", "feeling":
            return .yellow
        case "sleep", "rest":
            return .indigo
        case "energy", "activity":
            return .orange
        case "social":
            return .pink
        case "work", "productivity":
            return .blue
        default:
            return primaryColor
        }
    }
}

// MARK: - Button Styles

/// Standard scale button style with subtle press feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Primary action button - filled background
struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = SemanticColor.primary) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Secondary action button - outlined style
struct SecondaryButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = SemanticColor.primary) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(color, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
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
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
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
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primaryColor)
            
            VStack(spacing: 8) {
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
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
    }
}

#Preview("Themed Icons") {
    ZStack {
        AppTheme.purple.gradient
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ThemedIcon(systemName: "pills.fill", color: .purple, size: 44, backgroundStyle: .circle)
                ThemedIcon(systemName: "heart.fill", color: .red, size: 44, backgroundStyle: .roundedSquare)
                ThemedIcon(systemName: "moon.fill", color: .indigo, size: 44, backgroundStyle: .circle)
            }
            
            InfoBox(
                icon: "info.circle.fill",
                title: "Sample Info Box",
                message: "This is an example of the InfoBox component with themed styling",
                color: .blue
            )
            .padding()
            
            BadgeView(text: "New", color: .green, icon: "sparkles")
            
            LoadingView(message: "Loading data", theme: AppTheme.purple)
        }
        .padding()
    }
}
