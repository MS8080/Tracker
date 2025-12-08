import SwiftUI

struct AIInsightsSettingsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSavedFeedback = false

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    @State private var selectedModel: AIModel = AIAnalysisService.shared.selectedModel

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                List {
                    Section("Analysis Mode") {
                        Picker("Mode", selection: $viewModel.analysisMode) {
                            ForEach(AnalysisMode.allCases, id: \.self) { mode in
                                HStack {
                                    Image(systemName: mode.icon)
                                    Text(mode == .local ? "Local" : "AI")
                                }
                                .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(viewModel.analysisMode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Analysis Options") {
                        Picker("Timeframe", selection: $viewModel.timeframeDays) {
                            Text("7 days").tag(7)
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                        }

                        Toggle("Include Patterns", isOn: $viewModel.includePatterns)
                        Toggle("Include Journals", isOn: $viewModel.includeJournals)
                        Toggle("Include Medications", isOn: $viewModel.includeMedications)
                    }

                    if viewModel.analysisMode == .ai {
                        Section("AI Model") {
                            Picker("Model", selection: $selectedModel) {
                                ForEach(AIModel.allCases, id: \.self) { model in
                                    HStack {
                                        Image(systemName: model.icon)
                                        Text(model.displayName)
                                    }
                                    .tag(model)
                                }
                            }
                            .onChange(of: selectedModel) { _, newValue in
                                AIAnalysisService.shared.selectedModel = newValue
                                HapticFeedback.selection.trigger()
                            }

                            Text(selectedModel == .claude
                                ? "Claude Opus 4 - Anthropic's most capable model for deep analysis"
                                : "Gemini 2.5 Flash - Fast and cost-effective for quick insights")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if viewModel.analysisMode == .ai && selectedModel == .gemini {
                        Section("Gemini API Key") {
                            SecureField("Gemini API Key", text: $viewModel.apiKeyInput)
                                #if os(iOS)
                                .autocapitalization(.none)
                                #endif
                                .autocorrectionDisabled()

                            Button {
                                viewModel.saveAPIKey()
                                if viewModel.errorMessage == nil {
                                    showSavedFeedback = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showSavedFeedback = false
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Save API Key")
                                    Spacer()
                                    if showSavedFeedback {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }

                            if viewModel.isAPIKeyConfigured && !showSavedFeedback {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("API key configured")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let credentialsURL = URL(string: "https://console.cloud.google.com/apis/credentials") {
                                Link(destination: credentialsURL) {
                                    HStack {
                                        Text("Get a Vertex AI API key")
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                    }
                                }
                            }

                            Text("You need a Google Cloud project with Vertex AI API enabled and an API key with appropriate permissions.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if viewModel.analysisMode == .ai && selectedModel == .claude {
                        Section("Claude Configuration") {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Claude is configured via service account")
                                    .font(.subheadline)
                            }

                            Text("Claude uses secure service account authentication. No additional configuration needed.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if viewModel.analysisMode == .ai {
                        Section("Privacy") {
                            Button("Reset Privacy Acknowledgment", role: .destructive) {
                                UserDefaults.standard.set(false, forKey: "ai_privacy_acknowledged")
                                dismiss()
                            }

                            if selectedModel == .gemini {
                                Button("Remove API Key", role: .destructive) {
                                    GeminiService.shared.apiKey = nil
                                    viewModel.apiKeyInput = ""
                                    dismiss()
                                }
                            }
                        }

                        Section("About") {
                            Text(selectedModel == .claude
                                ? "AI insights are powered by Anthropic's Claude via Google Cloud Vertex AI. Authentication uses a secure service account. Data is processed according to Anthropic's and Google's privacy policies."
                                : "AI insights are powered by Google's Gemini AI via Vertex AI. Your API key is stored securely in the device Keychain. Data is processed according to Google's privacy policy.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Insights Settings")
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
