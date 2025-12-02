import SwiftUI
import CoreData

// MARK: - Day Analysis Data

struct DayAnalysisData: Identifiable {
    let id = UUID()
    let entries: [JournalEntry]
    let date: Date
}

// MARK: - Day Analysis View

struct DayAnalysisView: View {
    let entries: [JournalEntry]
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var analysisViewModel = DayAnalysisViewModel()

    @ThemeWrapper var theme

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private var dateHeader: String {
        Self.dateFormatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        dayOverviewCard
                        analysisResultsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Day Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await analysisViewModel.analyzeDay(entries: entries, date: date, context: viewContext)
            }
        }
    }

    // MARK: - Day Overview Card

    private var dayOverviewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("Analyzing Day")
                    .font(.headline)
                Spacer()
                Text("\(entries.count) entries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(dateHeader)
                .font(.title3)
                .fontWeight(.semibold)

            // Timeline preview
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(entries.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { entry in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Text(Self.timeFormatter.string(from: entry.timestamp))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)

                        Text(entry.title ?? entry.preview)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }

    // MARK: - Analysis Results Section

    @ViewBuilder
    private var analysisResultsSection: some View {
        if analysisViewModel.isAnalyzing {
            loadingCard
        } else if let analysis = analysisViewModel.analysisResult {
            analysisResultCard(analysis)
        } else if let error = analysisViewModel.errorMessage {
            errorCard(error)
        }
    }

    private var loadingCard: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing your day...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }

    private func analysisResultCard(_ analysis: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(SemanticColor.warning)
                Text("Day Analysis")
                    .font(.headline)
                Spacer()
            }

            FormattedAnalysisContent(content: analysis, theme: theme)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }

    private func errorCard(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await analysisViewModel.analyzeDay(entries: entries, date: date, context: viewContext)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }
}

#Preview {
    DayAnalysisView(entries: [], date: Date())
}
