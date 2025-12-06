import SwiftUI

struct AddGoalView: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var category: Goal.Category?
    @State private var priority: Goal.Priority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("What do you want to achieve?", text: $title)

                    Picker("Category", selection: $category) {
                        Text("None").tag(nil as Goal.Category?)
                        ForEach(Goal.Category.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat as Goal.Category?)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(Goal.Priority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addGoal()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addGoal() {
        viewModel.createGoal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            priority: priority,
            notes: notes.isEmpty ? nil : notes,
            dueDate: hasDueDate ? dueDate : nil
        )
        HapticFeedback.success.trigger()
        dismiss()
    }
}

#Preview {
    AddGoalView(viewModel: LifeGoalsViewModel())
}
