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
    let icon: String
    let color: Color

    static func parse(from markdown: String) -> [AIInsightCard] {
        var cards: [AIInsightCard] = []

        // Split by headers (### or **)
        let lines = markdown.components(separatedBy: "\n")
        var currentTitle = ""
        var currentContent: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for header patterns
            if trimmed.hasPrefix("###") || trimmed.hasPrefix("##") || trimmed.hasPrefix("#") {
                // Save previous card if exists
                if !currentTitle.isEmpty && !currentContent.isEmpty {
                    cards.append(createCard(title: currentTitle, content: currentContent.joined(separator: "\n")))
                }
                // Start new section
                currentTitle = trimmed
                    .replacingOccurrences(of: "###", with: "")
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentContent = []
            } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && !trimmed.contains(":") {
                // Bold line as header (e.g., **Key Patterns**)
                if !currentTitle.isEmpty && !currentContent.isEmpty {
                    cards.append(createCard(title: currentTitle, content: currentContent.joined(separator: "\n")))
                }
                currentTitle = trimmed.replacingOccurrences(of: "**", with: "")
                currentContent = []
            } else if !trimmed.isEmpty && trimmed != "---" {
                currentContent.append(line)
            }
        }

        // Don't forget the last card
        if !currentTitle.isEmpty && !currentContent.isEmpty {
            cards.append(createCard(title: currentTitle, content: currentContent.joined(separator: "\n")))
        }

        // If no cards were parsed, create a single card with all content
        if cards.isEmpty && !markdown.isEmpty {
            cards.append(AIInsightCard(
                title: "Insights",
                content: markdown,
                icon: "sparkles",
                color: .purple
            ))
        }

        return cards
    }

    private static func createCard(title: String, content: String) -> AIInsightCard {
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

        return AIInsightCard(title: title, content: content.trimmingCharacters(in: .whitespacesAndNewlines), icon: icon, color: color)
    }
}

struct AIInsightsView: View {
    @StateObject private var viewModel = AIInsightsTabViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingSaveAlert = false
    @State private var cardToSave: AIInsightCard?
    @State private var savedCardIds: Set<UUID> = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Demo mode indicator
                    if viewModel.isDemoMode {
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

                    // Header
                    headerSection

                    // Mode selector (hidden in demo mode)
                    if !viewModel.isDemoMode {
                        modeSelectorSection
                    }

                    // Content based on mode
                    if viewModel.isDemoMode {
                        // Demo mode - always show analysis section
                        analysisSection
                    } else if viewModel.analysisMode == .local {
                        // Local mode - always available
                        analysisSection
                    } else {
                        // AI mode - service account is built-in, just need privacy acknowledgment
                        if !viewModel.hasAcknowledgedPrivacy {
                            privacyNoticeSection
                        } else {
                            analysisSection
                        }
                    }
                }
                .padding()
            }
            .background(Color(PlatformColor.systemGroupedBackground))
            .navigationTitle("Insights")
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

    // MARK: - Mode Selector

    private var modeSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Mode")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(AnalysisMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.analysisMode = mode
                            // Clear previous results when switching modes
                            viewModel.insights = nil
                            viewModel.localInsights = nil
                            viewModel.errorMessage = nil
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
                            viewModel.analysisMode == mode
                                ? Color.purple
                                : Color(PlatformColor.tertiarySystemGroupedBackground)
                        )
                        .foregroundColor(viewModel.analysisMode == mode ? .white : .primary)
                        .cornerRadius(10)
                    }
                }
            }

            // Info about current mode
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: viewModel.analysisMode == .local ? "checkmark.shield.fill" : "network")
                    .foregroundColor(viewModel.analysisMode == .local ? .green : .blue)
                    .font(.caption)

                Text(viewModel.analysisMode == .local
                    ? "All analysis happens on your device. No data leaves your phone."
                    : "Data is sent to AI services for analysis. Requires internet connection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(PlatformColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Privacy Notice

    private var privacyNoticeSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Privacy Notice", systemImage: "hand.raised.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                Text("To provide AI insights, your data will be sent to an AI service (Google Gemini or Anthropic Claude). This includes:")
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    privacyBullet("Pattern entries and intensities")
                    privacyBullet("Journal content and mood ratings")
                    privacyBullet("Medication names and effectiveness")
                }

                Text("No personally identifying information (name, email, location) is sent. You can choose which data to include.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(PlatformColor.secondarySystemGroupedBackground))
            .cornerRadius(12)

            Button {
                viewModel.acknowledgePrivacy()
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

    private func privacyBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(spacing: 16) {
            // Options
            VStack(alignment: .leading, spacing: 12) {
                Text("Include in Analysis")
                    .font(.headline)

                Toggle("Pattern Entries", isOn: $viewModel.includePatterns)
                Toggle("Journal Entries", isOn: $viewModel.includeJournals)
                Toggle("Medications", isOn: $viewModel.includeMedications)

                Divider()

                Picker("Timeframe", selection: $viewModel.timeframeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(PlatformColor.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Analyze button
            Button {
                Task {
                    await viewModel.analyze()
                }
            } label: {
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
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isAnalyzing ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isAnalyzing)

            // Error message
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Results - show based on mode
            if viewModel.analysisMode == .local {
                if let localInsights = viewModel.localInsights {
                    localInsightsResultSection(localInsights)
                }
            } else {
                if let insights = viewModel.insights {
                    aiInsightsResultSection(insights)
                }
            }
        }
    }

    // MARK: - AI Results Section

    private func aiInsightsResultSection(_ insights: AIInsights) -> some View {
        let cards = AIInsightCard.parse(from: insights.content)

        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Insights")
                    .font(.headline)
                Spacer()
                Text(insights.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Hint
            Text("Hold a card to save to journal")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Cards
            ForEach(cards) { card in
                insightCardView(card)
            }

            // Copy all button
            Button {
                #if os(iOS)
                UIPasteboard.general.string = insights.content
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
                    Image(systemName: viewModel.showCopiedFeedback ? "checkmark" : "doc.on.doc")
                    Text(viewModel.showCopiedFeedback ? "Copied!" : "Copy All Insights")
                }
                .font(.subheadline)
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(.vertical)
        .alert("Save to Journal", isPresented: $showingSaveAlert) {
            Button("Save") {
                if let card = cardToSave {
                    saveCardToJournal(card)
                }
            }
            Button("Cancel", role: .cancel) {
                cardToSave = nil
            }
        } message: {
            if let card = cardToSave {
                Text("Save \"\(card.title)\" to your journal as an insight?")
            }
        }
    }

    // MARK: - Insight Card View

    private func insightCardView(_ card: AIInsightCard) -> some View {
        let isSaved = savedCardIds.contains(card.id)

        return VStack(alignment: .leading, spacing: 12) {
            // Card header
            HStack {
                Image(systemName: card.icon)
                    .foregroundColor(card.color)
                    .font(.title3)

                Text(card.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if isSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }

            // Card content
            Text(cleanMarkdown(card.content))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(PlatformColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(card.color.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            cardToSave = card
            showingSaveAlert = true
        }
        .onTapGesture {
            // Single tap can expand/collapse in future
        }
    }

    // MARK: - Save to Journal

    private func saveCardToJournal(_ card: AIInsightCard) {
        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.title = "💡 \(card.title)"
        entry.content = card.content
        entry.mood = 0
        entry.isFavorite = false

        // Create or find "Insights" tag
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Insights")

        do {
            let existingTags = try viewContext.fetch(fetchRequest)
            let insightsTag: Tag

            if let existing = existingTags.first {
                insightsTag = existing
            } else {
                // Create new Insights tag
                insightsTag = Tag(context: viewContext)
                insightsTag.id = UUID()
                insightsTag.name = "Insights"
            }

            entry.addToTags(insightsTag)
            try viewContext.save()

            savedCardIds.insert(card.id)
            cardToSave = nil
        } catch {
            print("Failed to save insight to journal: \(error)")
        }
    }

    // MARK: - Clean Markdown

    private func cleanMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "- ", with: "• ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Local Results Section

    private func localInsightsResultSection(_ insights: LocalInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
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

            Divider()

            ForEach(insights.sections) { section in
                localInsightSectionView(section)
            }
        }
        .padding()
        .background(Color(PlatformColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func localInsightSectionView(_ section: LocalInsightSection) -> some View {
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
                localInsightItemView(insight)
            }
        }
        .padding(.vertical, 8)
    }

    private func localInsightItemView(_ insight: LocalInsightItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon based on type
            Image(systemName: iconForInsightType(insight.type))
                .foregroundColor(colorForInsightType(insight.type))
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
                            .foregroundColor(colorForTrend(insight.trend))
                    }
                }

                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Trend indicator
            if let trend = insight.trend {
                trendIndicator(trend)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconForInsightType(_ type: LocalInsightType) -> String {
        switch type {
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

    private func colorForInsightType(_ type: LocalInsightType) -> Color {
        switch type {
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

    private func colorForTrend(_ trend: LocalInsightTrend?) -> Color {
        switch trend {
        case .positive: return .green
        case .negative: return .red
        case .neutral, .none: return .primary
        }
    }

    @ViewBuilder
    private func trendIndicator(_ trend: LocalInsightTrend) -> some View {
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

    // MARK: - Markdown Helper

    private func markdownToAttributedString(_ markdown: String) -> AttributedString {
        // Pre-process markdown to convert headers to bold (SwiftUI doesn't render ### headers)
        var processed = markdown

        // Convert ### Header to **Header** (bold)
        let headerPattern = /^#{1,3}\s*(.+)$/
        processed = processed
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                let lineStr = String(line)
                if let match = lineStr.firstMatch(of: headerPattern) {
                    return "\n**\(match.1)**\n"
                }
                return lineStr
            }
            .joined(separator: "\n")

        // Clean up extra newlines
        while processed.contains("\n\n\n") {
            processed = processed.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        do {
            return try AttributedString(markdown: processed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(processed)
        }
    }
}

#Preview {
    AIInsightsView()
}
