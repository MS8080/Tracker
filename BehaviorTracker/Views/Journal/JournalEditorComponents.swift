import SwiftUI

// MARK: - Event Mention Autocomplete

/// Autocomplete overlay for @mentioning calendar events
struct EventMentionAutocomplete: View {
    let events: [CalendarEvent]
    let onSelect: (CalendarEvent) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .background(.white.opacity(0.2))
            eventsList
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(SemanticColor.calendar)
            Text("Events")
                .font(.caption.bold())
                .foregroundStyle(CardText.secondary)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private var eventsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(events.prefix(6)) { event in
                    EventSuggestionRow(event: event) {
                        onSelect(event)
                    }
                }
            }
        }
        .frame(maxHeight: 200)
    }
}

// MARK: - Event Suggestion Row

struct EventSuggestionRow: View {
    let event: CalendarEvent
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color(cgColor: event.calendarColor ?? CGColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(event.formattedDateForMention)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Picker Overlay

struct JournalDatePickerOverlay: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let theme: AppTheme

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 0) {
                header
                datePicker
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding(.horizontal, Spacing.lg)
        }
        .transition(.opacity)
    }

    private var header: some View {
        HStack {
            Text("Select Date & Time")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
    }

    private var datePicker: some View {
        DatePicker(
            "Entry Date",
            selection: $selectedDate,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.graphical)
        .tint(theme.primaryColor)
        .colorScheme(.dark)
        .padding()
    }
}

// MARK: - Undo Toast

struct UndoToast: View {
    let message: String
    let theme: AppTheme
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                Button("Undo") {
                    onUndo()
                }
                .font(.subheadline.bold())
                .foregroundStyle(theme.primaryColor)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Journal Action Toolbar

struct JournalActionToolbar: View {
    let isAnalyzing: Bool
    let isContentEmpty: Bool
    let onVoice: () -> Void
    let onAnalyze: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.lg) {
            toolbarButton(
                icon: "mic.fill",
                label: "Voice",
                color: .white.opacity(0.9),
                action: onVoice
            )

            toolbarButton(
                icon: isAnalyzing ? nil : "sparkles",
                label: "Analyze",
                color: .white.opacity(0.9),
                isLoading: isAnalyzing,
                isDisabled: isContentEmpty || isAnalyzing,
                action: onAnalyze
            )

            toolbarButton(
                icon: "trash",
                label: "Delete",
                color: .red.opacity(0.9),
                isDisabled: isContentEmpty,
                action: onDelete
            )
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
    }

    private func toolbarButton(
        icon: String?,
        label: String,
        color: Color,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticFeedback.medium.trigger()
            action()
        } label: {
            VStack(spacing: 2) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                        .frame(height: 20)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - CalendarEvent Extension

extension CalendarEvent {
    /// Formatted date string for mention autocomplete
    var formattedDateForMention: String {
        if isAllDay {
            return "All day"
        }

        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(startDate) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(startDate) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        }

        return formatter.string(from: startDate)
    }
}

// MARK: - Circular Glass Modifier

/// Applies a circular glass background to toolbar buttons.
/// On iOS 26+, let the system handle glass effect - don't add custom background.
struct CircularGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

extension View {
    func circularGlass() -> some View {
        modifier(CircularGlassModifier())
    }
}
