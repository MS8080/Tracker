import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AIInsightsTabView: View {
    @StateObject private var viewModel = AIInsightsTabViewModel()
    @Binding var showingProfile: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        // Privacy/API Setup if needed
                        if !viewModel.hasAcknowledgedPrivacy {
                            privacyNoticeCard
                        } else if !viewModel.isAPIKeyConfigured {
                            apiKeyCard
                        } else {
                            // Main content
                            analysisOptionsCard
                            analyzeButton

                            if viewModel.isAnalyzing {
                                analyzingCard
                            }

                            if let error = viewModel.errorMessage {
                                errorCard(error)
                            }

                            // Results
                            if let insights = viewModel.insights {
                                // Full report first
                                fullReportCard(insights)

                                // Summary tiles at bottom
                                if let summary = viewModel.summaryInsights {
                                    summarySection(summary)
                                }
                            }
                        }

                        // Settings button
                        if viewModel.isAPIKeyConfigured {
                            settingsButton
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Analyze")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                AIInsightsSettingsView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Privacy Notice Card

    private var privacyNoticeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Privacy Notice")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("To provide AI insights, your data will be sent to Google's Gemini AI service. This includes:")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("Pattern entries and intensities")
                bulletPoint("Journal content and mood ratings")
                bulletPoint("Medication names and effectiveness")
            }

            Text("No personally identifying information is sent. You choose which data to include.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                viewModel.acknowledgePrivacy()
            } label: {
                Text("I Understand, Continue")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(.secondary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.callout)
        }
    }

    // MARK: - API Key Card

    private var apiKeyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Setup Required")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("To use AI insights, you need a free Gemini API key from Google.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                HStack {
                    Text("Get your free API key")
                    Image(systemName: "arrow.up.right.square")
                }
                .font(.callout)
                .foregroundStyle(.blue)
            }

            TextField("Paste your API key here", text: $viewModel.apiKeyInput)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .autocapitalization(.none)
                #endif
                .autocorrectionDisabled()

            Button {
                viewModel.saveAPIKey()
            } label: {
                Text("Save API Key")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.apiKeyInput.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(viewModel.apiKeyInput.isEmpty)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - Analysis Options Card

    private var analysisOptionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Options")
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Toggle(isOn: $viewModel.includePatterns) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.blue)
                        Text("Pattern Entries")
                            .font(.callout)
                    }
                }

                Toggle(isOn: $viewModel.includeJournals) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.green)
                        Text("Journal Entries")
                            .font(.callout)
                    }
                }

                Toggle(isOn: $viewModel.includeMedications) {
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(.purple)
                        Text("Medications")
                            .font(.callout)
                    }
                }
            }
            .tint(theme.primaryColor)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Timeframe")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Picker("Timeframe", selection: $viewModel.timeframeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        Button {
            Task {
                await viewModel.analyze()
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                        .font(.title3)
                }
                Text(viewModel.isAnalyzing ? "Analyzing..." : "Generate AI Insights")
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(viewModel.isAnalyzing)
    }

    // MARK: - Analyzing Card

    private var analyzingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing your data...")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("This may take a moment")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - Error Card

    private func errorCard(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            Text(error)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - Summary Section

    private func summarySection(_ summary: SummaryInsights) -> some View {
        VStack(spacing: 12) {
            // Summary Header
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(.yellow)
                Text("Quick Summary")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 4)

            // Two summary tiles - stacked vertically for more space
            VStack(spacing: 10) {
                // Key Patterns Tile
                summaryTile(
                    title: "Key Patterns",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    content: summary.keyPatterns
                )

                // Recommendations Tile
                summaryTile(
                    title: "Top Advice",
                    icon: "lightbulb.fill",
                    color: .yellow,
                    content: summary.topRecommendation
                )
            }
        }
    }

    private func summaryTile(title: String, icon: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text(content)
                .font(.callout)
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - Full Report Card

    private func fullReportCard(_ insights: AIInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("Full Analysis Report")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(insights.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Rendered markdown content
            formattedInsightsContent(insights.content)

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    copyToClipboard(insights.content)
                } label: {
                    HStack {
                        Image(systemName: viewModel.showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        Text(viewModel.showCopiedFeedback ? "Copied!" : "Copy")
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.primaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.primaryColor, lineWidth: 1)
                    )
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.analyze()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - Formatted Content

    @ViewBuilder
    private func formattedInsightsContent(_ content: String) -> some View {
        let sections = parseMarkdownSections(content)

        VStack(alignment: .leading, spacing: 20) {
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 8) {
                    if !section.title.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: section.icon)
                                .foregroundStyle(section.color)
                            Text(section.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }

                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(section.color.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(bullet)
                                .font(.callout)
                                .foregroundStyle(.primary.opacity(0.9))
                        }
                    }

                    if !section.paragraph.isEmpty {
                        Text(section.paragraph)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func parseMarkdownSections(_ content: String) -> [InsightSection] {
        var sections: [InsightSection] = []
        let lines = content.components(separatedBy: "\n")

        var currentTitle = ""
        var currentBullets: [String] = []
        var currentParagraph = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("##") || trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                // Save previous section
                if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
                    sections.append(InsightSection(
                        title: currentTitle,
                        bullets: currentBullets,
                        paragraph: currentParagraph
                    ))
                }

                // Start new section
                currentTitle = trimmed
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentBullets = []
                currentParagraph = ""

            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                // Clean up markdown bold markers
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    currentBullets.append(bullet)
                }
            } else if !trimmed.isEmpty {
                // Clean up markdown bold markers from paragraphs
                let cleanedLine = trimmed.replacingOccurrences(of: "**", with: "")
                if currentParagraph.isEmpty {
                    currentParagraph = cleanedLine
                } else {
                    currentParagraph += " " + cleanedLine
                }
            }
        }

        // Add final section
        if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
            sections.append(InsightSection(
                title: currentTitle,
                bullets: currentBullets,
                paragraph: currentParagraph.replacingOccurrences(of: "**", with: "")
            ))
        }

        return sections
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            viewModel.showingSettings = true
        } label: {
            HStack {
                Image(systemName: "gear")
                Text("AI Settings")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

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

// MARK: - Supporting Types

struct InsightSection {
    let title: String
    let bullets: [String]
    let paragraph: String

    var icon: String {
        let lowercased = title.lowercased()
        if lowercased.contains("pattern") || lowercased.contains("trend") {
            return "chart.line.uptrend.xyaxis"
        } else if lowercased.contains("recommend") || lowercased.contains("suggest") || lowercased.contains("advice") {
            return "lightbulb.fill"
        } else if lowercased.contains("mood") || lowercased.contains("emotion") {
            return "heart.fill"
        } else if lowercased.contains("sleep") {
            return "moon.fill"
        } else if lowercased.contains("medication") || lowercased.contains("medicine") {
            return "pills.fill"
        } else if lowercased.contains("correlation") || lowercased.contains("connection") {
            return "link"
        } else if lowercased.contains("summary") || lowercased.contains("overview") {
            return "doc.text"
        } else if lowercased.contains("warning") || lowercased.contains("concern") {
            return "exclamationmark.triangle.fill"
        } else {
            return "sparkle"
        }
    }

    var color: Color {
        let lowercased = title.lowercased()
        if lowercased.contains("pattern") || lowercased.contains("trend") {
            return .blue
        } else if lowercased.contains("recommend") || lowercased.contains("suggest") {
            return .yellow
        } else if lowercased.contains("mood") || lowercased.contains("emotion") {
            return .pink
        } else if lowercased.contains("sleep") {
            return .indigo
        } else if lowercased.contains("medication") {
            return .purple
        } else if lowercased.contains("correlation") {
            return .cyan
        } else if lowercased.contains("warning") || lowercased.contains("concern") {
            return .orange
        } else {
            return .green
        }
    }
}

struct SummaryInsights {
    let keyPatterns: String
    let topRecommendation: String
}

// MARK: - ViewModel

@MainActor
class AIInsightsTabViewModel: ObservableObject {
    @Published var includePatterns = true
    @Published var includeJournals = true
    @Published var includeMedications = true
    @Published var timeframeDays = 30

    @Published var isAnalyzing = false
    @Published var insights: AIInsights?
    @Published var summaryInsights: SummaryInsights?
    @Published var errorMessage: String?

    @Published var apiKeyInput = ""
    @Published var showingSettings = false
    @Published var showCopiedFeedback = false

    private let geminiService = GeminiService.shared
    private let analysisService = AIAnalysisService.shared

    var hasAcknowledgedPrivacy: Bool {
        UserDefaults.standard.bool(forKey: "ai_privacy_acknowledged")
    }

    var isAPIKeyConfigured: Bool {
        geminiService.isConfigured
    }

    init() {
        apiKeyInput = geminiService.apiKey ?? ""
    }

    func acknowledgePrivacy() {
        UserDefaults.standard.set(true, forKey: "ai_privacy_acknowledged")
        objectWillChange.send()
    }

    func saveAPIKey() {
        geminiService.apiKey = apiKeyInput
        objectWillChange.send()
    }

    func analyze() async {
        isAnalyzing = true
        errorMessage = nil
        insights = nil
        summaryInsights = nil

        let preferences = AIAnalysisService.AnalysisPreferences(
            includePatterns: includePatterns,
            includeJournals: includeJournals,
            includeMedications: includeMedications,
            timeframeDays: timeframeDays
        )

        do {
            let result = try await analysisService.analyzeData(preferences: preferences)
            insights = result

            // Parse summary from the full report
            summaryInsights = extractSummary(from: result.content)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    private func extractSummary(from content: String) -> SummaryInsights {
        // Extract key patterns - look for pattern-related content
        var keyPatterns = "Based on your data, notable patterns have been identified in your tracked behaviors."
        var topRecommendation = "Continue tracking consistently for more personalized insights."

        let lines = content.components(separatedBy: "\n")
        var inPatternsSection = false
        var inRecommendationsSection = false

        for line in lines {
            let lowercased = line.lowercased()

            if lowercased.contains("pattern") || lowercased.contains("trend") || lowercased.contains("observation") {
                inPatternsSection = true
                inRecommendationsSection = false
            } else if lowercased.contains("recommend") || lowercased.contains("suggest") || lowercased.contains("advice") {
                inPatternsSection = false
                inRecommendationsSection = true
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if (trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ")) {
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                // Clean up markdown bold markers
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    if inPatternsSection && keyPatterns == "Based on your data, notable patterns have been identified in your tracked behaviors." {
                        keyPatterns = bullet
                    } else if inRecommendationsSection && topRecommendation == "Continue tracking consistently for more personalized insights." {
                        topRecommendation = bullet
                    }
                }
            }
        }

        return SummaryInsights(keyPatterns: keyPatterns, topRecommendation: topRecommendation)
    }
}

// MARK: - Settings View

struct AIInsightsSettingsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                List {
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
                            UserDefaults.standard.set(false, forKey: "ai_privacy_acknowledged")
                            dismiss()
                        }

                        Button("Remove API Key", role: .destructive) {
                            GeminiService.shared.apiKey = nil
                            viewModel.apiKeyInput = ""
                            dismiss()
                        }
                    }

                    Section("About") {
                        Text("AI insights are powered by Google's Gemini AI. Your data is processed according to Google's privacy policy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
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
    AIInsightsTabView()
}
