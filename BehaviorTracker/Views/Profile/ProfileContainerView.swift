import SwiftUI

struct ProfileContainerView: View {
    @Environment(\.dismiss) private var dismiss

    // Lazy initialization - only create when needed
    @State private var healthKitManager: HealthKitManager?
    @State private var settingsViewModel: SettingsViewModel?
    private let dataController = DataController.shared

    @State private var profile: UserProfile?
    @State private var healthSummary: HealthDataSummary?
    @State private var isLoadingHealth = false
    @State private var showingEditProfile = false
    @State private var isSettingsExpanded = false
    @State private var isInitialized = false

    @AppStorage("fontSizeScale") private var fontSizeScale: Double = 1.0
    @AppStorage("blueLightFilterEnabled") private var blueLightFilterEnabled: Bool = false

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                // Apply theme gradient background
                theme.gradient
                    .ignoresSafeArea()

                if !isInitialized {
                    // Show placeholder while initializing
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ProfileHeaderSection(profile: profile) {
                                showingEditProfile = true
                            }

                            if let healthKitManager = healthKitManager {
                                ProfileHealthDataSection(
                                    healthSummary: healthSummary,
                                    isAuthorized: healthKitManager.isAuthorized,
                                    isLoading: isLoadingHealth,
                                    onRefresh: { loadHealthData() },
                                    onConnect: {
                                        await healthKitManager.requestAuthorization()
                                        if healthKitManager.isAuthorized {
                                            loadHealthData()
                                        }
                                    }
                                )
                            }

                            if let settingsViewModel = settingsViewModel {
                                ProfileSettingsSection(
                                    isExpanded: $isSettingsExpanded,
                                    settingsViewModel: settingsViewModel
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    FontSizeToolbarControl(fontSizeScale: $fontSizeScale)
                }

                ToolbarItem(placement: .topBarLeading) {
                    BlueLightFilterToolbarControl(blueLightFilterEnabled: $blueLightFilterEnabled)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                // Initialize ViewModels immediately
                healthKitManager = HealthKitManager.shared
                settingsViewModel = SettingsViewModel()

                isInitialized = true

                // Load data in parallel
                async let profileTask: () = loadProfileAsync()
                async let healthTask: () = loadHealthDataAsync()

                _ = await (profileTask, healthTask)
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(dataController: dataController, profile: $profile)
            }
            .onChange(of: showingEditProfile) { _, isShowing in
                if !isShowing {
                    loadProfile()
                }
            }
        }
    }

    // MARK: - Methods

    private func loadProfile() {
        profile = dataController.getOrCreateUserProfile()
    }

    private func loadProfileAsync() async {
        await Task.yield()
        profile = dataController.getOrCreateUserProfile()
    }

    private func loadHealthDataAsync() async {
        guard let healthKitManager = healthKitManager else { return }
        await healthKitManager.checkAuthorizationStatus()
        guard healthKitManager.isAuthorized else { return }

        isLoadingHealth = true
        let summary = await healthKitManager.fetchHealthSummary()
        healthSummary = summary
        isLoadingHealth = false
    }

    private func loadHealthData() {
        guard let healthKitManager = healthKitManager else { return }
        guard healthKitManager.isAuthorized else { return }

        isLoadingHealth = true
        Task {
            let summary = await healthKitManager.fetchHealthSummary()
            healthSummary = summary
            isLoadingHealth = false
        }
    }
}

#Preview {
    ProfileContainerView()
}
