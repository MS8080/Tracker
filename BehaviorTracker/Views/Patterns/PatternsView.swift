import SwiftUI

struct PatternsView: View {
    @Binding var showingProfile: Bool
    @StateObject private var viewModel = PatternsViewModel()
    @ThemeWrapper var theme
    @State private var showingFlowMap = false
    @AppStorage("showPatternTriggers") private var showTriggers = true

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isDemoMode {
                    // Demo mode content
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Demo mode indicator
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

                            // Summary card for demo
                            demoSummaryCard

                            // Demo pattern details list
                            demoPatternDetailsList
                        }
                        .padding()
                    }
                } else if viewModel.todayPatterns.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Summary card
                            summaryCard

                            // Pattern details list
                            patternDetailsList
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.analyzeUnanalyzedEntries()
                        await viewModel.loadTodayPatterns()
                    }
                }
            }
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }


                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFlowMap = true
                    } label: {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .modifier(CircularGlassModifier())
                    .disabled(viewModel.todayPatterns.isEmpty && !viewModel.isDemoMode)
                }

            }
            .task {
                // Load patterns - this will also check for unanalyzed entries
                await viewModel.loadTodayPatterns()
            }
            .fullScreenCover(isPresented: $showingFlowMap) {
                FullScreenFlowView(
                    patterns: viewModel.todayPatterns,
                    cascades: viewModel.todayCascades,
                    theme: theme
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Analyzing patterns...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: Spacing.sm) {
                Text("No patterns today")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("Write a journal entry and patterns will appear here automatically")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            if viewModel.hasUnanalyzedEntries {
                Button {
                    Task {
                        await viewModel.analyzeUnanalyzedEntries()
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Analyze Journal Entries")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .disabled(viewModel.isAnalyzing)
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(theme.primaryColor)
                    Text("Today's Summary")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .capsuleLabel(theme: theme, style: .title)
                Spacer()
                Text(viewModel.todayDateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Spacing.xl) {
                summaryItem(
                    value: "\(viewModel.todayPatterns.count)",
                    label: "Patterns",
                    icon: "brain"
                )

                summaryItem(
                    value: "\(viewModel.todayCascades.count)",
                    label: "Cascades",
                    icon: "arrow.right"
                )

                summaryItem(
                    value: viewModel.averageIntensity,
                    label: "Avg Intensity",
                    icon: "gauge"
                )
            }

            // Daily summary section
            if viewModel.isGeneratingSummary {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                    Text("Generating daily summary...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.sm)
            } else if let summary = viewModel.todaySummary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, Spacing.sm)
            }

            // Show analyze button if there are unanalyzed entries
            if viewModel.hasUnanalyzedEntries {
                Button {
                    Task {
                        await viewModel.analyzeUnanalyzedEntries()
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(viewModel.isAnalyzing ? "Analyzing..." : "Analyze New Entries")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(theme.primaryColor.opacity(0.3), in: RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .disabled(viewModel.isAnalyzing)
                .padding(.top, Spacing.sm)
            }
        }
        .padding()
        .cardStyle(theme: theme)
    }

    private func summaryItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(theme.primaryColor)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Demo Summary Card

    private var demoSummaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(theme.primaryColor)
                    Text("Today's Summary")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .capsuleLabel(theme: theme, style: .title)
                Spacer()
                Text(viewModel.todayDateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Spacing.xl) {
                summaryItem(
                    value: "\(viewModel.demoPatterns.count)",
                    label: "Patterns",
                    icon: "brain"
                )

                summaryItem(
                    value: "\(viewModel.demoCascades.count)",
                    label: "Cascades",
                    icon: "arrow.right"
                )

                summaryItem(
                    value: viewModel.averageIntensity,
                    label: "Avg Intensity",
                    icon: "gauge"
                )
            }

            // Daily summary
            if let summary = viewModel.todaySummary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, Spacing.sm)
            }
        }
        .padding()
        .cardStyle(theme: theme)
    }

    // MARK: - Demo Pattern Details List

    private var demoPatternDetailsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundStyle(theme.primaryColor)
                    Text("Pattern Details")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .capsuleLabel(theme: theme, style: .title)
                Spacer()

                // Toggle triggers visibility
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTriggers.toggle()
                    }
                } label: {
                    Image(systemName: showTriggers ? "tag.fill" : "tag.slash")
                        .font(.subheadline)
                        .foregroundStyle(showTriggers ? theme.primaryColor : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            ForEach(viewModel.demoPatterns) { pattern in
                DemoPatternDetailRow(pattern: pattern, theme: theme, showTriggers: showTriggers)
            }
        }
        .padding()
        .cardStyle(theme: theme)
    }

    // MARK: - Pattern Details List

    private var patternDetailsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundStyle(theme.primaryColor)
                    Text("Pattern Details")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .capsuleLabel(theme: theme, style: .title)
                Spacer()

                // Toggle triggers visibility
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTriggers.toggle()
                    }
                } label: {
                    Image(systemName: showTriggers ? "tag.fill" : "tag.slash")
                        .font(.subheadline)
                        .foregroundStyle(showTriggers ? theme.primaryColor : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            ForEach(viewModel.todayPatterns) { pattern in
                PatternDetailRow(pattern: pattern, theme: theme, showTriggers: showTriggers)
            }
        }
        .padding()
        .cardStyle(theme: theme)
    }
}

// MARK: - Pattern Detail Row

struct PatternDetailRow: View {
    let pattern: ExtractedPattern
    let theme: AppTheme
    var showTriggers: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 12, height: 12)

                Text(pattern.patternType)
                    .font(.body)
                    .fontWeight(.semibold)
                    .capsuleLabel(theme: theme, style: .title)

                Spacer()

                // Intensity indicator
                HStack(spacing: 3) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(i < pattern.intensity / 2 ? theme.primaryColor : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }

                Text("\(pattern.intensity)/10")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let details = pattern.details, !details.isEmpty {
                Text(details)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Triggers - using wrapping layout (conditionally shown)
            if showTriggers && !pattern.triggers.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Triggers:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(pattern.triggers, id: \.self) { trigger in
                            Text(trigger)
                                .font(.caption)
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }

            // Time
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text(formattedTime)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var categoryColor: Color {
        switch pattern.category {
        case "Sensory": return .red
        case "Executive Function": return .orange
        case "Energy & Regulation": return .purple
        case "Social & Communication": return .blue
        case "Routine & Change": return .yellow
        case "Demand Avoidance": return .pink
        case "Physical & Sleep": return .green
        case "Positive & Coping": return .mint
        default: return .gray
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let timeString = formatter.string(from: pattern.timestamp)

        // Add time of day context if available and not "unknown"
        if let timeOfDay = pattern.timeOfDay,
           timeOfDay.lowercased() != "unknown" {
            return "\(timeString) (\(timeOfDay.capitalized))"
        }

        return timeString
    }
}

// MARK: - Demo Pattern Detail Row

struct DemoPatternDetailRow: View {
    let pattern: DemoModeService.DemoExtractedPattern
    let theme: AppTheme
    var showTriggers: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 12, height: 12)

                Text(pattern.patternType)
                    .font(.body)
                    .fontWeight(.semibold)
                    .capsuleLabel(theme: theme, style: .title)

                Spacer()

                // Intensity indicator
                HStack(spacing: 3) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(i < pattern.intensity / 2 ? theme.primaryColor : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }

                Text("\(pattern.intensity)/10")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let details = pattern.details, !details.isEmpty {
                Text(details)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Triggers - using wrapping layout (conditionally shown)
            if showTriggers && !pattern.triggers.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Triggers:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(pattern.triggers, id: \.self) { trigger in
                            Text(trigger)
                                .font(.caption)
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }

            // Time
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text(formattedTime)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var categoryColor: Color {
        switch pattern.category {
        case "Sensory": return .red
        case "Executive Function": return .orange
        case "Energy & Regulation": return .purple
        case "Social & Communication": return .blue
        case "Routine & Change": return .yellow
        case "Demand Avoidance": return .pink
        case "Physical & Sleep": return .green
        case "Positive & Coping": return .mint
        default: return .gray
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let timeString = formatter.string(from: pattern.timestamp)

        // Add time of day context if available
        if let timeOfDay = pattern.timeOfDay {
            return "\(timeString) (\(timeOfDay.capitalized))"
        }

        return timeString
    }
}

// MARK: - Full Screen Flow View

struct FullScreenFlowView: View {
    let patterns: [ExtractedPattern]
    let cascades: [PatternCascade]
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            theme.gradient
                .ignoresSafeArea()

            // Flow map
            PatternFlowView(
                patterns: patterns,
                cascades: cascades,
                theme: theme
            )
            .ignoresSafeArea()

            // Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                            )
                    }
                    .padding()

                    Spacer()
                }

                Spacer()

                // Hint
                Text("Pinch to zoom • Drag to pan • Double-tap to reset")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.lg)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, Spacing.xl)
            }
        }
    }
}

#Preview {
    PatternsView(showingProfile: .constant(false))
}
