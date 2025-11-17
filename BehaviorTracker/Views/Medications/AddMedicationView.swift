import SwiftUI

struct AddMedicationView: View {
    @ObservedObject var viewModel: MedicationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dosage = ""
    @State private var selectedFrequency: MedicationFrequency = .daily
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Medication Information") {
                    TextField("Medication Name", text: $name)
                        .textContentType(.none)
                        .autocapitalization(.words)

                    TextField("Dosage (e.g., 10mg)", text: $dosage)
                        .textContentType(.none)
                }

                Section("Frequency") {
                    Picker("How often?", selection: $selectedFrequency) {
                        ForEach(MedicationFrequency.allCases, id: \.self) { frequency in
                            HStack {
                                Image(systemName: frequency.icon)
                                Text(frequency.description)
                            }
                            .tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveMedication() {
        viewModel.addMedication(
            name: name,
            dosage: dosage.isEmpty ? nil : dosage,
            frequency: selectedFrequency,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
}

#Preview {
    AddMedicationView(viewModel: MedicationViewModel())
}
