import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Full Report View (Full Screen)

struct FullReportView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var appearAnimation = false
    @State private var bookmarkedSections: Set<String> = []
    @State private var flyingTile: FlyingTileInfo?
    @State private var showJournalSuccess = false

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Divider()
                    .opacity(0.3)

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        if let insights = viewModel.insights {
                            // Date
                            dateHeader(insights)

                            // Full report content
                            fullReportContent(insights)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)

                            // Summary tiles
                            if let summary = viewModel.summaryInsights {
                                summarySection(summary)
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 30)
                            }

                            // Regenerate button
                            regenerateButton
                        }
                    }
                    .padding(Spacing.xl)
                }
            }

            // Flying tile animation overlay
            if let flying = flyingTile {
                FlyingTileView(info: flying, theme: theme) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                        flyingTile = nil
                    }
                    showJournalSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showJournalSuccess = false
                    }
                }
            }

            // Success toast
            if showJournalSuccess {
                successToast
            }
        }
        .onAppear {
            loadBookmarks()
            withAnimation(.easeOut(duration: 0.2).delay(0.05)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            Spacer()

            Text("AI Analysis")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Copy button
            if let insights = viewModel.insights {
                Button {
                    copyToClipboard(insights.content)
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.showCopiedFeedback ? Color.green.opacity(0.2) : Color.white.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: viewModel.showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(viewModel.showCopiedFeedback ? .green : .white.opacity(0.9))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Date Header

    private func dateHeader(_ insights: AIInsights) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.2))
                    .frame(width: 28, height: 28)

                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.primaryColor)
            }

            Text(insights.formattedDate)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(CardText.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Full Report Content

    private func fullReportContent(_ insights: AIInsights) -> some View {
        let sections = MarkdownParser.parseMarkdownSections(insights.content)

        return VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(sections.enumerated()), id: \.element.title) { _, section in
                InsightTileView(
                    section: section,
                    theme: theme,
                    isBookmarked: bookmarkedSections.contains(section.title),
                    onBookmark: { toggleBookmark(section.title) },
                    onAddToJournal: { frame in
                        addToJournal(section: section, fromFrame: frame)
                    }
                )
            }
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ summary: SummaryInsights) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(.yellow)
                Text("Quick Summary")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)

            VStack(spacing: 10) {
                SummaryTileView(
                    title: "Key Patterns",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    content: summary.keyPatterns,
                    theme: theme,
                    isBookmarked: bookmarkedSections.contains("Key Patterns"),
                    onBookmark: { toggleBookmark("Key Patterns") },
                    onAddToJournal: { frame in
                        addSummaryToJournal(title: "Key Patterns", content: summary.keyPatterns, fromFrame: frame)
                    }
                )

                SummaryTileView(
                    title: "Top Advice",
                    icon: "lightbulb.fill",
                    color: .yellow,
                    content: summary.topRecommendation,
                    theme: theme,
                    isBookmarked: bookmarkedSections.contains("Top Advice"),
                    onBookmark: { toggleBookmark("Top Advice") },
                    onAddToJournal: { frame in
                        addSummaryToJournal(title: "Top Advice", content: summary.topRecommendation, fromFrame: frame)
                    }
                )
            }
        }
    }

    // MARK: - Regenerate Button

    private var regenerateButton: some View {
        Button {
            Task {
                dismiss()
                try? await Task.sleep(nanoseconds: 300_000_000)
                await viewModel.analyze()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Generate New Analysis")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding()
        }
        .padding(.top, 10)
    }

    // MARK: - Success Toast

    private var successToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Added to Journal")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Bookmark Management

    private func loadBookmarks() {
        if let saved = UserDefaults.standard.stringArray(forKey: "ai_bookmarked_sections") {
            bookmarkedSections = Set(saved)
        }
    }

    private func toggleBookmark(_ sectionTitle: String) {
        if bookmarkedSections.contains(sectionTitle) {
            bookmarkedSections.remove(sectionTitle)
        } else {
            bookmarkedSections.insert(sectionTitle)
        }
        UserDefaults.standard.set(Array(bookmarkedSections), forKey: "ai_bookmarked_sections")
        HapticFeedback.light.trigger()
    }

    // MARK: - Add to Journal

    private func addToJournal(section: InsightSection, fromFrame: CGRect) {
        let content = formatSectionForJournal(section)
        flyingTile = FlyingTileInfo(
            title: section.title,
            content: content,
            icon: section.icon,
            color: section.color,
            startFrame: fromFrame
        )
        saveToJournal(title: "AI Insight: \(section.title)", content: content)
    }

    private func addSummaryToJournal(title: String, content: String, fromFrame: CGRect) {
        let icon = title == "Key Patterns" ? "chart.line.uptrend.xyaxis" : "lightbulb.fill"
        let color: Color = title == "Key Patterns" ? .blue : .yellow
        flyingTile = FlyingTileInfo(
            title: title,
            content: content,
            icon: icon,
            color: color,
            startFrame: fromFrame
        )
        saveToJournal(title: "AI Insight: \(title)", content: content)
    }

    private func formatSectionForJournal(_ section: InsightSection) -> String {
        var text = ""
        if !section.bullets.isEmpty {
            text += section.bullets.map { "• \($0)" }.joined(separator: "\n")
        }
        if !section.paragraph.isEmpty {
            if !text.isEmpty { text += "\n\n" }
            text += section.paragraph
        }
        return text
    }

    private func saveToJournal(title: String, content: String) {
        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.title = title
        entry.content = content
        entry.timestamp = Date()
        entry.mood = 0
        entry.isFavorite = false

        do {
            try viewContext.save()
        } catch {
        }
    }

    // MARK: - Clipboard

    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        viewModel.showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            viewModel.showCopiedFeedback = false
        }
    }
}
