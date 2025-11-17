import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var connectivity: WatchConnectivityService

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Text("Today")
                    .font(.title3)
                    .fontWeight(.bold)

                // Connection Status
                if !connectivity.isReachable {
                    HStack {
                        Image(systemName: "iphone.slash")
                            .foregroundColor(.orange)
                        Text("iPhone not connected")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }

                // Today's Log Count
                VStack(spacing: 4) {
                    Text("\(connectivity.todayLogCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.purple)

                    Text("entries today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(connectivity.todayLogCount) entries logged today")

                Divider()

                // Streak
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(connectivity.streakCount) days")
                            .font(.headline)
                        Text("Current streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(connectivity.streakCount) day logging streak")

                // Upcoming Medications
                if !connectivity.upcomingMedications.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next Medication")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let nextMed = connectivity.upcomingMedications.first,
                           let name = nextMed["name"] as? String {
                            HStack {
                                Image(systemName: "pills.fill")
                                    .foregroundColor(.green)
                                Text(name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Refresh Button
                Button(action: {
                    connectivity.requestUpdate()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }
            .padding()
        }
        .onAppear {
            connectivity.requestUpdate()
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(WatchConnectivityService.shared)
}
