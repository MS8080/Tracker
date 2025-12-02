import SwiftUI

struct MonthlyReportView: View {
    let report: MonthlyReport
    let theme: AppTheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            summaryCard
            topPatternsCard
            correlationsCard
            performanceCard
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ReportCard(title: "Monthly Summary", subtitle: "Last 30 days", theme: theme) {
            VStack(spacing: Spacing.lg) {
                StatRow(label: "Total Entries", value: "\(report.totalEntries)")
                StatRow(label: "Most Active Week", value: report.mostActiveWeek)
                StatRow(label: "Average Per Day", value: String(format: "%.1f", report.averagePerDay))
            }
        }
    }

    // MARK: - Top Patterns Card

    private var topPatternsCard: some View {
        ReportCard(title: "Top Patterns", subtitle: "Most frequently logged", theme: theme) {
            if report.topPatterns.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.xaxis",
                    title: "No Patterns Yet",
                    message: "Start logging to see your top patterns"
                )
                .frame(height: 150)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(Array(report.topPatterns.prefix(10).enumerated()), id: \.element.key) { index, item in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(CardText.secondary)
                                .frame(width: 24)

                            Text(item.key)
                                .font(.subheadline)
                                .foregroundStyle(CardText.body)

                            Spacer()

                            Text("\(item.value)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(CardText.title)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Correlations Card

    private var correlationsCard: some View {
        ReportCard(
            title: "Correlation Insights",
            subtitle: "Pattern relationships",
            theme: theme,
            minHeight: 280
        ) {
            if report.correlations.isEmpty {
                ReportEmptyState(message: "Not enough data for correlation analysis")
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(report.correlations, id: \.self) { correlation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.subheadline)

                            Text(correlation)
                                .font(.subheadline)
                                .foregroundStyle(CardText.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
            }
        }
    }

    // MARK: - Performance Card

    private var performanceCard: some View {
        ReportCard(title: "Best vs Challenging Days", subtitle: "Performance analysis", theme: theme) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                bestDaysSection
                Divider()
                challengingDaysSection
            }
        }
    }

    private var bestDaysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Best Performing Days", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(SemanticColor.success)

            ForEach(report.bestDays.prefix(3), id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
            }
        }
    }

    private var challengingDaysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Challenging Days", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(SemanticColor.warning)

            ForEach(report.challengingDays.prefix(3), id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
            }
        }
    }
}

#Preview {
    MonthlyReportView(
        report: MonthlyReport(
            totalEntries: 100,
            mostActiveWeek: "Week 2",
            averagePerDay: 3.3,
            topPatterns: [],
            correlations: [],
            bestDays: [],
            challengingDays: []
        ),
        theme: .purple
    )
}
