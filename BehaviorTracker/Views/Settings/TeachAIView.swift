import SwiftUI

/// View for managing personal knowledge snippets that teach the AI about the user
struct TeachAIView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var knowledgeItems: [PersonalKnowledge] = []
    @State private var showingAddSheet = false
    @State private var editingItem: PersonalKnowledge?
    @State private var itemToDelete: PersonalKnowledge?
    @State private var showingDeleteConfirmation = false

    @ThemeWrapper var theme

    private let repository = PersonalKnowledgeRepository.shared

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection

                    if knowledgeItems.isEmpty {
                        emptyStateView
                    } else {
                        knowledgeListSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Teach AI About Me")
        .navigationBarTitleDisplayModeInline()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            PersonalKnowledgeEditorView(mode: .add) { title, content in
                addKnowledge(title: title, content: content)
            }
        }
        .sheet(item: $editingItem) { item in
            PersonalKnowledgeEditorView(
                mode: .edit(item),
                onSave: { title, content in
                    updateKnowledge(item, title: title, content: content)
                }
            )
        }
        .confirmationDialog(
            "Delete this knowledge?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    deleteKnowledge(item)
                }
            }
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear {
            loadKnowledge()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.white)

                Text("Personal Context")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            Text("Add information about yourself to help the AI provide more personalized insights, recommendations, and pattern analysis.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: Spacing.xs) {
                Text("No Personal Context Yet")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Add things like your diagnosis history, sensory preferences, common triggers, or coping strategies.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Knowledge", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(theme.primaryColor)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(.white, in: Capsule())
            }
        }
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal)
    }

    // MARK: - Knowledge List

    private var knowledgeListSection: some View {
        VStack(spacing: Spacing.md) {
            ForEach(knowledgeItems, id: \.id) { item in
                KnowledgeItemCard(
                    item: item,
                    onToggleActive: { toggleActive(item) },
                    onEdit: { editingItem = item },
                    onDelete: {
                        itemToDelete = item
                        showingDeleteConfirmation = true
                    }
                )
            }
        }
    }

    // MARK: - Data Operations

    private func loadKnowledge() {
        knowledgeItems = repository.fetchAll()
    }

    private func addKnowledge(title: String?, content: String) {
        do {
            _ = try repository.create(title: title, content: content)
            loadKnowledge()
        } catch {
            print("Failed to add knowledge: \(error)")
        }
    }

    private func updateKnowledge(_ item: PersonalKnowledge, title: String?, content: String) {
        do {
            try repository.update(item, title: title, content: content)
            loadKnowledge()
        } catch {
            print("Failed to update knowledge: \(error)")
        }
    }

    private func toggleActive(_ item: PersonalKnowledge) {
        repository.toggleActive(item)
        loadKnowledge()
    }

    private func deleteKnowledge(_ item: PersonalKnowledge) {
        repository.delete(item)
        itemToDelete = nil
        loadKnowledge()
    }
}

// MARK: - Knowledge Item Card

struct KnowledgeItemCard: View {
    let item: PersonalKnowledge
    let onToggleActive: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                if let title = item.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Spacer()

                // Active toggle
                Button {
                    onToggleActive()
                } label: {
                    Image(systemName: item.isActive ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.isActive ? .green : .white.opacity(0.4))
                }
            }

            if let content = item.content {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(3)
            }

            HStack {
                if let date = item.updatedAt {
                    Text("Updated \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(.white.opacity(item.isActive ? 0.12 : 0.05), in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(item.isActive ? .green.opacity(0.3) : .clear, lineWidth: 1)
        )
    }
}

// MARK: - Personal Knowledge Editor

struct PersonalKnowledgeEditorView: View {
    enum Mode {
        case add
        case edit(PersonalKnowledge)

        var title: String {
            switch self {
            case .add: "Add Knowledge"
            case .edit: "Edit Knowledge"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    let mode: Mode
    let onSave: (String?, String) -> Void

    @State private var title: String = ""
    @State private var content: String = ""
    @FocusState private var contentFocused: Bool

    @ThemeWrapper var theme

    init(mode: Mode, onSave: @escaping (String?, String) -> Void) {
        self.mode = mode
        self.onSave = onSave

        // Initialize state from edit item
        if case .edit(let item) = mode {
            _title = State(initialValue: item.title ?? "")
            _content = State(initialValue: item.content ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Title field (optional)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Title (Optional)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))

                            TextField("e.g., Sensory Preferences", text: $title)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.md))
                                .foregroundStyle(.white)
                        }

                        // Content field
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("Content")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))

                                Spacer()

                                Text("\(content.count)/5000")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            TextEditor(text: $content)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                                .padding()
                                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.md))
                                .foregroundStyle(.white)
                                .focused($contentFocused)
                        }

                        // Examples
                        examplesSection
                    }
                    .padding()
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title.isEmpty ? nil : title, content)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    contentFocused = true
                }
            }
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Examples of helpful context:")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                exampleRow("Diagnosed with ASD at age 25")
                exampleRow("Sensitive to loud noises and bright lights")
                exampleRow("Deep pressure helps when overwhelmed")
                exampleRow("Prefer written communication over phone calls")
                exampleRow("Special interest in astronomy")
            }
        }
        .padding()
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private func exampleRow(_ text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb.min")
                .font(.caption)
                .foregroundStyle(.yellow.opacity(0.7))

            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

#Preview {
    NavigationStack {
        TeachAIView()
    }
}
