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
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
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
                .foregroundStyle(CardText.secondary)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("Pattern entries and intensities")
                bulletPoint("Journal content and mood ratings")
                bulletPoint("Medication names and effectiveness")
            }

            Text("No personally identifying information is sent. You choose which data to include.")
                .font(.caption)
                .foregroundStyle(CardText.caption)

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
        .cardStyle(theme: theme)
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
                .foregroundStyle(CardText.secondary)

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
        .cardStyle(theme: theme)
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
                    .foregroundStyle(CardText.secondary)

                Picker("Timeframe", selection: $viewModel.timeframeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
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
                .foregroundStyle(CardText.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
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
                    .foregroundStyle(CardText.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        }
        .padding(.top, 8)
    }
}

#Preview {
    AIInsightsTabView()
}
