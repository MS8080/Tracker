import SwiftUI
import CoreData
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - AI Insight Card Model

struct AIInsightCard: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let bullets: [String]
    let icon: String
    let color: Color

    static func parse(from markdown: String) -> [AIInsightCard] {
        var cards: [AIInsightCard] = []
        let lines = markdown.components(separatedBy: "\n")
        var currentTitle = ""
        var currentContent: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("###") || trimmed.hasPrefix("##") || trimmed.hasPrefix("#") {
                if !currentTitle.isEmpty && !currentContent.isEmpty {
                    cards.append(createCard(title: currentTitle, lines: currentContent))
                }
                currentTitle = trimmed
                    .replacingOccurrences(of: "###", with: "")
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentContent = []
            } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && !trimmed.contains(":") {
                if !currentTitle.isEmpty && !currentContent.isEmpty {
                    cards.append(createCard(title: currentTitle, lines: currentContent))
                }
                currentTitle = trimmed.replacingOccurrences(of: "**", with: "")
                currentContent = []
            } else if !trimmed.isEmpty && trimmed != "---" {
                currentContent.append(line)
            }
        }

        if !currentTitle.isEmpty && !currentContent.isEmpty {
            cards.append(createCard(title: currentTitle, lines: currentContent))
        }

        if cards.isEmpty && !markdown.isEmpty {
            cards.append(AIInsightCard(
                title: "Insights",
                content: cleanMarkdownText(markdown),
                bullets: [],
                icon: "sparkles",
                color: .purple
            ))
        }

        return cards
    }

    private static func createCard(title: String, lines: [String]) -> AIInsightCard {
        let lowercased = title.lowercased()
        let icon: String
        let color: Color

        if lowercased.contains("pattern") {
            icon = "waveform.path.ecg"
            color = .blue
        } else if lowercased.contains("trigger") {
            icon = "bolt.fill"
            color = .orange
        } else if lowercased.contains("help") || lowercased.contains("positive") || lowercased.contains("working") {
            icon = "hand.thumbsup.fill"
            color = .green
        } else if lowercased.contains("suggest") || lowercased.contains("recommend") || lowercased.contains("tip") {
            icon = "lightbulb.fill"
            color = .yellow
        } else if lowercased.contains("warning") || lowercased.contains("concern") {
            icon = "exclamationmark.triangle.fill"
            color = .red
        } else {
            icon = "sparkles"
            color = .purple
        }

        var bullets: [String] = []
        var paragraphs: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                let bulletText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                bullets.append(cleanMarkdownText(bulletText))
            } else if let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                // Handle numbered lists (1. 2. 3. etc)
                let bulletText = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                bullets.append(cleanMarkdownText(bulletText))
            } else if !trimmed.isEmpty {
                paragraphs.append(cleanMarkdownText(trimmed))
            }
        }

        return AIInsightCard(
            title: title,
            content: paragraphs.joined(separator: " "),
            bullets: bullets,
            icon: icon,
            color: color
        )
    }

    static func cleanMarkdownText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var fullText: String {
        var text = title + "\n\n"
        if !content.isEmpty {
            text += content + "\n\n"
        }
        for bullet in bullets {
            text += "• " + bullet + "\n"
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Insight Card View

struct InsightCardView: View {
    let card: AIInsightCard
    let theme: AppTheme
    let isSaved: Bool
    let isBookmarked: Bool
    let onCopy: () -> Void
    let onBookmark: () -> Void
    let onSaveToJournal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            cardHeader
            cardBullets
            cardContent
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(theme: theme)
        .contextMenu {
            Button { onCopy() } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button { onBookmark() } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark",
                      systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }
            Button { onSaveToJournal() } label: {
                Label("Add to Journal", systemImage: "book.fill")
            }
        }
    }

    private var cardHeader: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: card.icon)
                .font(.title3)
                .foregroundStyle(card.color)

            Text(card.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(CardText.title)

            Spacer()

            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }

            if isSaved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    private var cardBullets: some View {
        ForEach(Array(card.bullets.enumerated()), id: \.offset) { _, bullet in
            HStack(alignment: .top, spacing: Spacing.sm) {
                Text("•")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(card.color)
                    .frame(width: 16, alignment: .center)

                Text(bullet)
                    .font(.body)
                    .foregroundStyle(CardText.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        if !card.content.isEmpty {
            Text(card.content)
                .font(.body)
                .foregroundStyle(CardText.secondary)
        }
    }
}

// MARK: - Local Insights Section

struct LocalInsightsResultView: View {
    let insights: LocalInsights

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            ForEach(insights.sections) { section in
                LocalInsightSectionView(section: section)
            }
        }
        .padding()
        .background(Color(PlatformColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var header: some View {
        HStack {
            Image(systemName: "cpu")
                .foregroundColor(.green)
            Text("Local Analysis")
                .font(.headline)
            Spacer()
            Text(insights.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Local Insight Section View

struct LocalInsightSectionView: View {
    let section: LocalInsightSection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .foregroundColor(.purple)
                    .font(.subheadline)
                Text(section.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(section.insights) { insight in
                LocalInsightItemView(insight: insight)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Local Insight Item View

struct LocalInsightItemView: View {
    let insight: LocalInsightItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForType)
                .foregroundColor(colorForType)
                .frame(width: 20)
                .font(.caption)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let value = insight.value {
                        Spacer()
                        Text(value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorForTrend)
                    }
                }

                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let trend = insight.trend {
                TrendIndicator(trend: trend)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconForType: String {
        switch insight.type {
        case .statistic: return "number"
        case .pattern: return "waveform.path.ecg"
        case .time: return "clock"
        case .warning: return "exclamationmark.triangle"
        case .factor: return "list.bullet"
        case .category: return "folder"
        case .mood: return "face.smiling"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .streak: return "flame"
        case .medication: return "pills"
        case .adherence: return "checkmark.circle"
        case .effectiveness: return "star"
        case .correlation: return "arrow.triangle.branch"
        case .trigger: return "bolt"
        case .coping: return "heart"
        case .cascade: return "arrow.right.arrow.left"
        case .suggestion: return "lightbulb"
        case .positive: return "hand.thumbsup"
        }
    }

    private var colorForType: Color {
        switch insight.type {
        case .warning: return .orange
        case .positive: return .green
        case .suggestion: return .yellow
        case .mood: return .pink
        case .medication, .adherence: return .blue
        case .effectiveness: return .purple
        case .trigger: return .red
        case .coping: return .green
        default: return .secondary
        }
    }

    private var colorForTrend: Color {
        switch insight.trend {
        case .positive: return .green
        case .negative: return .red
        case .neutral, .none: return .primary
        }
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let trend: LocalInsightTrend

    var body: some View {
        switch trend {
        case .positive:
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .negative:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
        case .neutral:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}

// MARK: - Mode Selector

struct AnalysisModeSelector: View {
    @Binding var selectedMode: AnalysisMode
    let onModeChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Mode")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(AnalysisMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMode = mode
                            onModeChange()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16))
                            Text(mode.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedMode == mode
                                ? Color.purple
                                : Color(PlatformColor.tertiarySystemGroupedBackground)
                        )
                        .foregroundColor(selectedMode == mode ? .white : .primary)
                        .cornerRadius(10)
                    }
                }
            }

            modeDescription
        }
        .padding()
        .background(Color(PlatformColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var modeDescription: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: selectedMode == .local ? "checkmark.shield.fill" : "network")
                .foregroundColor(selectedMode == .local ? .green : .blue)
                .font(.caption)

            Text(selectedMode == .local
                ? "All analysis happens on your device. No data leaves your phone."
                : "Data is sent to AI services for analysis. Requires internet connection.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }
}

// MARK: - Privacy Notice

struct PrivacyNoticeView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Privacy Notice", systemImage: "hand.raised.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                Text("To provide AI insights, your data will be sent to an AI service (Google Gemini or Anthropic Claude). This includes:")
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    PrivacyBullet(text: "Pattern entries and intensities")
                    PrivacyBullet(text: "Journal content and mood ratings")
                    PrivacyBullet(text: "Medication names and effectiveness")
                }

                Text("No personally identifying information (name, email, location) is sent. You can choose which data to include.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(PlatformColor.secondarySystemGroupedBackground))
            .cornerRadius(12)

            Button {
                onAcknowledge()
            } label: {
                Text("I Understand, Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}

struct PrivacyBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - AI Section Header

struct AIInsightsSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
            Text(title)
                .font(.headline)
                .foregroundStyle(CardText.title)
        }
    }
}

// MARK: - Insights Results View (Full Screen)

struct InsightsResultsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Binding var savedCardIds: Set<UUID>
    @Binding var bookmarkedCardIds: Set<UUID>
    let theme: AppTheme
    let onSaveToJournal: (AIInsightCard) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
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
                .padding()
            }
            .background(Color(PlatformColor.systemGroupedBackground))
            .navigationTitle("Results")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

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
                    onSaveToJournal: { onSaveToJournal(card) }
                )
            }

            copyAllButton(insights: insights)
        }
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
}

// MARK: - Full Screen Insights View

struct FullScreenInsightsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Binding var savedCardIds: Set<UUID>
    @Binding var bookmarkedCardIds: Set<UUID>
    let theme: AppTheme
    var namespace: Namespace.ID
    let onSaveToJournal: (AIInsightCard) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            theme.gradient
                .ignoresSafeArea()

            // Scrollable content
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    insightsHeader
                    contentArea
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }

            // X button - top right
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.8))
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.top, 60)
            .padding(.trailing, 20)
        }
    }

    private var insightsHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))

                Text("AI Insights")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            if viewModel.insights != nil {
                Text("Based on your last \(viewModel.timeframeDays) days")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isAnalyzing {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else if viewModel.analysisMode == .local, let localInsights = viewModel.localInsights {
            LocalInsightsResultView(insights: localInsights)
        } else if let insights = viewModel.insights {
            aiInsightsResultSection(insights)
        } else {
            emptyStateView
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
                .frame(height: 100)

            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))

            Text("Analyzing your data...")
                .font(.headline)
                .foregroundStyle(.white)

            Text(viewModel.analysisMode == .local ? "Running local analysis" : "Getting AI insights")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Analysis Failed")
                .font(.headline)
                .foregroundStyle(.white)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.analyze() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
                .frame(height: 100)

            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.5))

            Text("No insights yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func aiInsightsResultSection(_ insights: AIInsights) -> some View {
        let cards = AIInsightCard.parse(from: insights.content)

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            ForEach(cards) { card in
                InsightCardView(
                    card: card,
                    theme: theme,
                    isSaved: savedCardIds.contains(card.id),
                    isBookmarked: bookmarkedCardIds.contains(card.id),
                    onCopy: { copyCard(card) },
                    onBookmark: { toggleBookmark(card) },
                    onSaveToJournal: { onSaveToJournal(card) }
                )
            }

            copyAllButton(insights: insights)
        }
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
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }
}

// MARK: - Direct Insights View (Loading + Results)

struct DirectInsightsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Binding var savedCardIds: Set<UUID>
    @Binding var bookmarkedCardIds: Set<UUID>
    let theme: AppTheme
    let onSaveToJournal: (AIInsightCard) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(PlatformColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isAnalyzing {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.analysisMode == .local, let localInsights = viewModel.localInsights {
                    resultsScrollView {
                        LocalInsightsResultView(insights: localInsights)
                    }
                } else if let insights = viewModel.insights {
                    resultsScrollView {
                        aiInsightsResultSection(insights)
                    }
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryColor))

            Text("Analyzing your data...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(viewModel.analysisMode == .local ? "Running local analysis" : "Getting AI insights")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Analysis Failed")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task { await viewModel.analyze() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(theme.primaryColor.opacity(0.5))

            Text("No insights yet")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultsScrollView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                content()
            }
            .padding()
        }
    }

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
                    onSaveToJournal: { onSaveToJournal(card) }
                )
            }

            copyAllButton(insights: insights)
        }
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
}
