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
                        // Analysis Cards
                        HStack(spacing: Spacing.md) {
                            correlationInsightsCard
                            aiInsightsCard
                        }

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
                AIInsightsSheetView()
            }
        }
    }
    
    private func refreshReports() async {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        viewModel.generateReports()
    }

    private var correlationInsightsCard: some View {
        Button {
            showingCorrelations = true
        } label: {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: TouchTarget.recommended, height: TouchTarget.recommended)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.white)
                }

                VStack(spacing: Spacing.xs) {
                    Text("Correlations")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.body)

                    Text("Find triggers")
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

    private var aiInsightsCard: some View {
        Button {
            showingAIInsights = true
        } label: {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(SemanticColor.ai)
                        .frame(width: TouchTarget.recommended, height: TouchTarget.recommended)

                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.white)
                }

                VStack(spacing: Spacing.xs) {
                    Text("AI Insights")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.body)

                    Text("Get analysis")
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

    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            Text("Weekly").tag(ReportTimeframe.weekly)
            Text("Monthly").tag(ReportTimeframe.monthly)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .tint(theme.primaryColor)
    }

    private var weeklyReportView: some View {
        VStack(spacing: Spacing.md) {
            reportCard(
                title: "Weekly Summary",
                subtitle: "Last 7 days"
            ) {
                VStack(spacing: Spacing.lg) {
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
                    VStack(spacing: Spacing.md) {
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

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(Array(viewModel.weeklyReport.categoryBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { category, count in
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
                }
            }

            // Pattern Frequency Card - using SimpleBarChart
            equalSizeReportCard(
                title: "Pattern Frequency",
                subtitle: "Top patterns this week"
            ) {
                if viewModel.weeklyReport.patternFrequency.isEmpty {
                    emptyStateView(message: "No data available")
                } else {
                    SimpleBarChart(
                        data: viewModel.weeklyReport.patternFrequency.prefix(5).map { pattern, count in
                            BarChartData(
                                label: pattern,
                                value: Double(count),
                                color: theme.primaryColor
                            )
                        },
                        showValues: true,
                        barHeight: 24
                    )
                }
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        EmptyStateView(
            icon: "chart.bar.xaxis",
            title: "No Data Yet",
            message: message
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func equalSizeReportCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.title)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CardText.secondary)
            }

            content()
                .frame(maxWidth: .infinity, minHeight: 200)
        }
        .padding(Spacing.xl)
        .frame(minHeight: 280)
        .cardStyle(theme: theme)
    }

    private var monthlyReportView: some View {
        VStack(spacing: Spacing.md) {
            reportCard(
                title: "Monthly Summary",
                subtitle: "Last 30 days"
            ) {
                VStack(spacing: Spacing.lg) {
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
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No Patterns Yet",
                        message: "Start logging to see your top patterns"
                    )
                    .frame(height: 150)
                } else {
                    VStack(spacing: Spacing.md) {
                        ForEach(Array(viewModel.monthlyReport.topPatterns.prefix(10).enumerated()), id: \.element.key) { index, item in
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

            equalSizeReportCard(
                title: "Correlation Insights",
                subtitle: "Pattern relationships"
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(viewModel.monthlyReport.correlations, id: \.self) { correlation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.subheadline)

                            Text(correlation)
                                .font(.subheadline)
                                .foregroundStyle(CardText.secondary)
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
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Best Performing Days", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(SemanticColor.success)

                        ForEach(viewModel.monthlyReport.bestDays.prefix(3), id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(CardText.caption)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Challenging Days", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(SemanticColor.warning)

                        ForEach(viewModel.monthlyReport.challengingDays.prefix(3), id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(CardText.caption)
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
        .cardStyle(theme: theme)
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

// MARK: - AI Insights Sheet View

struct AIInsightsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AIInsightsTabViewModel()
    @State private var showingFullReport = false

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        if !viewModel.hasAcknowledgedPrivacy {
                            privacyNoticeCard
                        } else if !viewModel.isAPIKeyConfigured {
                            apiKeyCard
                        } else {
                            analysisOptionsCard
                            analyzeButton

                            if let error = viewModel.errorMessage {
                                errorCard(error)
                            }

                            if viewModel.isAPIKeyConfigured {
                                settingsButton
                            }
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                AIInsightsSettingsView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showingFullReport) {
                FullReportView(viewModel: viewModel, theme: theme)
            }
            .onChange(of: viewModel.insights) { _, newValue in
                if newValue != nil {
                    showingFullReport = true
                }
            }
        }
    }

    // MARK: - Privacy Notice Card

    private var privacyNoticeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundStyle(SemanticColor.warning)
                Text("Privacy Notice")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("To provide AI insights, your data will be sent to Google's Gemini AI service. This includes:")
                .font(.body)
                .foregroundStyle(CardText.secondary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                bulletPoint("Pattern entries and intensities")
                bulletPoint("Journal content and mood ratings")
                bulletPoint("Medication names and effectiveness")
            }

            Text("No personally identifying information is sent. You choose which data to include.")
                .font(.caption)
                .foregroundStyle(CardText.caption)

            Button {
                viewModel.acknowledgePrivacy()
            } label: {
                Text("I Understand, Continue")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Circle()
                .fill(.secondary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.body)
        }
    }

    // MARK: - API Key Card

    private var apiKeyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundStyle(SemanticColor.primary)
                Text("Setup Required")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("To use AI insights, you need a free Gemini API key from Google.")
                .font(.body)
                .foregroundStyle(CardText.secondary)

            Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                HStack {
                    Text("Get your free API key")
                    Image(systemName: "arrow.up.right.square")
                }
                .font(.body)
                .foregroundStyle(SemanticColor.primary)
            }

            TextField("Paste your API key here", text: $viewModel.apiKeyInput)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .autocapitalization(.none)
                #endif
                .autocorrectionDisabled()

            Button {
                viewModel.saveAPIKey()
            } label: {
                Text("Save API Key")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.apiKeyInput.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(viewModel.apiKeyInput.isEmpty)
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    // MARK: - Analysis Options Card

    private var analysisOptionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Analysis Options")
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: Spacing.md) {
                Toggle(isOn: $viewModel.includePatterns) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(SemanticColor.primary)
                        Text("Pattern Entries")
                            .font(.body)
                    }
                }

                Toggle(isOn: $viewModel.includeJournals) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(SemanticColor.success)
                        Text("Journal Entries")
                            .font(.body)
                    }
                }

                Toggle(isOn: $viewModel.includeMedications) {
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(.purple)
                        Text("Medications")
                            .font(.body)
                    }
                }
            }
            .tint(theme.primaryColor)

            Divider()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Timeframe")
                    .font(.body)
                    .foregroundStyle(CardText.secondary)

                Picker("Timeframe", selection: $viewModel.timeframeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        Button {
            Task {
                await viewModel.analyze()
            }
        } label: {
            HStack(spacing: Spacing.md) {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                        .font(.title3)
                }
                Text(viewModel.isAnalyzing ? "Analyzing..." : "Generate AI Insights")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(SemanticColor.ai)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(viewModel.isAnalyzing)
    }

    // MARK: - Error Card

    private func errorCard(_ error: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(SemanticColor.warning)

            Text(error)
                .font(.body)
                .foregroundStyle(CardText.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            viewModel.showingSettings = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "gear")
                    .font(.subheadline)
                    .foregroundStyle(theme.primaryColor)

                Text("AI Settings")
                    .font(.body)
                    .foregroundStyle(CardText.secondary)
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        }
    }
}

#Preview {
    ReportsView()
}
