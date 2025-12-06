import SwiftUI

struct CorrelationInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var insights: [CorrelationInsight] = []
    @State private var isLoading = true
    @State private var selectedDays = 30
    @State private var filterType: CorrelationInsight.CorrelationType?

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    private var filteredInsights: [CorrelationInsight] {
        if let filterType = filterType {
            return insights.filter { $0.type == filterType }
        }
        return insights
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Time Range Selector
                        timeRangePicker

                        // Filter Chips
                        filterChips

                        // Insights List
                        if isLoading {
                            loadingView
                        } else if filteredInsights.isEmpty {
                            emptyStateView
                        } else {
                            insightsList
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Correlations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .hideSharedBackground()
            }
            .onAppear {
                loadInsights()
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Period")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                ForEach([7, 30, 90], id: \.self) { days in
                    Button(action: {
                        selectedDays = days
                        loadInsights()
                    }) {
                        Text("\(days) days")
                            .font(.subheadline)
                            .fontWeight(selectedDays == days ? .semibold : .regular)
                            .foregroundStyle(selectedDays == days ? .white : .white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.lg)
                                    .fill(selectedDays == days ? theme.primaryColor : .white.opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding()
        .cardStyle(theme: theme)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    icon: "circle.grid.2x2",
                    isSelected: filterType == nil
                ) {
                    filterType = nil
                }

                FilterChip(
                    title: "Medications",
                    icon: "pills",
                    isSelected: filterType == .medicationPattern
                ) {
                    filterType = .medicationPattern
                }

                FilterChip(
                    title: "Time",
                    icon: "clock",
                    isSelected: filterType == .timePattern
                ) {
                    filterType = .timePattern
                }

                FilterChip(
                    title: "Factors",
                    icon: "list.bullet",
                    isSelected: filterType == .factorPattern
                ) {
                    filterType = .factorPattern
                }

                FilterChip(
                    title: "Mood",
                    icon: "face.smiling",
                    isSelected: filterType == .moodPattern
                ) {
                    filterType = .moodPattern
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Insights List

    private var insightsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredInsights) { insight in
                InsightCard(insight: insight, theme: theme)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Analyzing patterns...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))

            Text("Not enough data yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Keep tracking patterns and medications to see correlations")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .cardStyle(theme: theme)
    }

    // MARK: - Load Insights

    private func loadInsights() {
        isLoading = true

        Task {
            let generatedInsights = await CorrelationAnalysisService.shared.generateInsights(days: selectedDays)

            await MainActor.run {
                withAnimation {
                    self.insights = generatedInsights
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(isSelected ? Color.blue : .white.opacity(0.15))
            )
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: CorrelationInsight
    let theme: AppTheme

    private var typeIcon: String {
        switch insight.type {
        case .medicationPattern: return "pills.fill"
        case .timePattern: return "clock.fill"
        case .factorPattern: return "list.bullet.circle.fill"
        case .moodPattern: return "face.smiling.fill"
        }
    }

    private var typeColor: Color {
        switch insight.type {
        case .medicationPattern: return .green
        case .timePattern: return .blue
        case .factorPattern: return .orange
        case .moodPattern: return .pink
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type icon and confidence
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: typeIcon)
                        .foregroundStyle(typeColor)

                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.title)
                }

                Spacer()

                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                    Text(insight.confidence.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(confidenceColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(confidenceColor.opacity(0.2))
                )
            }

            // Description
            Text(insight.description)
                .font(.body)
                .foregroundStyle(CardText.body)

            // Strength bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Correlation Strength")
                        .font(.caption)
                        .foregroundStyle(CardText.caption)

                    Spacer()

                    Text("\(Int(insight.strength * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.title)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [theme.primaryColor.opacity(0.6), theme.primaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * insight.strength, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Sample size
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.caption)
                Text("Based on \(insight.sampleSize) data points")
                    .font(.caption)
            }
            .foregroundStyle(CardText.caption)
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    private var confidenceColor: Color {
        switch insight.confidence {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        }
    }
}

#Preview {
    CorrelationInsightsView()
}
