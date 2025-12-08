import SwiftUI

// MARK: - Health Data Section

struct ProfileHealthDataSection: View {
    let healthSummary: HealthDataSummary?
    let isAuthorized: Bool
    let isLoading: Bool
    let onRefresh: () -> Void
    let onConnect: () async -> Void

    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("Health Data")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        onRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }

            if !isAuthorized {
                VStack(spacing: 12) {
                    Text("Connect to Apple Health to see your health data")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Connect Apple Health") {
                        Task {
                            await onConnect()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let summary = healthSummary {
                HealthDataGrid(summary: summary)
            } else {
                Text("No health data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .cardStyle(theme: theme)
    }
}

// MARK: - Health Data Grid

struct HealthDataGrid: View {
    let summary: HealthDataSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let steps = summary.steps {
                HealthStatCard(icon: "figure.walk", title: "Steps", value: "\(Int(steps))", color: .green)
            }
            if let heartRate = summary.heartRate {
                HealthStatCard(icon: "heart.fill", title: "Heart Rate", value: "\(Int(heartRate)) bpm", color: .red)
            }
            if let sleepHours = summary.sleepHours {
                HealthStatCard(icon: "bed.double.fill", title: "Sleep", value: String(format: "%.1f hrs", sleepHours), color: .purple)
            }
            if let energy = summary.activeEnergy {
                HealthStatCard(icon: "flame.fill", title: "Active Energy", value: "\(Int(energy)) kcal", color: .orange)
            }
            if let exercise = summary.exerciseMinutes {
                HealthStatCard(icon: "figure.run", title: "Exercise", value: "\(Int(exercise)) min", color: .cyan)
            }
            if let weight = summary.weight {
                HealthStatCard(icon: "scalemass.fill", title: "Weight", value: String(format: "%.1f kg", weight), color: .blue)
            }
            if let water = summary.waterIntake {
                HealthStatCard(icon: "drop.fill", title: "Water", value: String(format: "%.1f L", water), color: .blue)
            }
        }
    }
}

// MARK: - Health Stat Card

struct HealthStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .compactCardStyle(theme: theme)
    }
}

// MARK: - Previews

#Preview("HealthStatCard") {
    HealthStatCard(
        icon: "figure.walk",
        title: "Steps",
        value: "8,432",
        color: .green
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
