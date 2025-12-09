import SwiftUI

// MARK: - Daily Summary View

struct DailySummaryView: View {
    @Binding var showingProfile: Bool
    @StateObject private var viewModel = DailySummaryViewModel()
    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Spacing.lg) {
                        ForEach(viewModel.daySummaries) { daySummary in
                            DaySummaryCard(
                                summary: daySummary,
                                showPatterns: viewModel.showPatterns,
                                onCopyEntry: { viewModel.copyEntrySummary($0) },
                                onShareEntry: { viewModel.showShareOptions(for: $0) }
                            )
                        }

                        // Empty state
                        if viewModel.daySummaries.isEmpty && !viewModel.isLoading {
                            NoEntriesView()
                        }

                        // Loading
                        if viewModel.isLoading {
                            SummaryLoadingView()
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showPatterns.toggle()
                    } label: {
                        Image(systemName: viewModel.showPatterns ? "tag.fill" : "tag")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .modifier(CircularGlassModifier())
                }

                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .task {
                await viewModel.loadSummaries()
            }
        }
        .sheet(item: $viewModel.entryToShare) { entry in
            TranslationShareSheet(
                entry: entry,
                onShare: { text in
                    viewModel.shareText(text)
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $viewModel.shareItem) { item in
            ShareSheet(items: [item.text])
        }
    }
}

// MARK: - Day Summary Card

struct DaySummaryCard: View {
    let summary: DaySummary
    let showPatterns: Bool
    let onCopyEntry: (EntrySummary) -> Void
    let onShareEntry: (EntrySummary) -> Void
    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Day header
            Text(summary.dayLabel)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, Spacing.xs)

            // Entry summaries
            ForEach(summary.entries) { entry in
                EntrySummaryRow(
                    entry: entry,
                    showPatterns: showPatterns,
                    onCopy: { onCopyEntry(entry) },
                    onShare: { onShareEntry(entry) }
                )

                // Divider between entries
                if entry.id != summary.entries.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Entry Summary Row

struct EntrySummaryRow: View {
    let entry: EntrySummary
    let showPatterns: Bool
    let onCopy: () -> Void
    let onShare: () -> Void
    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Time on top
            Text(entry.timeLabel)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))

            // Summary text
            if entry.isGenerating {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white.opacity(0.6))
                    Text("Summarizing...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                Text(entry.summary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Patterns (if enabled)
            if showPatterns && !entry.patterns.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(entry.patterns, id: \.self) { pattern in
                        Text(pattern)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.primaryColor.opacity(0.3))
                            .foregroundStyle(.white.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Empty State

struct NoEntriesView: View {
    @ThemeWrapper var theme

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundStyle(theme.primaryColor.opacity(0.5))

            VStack(spacing: Spacing.sm) {
                Text("No entries yet")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text("Your journal entries will appear here as easy-to-read summaries")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Loading View

struct SummaryLoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(.white)

            Text("Loading summaries...")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, Spacing.xxl)
    }
}

// MARK: - Translation Share Sheet

struct TranslationShareSheet: View {
    let entry: EntrySummary
    let onShare: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage: ShareLanguage = .english
    @State private var translatedText: String = ""
    @State private var isTranslating = false
    @ThemeWrapper var theme

    private var userName: String {
        UserProfileRepository.shared.getCurrentProfile()?.name ?? ""
    }

    enum ShareLanguage: String, CaseIterable {
        case english = "English"
        case german = "Deutsch"
        case arabic = "العربية"

        var code: String {
            switch self {
            case .english: return "en"
            case .german: return "de"
            case .arabic: return "ar"
            }
        }

        var flag: String {
            switch self {
            case .english: return "🇬🇧"
            case .german: return "🇩🇪"
            case .arabic: return "🇸🇦"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Language selection
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Share in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(ShareLanguage.allCases, id: \.self) { lang in
                            Button {
                                selectedLanguage = lang
                                Task { await translateEntry() }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(lang.flag)
                                    Text(lang.rawValue)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedLanguage == lang ? theme.primaryColor : Color.gray.opacity(0.2))
                                .foregroundStyle(selectedLanguage == lang ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Preview
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Preview")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if isTranslating {
                        HStack {
                            ProgressView()
                            Text("Translating...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else {
                        Text(translatedText)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                }

                Spacer()

                // Share button
                Button {
                    onShare(translatedText)
                    dismiss()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primaryColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .disabled(isTranslating || translatedText.isEmpty)
            }
            .padding()
            .navigationTitle("Share Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await translateEntry()
        }
    }

    private func translateEntry() async {
        isTranslating = true

        // Format as "I feel X" style for sharing
        let shareFormat = formatForSharing(entry.summary)

        if selectedLanguage == .english {
            translatedText = shareFormat
            isTranslating = false
            return
        }

        // Translate using Gemini
        do {
            let prompt = """
            Translate this text to \(selectedLanguage.rawValue). Keep it natural and conversational.
            Only return the translation, nothing else.

            Text: \(shareFormat)
            """

            let response = try await GeminiService.shared.generateContent(prompt: prompt)
            translatedText = response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            translatedText = shareFormat // Fallback to English
        }

        isTranslating = false
    }

    private func formatForSharing(_ summary: String) -> String {
        // AI now generates summaries with "You" directly
        // This is kept as a fallback for older summaries that might have the user's name
        guard !userName.isEmpty else { return summary }

        return summary
            .replacingOccurrences(of: "\(userName) ", with: "You ")
            .replacingOccurrences(of: "\(userName)'s", with: "Your")
    }
}

// MARK: - Preview

#Preview {
    DailySummaryView(showingProfile: .constant(false))
}
