import SwiftUI

struct ProfileContainerView: View {
    @Environment(\.dismiss) private var dismiss

    // Lazy initialization - only create when needed
    @State private var healthKitManager: HealthKitManager?
    @State private var settingsViewModel: SettingsViewModel?
    @State private var medicationViewModel: MedicationViewModel?
    private let dataController = DataController.shared

    @State private var profile: UserProfile?
    @State private var healthSummary: HealthDataSummary?
    @State private var isLoadingHealth = false
    @State private var showingEditProfile = false
    @State private var showingAddMedication = false
    @State private var showingImportMedications = false
    @State private var isMedicationsExpanded = false
    @State private var isSettingsExpanded = false
    @State private var isInitialized = false

    @AppStorage("fontSizeScale") private var fontSizeScale: Double = 1.0
    @AppStorage("blueLightFilterEnabled") private var blueLightFilterEnabled: Bool = false

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
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

                            if let medicationViewModel = medicationViewModel {
                                ProfileMedicationsSection(
                                    medications: medicationViewModel.medications,
                                    isExpanded: $isMedicationsExpanded,
                                    hasTakenToday: { medicationViewModel.hasTakenToday(medication: $0) },
                                    onAddTapped: { showingAddMedication = true },
                                    onImportTapped: { showingImportMedications = true },
                                    medicationViewModel: medicationViewModel
                                )
                            }

                            if let settingsViewModel = settingsViewModel {
                                ProfileSettingsSection(
                                    isExpanded: $isSettingsExpanded,
                                    settingsViewModel: settingsViewModel
                                )
                            }
                        }
                        .padding()
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileToolbarControls(
                        fontSizeScale: $fontSizeScale,
                        blueLightFilterEnabled: $blueLightFilterEnabled
                    )
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .task {
                // Initialize ViewModels asynchronously AFTER sheet appears
                healthKitManager = HealthKitManager.shared
                settingsViewModel = SettingsViewModel()
                medicationViewModel = MedicationViewModel()

                isInitialized = true

                // Load data in parallel
                async let profileTask: () = loadProfileAsync()
                async let medicationsTask: () = loadMedicationsAsync()
                async let healthTask: () = loadHealthDataAsync()

                _ = await (profileTask, medicationsTask, healthTask)
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(dataController: dataController, profile: $profile)
            }
            .onChange(of: showingEditProfile) { _, isShowing in
                if !isShowing {
                    loadProfile()
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                if let medicationViewModel = medicationViewModel {
                    AddMedicationView(viewModel: medicationViewModel)
                }
            }
            .sheet(isPresented: $showingImportMedications) {
                if let medicationViewModel = medicationViewModel {
                    ImportMedicationsView(medicationViewModel: medicationViewModel)
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

    private func loadMedicationsAsync() async {
        guard let medicationViewModel = medicationViewModel else { return }
        await Task.yield()
        medicationViewModel.loadMedications()
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
