import SwiftUI

// MARK: - Dynamic Day Card with Adaptive Sizing

struct DynamicDayCard: View {
    let date: Date
    let entries: [JournalEntry]
    let theme: AppTheme
    var isExpanded: Bool = false
    var isFocused: Bool = false
    var namespace: Namespace.ID
    let onEntryTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onSpeak: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void
    let onAnalyze: (JournalEntry) -> Void
    let onAnalyzeDay: ([JournalEntry], Date) -> Void
    let onTapCard: () -> Void

    // MARK: - Dynamic Sizing Calculations

    /// Calculate card height based on content
    private var dynamicCardHeight: CGFloat? {
        if isExpanded {
            return nil // Let content determine height
        }

        let entryCount = entries.count
        let baseHeight: CGFloat = 120
        let heightPerEntry: CGFloat = 60

        // More entries = taller card
        let calculatedHeight = baseHeight + (CGFloat(entryCount) * heightPerEntry)

        // Cap maximum height in timeline view
        return min(calculatedHeight, 400)
    }

    /// Calculate spacing between timeline entries
    private func spacingForEntry(_ entry: JournalEntry) -> CGFloat {
        let contentLength = entry.content.count

        if isExpanded {
            // Expanded view: generous spacing
            return contentLength > 200 ? Spacing.xl : Spacing.lg
        } else {
            // Compact view: adaptive spacing
            if contentLength < 50 {
                return Spacing.xs // Very short entry
            } else if contentLength < 150 {
                return Spacing.sm // Short entry
            } else {
                return Spacing.md // Long entry
            }
        }
    }

    /// Maximum lines to show for entry preview
    private func lineLimitForEntry(_ entry: JournalEntry) -> Int {
        if isExpanded {
            return 10
        }

        // In timeline view, limit long entries to 2 lines max
        let contentLength = entry.content.count
        if contentLength < 80 {
            return 2
        } else {
            return 2  // Max 2 lines for long entries to avoid boring scrolling
        }
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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Date Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateHeader)
                        .font(isFocused ? .title : .title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.95))

                    if !isToday {
                        Text(Self.dateHeaderFormatter.string(from: date))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Entry count badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption2)
                    Text("\(entries.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(theme.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.primaryColor.opacity(0.2))
                )
            }

            // Timeline Entries
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    AdaptiveTimelineEntry(
                        entry: entry,
                        isLast: index == entries.count - 1,
                        isExpanded: isExpanded,
                        lineLimit: lineLimitForEntry(entry),
                        spacing: spacingForEntry(entry),
                        theme: theme,
                        onTap: { onEntryTap(entry) },
                        onToggleFavorite: { onToggleFavorite(entry) },
                        onSpeak: { onSpeak(entry) },
                        onDelete: { onDelete(entry) },
                        onAnalyze: { onAnalyze(entry) }
                    )
                }
            }

            // Quick actions footer (in expanded mode)
            if isExpanded {
                HStack {
                    Button {
                        onAnalyzeDay(entries, date)
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "sparkles")
                            Text("Analyze Day")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.primaryColor)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(theme.primaryColor.opacity(0.15))
                        )
                    }

                    Spacer()

                    Text("\(entries.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(isExpanded ? Spacing.xxl : Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: dynamicCardHeight) // Dynamic height!
        .focusableCardStyle(
            theme: theme,
            cornerRadius: isFocused ? CornerRadius.lg : CornerRadius.md,
            isFocused: isFocused
        )
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
    var isExpanded: Bool
    var lineLimit: Int
    var spacing: CGFloat
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
            HStack(alignment: .top, spacing: Spacing.md) {
                // Timeline bullet
                VStack(spacing: 0) {
                    Circle()
                        .fill(theme.timelineColor)
                        .frame(width: isExpanded ? 12 : 8, height: isExpanded ? 12 : 8)
                        .shadow(color: theme.timelineColor.opacity(0.6), radius: 4)
                        .padding(.top, 4)

                    if !isLast {
                        Rectangle()
                            .fill(theme.timelineColor.opacity(0.5))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: isExpanded ? 12 : 8)

                // Entry content
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Time
                    Text(Self.timeFormatter.string(from: entry.timestamp))
                        .font(isExpanded ? .subheadline : .caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.timelineColor)

                    // Title (if exists)
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(isExpanded ? .callout : .caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.95))
                            .lineLimit(1)
                    }

                    // Content preview with better readability
                    Text(entry.preview)
                        .font(isExpanded ? .callout : .caption)
                        .lineSpacing(isExpanded ? 4 : 3)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(lineLimit)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // Show "Read more..." for truncated long entries
                    if !isExpanded && entry.content.count > 150 {
                        Text("Read more...")
                            .font(.caption2)
                            .foregroundStyle(theme.primaryColor.opacity(0.8))
                            .padding(.top, 2)
                    }

                    // Action buttons (only in timeline, not expanded)
                    if !isExpanded {
                        HStack(spacing: Spacing.md) {
                            // Favorite button
                            Button {
                                onToggleFavorite()
                            } label: {
                                Image(systemName: entry.isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(entry.isFavorite ? .yellow : .white.opacity(0.6))
                            }

                            // Analyze button
                            Button {
                                onAnalyze()
                            } label: {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            // Speak button
                            Button {
                                onSpeak()
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, Spacing.sm)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isLast ? 0 : spacing)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedback.light.trigger()
                    onTap()
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
            // Date header - single date display with entry count
            HStack(spacing: Spacing.md) {
                Text(Self.dateFormatter.string(from: date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.95))

                Spacer()

                // Entry count badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                    Text("\(entries.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(theme.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.primaryColor.opacity(0.2))
                )
            }
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
            .padding()
            .cardStyle(theme: theme, cornerRadius: CornerRadius.lg)

            // Day actions
            HStack(spacing: Spacing.md) {
                Button {
                    onAnalyzeDay(entries, date)
                } label: {
                    Label("Analyze This Day", systemImage: "sparkles")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(theme.primaryColor)
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
                            .frame(maxHeight: .infinity)
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

                    // Actions - larger, more visible buttons
                    HStack(spacing: Spacing.lg) {
                        Button {
                            HapticFeedback.light.trigger()
                            onToggleFavorite()
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: entry.isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 16, weight: .medium))
                                Text(entry.isFavorite ? "Favorited" : "Favorite")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(entry.isFavorite ? .yellow : .white.opacity(0.8))
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(entry.isFavorite ? Color.yellow.opacity(0.15) : Color.white.opacity(0.1))
                            )
                        }

                        Button {
                            HapticFeedback.light.trigger()
                            onSpeak()
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Read")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                        }

                        Button {
                            HapticFeedback.light.trigger()
                            onAnalyze()
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Analyze")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }
                    .padding(.top, Spacing.xs)
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
