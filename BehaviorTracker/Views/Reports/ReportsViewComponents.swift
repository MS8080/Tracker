import SwiftUI

// MARK: - Report Timeframe

enum ReportTimeframe {
    case weekly
    case monthly
}

// MARK: - Trend Direction

enum TrendDirection {
    case up, down, neutral

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - Analysis Cards Row

struct AnalysisCardsRow: View {
    let theme: AppTheme
    let onAIInsights: () -> Void
    let onCorrelations: () -> Void
    let onExport: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Featured Insights Card - Full Width
            FeaturedAnalysisCard(
                icon: "sparkles",
                iconColor: Color(red: 0.7, green: 0.5, blue: 0.9),
                title: "Insights",
                subtitle: "Get personalized analysis powered by AI",
                theme: theme,
                action: onAIInsights
            )

            // Secondary Actions - Side by Side
            HStack(spacing: Spacing.md) {
                CompactAnalysisCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: theme.primaryColor,
                    title: "Correlations",
                    subtitle: "Find triggers",
                    theme: theme,
                    action: onCorrelations
                )

                CompactAnalysisCard(
                    icon: "chart.bar.doc.horizontal",
                    iconColor: Color(red: 0.5, green: 0.8, blue: 0.9),
                    title: "Export",
                    subtitle: "Share data",
                    theme: theme,
                    action: onExport
                )
            }
        }
    }
}

// MARK: - Timeframe Picker

struct TimeframePicker: View {
    @Binding var selectedTimeframe: ReportTimeframe
    let theme: AppTheme
    @Namespace private var pickerNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach([ReportTimeframe.weekly, ReportTimeframe.monthly], id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTimeframe = timeframe
                        HapticFeedback.light.trigger()
                    }
                } label: {
                    Text(timeframe == .weekly ? "Weekly" : "Monthly")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTimeframe == timeframe ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if selectedTimeframe == timeframe {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.primaryColor.opacity(0.3))
                                    .matchedGeometryEffect(id: "picker", in: pickerNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Featured Analysis Card (Large, Full Width)

struct FeaturedAnalysisCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 64, height: 64)

                    Circle()
                        .fill(iconColor)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(CardText.title)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(CardText.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.caption)
            }
            .padding(Spacing.lg)
            .cardStyle(theme: theme, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Analysis Card (Small, Side by Side)

struct CompactAnalysisCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }

                VStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.body)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CardText.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .padding(Spacing.md)
            .cardStyle(theme: theme)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Original Analysis Card (Kept for compatibility)

struct AnalysisCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: TouchTarget.recommended, height: TouchTarget.recommended)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }

                VStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.body)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CardText.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: TouchTarget.large)
            .padding(Spacing.lg)
            .cardStyle(theme: theme)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Stat Row with Icons and Trends

struct EnhancedStatRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var trend: TrendDirection? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(CardText.secondary)
                    .frame(width: 20)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(CardText.secondary)

            Spacer()

            if let trend = trend {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundStyle(trend.color)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(CardText.body)
        }
    }
}

// MARK: - Original Stat Row (Kept for compatibility)

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(CardText.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(CardText.body)
        }
    }
}

// MARK: - Report Summary Card

struct ReportSummaryCard: View {
    let summary: ReportSummary
    let isLoading: Bool
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "text.quote")
                    .font(.headline)
                    .foregroundStyle(theme.primaryColor)

                Text("This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.title)

                Spacer()
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, Spacing.lg)
            } else if summary.tldr.isEmpty {
                Text("Loading your summary...")
                    .font(.subheadline)
                    .foregroundStyle(CardText.secondary)
                    .italic()
            } else {
                // TL;DR
                Text(summary.tldr)
                    .font(.body)
                    .foregroundStyle(CardText.body)
                    .fixedSize(horizontal: false, vertical: true)

                // Recommendations
                if !summary.recommendations.isEmpty {
                    Divider()
                        .background(CardText.caption.opacity(0.3))

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recommendations")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(CardText.secondary)

                        ForEach(Array(summary.recommendations.enumerated()), id: \.offset) { index, recommendation in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Text("\(index + 1).")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(theme.primaryColor)
                                    .frame(width: 20, alignment: .leading)

                                Text(recommendation)
                                    .font(.subheadline)
                                    .foregroundStyle(CardText.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                // Data sources indicator
                if !summary.dataSource.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)

                        Text("Based on: \(summary.dataSource)")
                            .font(.caption2)
                            .foregroundStyle(CardText.caption)
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }
}
