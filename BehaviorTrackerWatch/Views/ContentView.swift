import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityService

    var body: some View {
        TabView {
            // Dashboard
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "chart.bar.fill")
                }

            // Quick Log
            QuickLogView()
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }

            // Medications
            MedicationsView()
                .tabItem {
                    Label("Meds", systemImage: "pills.fill")
                }

            // Voice Note
            VoiceNoteView()
                .tabItem {
                    Label("Note", systemImage: "mic.fill")
                }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityService.shared)
}
