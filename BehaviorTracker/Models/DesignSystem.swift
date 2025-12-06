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
    static let sm: CGFloat = 16
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
}

// MARK: - Touch Target Constants

enum TouchTarget {
    static let minimum: CGFloat = 44
    static let recommended: CGFloat = 48
    static let large: CGFloat = 56
}

// MARK: - Card Text Colors

enum CardText {
    static let title: Color = .primary.opacity(0.95)
    static let body: Color = .primary.opacity(0.85)
    static let secondary: Color = .primary.opacity(0.7)
    static let caption: Color = .secondary.opacity(0.8)
    static let muted: Color = .secondary.opacity(0.6)
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
        Button {
            action()
        } label: {
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
            .compactCardStyle(theme: theme)
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
        .cardStyle(theme: theme, cornerRadius: CornerRadius.lg)
    }
}

// MARK: - Streak Counter Component

struct StreakCounter: View {
    let currentStreak: Int
    let targetStreak: Int
    let theme: AppTheme

    private var progress: Double {
        min(Double(currentStreak) / Double(targetStreak), 1.0)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(theme.primaryColor.opacity(0.2), lineWidth: 8)
                .frame(width: 70, height: 70)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    theme.primaryColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))

            // Streak number
            VStack(spacing: 0) {
                Text("\(currentStreak)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(CardText.title)
                Text("days")
                    .font(.caption2)
                    .foregroundStyle(CardText.caption)
            }
        }
    }
}

// MARK: - Bar Chart Data

struct BarChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

// MARK: - Simple Bar Chart Component

struct SimpleBarChart: View {
    let data: [BarChartData]
    let showValues: Bool
    let barHeight: CGFloat

    init(data: [BarChartData], showValues: Bool = true, barHeight: CGFloat = 24) {
        self.data = Array(data)
        self.showValues = showValues
        self.barHeight = barHeight
    }

    private var maxValue: Double {
        data.map(\.value).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(data) { item in
                HStack(spacing: Spacing.sm) {
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(CardText.secondary)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geometry in
                        let width = max(0, geometry.size.width * (item.value / maxValue))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color)
                            .frame(width: width, height: barHeight)
                    }
                    .frame(height: barHeight)

                    if showValues {
                        Text("\(Int(item.value))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(CardText.body)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
    }
}

// MARK: - Capsule Label Style (Accessibility Feature)

/// A view modifier that optionally wraps text in a capsule for better visibility
struct CapsuleLabelModifier: ViewModifier {
    @AppStorage("useCapsuleLabels") private var useCapsuleLabels: Bool = false
    let theme: AppTheme
    let style: CapsuleLabelStyle

    enum CapsuleLabelStyle {
        case time       // For timestamps (smaller, subtle)
        case title      // For section titles (medium, prominent)
        case header     // For main headers (larger)
    }

    func body(content: Content) -> some View {
        if useCapsuleLabels {
            content
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(backgroundColor, in: Capsule())
        } else {
            content
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .time: return Spacing.sm
        case .title: return Spacing.md
        case .header: return Spacing.lg
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .time: return Spacing.xs
        case .title: return Spacing.sm
        case .header: return Spacing.sm
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .time: return theme.primaryColor.opacity(0.15)
        case .title: return theme.primaryColor.opacity(0.2)
        case .header: return theme.primaryColor.opacity(0.25)
        }
    }
}

extension View {
    /// Apply capsule styling if the accessibility setting is enabled
    func capsuleLabel(theme: AppTheme, style: CapsuleLabelModifier.CapsuleLabelStyle = .title) -> some View {
        modifier(CapsuleLabelModifier(theme: theme, style: style))
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing, wrapping manner (like tags/chips)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangement(in: proposal.width ?? 0, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(in: bounds.width, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, proposal: .unspecified)
        }
    }

    private func arrangement(in maxWidth: CGFloat, subviews: Subviews) -> (positions: [CGPoint], height: CGFloat) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, y + rowHeight)
    }
}
