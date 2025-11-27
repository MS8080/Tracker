import SwiftUI

@main
struct BehaviorTrackerApp: App {
    private let dataController = DataController.shared
    @State private var isReady = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if isReady {
                ContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
            } else {
                SplashView()
                    .onAppear {
                        // Process any pending widget logs
                        dataController.processPendingWidgetLogs()
                        // Sync widget data
                        dataController.syncWidgetData()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isReady = true
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Process pending widget logs when app becomes active
                dataController.processPendingWidgetLogs()
            }
        }
    }
}

struct SplashView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Infinity Logo
                Image("InfinityLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 75)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

                Text("Cortex")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)
            }
        }
    }
}
