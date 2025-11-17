import SwiftUI

@main
struct BehaviorTrackerWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
        }
    }
}
