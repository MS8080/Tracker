import SwiftUI

struct ASDInsightsView: View {
    @StateObject private var analysisService = ASDPatternAnalysisService.shared
    @State private var selectedTimeRange = 14

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                riskGaugeSection

                if analysisService.isAnalyzing {
                    loadingView
                } else if analysisService.currentInsights.isEmpty {
                    emptyStateView
                } else {
                    insightsSection
                    if !analysisService.triggerChains.isEmpty {
                        triggerChainsSection
                    }
                    dailyLoadSection
                }
            }
            .padding()
        }
        .background(theme.gradient.ignoresSafeArea())
        .navigationTitle("Pattern Analysis")
        .navigationBarTitleDisplayModeInline()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        Text("Last 7 days").tag(7)
                        Text("Last 14 days").tag(14)
                        Text("Last 30 days").tag(30)
                    }
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(theme.primaryColor)
                }
            }
        }
        .task {
            await analysisService.analyzePatterns(days: selectedTimeRange)
        }
        .onChange(of: selectedTimeRange) { _, newValue in
            Task {
                await analysisService.analyzePatterns(days: newValue)
            }
        }
    }

    private var riskGaugeSection: some View {
        let risk = analysisService.getCurrentRiskLevel()

        return VStack(spacing: Spacing.md) {
            Text("Current Load Level")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: min(Double(risk.score) / 100.0, 1.0))
                    .stroke(risk.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: risk.score)

                VStack(spacing: 2) {
                    Text(risk.level)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(risk.color)
                    Text("\(risk.score)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cardStyle(theme: theme)
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing patterns...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Not enough data yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Keep logging patterns to see personalized insights")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Insights")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)

            ForEach(analysisService.currentInsights) { insight in
                ASDInsightCard(insight: insight, theme: theme)
            }
        }
    }

    private var triggerChainsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Trigger Patterns")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)

            ForEach(analysisService.triggerChains) { chain in
                TriggerChainCard(chain: chain, theme: theme)
            }
        }
    }

    private var dailyLoadSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Daily Load History")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)

            if !analysisService.dailyLoads.isEmpty {
                DailyLoadChart(loads: analysisService.dailyLoads, theme: theme)
            }
        }
    }
}

struct ASDInsightCard: View {
    let insight: ASDInsight
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(insight.color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: insight.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(insight.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    HStack(spacing: Spacing.xs) {
                        severityBadge
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("\(insight.dataPoints) data points")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }

            Text(insight.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let suggestion = insight.actionSuggestion {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.xs)
            }

            if !insight.relatedPatterns.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(insight.relatedPatterns.prefix(3), id: \.self) { pattern in
                            Text(pattern)
                                .font(.caption2)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(theme.primaryColor.opacity(0.1))
                                )
                                .foregroundStyle(theme.primaryColor)
                        }
                    }
                }
            }
        }
        .padding()
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(severityBorderColor, lineWidth: insight.severity >= .warning ? 1 : 0.5)
        )
    }

    private var severityBadge: some View {
        Text(severityText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(severityColor.opacity(0.2))
            )
            .foregroundStyle(severityColor)
    }

    private var severityText: String {
        switch insight.severity {
        case .info: return "Info"
        case .attention: return "Attention"
        case .warning: return "Warning"
        case .urgent: return "Urgent"
        }
    }

    private var severityColor: Color {
        switch insight.severity {
        case .info: return .blue
        case .attention: return .yellow
        case .warning: return .orange
        case .urgent: return .red
        }
    }

    private var severityBorderColor: Color {
        switch insight.severity {
        case .info: return .clear
        case .attention: return .yellow.opacity(0.3)
        case .warning: return .orange.opacity(0.5)
        case .urgent: return .red.opacity(0.5)
        }
    }
}

struct TriggerChainCard: View {
    let chain: TriggerChain
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Pattern found \(chain.occurrences)x")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Avg intensity: \(String(format: "%.1f", chain.averageIntensity))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(Array(chain.triggers.enumerated()), id: \.offset) { index, trigger in
                        Text(trigger)
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.primaryColor.opacity(0.1))
                            )
                            .foregroundStyle(.primary)

                        if index < chain.triggers.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(chain.outcome)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.2))
                        )
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
    }
}

struct DailyLoadChart: View {
    let loads: [DailyLoad]
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.lg) {
                legendItem(color: .purple, label: "Sensory")
                legendItem(color: .cyan, label: "Social")
                legendItem(color: .yellow, label: "Demand")
            }
            .font(.caption2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(loads) { load in
                        VStack(spacing: 2) {
                            if load.hadMeltdownOrShutdown {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }

                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 16, height: 60)

                                VStack(spacing: 1) {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.yellow.opacity(0.8))
                                        .frame(width: 16, height: max(2, load.demandLoad * 20))

                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.cyan.opacity(0.8))
                                        .frame(width: 16, height: max(2, load.socialLoad * 20))

                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.purple.opacity(0.8))
                                        .frame(width: 16, height: max(2, load.sensoryLoad * 20))
                                }
                            }

                            Text(dayLabel(load.date))
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xs)
            }
        }
        .padding()
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    NavigationStack {
        ASDInsightsView()
    }
}
