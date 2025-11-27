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
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if importedMedications.isEmpty {
                    emptyView
                } else {
                    medicationListView
                }
            }
            .navigationTitle("Import from Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !importedMedications.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            importSelected()
                        }
                        .disabled(selectedMedications.isEmpty)
                    }
                }
            }
            .onAppear {
                loadMedications()
            }
            .alert("Import Successful", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Imported \(selectedMedications.count) medication(s)")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading medications from Apple Health...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            VStack(spacing: 12) {
                Text("Unable to Import")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if message.contains("entitlement") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Note:")
                        .font(.headline)
                    Text("Medication import requires special Apple approval. In the meantime, you can manually add your medications.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.orange.opacity(0.1))
                )
                .padding(.horizontal, 32)
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "pills.circle")
                .font(.system(size: 60))
                .foregroundStyle(theme.primaryColor)
            
            VStack(spacing: 12) {
                Text("No Medications Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("No medications were found in Apple Health. Add medications in the Health app first.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var medicationListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Select medications to import")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    ForEach(importedMedications, id: \.name) { medication in
                        medicationRow(medication)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func medicationRow(_ medication: MedicationImportData) -> some View {
        Button {
            if selectedMedications.contains(medication.name) {
                selectedMedications.remove(medication.name)
            } else {
                selectedMedications.insert(medication.name)
            }
            HapticFeedback.light.trigger()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: selectedMedications.contains(medication.name) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selectedMedications.contains(medication.name) ? theme.primaryColor : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if let dosage = medication.dosage {
                        Text(dosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Started: \(medication.startDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedMedications.contains(medication.name) ? theme.primaryColor : theme.cardBorderColor,
                        lineWidth: selectedMedications.contains(medication.name) ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
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
            medicationViewModel.addMedication(
                name: medication.name,
                dosage: medication.dosage,
                frequency: "as_needed", // Default frequency
                notes: "Imported from Apple Health on \(Date().formatted(date: .abbreviated, time: .omitted))"
            )
        }
        
        showSuccess = true
    }
}

#Preview {
    ImportMedicationsView(medicationViewModel: MedicationViewModel())
}
