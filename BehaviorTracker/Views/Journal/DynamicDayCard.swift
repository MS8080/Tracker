import SwiftUI

// MARK: - Adaptive Layout Configuration

/// Calculates optimal layout values based on available screen space and entry count
struct AdaptiveLayoutConfig {
    let availableHeight: CGFloat
    let entryCount: Int
    let isExpanded: Bool

    // Estimated heights for layout calculations
    private let headerHeight: CGFloat = 30
    private let cardPaddingTotal: CGFloat = 24  // top + bottom padding
    private let minLineHeight: CGFloat = 18     // approximate line height for caption font
    private let maxLineHeight: CGFloat = 24     // approximate line height for body font

    /// Initialize with available height and entries
    init(availableHeight: CGFloat, entryCount: Int, isExpanded: Bool = false) {
        self.availableHeight = max(availableHeight, 200) // minimum safety
        self.entryCount = max(entryCount, 1)
        self.isExpanded = isExpanded
    }

    /// Available height per entry after accounting for header and padding
    private var heightPerEntry: CGFloat {
        let usableHeight = availableHeight - headerHeight - cardPaddingTotal
        return usableHeight / CGFloat(entryCount)
    }

    /// How spacious the layout can be (0.0 = cramped, 1.0 = very spacious)
    var spaciousnessRatio: CGFloat {
        // Based on height per entry - more height = more spacious
        // 150pt per entry is very spacious, 50pt is cramped
        let ratio = (heightPerEntry - 50) / 100
        return min(max(ratio, 0), 1)
    }

    /// Calculated line limit for entry content
    var lineLimit: Int {
        if isExpanded {
            // Expanded view - more generous
            if entryCount == 1 {
                return 25
            } else if spaciousnessRatio > 0.7 {
                return 15
            } else if spaciousnessRatio > 0.4 {
                return 10
            } else {
                return 6
            }
        }

        // Timeline view - calculate based on available space
        if entryCount == 1 {
            // Single entry - use most of available space
            // Estimate: ~20pt per line, reserve 60pt for timestamp/title
            let availableForContent = heightPerEntry - 60
            let estimatedLines = Int(availableForContent / minLineHeight)
            return min(max(estimatedLines, 3), 15)
        } else {
            // Multiple entries - balance space
            let availableForContent = heightPerEntry - 40 // less overhead per entry
            let estimatedLines = Int(availableForContent / minLineHeight)

            // Apply reasonable bounds
            if spaciousnessRatio > 0.7 {
                return min(max(estimatedLines, 4), 8)
            } else if spaciousnessRatio > 0.4 {
                return min(max(estimatedLines, 3), 5)
            } else {
                return min(max(estimatedLines, 2), 4)
            }
        }
    }

    /// Spacing between entries
    var entrySpacing: CGFloat {
        if entryCount == 1 {
            return Spacing.lg
        }

        if spaciousnessRatio > 0.7 {
            return Spacing.md
        } else if spaciousnessRatio > 0.4 {
            return Spacing.sm
        } else if spaciousnessRatio > 0.2 {
            return Spacing.xs
        } else {
            return 2
        }
    }

    /// Card internal padding
    var cardPadding: CGFloat {
        if isExpanded {
            return spaciousnessRatio > 0.5 ? Spacing.lg : Spacing.md
        }

        if entryCount == 1 {
            return Spacing.md
        } else if spaciousnessRatio > 0.5 {
            return Spacing.sm
        } else {
            return Spacing.xs
        }
    }

    /// Timeline dot size
    var dotSize: CGFloat {
        if spaciousnessRatio > 0.5 || entryCount <= 2 {
            return isExpanded ? 12 : 8
        } else {
            return isExpanded ? 10 : 6
        }
    }

    /// Timeline connector width
    var connectorWidth: CGFloat {
        spaciousnessRatio > 0.5 || entryCount <= 2 ? 2 : 1.5
    }

    /// Content font based on space
    var contentFont: Font {
        if isExpanded {
            return entryCount == 1 ? .body : .subheadline
        }

        if entryCount == 1 {
            return .subheadline
        } else if spaciousnessRatio > 0.6 {
            return .subheadline
        } else if spaciousnessRatio > 0.3 {
            return .footnote
        } else {
            return .caption
        }
    }

    /// Timestamp font
    var timestampFont: Font {
        spaciousnessRatio > 0.5 || entryCount <= 2 ? .caption : .caption2
    }

    /// Title font
    var titleFont: Font {
        if entryCount == 1 || spaciousnessRatio > 0.6 {
            return .subheadline
        } else {
            return .caption
        }
    }

    /// Header font
    var headerFont: Font {
        if isExpanded {
            return entryCount <= 2 ? .title : .title2
        }

        if entryCount <= 2 || spaciousnessRatio > 0.6 {
            return .headline
        } else {
            return .subheadline
        }
    }

    /// Line spacing for content text
    var lineSpacing: CGFloat {
        if spaciousnessRatio > 0.6 {
            return 4
        } else if spaciousnessRatio > 0.3 {
            return 3
        } else {
            return 2
        }
    }

    /// Spacing between elements within an entry
    var internalSpacing: CGFloat {
        spaciousnessRatio > 0.5 || entryCount <= 2 ? Spacing.sm : Spacing.xs
    }

    /// HStack spacing for timeline row
    var rowSpacing: CGFloat {
        spaciousnessRatio > 0.5 || entryCount <= 2 ? Spacing.md : Spacing.sm
    }
}

// MARK: - Dynamic Day Card with Adaptive Sizing

struct DynamicDayCard: View {
    let date: Date
    let entries: [JournalEntry]
    let theme: AppTheme
    var isExpanded: Bool = false
    var availableHeight: CGFloat = 600  // Default, will be overridden by parent
    var namespace: Namespace.ID
    let onEntryTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onSpeak: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void
    let onAnalyze: (JournalEntry) -> Void
    let onAnalyzeDay: ([JournalEntry], Date) -> Void
    let onTapCard: () -> Void

    /// Computed layout configuration based on available space
    private var layoutConfig: AdaptiveLayoutConfig {
        AdaptiveLayoutConfig(
            availableHeight: availableHeight,
            entryCount: entries.count,
            isExpanded: isExpanded
        )
    }

    // Copy functions
    private func copyEntry(_ entry: JournalEntry) {
        var text = ""
        if let title = entry.title, !title.isEmpty {
            text += "\(title)\n\n"
        }
        text += entry.content
        UIPasteboard.general.string = text
        HapticFeedback.medium.trigger()
    }

    private func copyDay() {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        var text = "\(formatter.string(from: date))\n\n"

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            text += "[\(timeFormatter.string(from: entry.timestamp))]\n"
            if let title = entry.title, !title.isEmpty {
                text += "\(title)\n"
            }
            text += "\(entry.content)\n\n"
        }

        UIPasteboard.general.string = text
        HapticFeedback.medium.trigger()
    }

    // MARK: - Formatters

    private static let dateHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
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

    var body: some View {
        VStack(alignment: .leading, spacing: layoutConfig.internalSpacing) {
            // Date Header - adaptive based on available space
            Text(dateHeader)
                .font(layoutConfig.headerFont)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.95))
                .padding(.leading, 4)

            // Timeline Entries
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    AdaptiveTimelineEntry(
                        entry: entry,
                        isLast: index == entries.count - 1,
                        layoutConfig: layoutConfig,
                        theme: theme,
                        onTap: { onEntryTap(entry) },
                        onToggleFavorite: { onToggleFavorite(entry) },
                        onSpeak: { onSpeak(entry) },
                        onDelete: { onDelete(entry) },
                        onAnalyze: { onAnalyze(entry) },
                        onCopyEntry: copyEntry,
                        onCopyDay: copyDay
                    )
                }
            }

            // Entry count footer (in expanded mode)
            if isExpanded {
                HStack {
                    Spacer()
                    Text("\(entries.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.light.trigger()
            onTapCard()
        }
    }
}

// MARK: - Adaptive Timeline Entry

struct AdaptiveTimelineEntry: View {
    let entry: JournalEntry
    let isLast: Bool
    let layoutConfig: AdaptiveLayoutConfig
    let theme: AppTheme
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onSpeak: () -> Void
    let onDelete: () -> Void
    let onAnalyze: () -> Void
    var onCopyEntry: ((JournalEntry) -> Void)?
    var onCopyDay: (() -> Void)?

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        if !entry.isDeleted {
            HStack(alignment: .top, spacing: layoutConfig.rowSpacing) {
                // Timeline bullet - adaptive size based on available space
                VStack(spacing: 0) {
                    Circle()
                        .fill(theme.timelineColor)
                        .frame(width: layoutConfig.dotSize, height: layoutConfig.dotSize)
                        .shadow(color: theme.timelineColor.opacity(0.5), radius: layoutConfig.spaciousnessRatio > 0.5 ? 3 : 2)
                        .padding(.top, 3)

                    if !isLast {
                        Rectangle()
                            .fill(theme.timelineColor.opacity(0.4))
                            .frame(width: layoutConfig.connectorWidth)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: layoutConfig.dotSize)

                // Entry content
                VStack(alignment: .leading, spacing: layoutConfig.internalSpacing) {
                    // Time - adaptive font based on available space
                    Text(Self.timeFormatter.string(from: entry.timestamp))
                        .font(layoutConfig.timestampFont)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.timelineColor)

                    // Title (if exists)
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(layoutConfig.titleFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.95))
                            .lineLimit(layoutConfig.entryCount == 1 ? 2 : 1)
                    }

                    // Content preview - adaptive font and line limit based on screen space
                    Text(entry.preview)
                        .font(layoutConfig.contentFont)
                        .lineSpacing(layoutConfig.lineSpacing)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(layoutConfig.lineLimit)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isLast ? 0 : layoutConfig.entrySpacing)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedback.light.trigger()
                    onTap()
                }
                .contextMenu {
                    Button {
                        onCopyEntry?(entry)
                    } label: {
                        Label("Copy Entry", systemImage: "doc.on.doc")
                    }

                    Button {
                        onCopyDay?()
                    } label: {
                        Label("Copy Entire Day", systemImage: "doc.on.doc.fill")
                    }

                    Divider()

                    Button {
                        onToggleFavorite()
                    } label: {
                        Label(entry.isFavorite ? "Remove Bookmark" : "Bookmark", systemImage: entry.isFavorite ? "bookmark.slash" : "bookmark")
                    }

                    Button {
                        onSpeak()
                    } label: {
                        Label("Read Aloud", systemImage: "speaker.wave.2")
                    }

                    Button {
                        onAnalyze()
                    } label: {
                        Label("Analyze Entry", systemImage: "sparkles")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Expanded Day Content View

struct ExpandedDayContentView: View {
    let date: Date
    let entries: [JournalEntry]
    let theme: AppTheme
    let onEntryTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onSpeak: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void
    let onAnalyze: (JournalEntry) -> Void
    let onAnalyzeDay: ([JournalEntry], Date) -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Date header - single date display only
            Text(Self.dateFormatter.string(from: date))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.95))
                .padding(.bottom, Spacing.sm)

            // Full timeline with generous spacing
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    ExpandedTimelineEntry(
                        entry: entry,
                        isLast: index == entries.count - 1,
                        theme: theme,
                        onTap: { onEntryTap(entry) },
                        onToggleFavorite: { onToggleFavorite(entry) },
                        onSpeak: { onSpeak(entry) },
                        onDelete: { onDelete(entry) },
                        onAnalyze: { onAnalyze(entry) }
                    )
                }
            }
        }
    }
}

// MARK: - Expanded Timeline Entry (Fullscreen View)

struct ExpandedTimelineEntry: View {
    let entry: JournalEntry
    let isLast: Bool
    let theme: AppTheme
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onSpeak: () -> Void
    let onDelete: () -> Void
    let onAnalyze: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        if !entry.isDeleted {
            HStack(alignment: .top, spacing: Spacing.lg) {
                // Timeline with larger bullet
                VStack(spacing: 0) {
                    Circle()
                        .fill(theme.timelineColor)
                        .frame(width: 14, height: 14)
                        .shadow(color: theme.timelineColor.opacity(0.6), radius: 6)
                        .padding(.top, 6)

                    if !isLast {
                        Rectangle()
                            .fill(theme.timelineColor.opacity(0.5))
                            .frame(width: 2)
                    }
                }
                .frame(width: 14)

                // Entry content with full detail
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Time
                    Text(Self.timeFormatter.string(from: entry.timestamp))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.timelineColor)

                    // Title
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary.opacity(0.95))
                    }

                    // Full content
                    Text(entry.content)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundStyle(.primary.opacity(0.9))

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isLast ? 0 : Spacing.xxl)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedback.light.trigger()
                    onTap()
                }
            }
        }
    }
}
