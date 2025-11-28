import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AIInsightsTabView: View {
    @StateObject private var viewModel = AIInsightsTabViewModel()
    @Binding var showingProfile: Bool
    @State private var showingFullReport = false

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

                            if let error = viewModel.errorMessage {
                                errorCard(error)
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
            .fullScreenCover(isPresented: $showingFullReport) {
                FullReportView(viewModel: viewModel, theme: theme)
            }
            .onChange(of: viewModel.insights) { _, newValue in
                if newValue != nil {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showingFullReport = true
                    }
                }
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
                    .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
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
                    .cornerRadius(CornerRadius.sm)
            }
            .disabled(viewModel.apiKeyInput.isEmpty)
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
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
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
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
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(content)
                .font(.body)
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
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
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - Formatted Content

    @ViewBuilder
    private func formattedInsightsContent(_ content: String) -> some View {
        let sections = parseMarkdownSections(content)

        VStack(alignment: .leading, spacing: 24) {
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 12) {
                    if !section.title.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.title3)
                                .foregroundStyle(section.color)
                            Text(section.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(section.color.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .padding(.top, 8)

                            Text(bullet)
                                .font(.body)
                                .foregroundStyle(.primary.opacity(0.9))
                        }
                    }

                    if !section.paragraph.isEmpty {
                        Text(section.paragraph)
                            .font(.body)
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
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(theme.primaryColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primaryColor)
                }
                
                Text("AI Settings")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary.opacity(0.8))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(theme.cardBackground)
            )
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

                Divider()
                    .opacity(0.3)

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        if let insights = viewModel.insights {
                            // Date
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
                                    .foregroundStyle(.primary.opacity(0.8))
                                Spacer()
                            }
                            .padding(.horizontal, 4)

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
                    }
                    .padding(Spacing.xl)
                }
            }

            // Flying tile animation overlay
            if let flying = flyingTile {
                FlyingTileView(info: flying, theme: theme) {
                    withAnimation(.spring(response: 0.3)) {
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
        }
        .onAppear {
            loadBookmarks()
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    private func fullReportContent(_ insights: AIInsights) -> some View {
        let sections = parseMarkdownSections(insights.content)

        return VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(sections.enumerated()), id: \.element.title) { index, section in
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
            print("Failed to save journal entry: \(error)")
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
                if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
                    sections.append(InsightSection(
                        title: currentTitle,
                        bullets: currentBullets,
                        paragraph: currentParagraph
                    ))
                }

                currentTitle = trimmed
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentBullets = []
                currentParagraph = ""

            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    currentBullets.append(bullet)
                }
            } else if !trimmed.isEmpty {
                let cleanedLine = trimmed.replacingOccurrences(of: "**", with: "")
                if currentParagraph.isEmpty {
                    currentParagraph = cleanedLine
                } else {
                    currentParagraph += " " + cleanedLine
                }
            }
        }

        if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
            sections.append(InsightSection(
                title: currentTitle,
                bullets: currentBullets,
                paragraph: currentParagraph.replacingOccurrences(of: "**", with: "")
            ))
        }

        return sections
    }

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

// MARK: - Insight Tile View with Context Menu

struct InsightTileView: View {
    let section: InsightSection
    let theme: AppTheme
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onAddToJournal: (CGRect) -> Void

    @State private var tileFrame: CGRect = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.title3)
                    .foregroundStyle(section.color)
                Text(section.title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            ForEach(section.bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(section.color.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .padding(.top, 8)

                    Text(bullet)
                        .font(.body)
                        .foregroundStyle(.primary.opacity(0.9))
                }
            }

            if !section.paragraph.isEmpty {
                Text(section.paragraph)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(theme.cardBackground)
                    .onAppear {
                        tileFrame = geo.frame(in: .global)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        tileFrame = newFrame
                    }
            }
        )
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }

            Button {
                onAddToJournal(tileFrame)
            } label: {
                Label("Add to Journal", systemImage: "book.fill")
            }
        }
    }
}

// MARK: - Summary Tile View with Context Menu

struct SummaryTileView: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    let theme: AppTheme
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onAddToJournal: (CGRect) -> Void

    @State private var tileFrame: CGRect = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            Text(content)
                .font(.body)
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(theme.cardBackground)
                    .onAppear {
                        tileFrame = geo.frame(in: .global)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        tileFrame = newFrame
                    }
            }
        )
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }

            Button {
                onAddToJournal(tileFrame)
            } label: {
                Label("Add to Journal", systemImage: "book.fill")
            }
        }
    }
}

// MARK: - Flying Tile Animation (Apple Mail style)

struct FlyingTileInfo: Equatable {
    let title: String
    let content: String
    let icon: String
    let color: Color
    let startFrame: CGRect

    static func == (lhs: FlyingTileInfo, rhs: FlyingTileInfo) -> Bool {
        lhs.title == rhs.title && lhs.startFrame == rhs.startFrame
    }
}

struct FlyingTileView: View {
    let info: FlyingTileInfo
    let theme: AppTheme
    let onComplete: () -> Void

    @State private var animationPhase: Int = 0
    @State private var position: CGPoint
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    init(info: FlyingTileInfo, theme: AppTheme, onComplete: @escaping () -> Void) {
        self.info = info
        self.theme = theme
        self.onComplete = onComplete
        // Start at tile center
        _position = State(initialValue: CGPoint(
            x: info.startFrame.midX,
            y: info.startFrame.midY
        ))
    }

    var body: some View {
        // Mini preview of the tile
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: info.icon)
                    .font(.caption)
                    .foregroundStyle(info.color)
                Text(info.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            Text(info.content)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(theme.cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .position(position)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Get screen dimensions
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Target: Journal tab (3rd tab from left, roughly)
        let targetX = screenWidth * 0.5  // Center-ish for Journal tab
        let targetY = screenHeight - 40  // Tab bar area

        // Phase 1: Lift up and shrink slightly
        withAnimation(.easeOut(duration: 0.15)) {
            scale = 0.9
            position.y -= 20
        }

        // Phase 2: Arc towards journal with rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeIn(duration: 0.4)) {
                position = CGPoint(x: targetX, y: targetY)
                scale = 0.3
                rotation = -15
            }
        }

        // Phase 3: Final shrink and fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.15)) {
                scale = 0.1
                opacity = 0
            }
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onComplete()
        }
    }
}

#Preview {
    AIInsightsTabView()
}
