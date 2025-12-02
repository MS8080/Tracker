import SwiftUI
import Charts

struct WeeklyReportView: View {
    let report: WeeklyReport
    let theme: AppTheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            summaryCard
            categoryDistributionCard
            patternFrequencyCard
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ReportCard(title: "Weekly Summary", subtitle: "Last 7 days", theme: theme) {
            VStack(spacing: Spacing.lg) {
                StatRow(label: "Total Entries", value: "\(report.totalEntries)")
                StatRow(label: "Most Active Day", value: report.mostActiveDay)
                StatRow(label: "Average Per Day", value: String(format: "%.1f", report.averagePerDay))
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
                ReportEmptyState(message: "No data available")
            } else {
                VStack(spacing: Spacing.md) {
                    Chart {
                        ForEach(Array(report.categoryBreakdown), id: \.key) { category, count in
                            SectorMark(
                                angle: .value("Count", count),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(category.color)
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
                        .fill(category.color)
                        .frame(width: 10, height: 10)

                    Text(category.rawValue)
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

    // MARK: - Pattern Frequency Card

    private var patternFrequencyCard: some View {
        ReportCard(
            title: "Pattern Frequency",
            subtitle: "Top patterns this week",
            theme: theme,
            minHeight: 280
        ) {
            if report.patternFrequency.isEmpty {
                ReportEmptyState(message: "No data available")
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
