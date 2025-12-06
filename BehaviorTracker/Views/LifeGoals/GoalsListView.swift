import SwiftUI

struct GoalsListView: View {
    @ObservedObject var viewModel: LifeGoalsViewModel
    @State private var showingCompleted = false
    @ThemeWrapper var theme

    var body: some View {
        List {
            Section {
                ForEach(viewModel.goals) { goal in
                    GoalDetailRow(goal: goal, viewModel: viewModel)
                }
                .onDelete(perform: deleteGoals)
            } header: {
                Text("Active Goals (\(viewModel.goals.count))")
            }

            if showingCompleted {
                Section {
                    ForEach(GoalRepository.shared.fetchCompleted()) { goal in
                        GoalDetailRow(goal: goal, viewModel: viewModel)
                    }
                } header: {
                    Text("Completed")
                }
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showingAddGoal = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingCompleted.toggle()
                } label: {
                    Label(
                        showingCompleted ? "Hide Completed" : "Show Completed",
                        systemImage: showingCompleted ? "eye.slash" : "eye"
                    )
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddGoal) {
            AddGoalView(viewModel: viewModel)
        }
    }

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteGoal(viewModel.goals[index])
        }
    }
}

struct GoalDetailRow: View {
    let goal: Goal
    @ObservedObject var viewModel: LifeGoalsViewModel
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: Spacing.md) {
                Button {
                    viewModel.toggleGoalComplete(goal)
                    HapticFeedback.success.trigger()
                } label: {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(goal.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                        .strikethrough(goal.isCompleted)

                    if goal.progress > 0 && goal.progress < 1.0 {
                        HStack(spacing: Spacing.sm) {
                            ProgressView(value: goal.progress)
                                .tint(.orange)
                                .frame(maxWidth: 100)

                            Text("\(goal.progressPercentage)%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: Spacing.sm) {
                        if let category = goal.categoryType {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let dueDate = goal.formattedDueDate {
                            Label(dueDate, systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(goal.isOverdue ? .red : .secondary)
                        }
                    }
                }

                Spacer()

                priorityIndicator
            }
        }
        .sheet(isPresented: $showingDetail) {
            GoalDetailView(goal: goal, viewModel: viewModel)
        }
    }

    private var priorityIndicator: some View {
        VStack(spacing: 2) {
            ForEach(0..<goal.priorityLevel.rawValue, id: \.self) { _ in
                Circle()
                    .fill(priorityColor)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var priorityColor: Color {
        switch goal.priorityLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct GoalDetailView: View {
    let goal: Goal
    @ObservedObject var viewModel: LifeGoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double

    init(goal: Goal, viewModel: LifeGoalsViewModel) {
        self.goal = goal
        self.viewModel = viewModel
        _progress = State(initialValue: goal.progress)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Progress") {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("\(Int(progress * 100))%")
                                .font(.title)
                                .fontWeight(.bold)

                            Spacer()

                            if goal.isCompleted {
                                Label("Completed", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }

                        Slider(value: $progress, in: 0...1, step: 0.1) {
                            Text("Progress")
                        } onEditingChanged: { editing in
                            if !editing {
                                viewModel.updateGoalProgress(goal, progress: progress)
                            }
                        }

                        ProgressView(value: progress)
                            .tint(.orange)
                    }
                }

                Section("Details") {
                    LabeledContent("Priority", value: goal.priorityLevel.displayName)

                    if let category = goal.categoryType {
                        LabeledContent("Category", value: category.rawValue)
                    }

                    if let dueDate = goal.formattedDueDate {
                        LabeledContent("Due Date") {
                            Text(dueDate)
                                .foregroundStyle(goal.isOverdue ? .red : .primary)
                        }
                    }

                    LabeledContent("Created") {
                        Text(goal.createdAt, style: .date)
                    }
                }

                if let notes = goal.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                Section {
                    Button(goal.isCompleted ? "Mark as Incomplete" : "Mark as Complete") {
                        viewModel.toggleGoalComplete(goal)
                        HapticFeedback.success.trigger()
                        dismiss()
                    }
                    .foregroundStyle(goal.isCompleted ? .orange : .green)

                    Button("Delete Goal", role: .destructive) {
                        viewModel.deleteGoal(goal)
                        dismiss()
                    }
                }
            }
            .navigationTitle(goal.title)
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
        GoalsListView(viewModel: LifeGoalsViewModel())
    }
}
