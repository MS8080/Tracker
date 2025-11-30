import SwiftUI

// MARK: - Insight Tile View with Context Menu

struct InsightTileView: View {
    let section: InsightSection
    let theme: AppTheme
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onAddToJournal: (CGRect) -> Void

    @State private var tileFrame: CGRect = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.title3)
                    .foregroundStyle(section.color)
                Text(section.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.title)

                Spacer()

                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            ForEach(section.bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(section.color.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .padding(.top, 8)

                    Text(bullet)
                        .font(.body)
                        .foregroundStyle(CardText.body)
                }
            }

            if !section.paragraph.isEmpty {
                Text(section.paragraph)
                    .font(.body)
                    .foregroundStyle(CardText.secondary)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(theme: theme)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        tileFrame = geo.frame(in: .global)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        tileFrame = newFrame
                    }
            }
        )
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }

            Button {
                onAddToJournal(tileFrame)
            } label: {
                Label("Add to Journal", systemImage: "book.fill")
            }
        }
    }
}

// MARK: - Summary Tile View with Context Menu

struct SummaryTileView: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    let theme: AppTheme
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onAddToJournal: (CGRect) -> Void

    @State private var tileFrame: CGRect = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.title)

                Spacer()

                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            Text(content)
                .font(.body)
                .foregroundStyle(CardText.body)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        tileFrame = geo.frame(in: .global)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        tileFrame = newFrame
                    }
            }
        )
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }

            Button {
                onAddToJournal(tileFrame)
            } label: {
                Label("Add to Journal", systemImage: "book.fill")
            }
        }
    }
}

// MARK: - Flying Tile Animation (Apple Mail style)

struct FlyingTileView: View {
    let info: FlyingTileInfo
    let theme: AppTheme
    let onComplete: () -> Void

    @State private var animationPhase: Int = 0
    @State private var position: CGPoint
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    init(info: FlyingTileInfo, theme: AppTheme, onComplete: @escaping () -> Void) {
        self.info = info
        self.theme = theme
        self.onComplete = onComplete
        // Start at tile center
        _position = State(initialValue: CGPoint(
            x: info.startFrame.midX,
            y: info.startFrame.midY
        ))
    }

    var body: some View {
        // Mini preview of the tile
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: info.icon)
                    .font(.caption)
                    .foregroundStyle(info.color)
                Text(info.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            Text(info.content)
                .font(.caption2)
                .foregroundStyle(CardText.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(.ultraThinMaterial.opacity(0.5))
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .position(position)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Get screen dimensions
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Target: Journal tab (3rd tab from left, roughly)
        let targetX = screenWidth * 0.5  // Center-ish for Journal tab
        let targetY = screenHeight - 40  // Tab bar area

        // Phase 1: Lift up and shrink slightly
        withAnimation(.easeOut(duration: 0.15)) {
            scale = 0.9
            position.y -= 20
        }

        // Phase 2: Arc towards journal with rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeIn(duration: 0.25)) {
                position = CGPoint(x: targetX, y: targetY)
                scale = 0.3
                rotation = -15
            }
        }

        // Phase 3: Final shrink and fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.1)) {
                scale = 0.1
                opacity = 0
            }
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}
