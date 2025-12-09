import SwiftUI

// MARK: - Local Insights Result View

struct LocalInsightsResultView: View {
    let insights: LocalInsights
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Circular icon container (matching app design pattern)
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(Color.green)
                    .frame(width: 40, height: 40)

                Image(systemName: "cpu")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Local Analysis")
                        .font(.headline)
                        .foregroundStyle(CardText.title)
                    Spacer()
                    Text(insights.formattedDate)
                        .font(.caption)
                        .foregroundStyle(CardText.caption)
                }

                // Sections
                ForEach(insights.sections) { section in
                    LocalInsightSectionView(section: section)
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }
}

// MARK: - Local Insight Section View

struct LocalInsightSectionView: View {
    let section: LocalInsightSection

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: section.icon)
                    .foregroundStyle(.purple)
                    .font(.subheadline)
                Text(section.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
            }

            ForEach(section.insights) { insight in
                LocalInsightItemView(insight: insight)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Local Insight Item View

struct LocalInsightItemView: View {
    let insight: LocalInsightItem

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: iconForType)
                .foregroundStyle(colorForType)
                .frame(width: 20)
                .font(.caption)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(CardText.body)

                    if let value = insight.value {
                        Spacer()
                        Text(value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(colorForTrend)
                    }
                }

                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(CardText.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let trend = insight.trend {
                TrendIndicator(trend: trend)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var iconForType: String {
        switch insight.type {
        case .statistic: return "number"
        case .pattern: return "waveform.path.ecg"
        case .time: return "clock"
        case .warning: return "exclamationmark.triangle"
        case .factor: return "list.bullet"
        case .category: return "folder"
        case .mood: return "face.smiling"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .streak: return "flame"
        case .medication: return "pills"
        case .adherence: return "checkmark.circle"
        case .effectiveness: return "star"
        case .correlation: return "arrow.triangle.branch"
        case .trigger: return "bolt"
        case .coping: return "heart"
        case .cascade: return "arrow.right.arrow.left"
        case .suggestion: return "lightbulb"
        case .positive: return "hand.thumbsup"
        }
    }

    private var colorForType: Color {
        switch insight.type {
        case .warning: return .orange
        case .positive: return .green
        case .suggestion: return .yellow
        case .mood: return .pink
        case .medication, .adherence: return .blue
        case .effectiveness: return .purple
        case .trigger: return .red
        case .coping: return .green
        default: return .secondary
        }
    }

    private var colorForTrend: Color {
        switch insight.trend {
        case .positive: return .green
        case .negative: return .red
        case .neutral, .none: return CardText.body
        }
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let trend: LocalInsightTrend

    var body: some View {
        switch trend {
        case .positive:
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .negative:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
        case .neutral:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}
