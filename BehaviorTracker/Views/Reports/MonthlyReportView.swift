import SwiftUI

struct MonthlyReportView: View {
    let report: MonthlyReport
    let theme: AppTheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            heroStatsRow
            summaryCard
            if !report.cascadeInsights.isEmpty {
                cascadeInsightsCard
            }
            correlationsCard
            performanceCard
        }
    }
    
    // MARK: - Hero Stats Row
    
    private var heroStatsRow: some View {
        HStack(spacing: Spacing.md) {
            HeroStatCard(
                value: "\(report.totalPatterns)",
                label: "Patterns",
                sublabel: "This Month",
                iconName: "sparkles",
                color: theme.primaryColor,
                theme: theme
            )
            
            HeroStatCard(
                value: String(format: "%.1f", report.averagePerDay),
                label: "Daily Avg",
                sublabel: "Patterns",
                iconName: "chart.line.uptrend.xyaxis",
                color: Color(red: 0.9, green: 0.6, blue: 0.3), // Soft orange
                theme: theme
            )
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ReportCard(title: "Monthly Overview", subtitle: "Last 30 days", theme: theme, icon: "calendar", iconColor: theme.primaryColor) {
            VStack(spacing: Spacing.lg) {
                EnhancedStatRow(label: "Journal Entries", value: "\(report.totalEntries)", icon: "book.fill")
                EnhancedStatRow(label: "Most Active Week", value: report.mostActiveWeek, icon: "star.fill")
            }
        }
    }

    // MARK: - Top Patterns Card

    private var topPatternsCard: some View {
        ReportCard(title: "Top Patterns", subtitle: "Most frequently detected", theme: theme, icon: "star.fill", iconColor: Color(red: 0.9, green: 0.8, blue: 0.4)) { // Soft yellow
            if report.topPatterns.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.xaxis",
                    title: "No Patterns Yet",
                    message: "Write in your journal to see extracted patterns"
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

    // MARK: - Cascade Insights Card

    private var cascadeInsightsCard: some View {
        ReportCard(
            title: "Pattern Chains",
            subtitle: "How patterns connect",
            theme: theme,
            icon: "arrow.triangle.branch",
            iconColor: Color(red: 0.7, green: 0.5, blue: 0.9) // Soft purple
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(report.cascadeInsights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(Color(red: 0.7, green: 0.5, blue: 0.9)) // Soft purple
                            .font(.subheadline)

                        Text(insight)
                            .font(.subheadline)
                            .foregroundStyle(CardText.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Correlations Card

    private var correlationsCard: some View {
        ReportCard(
            title: "Insights",
            subtitle: "What we noticed",
            theme: theme,
            icon: "lightbulb.fill",
            iconColor: Color(red: 0.9, green: 0.8, blue: 0.4), // Soft yellow
            minHeight: 280
        ) {
            if report.correlations.isEmpty {
                ReportEmptyState(message: "Not enough data for insights yet")
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(report.correlations, id: \.self) { correlation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.4)) // Soft yellow
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
        ReportCard(title: "Best vs Challenging Days", subtitle: "Based on pattern intensity", theme: theme, icon: "scale.3d", iconColor: Color(red: 0.5, green: 0.8, blue: 0.6)) { // Soft green
            VStack(alignment: .leading, spacing: Spacing.lg) {
                bestDaysSection
                Divider()
                challengingDaysSection
            }
        }
    }

    private var bestDaysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Calmer Days", systemImage: "leaf.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(SemanticColor.success)

            if report.bestDays.isEmpty {
                Text("Not enough data yet")
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
            } else {
                ForEach(report.bestDays.prefix(3), id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(CardText.caption)
                }
            }
        }
    }

    private var challengingDaysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Harder Days", systemImage: "cloud.rain.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(SemanticColor.warning)

            if report.challengingDays.isEmpty {
                Text("Not enough data yet")
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
            } else {
                ForEach(report.challengingDays.prefix(3), id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(CardText.caption)
                }
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
