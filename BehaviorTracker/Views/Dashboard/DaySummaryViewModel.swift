import SwiftUI
import CoreData

struct CategoryBreakdown {
    let category: PatternCategory
    let count: Int
    let percentage: Double
}

class DaySummaryViewModel: ObservableObject {
    @Published var todayEntries: [PatternEntry] = []
    @Published var categoryBreakdown: [CategoryBreakdown] = []
    @Published var intensityDistribution: [Int: Int] = [:]
    @Published var maxIntensityCount: Double = 1
    
    private let dataController = DataController.shared
    
    var categoriesTracked: Int {
        Set(todayEntries.map { $0.category }).count
    }
    
    var totalDurationString: String {
        let totalMinutes = todayEntries.reduce(0) { $0 + Int($1.duration) }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    var averageIntensity: Double {
        let entriesWithIntensity = todayEntries.filter { $0.intensity > 0 }
        guard !entriesWithIntensity.isEmpty else { return 0 }
        
        let total = entriesWithIntensity.reduce(0) { $0 + Int($1.intensity) }
        return Double(total) / Double(entriesWithIntensity.count)
    }
    
    var encouragementIcon: String {
        switch todayEntries.count {
        case 0:
            return "moon.stars.fill"
        case 1...3:
            return "star.fill"
        case 4...6:
            return "star.circle.fill"
        case 7...10:
            return "trophy.fill"
        default:
            return "crown.fill"
        }
    }
    
    var encouragementTitle: String {
        switch todayEntries.count {
        case 0:
            return "Rest Day"
        case 1...3:
            return "Good Start!"
        case 4...6:
            return "Great Work!"
        case 7...10:
            return "Amazing Progress!"
        default:
            return "Exceptional Tracking!"
        }
    }
    
    var encouragementMessage: String {
        if todayEntries.isEmpty {
            return "Every day is different. Tomorrow is a new opportunity to track your patterns."
        }
        
        let categoryCount = categoriesTracked
        
        if categoryCount >= 4 {
            return "You've tracked \(todayEntries.count) patterns across \(categoryCount) different categories. This comprehensive tracking will give you valuable insights!"
        } else if todayEntries.count >= 7 {
            return "You logged \(todayEntries.count) entries today! Your dedication to self-awareness is impressive."
        } else if todayEntries.count >= 4 {
            return "You're building a clear picture of your day with \(todayEntries.count) logged patterns. Keep it up!"
        } else {
            return "You made \(todayEntries.count) entries today. Every observation brings more understanding."
        }
    }
    
    func loadTodayEntries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let allEntries = dataController.fetchPatternEntries()
        todayEntries = allEntries.filter { entry in
            entry.timestamp >= today && entry.timestamp < tomorrow
        }.sorted { $0.timestamp < $1.timestamp }
        
        calculateCategoryBreakdown()
        calculateIntensityDistribution()
    }
    
    private func calculateCategoryBreakdown() {
        let grouped = Dictionary(grouping: todayEntries) { entry in
            entry.category
        }
        
        categoryBreakdown = grouped.compactMap { key, entries in
            guard let category = PatternCategory(rawValue: key) else { return nil }
            let percentage = (Double(entries.count) / Double(todayEntries.count)) * 100
            return CategoryBreakdown(
                category: category,
                count: entries.count,
                percentage: percentage
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateIntensityDistribution() {
        var distribution: [Int: Int] = [:]
        
        for entry in todayEntries where entry.intensity > 0 {
            let intensity = Int(entry.intensity)
            distribution[intensity, default: 0] += 1
        }
        
        intensityDistribution = distribution
        maxIntensityCount = Double(distribution.values.max() ?? 1)
    }
}
