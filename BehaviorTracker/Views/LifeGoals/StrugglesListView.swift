import SwiftUI

struct StrugglesListView: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    @State private var showingResolved = false
    @ThemeWrapper var theme

    var body: some View {
        List {
            Section {
                ForEach(viewModel.struggles) { struggle in
                    StruggleDetailRow(struggle: struggle, viewModel: viewModel)
                }
                .onDelete(perform: deleteStruggles)
            } header: {
                Text("Active Struggles (\(viewModel.struggles.count))")
            }

            if showingResolved {
                Section {
                    ForEach(StruggleRepository.shared.fetchResolved()) { struggle in
                        StruggleDetailRow(struggle: struggle, viewModel: viewModel)
                    }
                } header: {
                    Text("Resolved")
                }
            }
        }
        .navigationTitle("Struggles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showingAddStruggle = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingResolved.toggle()
                } label: {
                    Label(
                        showingResolved ? "Hide Resolved" : "Show Resolved",
                        systemImage: showingResolved ? "eye.slash" : "eye"
                    )
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddStruggle) {
            AddStruggleView(viewModel: viewModel)
        }
    }

    private func deleteStruggles(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteStruggle(viewModel.struggles[index])
        }
    }
}

struct StruggleDetailRow: View {
    let struggle: Struggle
    @ObservedObject var viewModel: LifeGoalsViewModel
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(intensityColor)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(struggle.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(struggle.isActive ? .primary : .secondary)

                    HStack(spacing: Spacing.sm) {
                        Text(struggle.intensityLevel.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(intensityColor.opacity(0.2))
                            .foregroundStyle(intensityColor)
                            .cornerRadius(4)

                        if let category = struggle.categoryType {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(struggle.durationSinceCreated)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !struggle.triggersList.isEmpty {
                        Text("Triggers: \(struggle.triggersList.prefix(2).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: struggle.displayIcon)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingDetail) {
            StruggleDetailView(struggle: struggle, viewModel: viewModel)
        }
    }

    private var intensityColor: Color {
        switch struggle.intensityLevel {
        case .mild: return .green
        case .moderate: return .yellow
        case .significant: return .orange
        case .severe: return .red
        case .overwhelming: return .purple
        }
    }
}

struct StruggleDetailView: View {
    let struggle: Struggle
    @ObservedObject var viewModel: LifeGoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newTrigger = ""
    @State private var newCopingStrategy = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Intensity") {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Circle()
                                .fill(intensityColor)
                                .frame(width: 16, height: 16)
                            Text(struggle.intensityLevel.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Picker("Update Intensity", selection: Binding(
                            get: { struggle.intensityLevel },
                            set: { viewModel.updateStruggleIntensity(struggle, intensity: $0) }
                        )) {
                            ForEach(Struggle.Intensity.allCases, id: \.self) { intensity in
                                Text(intensity.displayName).tag(intensity)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Details") {
                    if let category = struggle.categoryType {
                        LabeledContent("Category") {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }

                    LabeledContent("Duration", value: struggle.durationSinceCreated)

                    LabeledContent("Status") {
                        Text(struggle.isActive ? "Active" : "Resolved")
                            .foregroundStyle(struggle.isActive ? .orange : .green)
                    }
                }

                Section("Triggers") {
                    if struggle.triggersList.isEmpty {
                        Text("No triggers added yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(struggle.triggersList, id: \.self) { trigger in
                            Label(trigger, systemImage: "bolt.fill")
                                .foregroundStyle(.orange)
                        }
                    }

                    HStack {
                        TextField("Add trigger...", text: $newTrigger)
                        Button {
                            if !newTrigger.isEmpty {
                                viewModel.addTriggerToStruggle(struggle, trigger: newTrigger)
                                newTrigger = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTrigger.isEmpty)
                    }
                }

                Section("Coping Strategies") {
                    if struggle.copingStrategiesList.isEmpty {
                        Text("No coping strategies added yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(struggle.copingStrategiesList, id: \.self) { strategy in
                            Label(strategy, systemImage: "heart.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    HStack {
                        TextField("Add strategy...", text: $newCopingStrategy)
                        Button {
                            if !newCopingStrategy.isEmpty {
                                viewModel.addCopingStrategyToStruggle(struggle, strategy: newCopingStrategy)
                                newCopingStrategy = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newCopingStrategy.isEmpty)
                    }
                }

                if let notes = struggle.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                Section {
                    Button(struggle.isActive ? "Mark as Resolved" : "Reactivate") {
                        if struggle.isActive {
                            viewModel.resolveStruggle(struggle)
                        } else {
                            viewModel.reactivateStruggle(struggle)
                        }
                        HapticFeedback.success.trigger()
                        dismiss()
                    }
                    .foregroundStyle(struggle.isActive ? .green : .orange)

                    Button("Delete Struggle", role: .destructive) {
                        viewModel.deleteStruggle(struggle)
                        dismiss()
                    }
                }
            }
            .navigationTitle(struggle.title)
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

    private var intensityColor: Color {
        switch struggle.intensityLevel {
        case .mild: return .green
        case .moderate: return .yellow
        case .significant: return .orange
        case .severe: return .red
        case .overwhelming: return .purple
        }
    }
}

#Preview {
    NavigationStack {
        StrugglesListView(viewModel: LifeGoalsViewModel())
    }
}
