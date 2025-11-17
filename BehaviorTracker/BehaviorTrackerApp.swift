import SwiftUI

@main
struct BehaviorTrackerApp: App {
    private let dataController = DataController.shared
    @State private var isReady = false

    var body: some Scene {
        WindowGroup {
            if isReady {
                ContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
            } else {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isReady = true
                        }
                    }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)

                Text("Behavior Tracker")
                    .font(.title)
                    .fontWeight(.bold)

                ProgressView()
                    .tint(.blue)
            }
        }
    }
}
