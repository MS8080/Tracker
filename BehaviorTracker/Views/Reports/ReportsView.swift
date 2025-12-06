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
            .sheet(isPresented: $showingExport) {
                ExportDataView(viewModel: settingsViewModel)
            }
        }
    }

    private func refreshReports() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        viewModel.generateReports()
    }

    // MARK: - Analysis Cards Row

    private var analysisCardsRow: some View {
        VStack(spacing: Spacing.md) {
            // Featured AI Insights Card - Full Width
            FeaturedAnalysisCard(
                icon: "sparkles",
                iconColor: Color(red: 0.7, green: 0.5, blue: 0.9), // Soft purple (was SemanticColor.ai)
                title: "AI Insights",
                subtitle: "Get personalized analysis powered by intelligence",
                theme: theme
            ) {
                showingAIInsights = true
            }
            
            // Secondary Actions - Side by Side
            HStack(spacing: Spacing.md) {
                CompactAnalysisCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: theme.primaryColor,
                    title: "Correlations",
                    subtitle: "Find triggers",
                    theme: theme
                ) {
                    showingCorrelations = true
                }
                
                CompactAnalysisCard(
                    icon: "chart.bar.doc.horizontal",
                    iconColor: Color(red: 0.5, green: 0.8, blue: 0.9), // Soft cyan
                    title: "Export",
                    subtitle: "Share data",
                    theme: theme
                ) {
                    showingExport = true
                }
            }
        }
    }

    // MARK: - Timeframe Picker

    @Namespace private var pickerNamespace
    
    private var timeframePicker: some View {
        HStack(spacing: 0) {
            ForEach([ReportTimeframe.weekly, ReportTimeframe.monthly], id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTimeframe = timeframe
                        HapticFeedback.light.trigger()
                    }
                } label: {
                    Text(timeframe == .weekly ? "Weekly" : "Monthly")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTimeframe == timeframe ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if selectedTimeframe == timeframe {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.primaryColor.opacity(0.3))
                                    .matchedGeometryEffect(id: "picker", in: pickerNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Views

// MARK: - Featured Analysis Card (Large, Full Width)

struct FeaturedAnalysisCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .fill(iconColor)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(CardText.title)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(CardText.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.caption)
            }
            .padding(Spacing.lg)
            .cardStyle(theme: theme, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Analysis Card (Small, Side by Side)

struct CompactAnalysisCard: View {
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
                        .frame(width: 48, height: 48)

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
            .frame(minHeight: 120)
            .padding(Spacing.md)
            .cardStyle(theme: theme)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Original Analysis Card (Kept for compatibility)

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

// MARK: - Enhanced Stat Row with Icons and Trends

enum TrendDirection {
    case up, down, neutral
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

struct EnhancedStatRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var trend: TrendDirection? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(CardText.secondary)
                    .frame(width: 20)
            }
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(CardText.secondary)
            
            Spacer()
            
            if let trend = trend {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundStyle(trend.color)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(CardText.body)
        }
    }
}

// MARK: - Original Stat Row (Kept for compatibility)

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
