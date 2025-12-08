import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var selectedTimeframe: ReportTimeframe = .weekly
    @State private var showingCorrelations = false
    @State private var showingAIInsights = false
    @State private var showingExport = false
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
                        // Demo mode indicator
                        if viewModel.isDemoMode {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Demo Mode - Sample Data")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.2), in: Capsule())
                        }

                        // Summary Card - TL;DR + Recommendations
                        ReportSummaryCard(
                            summary: viewModel.summary,
                            isLoading: viewModel.isLoadingSummary,
                            theme: theme
                        )

                        AnalysisCardsRow(
                            theme: theme,
                            onAIInsights: { showingAIInsights = true },
                            onCorrelations: { showingCorrelations = true },
                            onExport: { showingExport = true }
                        )

                        TimeframePicker(selectedTimeframe: $selectedTimeframe, theme: theme)

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
            .sheet(isPresented: $showingExport) {
                ExportDataView(viewModel: settingsViewModel)
            }
        }
    }

    private func refreshReports() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        viewModel.generateReports()
    }
}

#Preview {
    ReportsView()
}
