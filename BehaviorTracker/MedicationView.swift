import SwiftUI

struct IdentifiableUUID: Identifiable {
    let id: UUID
}

struct MedicationView: View {
    @StateObject private var viewModel = MedicationViewModel()
    @State private var showingAddMedication = false
    @State private var showingLogSheet = false
    @State private var selectedMedicationID: IdentifiableUUID?
    @State private var medicationToEditID: IdentifiableUUID?
    
    private let dataController = DataController.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.medications.isEmpty {
                    emptyStateView
                } else {
                    medicationListView
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add medication")
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView { name, dosage, frequency, notes in
                    _ = dataController.createMedication(
                        name: name,
                        dosage: dosage,
                        frequency: frequency,
                        notes: notes
                    )
                    viewModel.loadMedications()
                }
            }
            .sheet(item: $medicationToEditID) { wrapper in
                if let medication = viewModel.medications.first(where: { $0.id == wrapper.id }) {
                    EditMedicationView(medication: medication) {
                        viewModel.loadMedications()
                    }
                } else {
                    EmptyView()
                }
            }
            .sheet(item: $selectedMedicationID) { wrapper in
                if let medication = viewModel.medications.first(where: { $0.id == wrapper.id }) {
                    LogMedicationView(medication: medication) {
                        viewModel.loadTodaysLogs()
                    }
                } else {
                    EmptyView()
                }
            }
            .onAppear {
                viewModel.loadMedications()
                viewModel.loadTodaysLogs()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Medications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your medications to track them and log when you take them.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingAddMedication = true
            } label: {
                Label("Add Medication", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
    
    private var medicationListView: some View {
        List {
            Section {
                ForEach(viewModel.medications) { medication in
                    MedicationRowView(
                        medication: medication,
                        hasTakenToday: viewModel.hasTakenToday(medication: medication),
                        onLog: {
                            selectedMedicationID = IdentifiableUUID(id: medication.id)
                        },
                        onEdit: {
                            medicationToEditID = IdentifiableUUID(id: medication.id)
                        }
                    )
                }
                .onDelete(perform: deleteMedications)
            } header: {
                Text("Active Medications")
            } footer: {
                Text("Tap the checkmark to log a medication. Swipe to delete.")
            }
        }
    }
    
    private func deleteMedications(at offsets: IndexSet) {
        for index in offsets {
            let medication = viewModel.medications[index]
            dataController.deleteMedication(medication)
        }
        viewModel.loadMedications()
    }
}

// MARK: - Medication Row View

struct MedicationRowView: View {
    let medication: Medication
    let hasTakenToday: Bool
    let onLog: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                
                if let dosage = medication.dosage, !dosage.isEmpty {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(medication.frequency)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(medication.name)")
            
            Button {
                onLog()
            } label: {
                Image(systemName: hasTakenToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(hasTakenToday ? .green : .gray)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hasTakenToday ? "\(medication.name) taken today" : "Log \(medication.name)")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Medication View

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    @State private var notes = ""
    
    let frequencyOptions = ["As needed", "Daily", "Twice daily", "Three times daily", "Weekly", "Every other day"]
    
    let onSave: (String, String?, String, String?) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g., 10mg)", text: $dosage)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencyOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name,
                            dosage.isEmpty ? nil : dosage,
                            frequency,
                            notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Medication View

struct EditMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let medication: Medication
    let onSave: () -> Void
    
    @State private var name: String
    @State private var dosage: String
    @State private var frequency: String
    @State private var notes: String
    @State private var isActive: Bool
    
    let frequencyOptions = ["As needed", "Daily", "Twice daily", "Three times daily", "Weekly", "Every other day"]
    
    private let dataController = DataController.shared
    
    init(medication: Medication, onSave: @escaping () -> Void) {
        self.medication = medication
        self.onSave = onSave
        _name = State(initialValue: medication.name)
        _dosage = State(initialValue: medication.dosage ?? "")
        _frequency = State(initialValue: medication.frequency)
        _notes = State(initialValue: medication.notes ?? "")
        _isActive = State(initialValue: medication.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g., 10mg)", text: $dosage)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencyOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Active", isOn: $isActive)
                } footer: {
                    Text("Inactive medications won't appear in your daily list.")
                }
            }
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        medication.name = name
                        medication.dosage = dosage.isEmpty ? nil : dosage
                        medication.frequency = frequency
                        medication.notes = notes.isEmpty ? nil : notes
                        medication.isActive = isActive
                        dataController.updateMedication(medication)
                        onSave()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Log Medication View

struct LogMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let medication: Medication
    let onSave: () -> Void
    
    @State private var taken = true
    @State private var skippedReason = ""
    @State private var sideEffects = ""
    @State private var effectiveness: Int16 = 3
    @State private var mood: Int16 = 3
    @State private var energyLevel: Int16 = 3
    @State private var notes = ""
    
    private let dataController = DataController.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Taken", isOn: $taken)
                    
                    if !taken {
                        TextField("Reason for skipping", text: $skippedReason)
                    }
                }
                
                if taken {
                    Section("How are you feeling?") {
                        LabeledContent("Effectiveness") {
                            RatingPicker(rating: $effectiveness)
                        }
                        
                        LabeledContent("Mood") {
                            RatingPicker(rating: $mood)
                        }
                        
                        LabeledContent("Energy") {
                            RatingPicker(rating: $energyLevel)
                        }
                    }
                    
                    Section("Side Effects") {
                        TextField("Any side effects?", text: $sideEffects, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log \(medication.name)")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _ = dataController.createMedicationLog(
                            medication: medication,
                            taken: taken,
                            skippedReason: skippedReason.isEmpty ? nil : skippedReason,
                            sideEffects: sideEffects.isEmpty ? nil : sideEffects,
                            effectiveness: effectiveness,
                            mood: mood,
                            energyLevel: energyLevel,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Rating Picker

struct RatingPicker: View {
    @Binding var rating: Int16
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    rating = Int16(value)
                } label: {
                    Image(systemName: Int16(value) <= rating ? "star.fill" : "star")
                        .foregroundStyle(Int16(value) <= rating ? .yellow : .gray)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    MedicationView()
}
