import SwiftUI

struct AddWishlistItemView: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var category: WishlistItem.Category?
    @State private var priority: WishlistItem.Priority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Wishlist Item") {
                    TextField("What do you want?", text: $title)

                    Picker("Category", selection: $category) {
                        Text("None").tag(nil as WishlistItem.Category?)
                        ForEach(WishlistItem.Category.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat as WishlistItem.Category?)
                        }
                    }
                }

                Section("How much do you want it?") {
                    Picker("Priority", selection: $priority) {
                        ForEach(WishlistItem.Priority.allCases, id: \.self) { p in
                            HStack {
                                Text(p.displayName)
                                Spacer()
                                HStack(spacing: 2) {
                                    ForEach(0..<p.rawValue, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.yellow)
                                    }
                                }
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)

                    Text("Why do you want this? How would it help?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Wish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addItem() {
        viewModel.createWishlistItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            priority: priority,
            notes: notes.isEmpty ? nil : notes
        )
        HapticFeedback.success.trigger()
        dismiss()
    }
}

#Preview {
    AddWishlistItemView(viewModel: LifeGoalsViewModel())
}
