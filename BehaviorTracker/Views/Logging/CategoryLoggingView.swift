import SwiftUI

struct CategoryLoggingView: View {
    @Environment(\.dismiss) private var dismiss
    let category: PatternCategory
    @ObservedObject var viewModel: LoggingViewModel

    @State private var selectedPatternType: PatternType?

    var body: some View {
        NavigationStack {
            List {
                ForEach(patternsInCategory, id: \.self) { patternType in
                    Button {
                        selectedPatternType = patternType
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(patternType.rawValue)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                if viewModel.favoritePatterns.contains(patternType.rawValue) {
                                    Label("Favorite", systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPatternType) { patternType in
                PatternEntryFormView(
                    patternType: patternType,
                    viewModel: viewModel,
                    onSave: {
                        dismiss()
                    }
                )
            }
        }
    }

    private var patternsInCategory: [PatternType] {
        PatternType.allCases.filter { $0.category == category }
    }
}

extension PatternCategory: Identifiable {
    public var id: String { rawValue }
}

extension PatternType: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    CategoryLoggingView(category: .sensory, viewModel: LoggingViewModel())
}
