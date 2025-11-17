import SwiftUI

struct LogMedicationView: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var taken = true
    @State private var skippedReason = ""
    @State private var sideEffects = ""
    @State private var effectiveness = 3
    @State private var mood = 3
    @State private var energyLevel = 3
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Did you take \(medication.name)?") {
                    Toggle("Medication Taken", isOn: $taken)

                    if !taken {
                        TextField("Reason for skipping", text: $skippedReason)
                    }
                }

                if taken {
                    Section("How is it affecting you?") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Effectiveness")
                                .font(.subheadline)
                            HStack {
                                ForEach(1...5, id: \.self) { value in
                                    Button(action: {
                                        effectiveness = value
                                    }) {
                                        Image(systemName: effectiveness >= value ? "star.fill" : "star")
                                            .foregroundColor(effectiveness >= value ? .yellow : .gray)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood")
                                .font(.subheadline)
                            HStack {
                                ForEach(1...5, id: \.self) { value in
                                    Button(action: {
                                        mood = value
                                    }) {
                                        Image(systemName: mood >= value ? "face.smiling.fill" : "face.smiling")
                                            .foregroundColor(mood >= value ? .green : .gray)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Energy Level")
                                .font(.subheadline)
                            HStack {
                                ForEach(1...5, id: \.self) { value in
                                    Button(action: {
                                        energyLevel = value
                                    }) {
                                        Image(systemName: energyLevel >= value ? "bolt.fill" : "bolt")
                                            .foregroundColor(energyLevel >= value ? .orange : .gray)
                                    }
                                }
                            }
                        }
                    }

                    Section("Side Effects (Optional)") {
                        TextEditor(text: $sideEffects)
                            .frame(height: 80)
                    }

                    Section("Additional Notes (Optional)") {
                        TextEditor(text: $notes)
                            .frame(height: 80)
                    }
                }
            }
            .navigationTitle("Log Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedicationLog()
                    }
                }
            }
        }
    }

    private func saveMedicationLog() {
        viewModel.logMedication(
            medication: medication,
            taken: taken,
            skippedReason: taken ? nil : (skippedReason.isEmpty ? nil : skippedReason),
            sideEffects: sideEffects.isEmpty ? nil : sideEffects,
            effectiveness: taken ? effectiveness : 0,
            mood: taken ? mood : 0,
            energyLevel: taken ? energyLevel : 0,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
}
