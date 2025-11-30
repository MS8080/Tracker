import SwiftUI

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
                    .foregroundStyle(.white)
                }
            }
        }
    }
}
