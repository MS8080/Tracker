import SwiftUI
import Charts

struct WeeklyReportView: View {
    let report: WeeklyReport
    let theme: AppTheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            summaryCard
            categoryDistributionCard
            if !report.commonTriggers.isEmpty {
                triggersCard
            }
            if !report.topCascades.isEmpty {
                cascadesCard
            }
            patternFrequencyCard
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ReportCard(title: "Weekly Summary", subtitle: "Last 7 days", theme: theme) {
            VStack(spacing: Spacing.lg) {
                StatRow(label: "Journal Entries", value: "\(report.totalEntries)")
                StatRow(label: "Patterns Detected", value: "\(report.totalPatterns)")
                StatRow(label: "Most Active Day", value: report.mostActiveDay)
                StatRow(label: "Avg Patterns/Day", value: String(format: "%.1f", report.averagePerDay))
            }
        }
    }

    // MARK: - Category Distribution Card

    private var categoryDistributionCard: some View {
        ReportCard(
            title: "Category Distribution",
            subtitle: "Breakdown by category",
            theme: theme,
            minHeight: 280
        ) {
            if report.categoryBreakdown.isEmpty {
                ReportEmptyState(message: "No patterns extracted yet")
            } else {
                VStack(spacing: Spacing.md) {
                    Chart {
                        ForEach(Array(report.categoryBreakdown), id: \.key) { category, count in
                            SectorMark(
                                angle: .value("Count", count),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(colorForCategory(category))
                            .opacity(0.8)
                        }
                    }
                    .frame(height: 150)

                    categoryLegend
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
    }

    private var categoryLegend: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(report.categoryBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { category, count in
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(colorForCategory(category))
                        .frame(width: 10, height: 10)

                    Text(category)
                        .font(.subheadline)
                        .foregroundStyle(CardText.body)
                        .lineLimit(1)

                    Spacer()

                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(CardText.body)
                }
            }
        }
    }

    // MARK: - Triggers Card

    private var triggersCard: some View {
        ReportCard(
            title: "Common Triggers",
            subtitle: "What's been affecting you",
            theme: theme
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(report.commonTriggers, id: \.self) { trigger in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)

                        Text(trigger)
                            .font(.subheadline)
                            .foregroundStyle(CardText.body)
                    }
                }
            }
        }
    }

    // MARK: - Cascades Card

    private var cascadesCard: some View {
        ReportCard(
            title: "Pattern Connections",
            subtitle: "What led to what",
            theme: theme
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(report.topCascades, id: \.from) { cascade in
                    HStack(spacing: Spacing.sm) {
                        Text(cascade.from)
                            .font(.caption)
                            .foregroundStyle(CardText.body)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(CardText.caption)

                        Text(cascade.to)
                            .font(.caption)
                            .foregroundStyle(CardText.body)

                        Spacer()

                        Text("×\(cascade.count)")
                            .font(.caption)
                            .foregroundStyle(CardText.caption)
                    }
                }
            }
        }
    }

    // MARK: - Pattern Frequency Card

    private var patternFrequencyCard: some View {
        ReportCard(
            title: "Pattern Frequency",
            subtitle: "Top patterns this week",
            theme: theme,
            minHeight: 280
        ) {
            if report.patternFrequency.isEmpty {
                ReportEmptyState(message: "No patterns extracted yet")
            } else {
                SimpleBarChart(
                    data: report.patternFrequency.prefix(5).map { pattern, count in
                        BarChartData(
                            label: pattern,
                            value: Double(count),
                            color: theme.primaryColor
                        )
                    },
                    showValues: true,
                    barHeight: 24
                )
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
    }

    // MARK: - Helpers

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Sensory": return .red
        case "Executive Function": return .orange
        case "Energy & Regulation": return .purple
        case "Social & Communication": return .blue
        case "Routine & Change": return .yellow
        case "Demand Avoidance": return .pink
        case "Physical & Sleep": return .green
        case "Special Interests": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Reusable Report Components

struct ReportCard<Content: View>: View {
    let title: String
    let subtitle: String
    let theme: AppTheme
    var minHeight: CGFloat? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(CardText.title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
            }

            content()
        }
        .padding(Spacing.xl)
        .frame(minHeight: minHeight)
        .cardStyle(theme: theme)
    }
}

struct ReportEmptyState: View {
    let message: String

    var body: some View {
        EmptyStateView(
            icon: "chart.bar.xaxis",
            title: "No Data Yet",
            message: message
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WeeklyReportView(
        report: WeeklyReport(
            totalEntries: 25,
            mostActiveDay: "Monday",
            averagePerDay: 3.5,
            patternFrequency: [],
            categoryBreakdown: [:]
        ),
        theme: .purple
    )
}
