import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var selectedTimeframe: ReportTimeframe = .weekly
    @State private var showingAIInsights = false
    @State private var showingCorrelations = false
    @Binding var showingProfile: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Correlation Insights Card
                        correlationInsightsCard

                        // AI Insights Card
                        aiInsightsCard

                        timeframePicker

                        if selectedTimeframe == .weekly {
                            weeklyReportView
                        } else {
                            monthlyReportView
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .onAppear {
                viewModel.generateReports()
            }
            .sheet(isPresented: $showingAIInsights) {
                AIInsightsView()
            }
            .sheet(isPresented: $showingCorrelations) {
                CorrelationInsightsView()
            }
        }
    }

    private var correlationInsightsCard: some View {
        Button {
            showingCorrelations = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 50, height: 50)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Correlation Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Discover what triggers your patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var aiInsightsCard: some View {
        Button {
            showingAIInsights = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.purple.gradient)
                        .frame(width: 50, height: 50)

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Insights")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Get personalized analysis of your patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            Text("Weekly").tag(ReportTimeframe.weekly)
            Text("Monthly").tag(ReportTimeframe.monthly)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }

    private var weeklyReportView: some View {
        VStack(spacing: 20) {
            reportCard(
                title: "Weekly Summary",
                subtitle: "Last 7 days"
            ) {
                VStack(spacing: 16) {
                    StatRow(label: "Total Entries", value: "\(viewModel.weeklyReport.totalEntries)")
                    StatRow(label: "Most Active Day", value: viewModel.weeklyReport.mostActiveDay)
                    StatRow(label: "Average Per Day", value: String(format: "%.1f", viewModel.weeklyReport.averagePerDay))
                }
            }

            // Category Distribution Card
            equalSizeReportCard(
                title: "Category Distribution",
                subtitle: "Breakdown by category"
            ) {
                if viewModel.weeklyReport.categoryBreakdown.isEmpty {
                    emptyStateView(message: "No data available")
                } else {
                    VStack(spacing: 12) {
                        Chart {
                            ForEach(Array(viewModel.weeklyReport.categoryBreakdown), id: \.key) { category, count in
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

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(viewModel.weeklyReport.categoryBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { category, count in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 10, height: 10)

                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .lineLimit(1)

                                    Spacer()

                                    Text("\(count)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }

            // Energy Trends Card - same size as Category Distribution
            equalSizeReportCard(
                title: "Energy Trends",
                subtitle: "Average energy levels"
            ) {
                if viewModel.weeklyReport.energyTrend.isEmpty {
                    emptyStateView(message: "No energy data logged")
                } else {
                    Chart {
                        ForEach(viewModel.weeklyReport.energyTrend, id: \.date) { dataPoint in
                            LineMark(
                                x: .value("Day", dataPoint.date, unit: .day),
                                y: .value("Energy", dataPoint.value)
                            )
                            .foregroundStyle(.yellow.gradient)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Day", dataPoint.date, unit: .day),
                                y: .value("Energy", dataPoint.value)
                            )
                            .foregroundStyle(.yellow)
                        }
                    }
                    .chartYScale(domain: 1...5)
                }
            }

            // Pattern Frequency Card
            equalSizeReportCard(
                title: "Pattern Frequency",
                subtitle: "Top patterns this week"
            ) {
                if viewModel.weeklyReport.patternFrequency.isEmpty {
                    emptyStateView(message: "No data available")
                } else {
                    Chart {
                        ForEach(Array(viewModel.weeklyReport.patternFrequency.prefix(5)), id: \.key) { pattern, count in
                            BarMark(
                                x: .value("Count", count),
                                y: .value("Pattern", pattern)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                    }
                }
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func equalSizeReportCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
                .frame(maxWidth: .infinity, minHeight: 200)
        }
        .padding(20)
        .frame(minHeight: 280)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    private var monthlyReportView: some View {
        VStack(spacing: 20) {
            reportCard(
                title: "Monthly Summary",
                subtitle: "Last 30 days"
            ) {
                VStack(spacing: 16) {
                    StatRow(label: "Total Entries", value: "\(viewModel.monthlyReport.totalEntries)")
                    StatRow(label: "Most Active Week", value: viewModel.monthlyReport.mostActiveWeek)
                    StatRow(label: "Average Per Day", value: String(format: "%.1f", viewModel.monthlyReport.averagePerDay))
                }
            }

            reportCard(
                title: "Top Patterns",
                subtitle: "Most frequently logged"
            ) {
                if viewModel.monthlyReport.topPatterns.isEmpty {
                    Text("No data available")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.monthlyReport.topPatterns.prefix(10).enumerated()), id: \.element.key) { index, item in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                Text(item.key)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(item.value)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            equalSizeReportCard(
                title: "Correlation Insights",
                subtitle: "Pattern relationships"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.monthlyReport.correlations, id: \.self) { correlation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.subheadline)

                            Text(correlation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if viewModel.monthlyReport.correlations.isEmpty {
                        emptyStateView(message: "Not enough data for correlation analysis")
                    }
                }
            }

            reportCard(
                title: "Best vs Challenging Days",
                subtitle: "Performance analysis"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Best Performing Days", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)

                        ForEach(viewModel.monthlyReport.bestDays.prefix(3), id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Challenging Days", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)

                        ForEach(viewModel.monthlyReport.challengingDays.prefix(3), id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func reportCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

enum ReportTimeframe {
    case weekly
    case monthly
}

#Preview {
    ReportsView()
}
