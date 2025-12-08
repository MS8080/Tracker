import SwiftUI
import Charts
import CoreData

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var insightsViewModel = AIInsightsTabViewModel()
    @State private var selectedTimeframe: ReportTimeframe = .weekly
    @State private var showingCorrelations = false
    @State private var showingAIInsights = false
    @State private var showingExport = false
    @State private var showingInsightsConfig = false
    @State private var savedCardIds: Set<UUID> = []
    @State private var bookmarkedCardIds: Set<UUID> = []
    @Binding var showingProfile: Bool

    @Namespace private var insightsAnimation

    @Environment(\.managedObjectContext) private var viewContext

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
                    VStack(spacing: Spacing.md) {
                        // Demo mode indicator
                        if viewModel.isDemoMode {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Demo Mode - Sample Data")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.2), in: Capsule())
                        }

                        // Summary Card - TL;DR + Recommendations
                        ReportSummaryCard(
                            summary: viewModel.summary,
                            isLoading: viewModel.isLoadingSummary,
                            theme: theme
                        )

                        AnalysisCardsRow(
                            theme: theme,
                            insightsNamespace: insightsAnimation,
                            onAIInsights: {
                                showingAIInsights = true
                                Task { await insightsViewModel.analyze() }
                            },
                            onCorrelations: { showingCorrelations = true },
                            onExport: { showingExport = true }
                        )

                        TimeframePicker(selectedTimeframe: $selectedTimeframe, theme: theme)

                        if selectedTimeframe == .weekly {
                            WeeklyReportView(report: viewModel.weeklyReport, theme: theme)
                        } else {
                            MonthlyReportView(report: viewModel.monthlyReport, theme: theme)
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    HapticFeedback.light.trigger()
                    await refreshReports()
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingInsightsConfig = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .onAppear {
                viewModel.generateReports()
            }
            .sheet(isPresented: $showingCorrelations) {
                CorrelationInsightsView()
            }
            .fullScreenCover(isPresented: $showingAIInsights) {
                if #available(iOS 18.0, *) {
                    FullScreenInsightsView(
                        viewModel: insightsViewModel,
                        savedCardIds: $savedCardIds,
                        bookmarkedCardIds: $bookmarkedCardIds,
                        theme: theme,
                        namespace: insightsAnimation,
                        onSaveToJournal: saveCardToJournal,
                        onDismiss: {
                            showingAIInsights = false
                        }
                    )
                    .navigationTransition(.zoom(sourceID: "insightsCard", in: insightsAnimation))
                } else {
                    FullScreenInsightsView(
                        viewModel: insightsViewModel,
                        savedCardIds: $savedCardIds,
                        bookmarkedCardIds: $bookmarkedCardIds,
                        theme: theme,
                        namespace: insightsAnimation,
                        onSaveToJournal: saveCardToJournal,
                        onDismiss: {
                            showingAIInsights = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportDataView(viewModel: settingsViewModel)
            }
            .sheet(isPresented: $showingInsightsConfig) {
                AIInsightsSettingsView(viewModel: insightsViewModel)
            }
        }
    }

    private func refreshReports() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        viewModel.generateReports()
    }

    private func saveCardToJournal(_ card: AIInsightCard) {
        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.title = "💡 \(card.title)"

        var content = ""
        if !card.content.isEmpty {
            content += card.content + "\n\n"
        }
        for bullet in card.bullets {
            content += "• " + bullet + "\n"
        }
        entry.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.mood = 0
        entry.isFavorite = false

        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Insights")

        do {
            let existingTags = try viewContext.fetch(fetchRequest)
            let insightsTag: Tag

            if let existing = existingTags.first {
                insightsTag = existing
            } else {
                insightsTag = Tag(context: viewContext)
                insightsTag.id = UUID()
                insightsTag.name = "Insights"
            }

            entry.addToTags(insightsTag)
            try viewContext.save()

            savedCardIds.insert(card.id)
            #if os(iOS)
            HapticFeedback.success.trigger()
            #endif
        } catch {
            print("Failed to save insight to journal: \(error)")
        }
    }
}

#Preview {
    ReportsView()
}
