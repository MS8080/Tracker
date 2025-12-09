import SwiftUI

// MARK: - Insight Card View

struct InsightCardView: View {
    let card: AIInsightCard
    let theme: AppTheme
    let isSaved: Bool
    let isBookmarked: Bool
    let onCopy: () -> Void
    let onBookmark: () -> Void
    let onSaveToJournal: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Circular icon container (matching app design pattern)
            ZStack {
                Circle()
                    .fill(card.color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(card.color)
                    .frame(width: 40, height: 40)

                Image(systemName: card.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Title row with status icons
                HStack(spacing: Spacing.sm) {
                    Text(card.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.title)

                    Spacer()

                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    if isSaved {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                // Bullets
                if !card.bullets.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(Array(card.bullets.enumerated()), id: \.offset) { _, bullet in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Circle()
                                    .fill(card.color)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                Text(bullet)
                                    .font(.subheadline)
                                    .foregroundStyle(CardText.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                // Content
                if !card.content.isEmpty {
                    Text(card.content)
                        .font(.subheadline)
                        .foregroundStyle(CardText.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(theme: theme)
        .contextMenu {
            Button { onCopy() } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button { onBookmark() } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark",
                      systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }
            Button { onSaveToJournal() } label: {
                Label("Add to Journal", systemImage: "book.fill")
            }
        }
    }
}
