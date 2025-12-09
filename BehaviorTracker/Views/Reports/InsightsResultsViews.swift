import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Insights Results View (Full Screen)

struct InsightsResultsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Binding var savedCardIds: Set<UUID>
    @Binding var bookmarkedCardIds: Set<UUID>
    let theme: AppTheme
    let onSaveToJournal: (AIInsightCard) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
            .background(theme.gradient.ignoresSafeArea())
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
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
                    onCopy: { InsightCardActions.copyCard(card) },
                    onBookmark: { InsightCardActions.toggleBookmark(card, in: &bookmarkedCardIds) },
                    onSaveToJournal: { onSaveToJournal(card) }
                )
            }

            InsightCardActions.copyAllButton(insights: insights, viewModel: viewModel, color: theme.primaryColor)
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
            theme.gradient
                .ignoresSafeArea()

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
                    onCopy: { InsightCardActions.copyCard(card) },
                    onBookmark: { InsightCardActions.toggleBookmark(card, in: &bookmarkedCardIds) },
                    onSaveToJournal: { onSaveToJournal(card) }
                )
            }

            InsightCardActions.copyAllButton(insights: insights, viewModel: viewModel, color: .white)
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
        NavigationStack {
            ZStack {
                theme.gradient
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))

            Text("Analyzing your data...")
                .font(.headline)
                .foregroundStyle(.white)

            Text(viewModel.analysisMode == .local ? "Running local analysis" : "Getting AI insights")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
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
                .foregroundStyle(.white)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.5))

            Text("No insights yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
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
                    onCopy: { InsightCardActions.copyCard(card) },
                    onBookmark: { InsightCardActions.toggleBookmark(card, in: &bookmarkedCardIds) },
                    onSaveToJournal: { onSaveToJournal(card) }
                )
            }

            InsightCardActions.copyAllButton(insights: insights, viewModel: viewModel, color: theme.primaryColor)
        }
    }
}

// MARK: - Shared Card Actions

enum InsightCardActions {
    static func copyCard(_ card: AIInsightCard) {
        #if os(iOS)
        UIPasteboard.general.string = card.fullText
        HapticFeedback.light.trigger()
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(card.fullText, forType: .string)
        #endif
    }

    static func toggleBookmark(_ card: AIInsightCard, in bookmarkedCardIds: inout Set<UUID>) {
        if bookmarkedCardIds.contains(card.id) {
            bookmarkedCardIds.remove(card.id)
        } else {
            bookmarkedCardIds.insert(card.id)
            #if os(iOS)
            HapticFeedback.light.trigger()
            #endif
        }
    }

    static func copyAllButton(insights: AIInsights, viewModel: AIInsightsTabViewModel, color: Color) -> some View {
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
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }
}
