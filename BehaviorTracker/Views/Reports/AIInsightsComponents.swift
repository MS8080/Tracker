import SwiftUI

// MARK: - Mode Selector

struct AnalysisModeSelector: View {
    @Binding var selectedMode: AnalysisMode
    let onModeChange: () -> Void
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Analysis Mode")
                .font(.headline)
                .foregroundStyle(CardText.title)

            HStack(spacing: Spacing.md) {
                ForEach(AnalysisMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMode = mode
                            onModeChange()
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16))
                            Text(mode.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            selectedMode == mode
                                ? theme.primaryColor
                                : CardText.caption.opacity(0.2)
                        )
                        .foregroundStyle(selectedMode == mode ? .white : CardText.body)
                        .cornerRadius(10)
                    }
                }
            }

            modeDescription
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    private var modeDescription: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: selectedMode == .local ? "checkmark.shield.fill" : "network")
                .foregroundStyle(selectedMode == .local ? .green : .blue)
                .font(.caption)

            Text(selectedMode == .local
                ? "All analysis happens on your device. No data leaves your phone."
                : "Data is sent to AI services for analysis. Requires internet connection.")
                .font(.caption)
                .foregroundStyle(CardText.secondary)
        }
        .padding(.top, Spacing.xs)
    }
}

// MARK: - Privacy Notice

struct PrivacyNoticeView: View {
    let onAcknowledge: () -> Void
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Privacy Notice", systemImage: "hand.raised.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text("To provide AI insights, your data will be sent to an AI service (Google Gemini or Anthropic Claude). This includes:")
                    .font(.subheadline)
                    .foregroundStyle(CardText.body)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    PrivacyBullet(text: "Pattern entries and intensities")
                    PrivacyBullet(text: "Journal content and mood ratings")
                    PrivacyBullet(text: "Medication names and effectiveness")
                }

                Text("No personally identifying information (name, email, location) is sent. You can choose which data to include.")
                    .font(.caption)
                    .foregroundStyle(CardText.secondary)
            }
            .padding(Spacing.lg)
            .cardStyle(theme: theme)

            Button {
                onAcknowledge()
            } label: {
                Text("I Understand, Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
        }
    }
}

struct PrivacyBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(CardText.secondary)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(CardText.body)
        }
    }
}

// MARK: - AI Section Header

struct AIInsightsSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
            Text(title)
                .font(.headline)
                .foregroundStyle(CardText.title)
        }
    }
}
