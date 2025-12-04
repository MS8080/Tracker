import SwiftUI
import CoreData

// MARK: - Analysis Section Model

struct AnalysisSection: Hashable {
    let title: String
    let bullets: [String]
    let paragraph: String
}

// MARK: - Analysis Section Parser

enum AnalysisSectionParser {
    static func parse(_ content: String) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []
        let lines = content.components(separatedBy: "\n")

        var currentTitle = ""
        var currentBullets: [String] = []
        var currentParagraph = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for headers (##, **, or numbered like "1.", "2.")
            if trimmed.hasPrefix("##") || (trimmed.hasPrefix("**") && trimmed.hasSuffix("**")) ||
               trimmed.range(of: "^\\*?\\*?\\d+\\.\\s*", options: .regularExpression) != nil {
                // Save previous section
                if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
                    sections.append(AnalysisSection(
                        title: currentTitle,
                        bullets: currentBullets,
                        paragraph: currentParagraph
                    ))
                }

                // Clean the title
                currentTitle = trimmed
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                currentBullets = []
                currentParagraph = ""

            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                // Bullet point
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    currentBullets.append(bullet)
                }
            } else if !trimmed.isEmpty {
                // Regular text
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
            sections.append(AnalysisSection(
                title: currentTitle,
                bullets: currentBullets,
                paragraph: currentParagraph
            ))
        }

        return sections
    }
}

// MARK: - Formatted Analysis Content View

struct FormattedAnalysisContent: View {
    let content: String
    let theme: AppTheme

    var body: some View {
        let sections = AnalysisSectionParser.parse(content)

        VStack(alignment: .leading, spacing: 20) {
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 10) {
                    if !section.title.isEmpty {
                        Text(section.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.timelineColor)
                    }

                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(theme.timelineColor.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)

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
}

// MARK: - Journal Entry Analysis View

struct JournalEntryAnalysisView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var analysisViewModel = JournalAnalysisViewModel()

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        entryCard
                        analysisResultsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await analysisViewModel.analyzeEntry(entry, context: viewContext)
            }
        }
    }

    // MARK: - Entry Card

    private var entryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
                Text("Analyzing Entry")
                    .font(.headline)
                Spacer()
            }

            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(entry.content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            Text(entry.formattedDate)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(theme: theme, cornerRadius: 20)
    }

    // MARK: - Analysis Results Section

    @ViewBuilder
    private var analysisResultsSection: some View {
        if analysisViewModel.isAnalyzing {
            loadingCard
        } else if let analysis = analysisViewModel.analysisResult {
            analysisResultCard(analysis)
        } else if let error = analysisViewModel.errorMessage {
            errorCard(error)
        }
    }

    private var loadingCard: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .cardStyle(theme: theme, cornerRadius: 20)
    }

    private func analysisResultCard(_ analysis: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(SemanticColor.warning)
                Text("Analysis")
                    .font(.headline)
                Spacer()
            }

            FormattedAnalysisContent(content: analysis, theme: theme)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(theme: theme, cornerRadius: 20)
    }

    private func errorCard(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await analysisViewModel.analyzeEntry(entry, context: viewContext)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .cardStyle(theme: theme, cornerRadius: 20)
    }
}

#Preview {
    JournalEntryAnalysisView(entry: JournalEntry())
}
