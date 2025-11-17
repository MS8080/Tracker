import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var editedMood: Int = 3
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with date and mood
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.timestamp, style: .date)
                            .font(.headline)
                        Text(entry.timestamp, style: .time)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !isEditing {
                        Text(moodEmoji(for: Int(entry.mood)))
                            .font(.system(size: 40))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if isEditing {
                    // Edit mode
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextField("Title (Optional)", text: $editedTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextEditor(text: $editedContent)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 20) {
                                ForEach(1...5, id: \.self) { moodValue in
                                    Button {
                                        editedMood = moodValue
                                    } label: {
                                        VStack(spacing: 8) {
                                            Text(moodEmoji(for: moodValue))
                                                .font(.system(size: 40))
                                                .scaleEffect(editedMood == moodValue ? 1.2 : 1.0)
                                                .animation(.spring(response: 0.3), value: editedMood)
                                            
                                            if editedMood == moodValue {
                                                Circle()
                                                    .fill(.blue)
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                } else {
                    // View mode
                    VStack(alignment: .leading, spacing: 16) {
                        if let title = entry.title, !title.isEmpty {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(entry.content)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Done") {
                        saveChanges()
                    }
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    viewModel.toggleFavorite(entry)
                } label: {
                    Image(systemName: entry.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(entry.isFavorite ? .yellow : .primary)
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        editedTitle = entry.title ?? ""
        editedContent = entry.content
        editedMood = Int(entry.mood)
    }
    
    private func startEditing() {
        isEditing = true
    }
    
    private func cancelEditing() {
        setupInitialValues()
        isEditing = false
    }
    
    private func saveChanges() {
        entry.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedTitle
        entry.content = editedContent
        entry.mood = Int16(editedMood)
        
        viewModel.updateEntry(entry)
        isEditing = false
    }
    
    private func moodEmoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😔"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "😄"
        default: return "🙂"
        }
    }
}
