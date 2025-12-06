import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AIInsightsView: View {
    @StateObject private var viewModel = AIInsightsTabViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Mode selector
                    modeSelectorSection

                    // Content based on mode
                    if viewModel.analysisMode == .local {
                        // Local mode - always available
                        analysisSection
                    } else {
                        // AI mode - needs setup
                        if !viewModel.hasAcknowledgedPrivacy {
                            privacyNoticeSection
                        } else if !viewModel.isAPIKeyConfigured {
                            apiKeySection
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
                    : "Data is sent to Google Gemini for analysis. Requires internet connection.")
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

                Text("To provide AI insights, your data will be sent to Google's Gemini AI service. This includes:")
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

    // MARK: - API Key Section

    private var apiKeySection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Setup Required", systemImage: "key.fill")
                    .font(.headline)
                    .foregroundColor(.blue)

                Text("To use AI insights, you need a free Gemini API key from Google.")
                    .font(.subheadline)

                Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                    HStack {
                        Text("Get your free API key")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.subheadline)
                }

                TextField("Paste your API key here", text: $viewModel.apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .autocapitalization(.none)
                    #endif
                    .autocorrectionDisabled()
            }
            .padding()
            .background(Color(PlatformColor.secondarySystemGroupedBackground))
            .cornerRadius(12)

            Button {
                viewModel.saveAPIKey()
            } label: {
                Text("Save API Key")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.apiKeyInput.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(viewModel.apiKeyInput.isEmpty)
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

            // Settings link (only for AI mode)
            if viewModel.analysisMode == .ai {
                Button {
                    viewModel.showingSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("AI Settings")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .sheet(isPresented: $viewModel.showingSettings) {
                    AISettingsView(viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - AI Results Section

    private func aiInsightsResultSection(_ insights: AIInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            Divider()

            Text(markdownToAttributedString(insights.content))
                .font(.body)
                .lineSpacing(4)

            // Copy button
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
                    Text(viewModel.showCopiedFeedback ? "Copied!" : "Copy Insights")
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(PlatformColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
        do {
            return try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(markdown)
        }
    }
}

// MARK: - Settings View

struct AISettingsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("API Key") {
                    SecureField("Gemini API Key", text: $viewModel.apiKeyInput)
                        #if os(iOS)
                        .autocapitalization(.none)
                        #endif
                        .autocorrectionDisabled()

                    Button("Update API Key") {
                        viewModel.saveAPIKey()
                    }

                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Text("Get a new API key")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }

                Section("Privacy") {
                    Button("Reset Privacy Acknowledgment", role: .destructive) {
                        viewModel.resetPrivacyAcknowledgment()
                        dismiss()
                    }

                    Button("Remove API Key", role: .destructive) {
                        viewModel.removeAPIKey()
                        dismiss()
                    }
                }

                Section("About") {
                    Text("AI insights are powered by Google's Gemini AI. Your data is processed according to Google's privacy policy.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("AI Settings")
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
}

#Preview {
    AIInsightsView()
}
