import SwiftUI

struct WishlistListView: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    @State private var showingAcquired = false
    @ThemeWrapper var theme

    var body: some View {
        List {
            Section {
                ForEach(viewModel.wishlistItems) { item in
                    WishlistDetailRow(item: item, viewModel: viewModel)
                }
                .onDelete(perform: deleteItems)
            } header: {
                Text("Wishlist (\(viewModel.wishlistItems.count))")
            }

            if showingAcquired {
                Section {
                    ForEach(WishlistRepository.shared.fetchAcquired()) { item in
                        WishlistDetailRow(item: item, viewModel: viewModel)
                    }
                } header: {
                    Text("Acquired")
                }
            }
        }
        .navigationTitle("Wishlist")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showingAddWishlistItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingAcquired.toggle()
                } label: {
                    Label(
                        showingAcquired ? "Hide Acquired" : "Show Acquired",
                        systemImage: showingAcquired ? "eye.slash" : "eye"
                    )
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddWishlistItem) {
            AddWishlistItemView(viewModel: viewModel)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteWishlistItem(viewModel.wishlistItems[index])
        }
    }
}

struct WishlistDetailRow: View {
    let item: WishlistItem
    @ObservedObject var viewModel: LifeGoalsViewModel
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: Spacing.md) {
                Button {
                    viewModel.toggleWishlistAcquired(item)
                    HapticFeedback.success.trigger()
                } label: {
                    Image(systemName: item.isAcquired ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.isAcquired ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(item.isAcquired ? .secondary : .primary)
                        .strikethrough(item.isAcquired)

                    if let category = item.categoryType {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<item.priorityLevel.rawValue, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                        }
                        ForEach(0..<(3 - item.priorityLevel.rawValue), id: \.self) { _ in
                            Image(systemName: "star")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.3))
                        }
                    }

                    Text(item.priorityLevel.displayName)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            WishlistDetailView(item: item, viewModel: viewModel)
        }
    }
}

struct WishlistDetailView: View {
    let item: WishlistItem
    @ObservedObject var viewModel: LifeGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Priority") {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            HStack(spacing: 4) {
                                ForEach(0..<item.priorityLevel.rawValue, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.title2)
                                        .foregroundStyle(.yellow)
                                }
                            }
                            Text(item.priorityLevel.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }

                Section("Details") {
                    if let category = item.categoryType {
                        LabeledContent("Category") {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }

                    LabeledContent("Added") {
                        Text(item.createdAt, style: .date)
                    }

                    LabeledContent("Status") {
                        Text(item.isAcquired ? "Acquired" : "Wanted")
                            .foregroundStyle(item.isAcquired ? .green : .orange)
                    }
                }

                if let notes = item.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                Section {
                    Button(item.isAcquired ? "Mark as Not Acquired" : "Mark as Acquired") {
                        viewModel.toggleWishlistAcquired(item)
                        HapticFeedback.success.trigger()
                        dismiss()
                    }
                    .foregroundStyle(item.isAcquired ? .orange : .green)

                    Button("Delete Item", role: .destructive) {
                        viewModel.deleteWishlistItem(item)
                        dismiss()
                    }
                }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WishlistListView(viewModel: LifeGoalsViewModel())
    }
}
