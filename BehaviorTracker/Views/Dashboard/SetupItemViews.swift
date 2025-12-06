import SwiftUI

// MARK: - Effect Tag Chip (Shared)

struct EffectTagChip: View {
    let tag: String
    let isSelected: Bool
    let theme: AppTheme

    var body: some View {
        Text("#\(tag)")
            .font(.caption)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? theme.primaryColor.opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 1)
            )
    }
}

// MARK: - Add Setup Item View

struct AddSetupItemView: View {
    @Environment(\.dismiss) private var dismiss
    let category: SetupItemCategory

    @State private var name = ""
    @State private var selectedTags: Set<String> = []
    @State private var notes = ""
    @State private var errorMessage: String?

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                } header: {
                    Label(category.rawValue, systemImage: category.icon)
                }

                Section("Effect Tags") {
                    effectTagsPicker
                }

                if !selectedTags.isEmpty {
                    Section("Selected Tags") {
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(Array(selectedTags).sorted(), id: \.self) { tag in
                                EffectTagChip(tag: tag, isSelected: true, theme: theme)
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add \(category.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }


                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveItem() }
                        .foregroundStyle(name.isEmpty ? .white.opacity(0.4) : .white)
                        .disabled(name.isEmpty)
                }

            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var effectTagsPicker: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(EffectTag.allCases, id: \.rawValue) { tag in
                EffectTagChip(tag: tag.rawValue, isSelected: selectedTags.contains(tag.rawValue), theme: theme)
                    .onTapGesture {
                        if selectedTags.contains(tag.rawValue) {
                            selectedTags.remove(tag.rawValue)
                        } else {
                            selectedTags.insert(tag.rawValue)
                        }
                    }
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func saveItem() {
        do {
            _ = try DataController.shared.createSetupItem(
                name: name,
                category: category,
                effectTags: Array(selectedTags),
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Edit Setup Item View

struct EditSetupItemView: View {
    @Environment(\.dismiss) private var dismiss
    let item: SetupItem

    @State private var name: String
    @State private var selectedTags: Set<String>
    @State private var notes: String
    @State private var isActive: Bool
    @State private var showingDeleteConfirm = false

    @ThemeWrapper var theme

    init(item: SetupItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _selectedTags = State(initialValue: Set(item.effectTagsArray))
        _notes = State(initialValue: item.notes ?? "")
        _isActive = State(initialValue: item.isActive)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    Toggle("Active", isOn: $isActive)
                }

                Section("Effect Tags") {
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(EffectTag.allCases, id: \.rawValue) { tag in
                            EffectTagChip(tag: tag.rawValue, isSelected: selectedTags.contains(tag.rawValue), theme: theme)
                                .onTapGesture {
                                    if selectedTags.contains(tag.rawValue) {
                                        selectedTags.remove(tag.rawValue)
                                    } else {
                                        selectedTags.insert(tag.rawValue)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }


                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .foregroundStyle(name.isEmpty ? .white.opacity(0.4) : .white)
                        .disabled(name.isEmpty)
                }

            }
            .confirmationDialog("Delete Item", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    DataController.shared.deleteSetupItem(item)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete '\(item.name)'?")
            }
        }
    }

    private func saveChanges() {
        item.name = name
        item.setEffectTags(Array(selectedTags))
        item.notes = notes.isEmpty ? nil : notes
        item.isActive = isActive
        DataController.shared.updateSetupItem(item)
        dismiss()
    }
}

#Preview("Add") {
    AddSetupItemView(category: .medication)
}

#Preview("Edit") {
    EditSetupItemView(item: SetupItem())
}
