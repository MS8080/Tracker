import SwiftUI

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
                    Button("Done") {
                        dismiss()
                    }
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

#Preview {
    SetupManagerView()
}
