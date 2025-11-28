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
    @State private var showingImportMedications = false
    @State private var isMedicationsExpanded = false
    @State private var isSettingsExpanded = false

    @AppStorage("fontSizeScale") private var fontSizeScale: Double = 1.0
    @AppStorage("blueLightFilterEnabled") private var blueLightFilterEnabled: Bool = false
    
    @ThemeWrapper var theme

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
            .scrollContentBackground(.hidden)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        // Font size controls - liquid crystal pill shape
                        HStack(spacing: 0) {
                            Button {
                                if fontSizeScale > 0.8 {
                                    fontSizeScale -= 0.1
                                    HapticFeedback.light.trigger()
                                }
                            } label: {
                                Image(systemName: "textformat.size.smaller")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(fontSizeScale <= 0.8 ? .secondary : .primary)
                                    .frame(width: 32, height: 32)
                            }
                            .disabled(fontSizeScale <= 0.8)

                            Divider()
                                .frame(height: 18)
                                .opacity(0.5)

                            Button {
                                if fontSizeScale < 1.4 {
                                    fontSizeScale += 0.1
                                    HapticFeedback.light.trigger()
                                }
                            } label: {
                                Image(systemName: "textformat.size.larger")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(fontSizeScale >= 1.4 ? .secondary : .primary)
                                    .frame(width: 32, height: 32)
                            }
                            .disabled(fontSizeScale >= 1.4)
                        }
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )

                        // Blue light filter - separate circle button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                blueLightFilterEnabled.toggle()
                            }
                            HapticFeedback.light.trigger()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(blueLightFilterEnabled ? Color.orange.opacity(0.8) : .white.opacity(0.15))
                                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 0.5)

                                Image(systemName: blueLightFilterEnabled ? "sun.max.fill" : "moon.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(blueLightFilterEnabled ? .white : .primary)
                            }
                            .frame(width: 32, height: 32)
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProfile()
                medicationViewModel.loadMedications()
                Task {
                    await healthKitManager.checkAuthorizationStatus()
                    loadHealthData()
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(dataController: dataController, profile: $profile)
            }
            .onChange(of: showingEditProfile) { _, isShowing in
                if !isShowing {
                    // Reload profile when edit sheet is dismissed
                    loadProfile()
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView(viewModel: medicationViewModel)
            }
            .sheet(isPresented: $showingImportMedications) {
                ImportMedicationsView(medicationViewModel: medicationViewModel)
            }
        }
    }

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Image - tappable to edit
            Button {
                showingEditProfile = true
            } label: {
                ZStack {
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

                    // Edit indicator
                    Circle()
                        .fill(.blue)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 36, y: 36)
                }
            }
            .buttonStyle(.plain)

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

        }
        .padding()
        .frame(maxWidth: .infinity)
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
        .cardStyle(theme: theme)
    }

    // MARK: - Medications Section

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Medications")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if !medicationViewModel.medications.isEmpty {
                    Text("\(medicationViewModel.medications.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.white.opacity(0.12)))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isMedicationsExpanded ? 90 : 0))
            }
            .padding(.bottom, isMedicationsExpanded ? 12 : 0)

            // Expandable content with proper clipping
            if isMedicationsExpanded {
                VStack(spacing: 12) {
                    if medicationViewModel.medications.isEmpty {
                        VStack(spacing: 12) {
                            Text("No medications added")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 8) {
                                Button {
                                    showingImportMedications = true
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Import from Health")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(.green.opacity(0.8)))
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    showingAddMedication = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Manually")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(.cyan.opacity(0.8)))
                                }
                                .buttonStyle(.plain)
                            }
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

                        // Add button at the bottom
                        Button {
                            showingAddMedication = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.cyan)
                                Text("Add Medication")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .cardStyle(theme: theme)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isMedicationsExpanded.toggle()
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.gray)
                    .font(.title3)
                Text("Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isSettingsExpanded ? 90 : 0))
            }
            .padding(.bottom, isSettingsExpanded ? 16 : 0)

            // Expandable content
            if isSettingsExpanded {
                VStack(spacing: 12) {
                    // Appearance
                    NavigationLink {
                        AppearanceSettingsView(viewModel: settingsViewModel)
                    } label: {
                        ModernSettingsRow(
                            icon: "paintbrush.fill",
                            iconColor: .purple,
                            iconBackground: .purple.opacity(0.15),
                            title: "Appearance",
                            subtitle: "Theme & display"
                        )
                    }

                    // Notifications
                    NavigationLink {
                        NotificationSettingsView(viewModel: settingsViewModel)
                    } label: {
                        ModernSettingsRow(
                            icon: "bell.badge.fill",
                            iconColor: .red,
                            iconBackground: .red.opacity(0.15),
                            title: "Notifications",
                            subtitle: "Reminders & alerts"
                        )
                    }

                    // Export
                    NavigationLink {
                        ExportDataView(viewModel: settingsViewModel)
                    } label: {
                        ModernSettingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .green,
                            iconBackground: .green.opacity(0.15),
                            title: "Export Data",
                            subtitle: "Backup your data"
                        )
                    }

                    // About
                    NavigationLink {
                        AboutView()
                    } label: {
                        ModernSettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .cyan,
                            iconBackground: .cyan.opacity(0.15),
                            title: "About",
                            subtitle: "Version & info"
                        )
                    }
                }
            }
        }
        .padding()
        .cardStyle(theme: theme)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isSettingsExpanded.toggle()
            }
        }
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

struct ModernSettingsRow: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 18, weight: .semibold))
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.08))
        )
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
    @AppStorage("appearance") private var appearance: AppAppearance = .dark
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    @ThemeWrapper var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Theme Colors
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundStyle(.purple)
                            .font(.title3)
                        Text("Theme Color")
                            .font(.headline)
                    }

                    // Theme grid with labels
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], alignment: .center, spacing: 20) {
                        ForEach(AppTheme.allCases, id: \.self) { themeOption in
                            Button {
                                withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                                    selectedThemeRaw = themeOption.rawValue
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [themeOption.primaryColor, themeOption.primaryColor.opacity(0.6)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 52, height: 52)
                                            .shadow(color: themeOption.primaryColor.opacity(0.4), radius: selectedThemeRaw == themeOption.rawValue ? 8 : 0)

                                        if selectedThemeRaw == themeOption.rawValue {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 3)
                                                .frame(width: 52, height: 52)

                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }

                                    Text(themeOption.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(selectedThemeRaw == themeOption.rawValue ? .primary : .secondary)
                                        .frame(height: 14)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(selectedThemeRaw == themeOption.rawValue ? 1.05 : 1.0)
                        }
                    }
                }
                .padding(20)
                .cardStyle(theme: theme)

                // Light/Dark Mode
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundStyle(.orange)
                            .font(.title3)
                        Text("Appearance")
                            .font(.headline)
                    }

                    HStack(spacing: 12) {
                        // Light Mode
                        AppearanceModeButton(
                            title: "Light",
                            icon: "sun.max.fill",
                            iconColor: .orange,
                            backgroundColor: .white,
                            isSelected: appearance == .light
                        ) {
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                                appearance = .light
                            }
                        }

                        // Dark Mode
                        AppearanceModeButton(
                            title: "Dark",
                            icon: "moon.fill",
                            iconColor: .yellow,
                            backgroundColor: Color(white: 0.15),
                            isSelected: appearance == .dark
                        ) {
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                                appearance = .dark
                            }
                        }
                    }
                }
                .padding(20)
                .cardStyle(theme: theme)

                // Preview Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundStyle(.cyan)
                            .font(.title3)
                        Text("Preview")
                            .font(.headline)
                    }

                    // Mini preview of current theme
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.gradient)
                            .frame(height: 80)
                            .overlay(
                                VStack {
                                    Circle()
                                        .fill(.white.opacity(0.2))
                                        .frame(width: 30, height: 30)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.white.opacity(0.3))
                                        .frame(width: 50, height: 8)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }

                    Text("This is how your app will look")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .cardStyle(theme: theme)
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceModeButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(backgroundColor)
                        .frame(height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8)

                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(iconColor)
                }

                HStack(spacing: 6) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @ThemeWrapper var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Daily Reminders
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                        Text("Daily Reminders")
                            .font(.headline)
                    }

                    // Toggle card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Reminders")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Get notified to log your patterns")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.notificationsEnabled)
                            .labelsHidden()
                            .tint(.blue)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white.opacity(0.05))
                    )

                    if viewModel.notificationsEnabled {
                        // Time picker
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(.orange)
                                Text("Reminder Time")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            DatePicker(
                                "",
                                selection: $viewModel.notificationTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.05))
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(Spacing.xl)
                .cardStyle(theme: theme)
                .animation(.spring(response: 0.15, dampingFraction: 0.7), value: viewModel.notificationsEnabled)

                // Info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("About Notifications")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text("Daily reminders help you build a consistent tracking habit. You can change the time or disable them anytime.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(.blue.opacity(0.1))
                )
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Image Picker

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

#Preview {
    ProfileContainerView()
}
