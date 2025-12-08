import SwiftUI
import CoreData

struct PatternEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    let patternType: PatternType
    @ObservedObject var viewModel: LoggingViewModel
    let onSave: () -> Void

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    @State private var intensity: Double = 3
    @State private var duration: Int = 0
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var contextNotes: String = ""
    @State private var specificDetails: String = ""
    @State private var isFavorite: Bool = false
    @State private var saveToJournal: Bool = false
    @State private var selectedContributingFactors: Set<ContributingFactor> = []
    @State private var showingContributingFactors: Bool = false
    @State private var selectedCalendarEvents: Set<String> = []
    @State private var todayEvents: [CalendarEvent] = []

    // Voice input
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    @State private var isRecordingDetails: Bool = false
    @State private var isRecordingContext: Bool = false

    private let calendarService = CalendarEventService.shared

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
                                if patternType.isBidirectional {
                                    Text("State")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Intensity")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(Int(intensity))")
                                    .font(.headline)
                                    .foregroundStyle(intensityColor)
                            }

                            Slider(value: $intensity, in: 1...5, step: 1)
                                .tint(intensityColor)

                            HStack {
                                if let labels = patternType.scaleLabels {
                                    Text(labels.low)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(labels.high)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Low")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("High")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
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
                                #if os(iOS)
                                .pickerStyle(.wheel)
                                #endif
                                .frame(width: 80)

                                Picker("Minutes", selection: $minutes) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute)m").tag(minute)
                                    }
                                }
                                #if os(iOS)
                                .pickerStyle(.wheel)
                                #endif
                                .frame(width: 80)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $showingContributingFactors) {
                        // Today's Calendar Events
                        if !todayEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Today's Events")
                                    .font(.caption)
                                    .foregroundStyle(.cyan)
                                    .padding(.top, 4)

                                ForEach(todayEvents) { event in
                                    Button {
                                        if selectedCalendarEvents.contains(event.id) {
                                            selectedCalendarEvents.remove(event.id)
                                        } else {
                                            selectedCalendarEvents.insert(event.id)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "calendar")
                                                .frame(width: 20)
                                                .foregroundStyle(.cyan)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(event.title)
                                                    .foregroundStyle(.primary)
                                                Text(event.timeString)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            if selectedCalendarEvents.contains(event.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.cyan)
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

                            if !selectedContributingFactors.isEmpty || !selectedCalendarEvents.isEmpty {
                                Text("\(selectedContributingFactors.count + selectedCalendarEvents.count) selected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onAppear {
                    loadTodayEvents()
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Specific Details (Optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            // Voice input button
                            Button {
                                toggleVoiceInput(isRecording: $isRecordingDetails, otherRecording: $isRecordingContext, text: $specificDetails)
                            } label: {
                                Image(systemName: isRecordingDetails ? "mic.fill" : "mic")
                                    .foregroundStyle(isRecordingDetails ? .red : .blue)
                                    .font(.body)
                                    .symbolEffect(.pulse, isActive: isRecordingDetails)
                            }
                            .buttonStyle(.plain)
                        }

                        TextField(patternType.detailsPlaceholder, text: $specificDetails, axis: .vertical)
                            .lineLimit(2...4)

                        if isRecordingDetails {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Listening...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Context Notes (Optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            // Voice input button
                            Button {
                                toggleVoiceInput(isRecording: $isRecordingContext, otherRecording: $isRecordingDetails, text: $contextNotes)
                            } label: {
                                Image(systemName: isRecordingContext ? "mic.fill" : "mic")
                                    .foregroundStyle(isRecordingContext ? .red : .blue)
                                    .font(.body)
                                    .symbolEffect(.pulse, isActive: isRecordingContext)
                            }
                            .buttonStyle(.plain)
                        }

                        TextField("Additional observations or context", text: $contextNotes, axis: .vertical)
                            .lineLimit(2...6)

                        if isRecordingContext {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Listening...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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

                    Toggle(isOn: $saveToJournal) {
                        HStack {
                            Image(systemName: saveToJournal ? "book.fill" : "book")
                                .foregroundStyle(.green)
                            Text("Save to Journal")
                        }
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
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

    private func loadTodayEvents() {
        calendarService.checkAuthorizationStatus()
        if calendarService.isAuthorized {
            todayEvents = calendarService.fetchEvents(for: Date())
        }
    }

    private func saveEntry() {
        // Stop any recording before saving
        speechRecognizer.stopTranscribing()
        isRecordingDetails = false
        isRecordingContext = false

        let totalMinutes = (hours * 60) + minutes

        // Build context notes including selected calendar events
        var finalContextNotes = contextNotes

        if !selectedCalendarEvents.isEmpty {
            let selectedEventTitles = todayEvents
                .filter { selectedCalendarEvents.contains($0.id) }
                .map { "📅 \($0.title)" }

            if !selectedEventTitles.isEmpty {
                let eventsText = "Related events: " + selectedEventTitles.joined(separator: ", ")
                if finalContextNotes.isEmpty {
                    finalContextNotes = eventsText
                } else {
                    finalContextNotes += "\n\n" + eventsText
                }
            }
        }

        Task {
            _ = await viewModel.logPattern(
                patternType: patternType,
                intensity: Int16(intensity),
                duration: Int32(totalMinutes),
                contextNotes: finalContextNotes.isEmpty ? nil : finalContextNotes,
                specificDetails: specificDetails.isEmpty ? nil : specificDetails,
                isFavorite: isFavorite,
                contributingFactors: Array(selectedContributingFactors)
            )
        }

        // Save to journal if enabled
        if saveToJournal {
            saveToJournalEntry(finalContextNotes: finalContextNotes, totalMinutes: totalMinutes)
        }

        onSave()
    }

    private func saveToJournalEntry(finalContextNotes: String, totalMinutes: Int) {
        let journalEntry = JournalEntry(context: viewContext)

        // Format title with pattern type and date
        journalEntry.title = "Log: \(patternType.rawValue)"

        // Build journal content (plain text format)
        var content = "\(patternType.category.rawValue)\n"

        if patternType.hasIntensityScale {
            let intensityLabel: String
            switch Int(intensity) {
            case 1: intensityLabel = "Low"
            case 2: intensityLabel = "Mild"
            case 3: intensityLabel = "Moderate"
            case 4: intensityLabel = "High"
            case 5: intensityLabel = "Severe"
            default: intensityLabel = "Unknown"
            }
            content += "Intensity: \(Int(intensity))/5 (\(intensityLabel))\n"
        }

        if patternType.hasDuration && totalMinutes > 0 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            if hours > 0 {
                content += "Duration: \(hours)h \(mins)m\n"
            } else {
                content += "Duration: \(mins) minutes\n"
            }
        }

        if !selectedContributingFactors.isEmpty {
            let factorNames = selectedContributingFactors.map { $0.rawValue }.joined(separator: ", ")
            content += "Contributing Factors: \(factorNames)\n"
        }

        if !specificDetails.isEmpty {
            content += "\nDetails: \(specificDetails)\n"
        }

        if !finalContextNotes.isEmpty {
            content += "\nContext: \(finalContextNotes)\n"
        }

        journalEntry.content = content
        journalEntry.timestamp = Date()
        journalEntry.id = UUID()
        journalEntry.mood = 0
        journalEntry.isFavorite = false

        do {
            try viewContext.save()
        } catch {
        }
    }

    // MARK: - Voice Input

    private func toggleVoiceInput(isRecording: Binding<Bool>, otherRecording: Binding<Bool>, text: Binding<String>) {
        if isRecording.wrappedValue {
            speechRecognizer.stopTranscribing()
            isRecording.wrappedValue = false
        } else {
            if otherRecording.wrappedValue {
                speechRecognizer.stopTranscribing()
                otherRecording.wrappedValue = false
            }
            isRecording.wrappedValue = true
            speechRecognizer.startTranscribing { result in
                if !text.wrappedValue.isEmpty && !text.wrappedValue.hasSuffix(" ") {
                    text.wrappedValue += " "
                }
                text.wrappedValue += result
            }
        }
    }
}

#Preview {
    PatternEntryFormView(
        patternType: .sensoryState,
        viewModel: LoggingViewModel(),
        onSave: {}
    )
}
