import SwiftUI
import CoreData
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AIInsightsView: View {
    @StateObject private var viewModel = AIInsightsTabViewModel()
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var savedCardIds: Set<UUID> = []
    @State private var bookmarkedCardIds: Set<UUID> = []
    @State private var showingSettings = false
    @State private var showingResults = false

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isDemoMode {
                        demoModeIndicator
                    }

                    currentModelIndicator

                    headerSection

                    contentSection
                }
                .padding()
            }
            .background(Color(PlatformColor.systemGroupedBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSettings) {
                AIInsightsSettingsView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showingResults) {
                InsightsResultsView(
                    viewModel: viewModel,
                    savedCardIds: $savedCardIds,
                    bookmarkedCardIds: $bookmarkedCardIds,
                    theme: theme,
                    onSaveToJournal: saveCardToJournal
                )
            }
            .onChange(of: viewModel.insights) { _, newValue in
                if newValue != nil {
                    showingResults = true
                }
            }
        }
    }

    // MARK: - Demo Mode Indicator

    private var demoModeIndicator: some View {
        HStack {
            Image(systemName: "play.rectangle.fill")
                .foregroundStyle(.orange)
            Text("Demo Mode - Sample Data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.2), in: Capsule())
    }

    // MARK: - Current Mode/Model Indicator

    private var currentModelIndicator: some View {
        let isLocal = viewModel.analysisMode == .local
        let model = AIAnalysisService.shared.selectedModel
        let displayText = isLocal ? "Local Analysis" : model.displayName
        let icon = isLocal ? "cpu" : model.icon
        let color: Color = isLocal ? .green : (model == .claude ? .purple : .blue)

        return Button {
            showingSettings = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("•")
                    .font(.caption)
                Text("\(viewModel.timeframeDays)d")
                    .font(.caption)
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.analysisMode.icon)
                .font(.system(size: 50))
                .foregroundStyle(.purple.gradient)

            Text(viewModel.analysisMode == .local ? "Local Analysis" : "AI-Powered Analysis")
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.analysisMode.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isDemoMode {
            analysisSection
        } else if viewModel.analysisMode == .local {
            analysisSection
        } else {
            if !viewModel.hasAcknowledgedPrivacy {
                PrivacyNoticeView(onAcknowledge: viewModel.acknowledgePrivacy)
            } else {
                analysisSection
            }
        }
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(spacing: 16) {
            analyzeButton
            errorMessage
        }
    }

    private var configSummary: String {
        var parts: [String] = []
        parts.append("\(viewModel.timeframeDays) days")
        if viewModel.analysisMode == .local {
            parts.append("Local")
        } else {
            parts.append(AIAnalysisService.shared.selectedModel.displayName)
        }
        return parts.joined(separator: " • ")
    }

    private var analyzeButton: some View {
        Button {
            Task { await viewModel.analyze() }
        } label: {
            VStack(spacing: 6) {
                HStack {
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: viewModel.analysisMode == .local ? "cpu" : "sparkles")
                    }
                    Text(viewModel.isAnalyzing ? "Analyzing..." : "Analyze My Data")
                }
                .fontWeight(.semibold)

                Text(configSummary)
                    .font(.caption)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isAnalyzing ? Color.gray : Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isAnalyzing)
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let error = viewModel.errorMessage {
            ErrorBannerView(
                title: "Analysis Failed",
                message: error,
                style: error.lowercased().contains("api key") || error.lowercased().contains("not configured") ? .warning : .error,
                primaryAction: ErrorBannerView.ErrorAction(title: "Try Again", icon: "arrow.clockwise") {
                    Task { await viewModel.analyze() }
                },
                secondaryAction: error.lowercased().contains("api key") || error.lowercased().contains("not configured")
                    ? ErrorBannerView.ErrorAction(title: "Settings", icon: "gear") { showingSettings = true }
                    : nil,
                onDismiss: { viewModel.errorMessage = nil }
            )
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.analysisMode == .local {
            if let localInsights = viewModel.localInsights {
                LocalInsightsResultView(insights: localInsights)
            }
        } else {
            if let insights = viewModel.insights {
                aiInsightsResultSection(insights)
            }
        }
    }

    // MARK: - AI Results Section

    private func aiInsightsResultSection(_ insights: AIInsights) -> some View {
        let cards = AIInsightCard.parse(from: insights.content)

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            AIInsightsSectionHeader(title: "Generated Insights", icon: "sparkles")

            ForEach(cards) { card in
                InsightCardView(
                    card: card,
                    theme: theme,
                    isSaved: savedCardIds.contains(card.id),
                    isBookmarked: bookmarkedCardIds.contains(card.id),
                    onCopy: { copyCard(card) },
                    onBookmark: { toggleBookmark(card) },
                    onSaveToJournal: { saveCardToJournal(card) }
                )
            }

            copyAllButton(insights: insights)
        }
    }

    private func copyAllButton(insights: AIInsights) -> some View {
        Button {
            #if os(iOS)
            UIPasteboard.general.string = insights.content
            HapticFeedback.light.trigger()
            #elseif os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(insights.content, forType: .string)
            #endif
            viewModel.showCopiedFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.showCopiedFeedback = false
            }
        } label: {
            HStack {
                Image(systemName: viewModel.showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                Text(viewModel.showCopiedFeedback ? "Copied!" : "Copy All Insights")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(theme.primaryColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Card Actions

    private func clearResults() {
        viewModel.insights = nil
        viewModel.localInsights = nil
        viewModel.errorMessage = nil
    }

    private func copyCard(_ card: AIInsightCard) {
        #if os(iOS)
        UIPasteboard.general.string = card.fullText
        HapticFeedback.light.trigger()
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(card.fullText, forType: .string)
        #endif
    }

    private func toggleBookmark(_ card: AIInsightCard) {
        if bookmarkedCardIds.contains(card.id) {
            bookmarkedCardIds.remove(card.id)
        } else {
            bookmarkedCardIds.insert(card.id)
            #if os(iOS)
            HapticFeedback.light.trigger()
            #endif
        }
    }

    private func saveCardToJournal(_ card: AIInsightCard) {
        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.title = "💡 \(card.title)"

        var content = ""
        if !card.content.isEmpty {
            content += card.content + "\n\n"
        }
        for bullet in card.bullets {
            content += "• " + bullet + "\n"
        }
        entry.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.mood = 0
        entry.isFavorite = false

        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Insights")

        do {
            let existingTags = try viewContext.fetch(fetchRequest)
            let insightsTag: Tag

            if let existing = existingTags.first {
                insightsTag = existing
            } else {
                insightsTag = Tag(context: viewContext)
                insightsTag.id = UUID()
                insightsTag.name = "Insights"
            }

            entry.addToTags(insightsTag)
            try viewContext.save()

            savedCardIds.insert(card.id)
            #if os(iOS)
            HapticFeedback.success.trigger()
            #endif
        } catch {
            print("Failed to save insight to journal: \(error)")
        }
    }
}

#Preview {
    AIInsightsView()
}
