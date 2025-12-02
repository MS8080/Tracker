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

#Preview {
    CurrentSetupCard()
}
