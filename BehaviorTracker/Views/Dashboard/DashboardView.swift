import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Binding var showingProfile: Bool

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        MedicationQuickLogView()
                        streakCard
                        todaySummaryCard
                        recentEntriesSection
                        quickInsightsSection
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    HapticFeedback.light.trigger()
                    await refreshData()
                }
            }
            .navigationTitle(NSLocalizedString("dashboard.title", comment: ""))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }

    private func refreshData() async {
        // Simulate refresh with slight delay for smooth animation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        viewModel.loadData()
    }

    private var streakCard: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(SemanticColor.warning)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(viewModel.streakCount) Day Streak")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Keep it going!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(viewModel.todayEntryCount)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(theme.primaryColor)
                    .contentTransition(.numericText())
            }

            Text("Entries today")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Today's Summary")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.todayCategoryBreakdown.isEmpty {
                HStack {
                    Spacer()
                    Text("No entries for today")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 60)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(viewModel.todayCategoryBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                        HStack {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .foregroundStyle(category.color)

                            Text(category.rawValue)
                                .font(.body)

                            Spacer()

                            Text("\(count)")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Recent Entries")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink {
                    HistoryView()
                } label: {
                    Text("View All")
                        .font(.callout)
                        .foregroundStyle(theme.primaryColor)
                }
            }

            if viewModel.recentEntries.isEmpty {
                HStack {
                    Spacer()
                    Text("No recent activity")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 60)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(Array(viewModel.recentEntries.prefix(5))) { entry in
                        EntryRowView(entry: entry)
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    private var quickInsightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Quick Insights")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: Spacing.md) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: theme.primaryColor,
                    title: "Most Logged Pattern",
                    value: viewModel.mostLoggedPattern ?? "None yet"
                )

                InsightRow(
                    icon: "calendar",
                    color: .green,
                    title: "Weekly Entries",
                    value: "\(viewModel.weeklyEntryCount)"
                )

                InsightRow(
                    icon: "chart.bar",
                    color: theme.primaryColor.opacity(0.7),
                    title: "Monthly Entries",
                    value: "\(viewModel.monthlyEntryCount)"
                )
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
}

struct EntryRowView: View {
    let entry: PatternEntry

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: Spacing.md) {
            if let category = entry.patternCategoryEnum {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 36)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.patternType)
                    .font(.body)
                    .fontWeight(.medium)

                Text(entry.timestamp, style: .time)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.intensity > 0 {
                IntensityBadge(intensity: entry.intensity)
            }
        }
        .padding(Spacing.md)
        .compactCardStyle(theme: theme)
    }
}

struct IntensityBadge: View {
    let intensity: Int16

    var body: some View {
        Text("\(intensity)")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(
                Circle()
                    .fill(intensityColor)
            )
    }

    private var intensityColor: Color {
        switch intensity {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            Text(title)
                .font(.body)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Profile Button

struct ProfileButton: View {
    @Binding var showingProfile: Bool
    @ObservedObject private var dataController = DataController.shared
    
    @ThemeWrapper var theme

    var body: some View {
        Button {
            showingProfile = true
        } label: {
            if let profile = dataController.getCurrentUserProfile(),
               let profileImage = profile.profileImage {
                #if os(iOS)
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primaryColor.opacity(0.5), lineWidth: 2)
                    )
                #elseif os(macOS)
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primaryColor.opacity(0.5), lineWidth: 2)
                    )
                #endif
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.primaryColor)
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
