import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Binding var showingProfile: Bool

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        MedicationQuickLogView()
                        streakCard
                        todaySummaryCard
                        recentEntriesSection
                        quickInsightsSection
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
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

    private var streakCard: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 4) {
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
                    .foregroundStyle(.blue)
            }

            Text("Entries today")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }

    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Summary")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.todayCategoryBreakdown.isEmpty {
                Text("No entries logged today")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.todayCategoryBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                        HStack {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .foregroundStyle(category.color)

                            Text(category.rawValue)
                                .font(.callout)

                            Spacer()

                            Text("\(count)")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                        .foregroundStyle(.blue)
                }
            }

            if viewModel.recentEntries.isEmpty {
                Text("No recent entries")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.recentEntries.prefix(5))) { entry in
                        EntryRowView(entry: entry)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }

    private var quickInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Insights")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 14) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
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
                    color: .purple,
                    title: "Monthly Entries",
                    value: "\(viewModel.monthlyEntryCount)"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }
}

struct EntryRowView: View {
    let entry: PatternEntry

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        HStack(spacing: 12) {
            if let category = entry.patternCategoryEnum {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.patternType)
                    .font(.callout)
                    .fontWeight(.medium)

                Text(entry.timestamp, style: .time)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.intensity > 0 {
                IntensityBadge(intensity: entry.intensity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
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
                .font(.callout)

            Spacer()

            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Profile Button

struct ProfileButton: View {
    @Binding var showingProfile: Bool
    @ObservedObject private var dataController = DataController.shared

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
                #elseif os(macOS)
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                #endif
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
