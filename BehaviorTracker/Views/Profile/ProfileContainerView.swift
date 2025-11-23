import SwiftUI

struct ProfileContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var medicationViewModel = MedicationViewModel()
    @ObservedObject var dataController = DataController.shared

    @State private var profile: UserProfile?
    @State private var healthSummary: HealthDataSummary?
    @State private var isLoadingHealth = false
    @State private var showingEditProfile = false
    @State private var showingAddMedication = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeaderSection

                    // Health Data Section
                    healthDataSection

                    // Medications Section
                    medicationsSection

                    // Settings Section
                    settingsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProfile()
                loadHealthData()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(dataController: dataController, profile: $profile)
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView(viewModel: medicationViewModel)
            }
        }
    }

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            if let profileImage = profile?.profileImage {
                #if os(iOS)
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                #elseif os(macOS)
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                #endif
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(profile?.initials ?? "?")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            }

            VStack(spacing: 6) {
                Text(profile?.name ?? "User")
                    .font(.title)
                    .fontWeight(.bold)

                if let email = profile?.email, !email.isEmpty {
                    Text(email)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                if let age = profile?.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Button("Edit Profile") {
                showingEditProfile = true
            }
            .font(.body)
            .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Health Data Section

    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("Health Data")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if isLoadingHealth {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        loadHealthData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }

            if !healthKitManager.isAuthorized {
                VStack(spacing: 12) {
                    Text("Connect to Apple Health to see your health data")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Connect Apple Health") {
                        Task {
                            await healthKitManager.requestAuthorization()
                            if healthKitManager.isAuthorized {
                                loadHealthData()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let summary = healthSummary {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if let steps = summary.steps {
                        HealthStatCard(
                            icon: "figure.walk",
                            title: "Steps",
                            value: "\(Int(steps))",
                            color: .green
                        )
                    }

                    if let heartRate = summary.heartRate {
                        HealthStatCard(
                            icon: "heart.fill",
                            title: "Heart Rate",
                            value: "\(Int(heartRate)) bpm",
                            color: .red
                        )
                    }

                    if let sleepHours = summary.sleepHours {
                        HealthStatCard(
                            icon: "bed.double.fill",
                            title: "Sleep",
                            value: String(format: "%.1f hrs", sleepHours),
                            color: .purple
                        )
                    }

                    if let energy = summary.activeEnergy {
                        HealthStatCard(
                            icon: "flame.fill",
                            title: "Active Energy",
                            value: "\(Int(energy)) kcal",
                            color: .orange
                        )
                    }

                    if let exercise = summary.exerciseMinutes {
                        HealthStatCard(
                            icon: "figure.run",
                            title: "Exercise",
                            value: "\(Int(exercise)) min",
                            color: .cyan
                        )
                    }

                    if let weight = summary.weight {
                        HealthStatCard(
                            icon: "scalemass.fill",
                            title: "Weight",
                            value: String(format: "%.1f kg", weight),
                            color: .blue
                        )
                    }

                    if let hrv = summary.heartRateVariability {
                        HealthStatCard(
                            icon: "waveform.path.ecg",
                            title: "HRV",
                            value: "\(Int(hrv)) ms",
                            color: .pink
                        )
                    }

                    if let water = summary.waterIntake {
                        HealthStatCard(
                            icon: "drop.fill",
                            title: "Water",
                            value: String(format: "%.1f L", water),
                            color: .blue
                        )
                    }
                }
            } else {
                Text("No health data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Medications Section

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Medications")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddMedication = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }

            if medicationViewModel.medications.isEmpty {
                VStack(spacing: 8) {
                    Text("No medications added")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Add Medication") {
                        showingAddMedication = true
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(medicationViewModel.medications) { medication in
                    NavigationLink {
                        MedicationDetailView(medication: medication, viewModel: medicationViewModel)
                    } label: {
                        ProfileMedicationRowView(medication: medication, viewModel: medicationViewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.gray)
                    .font(.title3)
                Text("Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 0) {
                // Appearance
                NavigationLink {
                    AppearanceSettingsView(viewModel: settingsViewModel)
                } label: {
                    SettingsRow(icon: "paintbrush.fill", iconColor: .purple, title: "Appearance")
                }

                Divider().padding(.leading, 44)

                // Notifications
                NavigationLink {
                    NotificationSettingsView(viewModel: settingsViewModel)
                } label: {
                    SettingsRow(icon: "bell.fill", iconColor: .red, title: "Notifications")
                }

                Divider().padding(.leading, 44)

                // Favorites
                NavigationLink {
                    FavoritePatternsView(viewModel: settingsViewModel)
                } label: {
                    SettingsRow(icon: "star.fill", iconColor: .yellow, title: "Favorite Patterns")
                }

                Divider().padding(.leading, 44)

                // Export
                NavigationLink {
                    ExportDataView(viewModel: settingsViewModel)
                } label: {
                    SettingsRow(icon: "square.and.arrow.up", iconColor: .green, title: "Export Data")
                }

                Divider().padding(.leading, 44)

                // Privacy
                NavigationLink {
                    DataPrivacyView()
                } label: {
                    SettingsRow(icon: "lock.shield", iconColor: .blue, title: "Privacy & Security")
                }

                Divider().padding(.leading, 44)

                // About
                NavigationLink {
                    AboutView()
                } label: {
                    SettingsRow(icon: "info.circle", iconColor: .blue, title: "About")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Methods

    private func loadProfile() {
        profile = dataController.getOrCreateUserProfile()
    }

    private func loadHealthData() {
        guard healthKitManager.isAuthorized else { return }

        isLoadingHealth = true
        Task {
            let summary = await healthKitManager.fetchHealthSummary()
            await MainActor.run {
                healthSummary = summary
                isLoadingHealth = false
            }
        }
    }
}

// MARK: - Supporting Views

struct HealthStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

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
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileMedicationRowView: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if let dosage = medication.dosage {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if viewModel.hasTakenToday(medication: medication) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.body)
                .frame(width: 28)

            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataController: DataController
    @Binding var profile: UserProfile?

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var hasDateOfBirth: Bool = false
    @State private var selectedImage: PlatformImage?
    @State private var showImagePicker: Bool = false
    #if os(iOS)
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    #endif
    @State private var showImageSourcePicker: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        profileImageView
                            .onTapGesture {
                                showImageSourcePicker = true
                            }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } footer: {
                    Text("Tap to change photo")
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Personal Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif

                    Toggle("Date of Birth", isOn: $hasDateOfBirth)

                    if hasDateOfBirth {
                        DatePicker(
                            "Birthday",
                            selection: $dateOfBirth,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadProfile()
            }
            #if os(iOS)
            .confirmationDialog("Choose Photo Source", isPresented: $showImageSourcePicker) {
                Button("Camera") {
                    imageSourceType = .camera
                    showImagePicker = true
                }
                Button("Photo Library") {
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: imageSourceType)
            }
            #endif
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        ZStack {
            #if os(iOS)
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if let profileImage = profile?.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    )
            }
            #elseif os(macOS)
            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if let profileImage = profile?.profileImage {
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    )
            }
            #endif
        }
        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
    }

    private func loadProfile() {
        if let p = profile {
            name = p.name
            email = p.email ?? ""
            if let dob = p.dateOfBirth {
                dateOfBirth = dob
                hasDateOfBirth = true
            }
        }
    }

    private func saveProfile() {
        guard let p = profile else { return }

        p.name = name
        p.email = email.isEmpty ? nil : email
        p.dateOfBirth = hasDateOfBirth ? dateOfBirth : nil

        if let image = selectedImage {
            let resizedImage = image.resized(toMaxDimension: 500)
            p.profileImage = resizedImage
        }

        dataController.updateUserProfile(p)
    }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @AppStorage("appearance") private var appearance: AppAppearance = .system

    var body: some View {
        Form {
            Section {
                Picker(selection: $appearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { option in
                        HStack {
                            Image(systemName: option.icon)
                            Text(option.displayName)
                        }
                        .tag(option)
                    }
                } label: {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundStyle(.purple)
                        Text("Appearance")
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("Display Mode")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayModeInline()
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(.blue)
                        Text("Daily Reminders")
                    }
                }

                if viewModel.notificationsEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: $viewModel.notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Notifications")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayModeInline()
    }
}

#Preview {
    ProfileContainerView()
}
