import SwiftUI

struct AIInsightsSettingsView: View {
    @ObservedObject var viewModel: AIInsightsTabViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSavedFeedback = false

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
