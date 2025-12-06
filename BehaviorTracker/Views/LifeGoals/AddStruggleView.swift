import SwiftUI

struct AddStruggleView: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var category: Struggle.Category?
    @State private var intensity: Struggle.Intensity = .moderate
    @State private var triggersText = ""
    @State private var copingText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Struggle") {
                    TextField("What are you struggling with?", text: $title)

                    Picker("Category", selection: $category) {
                        Text("None").tag(nil as Struggle.Category?)
                        ForEach(Struggle.Category.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat as Struggle.Category?)
                        }
                    }

                    if let cat = category {
                        Text(cat.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("How intense is it?") {
                    Picker("Intensity", selection: $intensity) {
                        ForEach(Struggle.Intensity.allCases, id: \.self) { i in
                            Text(i.displayName).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)

                    intensityDescription
                }

                Section("Triggers (optional)") {
                    TextField("What makes it worse? (comma-separated)", text: $triggersText)
                        .font(.subheadline)

                    Text("Examples: loud noises, social situations, unexpected changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Coping Strategies (optional)") {
                    TextField("What helps? (comma-separated)", text: $copingText)
                        .font(.subheadline)

                    Text("Examples: deep breathing, noise-canceling headphones, quiet space")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Struggle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addStruggle()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var intensityDescription: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(intensityColor)
                .frame(width: 10, height: 10)

            Text(intensityMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var intensityColor: Color {
        switch intensity {
        case .mild: return .green
        case .moderate: return .yellow
        case .significant: return .orange
        case .severe: return .red
        case .overwhelming: return .purple
        }
    }

    private var intensityMessage: String {
        switch intensity {
        case .mild: return "Manageable most of the time"
        case .moderate: return "Noticeable but can cope"
        case .significant: return "Significantly affects daily life"
        case .severe: return "Very difficult to manage"
        case .overwhelming: return "Feels impossible to handle"
        }
    }

    private func addStruggle() {
        let triggers = triggersText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let coping = copingText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        viewModel.createStruggle(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            intensity: intensity,
            triggers: triggers,
            copingStrategies: coping,
            notes: notes.isEmpty ? nil : notes
        )
        HapticFeedback.success.trigger()
        dismiss()
    }
}

#Preview {
    AddStruggleView(viewModel: LifeGoalsViewModel())
}
