import SwiftUI

struct CurrentSetupCard: View {
    private let dataController = DataController.shared
    @State private var showingSetupManager = false
    @State private var editingItem: SetupItem?
    @State private var groupedItems: [SetupItemCategory: [SetupItem]] = [:]
    @State private var refreshID = UUID()

    @ThemeWrapper var theme

    private var hasItems: Bool {
        !groupedItems.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "gearshape.2.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("Current Setup")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.title)

                Spacer()

                Button {
                    showingSetupManager = true
                } label: {
                    Image(systemName: hasItems ? "pencil" : "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(theme.primaryColor.opacity(0.5))
                        )
                }
            }

            if hasItems {
                // Show items grouped by category
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(SetupItemCategory.allCases, id: \.self) { category in
                        if let items = groupedItems[category], !items.isEmpty {
                            categorySection(category: category, items: items)
                        }
                    }
                }
            } else {
                // Empty state
                VStack(spacing: Spacing.sm) {
                    Text("Track your current stack")
                        .font(.body)
                        .foregroundStyle(CardText.body)

                    Text("Add medications, supplements, activities, and accommodations")
                        .font(.subheadline)
                        .foregroundStyle(CardText.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
        .id(refreshID)
        .onAppear {
            loadItems()
        }
        .sheet(isPresented: $showingSetupManager, onDismiss: loadItems) {
            SetupManagerView()
        }
        .sheet(item: $editingItem, onDismiss: loadItems) { item in
            EditSetupItemView(item: item)
        }
    }

    private func loadItems() {
        groupedItems = dataController.fetchSetupItemsGrouped(activeOnly: true)
        refreshID = UUID()
    }

    private func categorySection(category: SetupItemCategory, items: [SetupItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category header
            HStack(spacing: Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(category.color)

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.secondary)
            }

            // Items with tags - tappable for editing
            FlowLayout(spacing: Spacing.sm) {
                ForEach(items, id: \.id) { item in
                    itemChip(item)
                        .onTapGesture {
                            HapticFeedback.light.trigger()
                            editingItem = item
                        }
                }
            }
        }
    }

    private func itemChip(_ item: SetupItem) -> some View {
        HStack(spacing: 4) {
            Text(item.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(CardText.body)

            if !item.effectTagsArray.isEmpty {
                Text(item.formattedEffectTags.prefix(2).joined(separator: " "))
                    .font(.caption2)
                    .foregroundStyle(item.displayColor)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(item.displayColor.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(item.displayColor.opacity(0.3), lineWidth: 0.5)
        )
        .contentShape(Capsule())
    }
}

// MARK: - Setup Manager View

struct SetupManagerView: View {
    @Environment(\.dismiss) private var dismiss
    private let dataController = DataController.shared
    @State private var addingToCategory: SetupItemCategory?
    @State private var editingItem: SetupItem?
    @State private var groupedItems: [SetupItemCategory: [SetupItem]] = [:]

    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        ForEach(SetupItemCategory.allCases, id: \.self) { category in
                            categoryCard(category)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Current Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addingToCategory = .medication
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                }
            }
            .onAppear {
                loadItems()
            }
            .sheet(item: $addingToCategory, onDismiss: loadItems) { category in
                AddSetupItemView(category: category)
            }
            .sheet(item: $editingItem, onDismiss: loadItems) { item in
                EditSetupItemView(item: item)
            }
        }
    }

    private func loadItems() {
        groupedItems = dataController.fetchSetupItemsGrouped(activeOnly: false)
    }

    private func categoryCard(_ category: SetupItemCategory) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(category.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.headline)

                    Text(category.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    addingToCategory = category
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }

            if let items = groupedItems[category], !items.isEmpty {
                VStack(spacing: Spacing.sm) {
                    ForEach(items, id: \.id) { item in
                        itemRow(item)
                    }
                }
            } else {
                Text("No \(category.rawValue.lowercased()) added yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, Spacing.sm)
            }
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme)
    }

    private func itemRow(_ item: SetupItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.sm) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(!item.isActive, color: .secondary)
                        .foregroundStyle(item.isActive ? .primary : .secondary)

                    if !item.isActive {
                        Text("Inactive")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.2)))
                    }
                }

                if !item.effectTagsArray.isEmpty {
                    Text(item.formattedEffectTags.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(item.displayColor)
                }
            }

            Spacer()

            Button {
                editingItem = item
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.white.opacity(0.05))
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
                                tagChip(tag, isSelected: true)
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
                tagChip(tag.rawValue, isSelected: selectedTags.contains(tag.rawValue))
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

    private func tagChip(_ tag: String, isSelected: Bool) -> some View {
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
                            tagChip(tag.rawValue, isSelected: selectedTags.contains(tag.rawValue))
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

    private func tagChip(_ tag: String, isSelected: Bool) -> some View {
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

    private func saveChanges() {
        item.name = name
        item.setEffectTags(Array(selectedTags))
        item.notes = notes.isEmpty ? nil : notes
        item.isActive = isActive
        DataController.shared.updateSetupItem(item)
        dismiss()
    }
}

#Preview {
    CurrentSetupCard()
}
