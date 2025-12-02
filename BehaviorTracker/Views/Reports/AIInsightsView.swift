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

                    // Privacy notice
                    if !viewModel.hasAcknowledgedPrivacy {
                        privacyNoticeSection
                    } else if !viewModel.isAPIKeyConfigured {
                        apiKeySection
                    } else {
                        // Analysis options and results
                        analysisSection
                    }
                }
                .padding()
            }
            .background(Color(PlatformColor.systemGroupedBackground))
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.purple.gradient)

            Text("AI-Powered Analysis")
                .font(.title2)
                .fontWeight(.bold)

            Text("Get personalized insights about your patterns, journals, and medications using AI.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
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
                        Image(systemName: "sparkles")
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

            // Results
            if let insights = viewModel.insights {
                insightsResultSection(insights)
            }

            // Settings link
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

    // MARK: - Results Section

    private func insightsResultSection(_ insights: AIInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Your Insights")
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
