import SwiftUI
import Charts

struct WeeklyReportView: View {
    let report: WeeklyReport
    let theme: AppTheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            heroStatsRow
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
    
    // MARK: - Hero Stats Row
    
    private var heroStatsRow: some View {
        HStack(spacing: Spacing.md) {
            HeroStatCard(
                value: "\(report.totalPatterns)",
                label: "Patterns",
                sublabel: "Detected",
                iconName: "chart.line.uptrend.xyaxis",
                color: theme.primaryColor,
                theme: theme
            )
            
            HeroStatCard(
                value: "\(report.totalEntries)",
                label: "Entries",
                sublabel: "Written",
                iconName: "book.fill",
                color: Color(red: 0.5, green: 0.8, blue: 0.9), // Soft cyan
                theme: theme
            )
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ReportCard(title: "Weekly Overview", subtitle: "Last 7 days", theme: theme, icon: "calendar", iconColor: theme.primaryColor) {
            VStack(spacing: Spacing.lg) {
                EnhancedStatRow(label: "Most Active Day", value: report.mostActiveDay, icon: "star.fill")
                EnhancedStatRow(label: "Avg Patterns/Day", value: String(format: "%.1f", report.averagePerDay), icon: "chart.bar.fill")
            }
        }
    }

    // MARK: - Category Distribution Card

    private var categoryDistributionCard: some View {
        ReportCard(
            title: "Category Distribution",
            subtitle: "Breakdown by category",
            theme: theme,
            icon: "chart.pie.fill",
            iconColor: Color(red: 0.7, green: 0.5, blue: 0.9), // Soft purple
            minHeight: 280
        ) {
            if report.categoryBreakdown.isEmpty {
                ReportEmptyState(message: "No patterns extracted yet")
            } else {
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Chart {
                            ForEach(Array(report.categoryBreakdown), id: \.key) { category, count in
                                SectorMark(
                                    angle: .value("Count", count),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 3.5
                                )
                                .foregroundStyle(colorForCategory(category))
                                .opacity(0.9)
                            }
                        }
                        .frame(height: 150)
                        
                        // Center label showing total
                        VStack(spacing: 2) {
                            Text("\(report.categoryBreakdown.values.reduce(0, +))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(CardText.title)
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(CardText.caption)
                        }
                    }

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

                    Text(formatCategoryName(category))
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
            theme: theme,
            icon: "exclamationmark.triangle.fill",
            iconColor: Color(red: 0.9, green: 0.6, blue: 0.3) // Soft orange
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(report.commonTriggers.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { trigger in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.3)) // Soft orange
                            .padding(.top, 6)

                        Text(formatTriggerName(trigger))
                            .font(.subheadline)
                            .foregroundStyle(CardText.body)
                            .fixedSize(horizontal: false, vertical: true)
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
            theme: theme,
            icon: "arrow.triangle.branch",
            iconColor: Color(red: 0.4, green: 0.7, blue: 0.9) // Soft blue
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(report.topCascades, id: \.from) { cascade in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Text(cascade.from)
                                .font(.subheadline)
                                .foregroundStyle(CardText.body)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Image(systemName: "arrow.down")
                                .font(.caption)
                                .foregroundStyle(CardText.caption)
                                .padding(.top, 2)
                        }
                        
                        HStack {
                            Text(cascade.to)
                                .font(.subheadline)
                                .foregroundStyle(theme.primaryColor)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Text("×\(cascade.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(CardText.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(theme.primaryColor.opacity(0.15), in: Capsule())
                        }
                    }
                    .padding(Spacing.sm)
                    .background(CardText.body.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
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
            icon: "chart.bar.fill",
            iconColor: Color(red: 0.5, green: 0.8, blue: 0.9), // Soft cyan
            minHeight: 280
        ) {
            if report.patternFrequency.isEmpty {
                ReportEmptyState(message: "No patterns extracted yet")
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(Array(report.patternFrequency.prefix(5).enumerated()), id: \.element.key) { index, item in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text(item.key)
                                    .font(.subheadline)
                                    .foregroundStyle(CardText.body)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                                
                                Text("\(item.value)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(theme.primaryColor)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.primaryColor.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    // Progress bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.primaryColor)
                                        .frame(width: barWidth(for: item.value, maxValue: report.patternFrequency.first?.value ?? 1, in: geometry.size.width), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
            }
        }
    }
    
    private func barWidth(for value: Int, maxValue: Int, in totalWidth: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        let percentage = CGFloat(value) / CGFloat(maxValue)
        return max(totalWidth * percentage, 20) // Minimum 20pt width
    }

    // MARK: - Helpers

    private func colorForCategory(_ category: String) -> Color {
        let lowercased = category.lowercased()

        if lowercased.contains("sensory") {
            return Color(red: 0.9, green: 0.4, blue: 0.4) // Soft red
        } else if lowercased.contains("executive") {
            return Color(red: 0.9, green: 0.6, blue: 0.3) // Soft orange
        } else if lowercased.contains("energy") || lowercased.contains("regulation") {
            return Color(red: 0.7, green: 0.5, blue: 0.9) // Soft purple
        } else if lowercased.contains("social") || lowercased.contains("communication") {
            return Color(red: 0.4, green: 0.7, blue: 0.9) // Soft blue
        } else if lowercased.contains("routine") || lowercased.contains("change") {
            return Color(red: 0.9, green: 0.8, blue: 0.4) // Soft yellow
        } else if lowercased.contains("demand") || lowercased.contains("pda") || lowercased.contains("avoidance") {
            return Color(red: 0.9, green: 0.6, blue: 0.7) // Soft pink
        } else if lowercased.contains("physical") || lowercased.contains("sleep") {
            return Color(red: 0.5, green: 0.8, blue: 0.6) // Soft green
        } else if lowercased.contains("special") || lowercased.contains("interest") {
            return Color(red: 0.5, green: 0.8, blue: 0.9) // Soft cyan
        } else if lowercased.contains("positive") || lowercased.contains("coping") {
            return Color(red: 0.6, green: 0.9, blue: 0.8) // Soft mint
        } else {
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Soft gray
        }
    }
    
    private func formatCategoryName(_ category: String) -> String {
        // Convert ALL CAPS or lowercase to Title Case
        return category.lowercased()
            .split(separator: " ")
            .map { word in
                // Keep special abbreviations uppercase
                if word.uppercased() == "PDA" || word.uppercased() == "ASD" {
                    return word.uppercased()
                }
                // Handle words with &
                if word == "&" {
                    return "&"
                }
                // Handle words in parentheses
                if word.hasPrefix("(") && word.hasSuffix(")") {
                    let inner = word.dropFirst().dropLast()
                    if inner.uppercased() == "PDA" {
                        return "(PDA)"
                    }
                    return "(\(inner.prefix(1).uppercased() + inner.dropFirst()))"
                }
                // Title case the word
                return word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }
    
    private func formatTriggerName(_ trigger: String) -> String {
        // Capitalize the first letter of the sentence, keep rest as-is
        guard !trigger.isEmpty else { return trigger }
        return trigger.prefix(1).uppercased() + trigger.dropFirst()
    }
}

// MARK: - Reusable Report Components

// MARK: - Hero Stat Card

struct HeroStatCard: View {
    let value: String
    let label: String
    let sublabel: String
    let iconName: String
    let color: Color
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            VStack(spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.body)
                
                Text(sublabel)
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .cardStyle(theme: theme)
    }
}

// MARK: - Report Card

struct ReportCard<Content: View>: View {
    let title: String
    let subtitle: String
    let theme: AppTheme
    var icon: String? = nil
    var iconColor: Color? = nil
    var minHeight: CGFloat? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headline)
                            .foregroundStyle(iconColor ?? theme.primaryColor)
                    }
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(CardText.title)
                }
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
