import SwiftUI

struct ImportMedicationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject var medicationViewModel: MedicationViewModel

    @State private var isImporting = false
    @State private var importedMedications: [MedicationImportData] = []
    @State private var selectedMedications: Set<String> = []
    @State private var errorMessage: String?
    @State private var showSuccess = false

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                if isImporting {
                    ImportLoadingView(theme: theme)
                } else if let error = errorMessage {
                    ImportErrorView(message: error, theme: theme) {
                        dismiss()
                    }
                } else if importedMedications.isEmpty {
                    ImportEmptyView(theme: theme) {
                        dismiss()
                    }
                } else {
                    medicationListView
                }
            }
            .navigationTitle("Import from Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.medium)
                    }
                }

                if !importedMedications.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            importSelected()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.subheadline)
                                Text("Import")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(selectedMedications.isEmpty)
                        .opacity(selectedMedications.isEmpty ? 0.5 : 1.0)
                    }
                }
            }
            .onAppear {
                loadMedications()
            }
            .alert("Successfully Imported", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                if selectedMedications.count == 1 {
                    Text("1 medication has been added to your profile.")
                } else {
                    Text("\(selectedMedications.count) medications have been added to your profile.")
                }
            }
        }
    }

    private var medicationListView: some View {
        VStack(spacing: 0) {
            MedicationListHeader(
                medicationCount: importedMedications.count,
                selectedCount: selectedMedications.count,
                allSelected: selectedMedications.count == importedMedications.count,
                theme: theme
            ) {
                if selectedMedications.count == importedMedications.count {
                    selectedMedications.removeAll()
                } else {
                    selectedMedications = Set(importedMedications.map { $0.name })
                }
            }

            // Medications list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(importedMedications, id: \.name) { medication in
                        ImportMedicationRow(
                            medication: medication,
                            isSelected: selectedMedications.contains(medication.name),
                            theme: theme
                        ) {
                            if selectedMedications.contains(medication.name) {
                                selectedMedications.remove(medication.name)
                            } else {
                                selectedMedications.insert(medication.name)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    private func loadMedications() {
        isImporting = true
        errorMessage = nil
        
        Task {
            do {
                if #available(iOS 16.0, *) {
                    let medications = try await healthKitManager.importMedications()
                    await MainActor.run {
                        importedMedications = medications
                        // Pre-select all medications
                        selectedMedications = Set(medications.map { $0.name })
                        isImporting = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Medication import requires iOS 16 or later"
                        isImporting = false
                    }
                }
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("authorization") {
                        errorMessage = "This feature requires special Apple entitlement for clinical health records. Please add medications manually."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    isImporting = false
                }
            }
        }
    }
    
    private func importSelected() {
        let toImport = importedMedications.filter { selectedMedications.contains($0.name) }
        
        for medication in toImport {
            _ = medicationViewModel.addMedication(
                name: medication.name,
                dosage: medication.dosage,
                frequency: .asNeeded, // Default frequency
                notes: "Imported from Apple Health on \(Date().formatted(date: .abbreviated, time: .omitted))"
            )
        }
        
        HapticFeedback.success.trigger()
        showSuccess = true
    }
}

#Preview {
    ImportMedicationsView(medicationViewModel: MedicationViewModel())
}
