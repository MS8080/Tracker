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
                RiskGaugeSection(
                    risk: analysisService.getCurrentRiskLevel(),
                    theme: theme
                )

                if analysisService.isAnalyzing {
                    AnalysisLoadingView()
                } else if analysisService.currentInsights.isEmpty {
                    AnalysisEmptyStateView()
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
        .onChange(of: selectedTimeRange) {
            Task {
                await analysisService.analyzePatterns(days: selectedTimeRange)
            }
        }
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

#Preview {
    NavigationStack {
        ASDInsightsView()
    }
}
