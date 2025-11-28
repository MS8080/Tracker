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
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primaryColor)
            
            VStack(spacing: 8) {
                Text("Loading medications from Apple Health...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("This may take a moment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
        .padding()
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 12) {
                Text("Unable to Import")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if message.contains("entitlement") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Important Note")
                            .font(.headline)
                    }
                    
                    Text("Medication import requires special Apple approval. In the meantime, you can manually add your medications.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryColor)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
    }
    
    private var emptyView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.primaryColor)
            }
            
            VStack(spacing: 12) {
                Text("No Medications Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("No medications were found in Apple Health. Add medications in the Health app first, then try importing again.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.primaryColor)
                        )
                }
                
                Button {
                    // Could open Health app if needed
                    dismiss()
                } label: {
                    Text("Add in Health App")
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryColor)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
    }
    
    private var medicationListView: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 8) {
                Text("Select medications to import")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text("\(importedMedications.count) found in Health")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Select All button
            HStack {
                Button {
                    if selectedMedications.count == importedMedications.count {
                        selectedMedications.removeAll()
                    } else {
                        selectedMedications = Set(importedMedications.map { $0.name })
                    }
                    HapticFeedback.light.trigger()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedMedications.count == importedMedications.count ? "checkmark.square.fill" : "square")
                            .foregroundStyle(theme.primaryColor)
                        Text(selectedMedications.count == importedMedications.count ? "Deselect All" : "Select All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(theme.primaryColor)
                }
                
                Spacer()
                
                Text("\(selectedMedications.count) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primaryColor.opacity(0.15))
                    )
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Medications list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(importedMedications, id: \.name) { medication in
                        medicationRow(medication)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func medicationRow(_ medication: MedicationImportData) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedMedications.contains(medication.name) {
                    selectedMedications.remove(medication.name)
                } else {
                    selectedMedications.insert(medication.name)
                }
            }
            HapticFeedback.light.trigger()
        } label: {
            HStack(spacing: 16) {
                // Checkbox with animation
                ZStack {
                    Circle()
                        .fill(selectedMedications.contains(medication.name) ? theme.primaryColor : Color.secondary.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    if selectedMedications.contains(medication.name) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMedications.contains(medication.name))
                
                // Medication icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.primaryColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "pills.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.primaryColor)
                }
                
                // Medication info
                VStack(alignment: .leading, spacing: 6) {
                    Text(medication.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    if let dosage = medication.dosage {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.dots.needle.33percent")
                                .font(.caption2)
                            Text(dosage)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("Started \(medication.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
                
                Spacer(minLength: 8)
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .opacity(0.5)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedMedications.contains(medication.name) ? theme.primaryColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(selectedMedications.contains(medication.name) ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMedications.contains(medication.name))
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
