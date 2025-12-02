import SwiftUI

// MARK: - Day Timeline Card

struct DayTimelineCard: View {
    let date: Date
    let entries: [JournalEntry]
    let theme: AppTheme
    var isExpanded: Bool = false
    var maxLines: Int = 2
    let onEntryTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onSpeak: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void
    let onAnalyze: (JournalEntry) -> Void
    let onAnalyzeDay: ([JournalEntry], Date) -> Void

    // MARK: - Cached Formatters (Performance Optimization)
    private static let dateHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dateHeader: String {
        if isToday {
            return NSLocalizedString("time.today", comment: "")
        } else if Calendar.current.isDateInYesterday(date) {
            return NSLocalizedString("time.yesterday", comment: "")
        } else {
            return Self.dateHeaderFormatter.string(from: date)
        }
    }

    private var dateHeaderFull: String {
        Self.fullDateFormatter.string(from: date)
    }

    private func copyDayTimeline() {
        var copyText = "📅 \(dateHeaderFull)\n"
        copyText += String(repeating: "─", count: 30) + "\n\n"

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let time = Self.timeFormatter.string(from: entry.timestamp)
            copyText += "⏱ \(time)\n"

            if let title = entry.title, !title.isEmpty {
                copyText += "📝 \(title)\n"
            }

            copyText += entry.content + "\n\n"
        }

        UIPasteboard.general.string = copyText
        HapticFeedback.medium.trigger()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Date Header with context menu for day actions
            HStack {
                Text(dateHeader)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()

                // Entry count badge
                Text("\(entries.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.primaryColor.opacity(0.15))
                    )
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    copyDayTimeline()
                } label: {
                    Label("Copy Day", systemImage: "doc.on.doc")
                }

                Button {
                    onAnalyzeDay(entries, date)
                } label: {
                    Label("Analyze Day", systemImage: "sparkles")
                }
            }

            // Timeline
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    JournalTimelineEntryRow(
                        entry: entry,
                        allDayEntries: entries,
                        date: date,
                        isLast: index == entries.count - 1,
                        isExpanded: isExpanded,
                        maxLines: maxLines,
                        theme: theme,
                        onTap: { onEntryTap(entry) },
                        onToggleFavorite: { onToggleFavorite(entry) },
                        onSpeak: { onSpeak(entry) },
                        onDelete: { onDelete(entry) },
                        onAnalyze: { onAnalyze(entry) },
                        onAnalyzeDay: { onAnalyzeDay(entries, date) },
                        onCopyDay: { copyDayTimeline() }
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        .shadow(color: theme.primaryColor.opacity(0.25), radius: 12, y: 2)
    }
}

// MARK: - Journal Timeline Entry Row

struct JournalTimelineEntryRow: View {
    let entry: JournalEntry
    let allDayEntries: [JournalEntry]
    let date: Date
    let isLast: Bool
    var isExpanded: Bool = false
    var maxLines: Int = 2
    let theme: AppTheme
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onSpeak: () -> Void
    let onDelete: () -> Void
    let onAnalyze: () -> Void
    let onAnalyzeDay: () -> Void
    let onCopyDay: () -> Void

    // MARK: - Cached Formatters (Performance Optimization)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    private var timeString: String {
        Self.timeFormatter.string(from: entry.timestamp)
    }

    private func copyEntryToClipboard() {
        var copyText = ""

        // Add title if present
        if let title = entry.title, !title.isEmpty {
            copyText += "\(title)\n\n"
        }

        // Add content
        copyText += entry.content

        // Add date and time
        copyText += "\n\n— \(Self.dateTimeFormatter.string(from: entry.timestamp))"

        UIPasteboard.general.string = copyText
        HapticFeedback.light.trigger()
    }

    var body: some View {
        // Safety check: don't render if entry is deleted
        if !entry.isDeleted {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Timeline with bullet point
                VStack(spacing: 0) {
                        Circle()
                        .fill(theme.timelineColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: theme.timelineColor.opacity(0.6), radius: 4)
                        .padding(.top, 4)

                // Vertical line (if not last)
                if !isLast {
                    Rectangle()
                        .fill(theme.timelineColor.opacity(0.5))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)

            // Content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Time
                Text(timeString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.timelineColor)

                // Entry content
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    if let title = entry.title, !title.isEmpty {
                        titleView(title)
                    }

                    Text(entry.preview)
                        .font(.callout)
                        .lineSpacing(4)
                        .foregroundStyle(.primary.opacity(0.85))
                        .lineLimit(isExpanded ? maxLines : 3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.bottom, isLast ? 0 : (isExpanded ? Spacing.md : Spacing.lg))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .contextMenu {
                // Entry-specific actions
                Section("This Entry") {
                    Button {
                        onAnalyze()
                    } label: {
                        Label("Analyze Entry", systemImage: "sparkles")
                    }

                    Button {
                        copyEntryToClipboard()
                    } label: {
                        Label("Copy Entry", systemImage: "doc.on.doc")
                    }

                    Button {
                        onToggleFavorite()
                    } label: {
                        Label(
                            entry.isFavorite ? "Unfavorite" : "Favorite",
                            systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                        )
                    }

                    Button {
                        onSpeak()
                    } label: {
                        Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                    }
                }

                // Day-level actions
                Section("Whole Day (\(allDayEntries.count) entries)") {
                    Button {
                        onAnalyzeDay()
                    } label: {
                        Label("Analyze Day", systemImage: "calendar.badge.sparkles")
                    }

                    Button {
                        onCopyDay()
                    } label: {
                        Label("Copy Day", systemImage: "doc.on.doc.fill")
                    }
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Favorite indicator
            if entry.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(SemanticColor.warning)
                    .font(.caption)
            }
        }
        }
    }

    /// Title tag configuration
    private struct TitleTag {
        let prefix: String
        let label: String
        let icon: String
        let color: Color

        static let tags: [TitleTag] = [
            TitleTag(prefix: "AI Insight:", label: "AI Insight", icon: "sparkles", color: .yellow),
            TitleTag(prefix: "Guided Entry:", label: "Guided", icon: "questionmark.circle.fill", color: .green),
            TitleTag(prefix: "Log:", label: "Log", icon: "plus.circle.fill", color: .blue)
        ]
    }

    @ViewBuilder
    private func titleView(_ title: String) -> some View {
        if let tag = TitleTag.tags.first(where: { title.hasPrefix($0.prefix) }) {
            taggedTitleView(title: title, tag: tag)
        } else {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.95))
        }
    }

    private func taggedTitleView(title: String, tag: TitleTag) -> some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tag.icon)
                    .font(.caption)
                Text(tag.label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(tag.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(tag.color.opacity(0.15))
            )

            Text(String(title.dropFirst(tag.prefix.count)).trimmingCharacters(in: .whitespaces))
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.95))
                .lineLimit(1)
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Rounded Search Bar

struct RoundedSearchBar: View {
    @Binding var text: String
    @ThemeWrapper var theme

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(NSLocalizedString("journal.search_placeholder", comment: "Search placeholder"), text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .accessibilityLabel(NSLocalizedString("journal.search_placeholder", comment: ""))

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(NSLocalizedString("accessibility.hide_search", comment: ""))
                }
            }
        }
        .padding(Spacing.md)
        .cardStyle(theme: theme, cornerRadius: 20)
    }
}
