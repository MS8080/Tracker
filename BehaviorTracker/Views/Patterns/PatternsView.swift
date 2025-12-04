import SwiftUI

struct PatternsView: View {
    @Binding var showingProfile: Bool
    @StateObject private var viewModel = PatternsViewModel()
    @ThemeWrapper var theme
    @State private var showingFlowMap = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
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
                        Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .disabled(viewModel.todayPatterns.isEmpty)
                }
            }
            .task {
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
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(theme.primaryColor)
                Text("Today's Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(viewModel.todayDateString)
                    .font(.caption)
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

            if let summary = viewModel.todaySummary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.sm)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private func summaryItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(theme.primaryColor)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pattern Details List

    private var patternDetailsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundStyle(theme.primaryColor)
                Text("Pattern Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            ForEach(viewModel.todayPatterns) { pattern in
                PatternDetailRow(pattern: pattern, theme: theme)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

// MARK: - Pattern Detail Row

struct PatternDetailRow: View {
    let pattern: ExtractedPattern
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 10, height: 10)

                Text(pattern.patternType)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Intensity indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(i < pattern.intensity / 2 ? theme.primaryColor : Color.white.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }

                Text("\(pattern.intensity)/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let details = pattern.details, !details.isEmpty {
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Triggers
            if !pattern.triggers.isEmpty {
                HStack {
                    Text("Triggers:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForEach(pattern.triggers, id: \.self) { trigger in
                        Text(trigger)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1), in: Capsule())
                    }
                }
            }

            // Time
            if let timeOfDay = pattern.timeOfDay {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(timeOfDay.capitalized)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
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
        default: return .gray
        }
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
