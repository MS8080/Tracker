import SwiftUI

struct PatternEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    let patternType: PatternType
    @ObservedObject var viewModel: LoggingViewModel
    let onSave: () -> Void

    @State private var intensity: Double = 3
    @State private var duration: Int = 0
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var contextNotes: String = ""
    @State private var specificDetails: String = ""
    @State private var isFavorite: Bool = false
    @State private var selectedContributingFactors: Set<ContributingFactor> = []
    @State private var showingContributingFactors: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: patternType.category.icon)
                            .font(.title2)
                            .foregroundStyle(patternType.category.color)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(patternType.rawValue)
                                .font(.headline)
                            Text(patternType.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if patternType.hasIntensityScale {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Intensity")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(intensity))")
                                    .font(.headline)
                                    .foregroundStyle(intensityColor)
                            }

                            Slider(value: $intensity, in: 1...5, step: 1)
                                .tint(intensityColor)

                            HStack {
                                Text("Low")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("High")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if patternType.hasDuration {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 20) {
                                Picker("Hours", selection: $hours) {
                                    ForEach(0..<24) { hour in
                                        Text("\(hour)h").tag(hour)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80)

                                Picker("Minutes", selection: $minutes) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute)m").tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $showingContributingFactors) {
                        ForEach(ContributingFactor.groupedByCategory, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                
                                ForEach(group.factors, id: \.self) { factor in
                                    Button {
                                        if selectedContributingFactors.contains(factor) {
                                            selectedContributingFactors.remove(factor)
                                        } else {
                                            selectedContributingFactors.insert(factor)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: factor.icon)
                                                .frame(width: 20)
                                                .foregroundStyle(.secondary)
                                            
                                            Text(factor.rawValue)
                                                .foregroundStyle(.primary)
                                            
                                            Spacer()
                                            
                                            if selectedContributingFactors.contains(factor) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.blue)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Contributing Factors")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            if !selectedContributingFactors.isEmpty {
                                Text("\(selectedContributingFactors.count) selected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Specific Details (Optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField(patternType.detailsPlaceholder, text: $specificDetails, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context Notes (Optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Additional observations or context", text: $contextNotes, axis: .vertical)
                            .lineLimit(2...6)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle(isOn: $isFavorite) {
                        HStack {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                            Text("Add to Favorites")
                        }
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var intensityColor: Color {
        switch Int(intensity) {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }

    private func saveEntry() {
        let totalMinutes = (hours * 60) + minutes

        viewModel.logPattern(
            patternType: patternType,
            intensity: Int16(intensity),
            duration: Int32(totalMinutes),
            contextNotes: contextNotes.isEmpty ? nil : contextNotes,
            specificDetails: specificDetails.isEmpty ? nil : specificDetails,
            isFavorite: isFavorite,
            contributingFactors: Array(selectedContributingFactors)
        )

        onSave()
    }
}

#Preview {
    PatternEntryFormView(
        patternType: .sensoryOverload,
        viewModel: LoggingViewModel(),
        onSave: {}
    )
}
