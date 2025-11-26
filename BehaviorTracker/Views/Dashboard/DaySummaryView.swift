import SwiftUI
import CoreData

struct DaySummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = DaySummaryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var currentSlide = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.todayEntries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Today",
                        systemImage: "calendar",
                        description: Text("Log some patterns to see your daily summary")
                    )
                } else {
                    TabView(selection: $currentSlide) {
                        OverviewSlide(viewModel: viewModel)
                            .tag(0)
                        
                        CategoryBreakdownSlide(viewModel: viewModel)
                            .tag(1)
                        
                        IntensitySlide(viewModel: viewModel)
                            .tag(2)
                        
                        TimelineSlide(viewModel: viewModel)
                            .tag(3)
                        
                        EncouragementSlide(viewModel: viewModel)
                            .tag(4)
                    }
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    #endif
                }
            }
            .navigationTitle("Today's Summary")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadTodayEntries()
            }
        }
    }
}

// MARK: - Overview Slide
struct OverviewSlide: View {
    @ObservedObject var viewModel: DaySummaryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text("How You Did Today")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(Date.now, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    icon: "number",
                    value: "\(viewModel.todayEntries.count)",
                    label: "Entries",
                    color: .blue
                )
                
                StatCard(
                    icon: "chart.bar.fill",
                    value: "\(viewModel.categoriesTracked)",
                    label: "Categories",
                    color: .purple
                )
                
                StatCard(
                    icon: "clock.fill",
                    value: viewModel.totalDurationString,
                    label: "Total Time",
                    color: .green
                )
                
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: String(format: "%.1f", viewModel.averageIntensity),
                    label: "Avg Intensity",
                    color: .orange
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("Swipe to see more →")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
        }
        .padding()
    }
}

// MARK: - Category Breakdown Slide
struct CategoryBreakdownSlide: View {
    @ObservedObject var viewModel: DaySummaryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.purple)
                
                Text("Category Breakdown")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.categoryBreakdown, id: \.category) { breakdown in
                        CategoryBreakdownRow(breakdown: breakdown)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct CategoryBreakdownRow: View {
    let breakdown: CategoryBreakdown

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: breakdown.category.icon)
                .font(.title2)
                .foregroundStyle(breakdown.category.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(breakdown.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(breakdown.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(breakdown.percentage))%")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(breakdown.category.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
    }
}

// MARK: - Intensity Slide
struct IntensitySlide: View {
    @ObservedObject var viewModel: DaySummaryViewModel

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "gauge.high")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)

                Text("Intensity Overview")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 40)

            // Average intensity display
            VStack(spacing: 12) {
                Text("Average Intensity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.1f", viewModel.averageIntensity))
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(intensityColor(viewModel.averageIntensity))

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(Double(level) <= viewModel.averageIntensity ? intensityColor(viewModel.averageIntensity) : Color.secondary.opacity(0.2))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.cardBackground)
            )
            .padding(.horizontal)
            
            // Intensity distribution
            VStack(alignment: .leading, spacing: 12) {
                Text("Intensity Distribution")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(1...5, id: \.self) { intensity in
                    HStack {
                        Text("\(intensity)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 30)
                        
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(intensityColor(Double(intensity)))
                                .frame(width: {
                                    guard let count = viewModel.intensityDistribution[intensity],
                                          viewModel.maxIntensityCount > 0 else {
                                        return 0
                                    }
                                    return geometry.size.width * CGFloat(count) / CGFloat(viewModel.maxIntensityCount)
                                }())
                        }
                        .frame(height: 24)
                        
                        Text("\(viewModel.intensityDistribution[intensity] ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func intensityColor(_ intensity: Double) -> Color {
        switch intensity {
        case 0..<1.5: return .green
        case 1.5..<2.5: return .mint
        case 2.5..<3.5: return .yellow
        case 3.5..<4.5: return .orange
        default: return .red
        }
    }
}

// MARK: - Timeline Slide
struct TimelineSlide: View {
    @ObservedObject var viewModel: DaySummaryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "timeline.selection")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                
                Text("Today's Timeline")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.todayEntries) { entry in
                        TimelineEntryRow(entry: entry)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TimelineEntryRow: View {
    let entry: PatternEntry

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle()
                    .fill(entry.patternCategoryEnum?.color ?? .gray)
                    .frame(width: 12, height: 12)
                
                if entry.id != entry.id { // Always show line
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 2)
                }
            }
            .frame(height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    if entry.intensity > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...Int(entry.intensity), id: \.self) { _ in
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                            }
                        }
                        .foregroundStyle(intensityColor(Int(entry.intensity)))
                    }
                }
                
                Text(entry.patternType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let notes = entry.contextNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
    }

    private func intensityColor(_ intensity: Int) -> Color {
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

// MARK: - Encouragement Slide
struct EncouragementSlide: View {
    @ObservedObject var viewModel: DaySummaryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: viewModel.encouragementIcon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, value: viewModel.todayEntries.count)
            
            VStack(spacing: 12) {
                Text(viewModel.encouragementTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.encouragementMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Keep tracking your patterns!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Consistency helps build awareness")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
    }
}

// MARK: - Preview
#Preview {
    DaySummaryView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
