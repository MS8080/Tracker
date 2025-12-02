import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var selectedTimeframe: ReportTimeframe = .weekly
    @State private var showingCorrelations = false
    @State private var showingAIInsights = false
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
                    VStack(spacing: Spacing.lg) {
                        analysisCardsRow
                        timeframePicker

                        if selectedTimeframe == .weekly {
                            WeeklyReportView(report: viewModel.weeklyReport, theme: theme)
                        } else {
                            MonthlyReportView(report: viewModel.monthlyReport, theme: theme)
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    HapticFeedback.light.trigger()
                    await refreshReports()
                }
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
            .sheet(isPresented: $showingCorrelations) {
                CorrelationInsightsView()
            }
            .sheet(isPresented: $showingAIInsights) {
                AIInsightsView()
            }
        }
    }

    private func refreshReports() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        viewModel.generateReports()
    }

    // MARK: - Analysis Cards Row

    private var analysisCardsRow: some View {
        HStack(spacing: Spacing.md) {
            AnalysisCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: theme.primaryColor,
                title: "Correlations",
                subtitle: "Find triggers",
                theme: theme
            ) {
                showingCorrelations = true
            }

            AnalysisCard(
                icon: "sparkles",
                iconColor: SemanticColor.ai,
                title: "AI Insights",
                subtitle: "Get analysis",
                theme: theme
            ) {
                showingAIInsights = true
            }
        }
    }

    // MARK: - Timeframe Picker

    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            Text("Weekly").tag(ReportTimeframe.weekly)
            Text("Monthly").tag(ReportTimeframe.monthly)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .tint(theme.primaryColor)
    }
}

// MARK: - Supporting Views

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

enum ReportTimeframe {
    case weekly
    case monthly
}

#Preview {
    ReportsView()
}
