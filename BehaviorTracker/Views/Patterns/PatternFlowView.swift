import SwiftUI

/// Flow visualization showing patterns as connected nodes (left to right)
struct PatternFlowView: View {
    let patterns: [ExtractedPattern]
    let cascades: [PatternCascade]
    let theme: AppTheme

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureOffset: CGSize = .zero

    // Node layout - larger nodes and more spacing
    private let nodeWidth: CGFloat = 140
    private let nodeHeight: CGFloat = 100
    private let horizontalSpacing: CGFloat = 80
    private let verticalSpacing: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            let layout = calculateLayout(in: geometry.size)

            ZStack {
                // Background with subtle grid
                flowBackground

                if patterns.isEmpty {
                    // Empty state
                    emptyFlowState
                } else {
                    // Connection lines (behind nodes)
                    ForEach(cascades) { cascade in
                        if let fromPos = layout.positions[cascade.fromPattern?.id],
                           let toPos = layout.positions[cascade.toPattern?.id] {
                            CascadeLineView(
                                from: fromPos,
                                to: toPos,
                                confidence: cascade.confidence,
                                theme: theme
                            )
                        }
                    }

                    // Pattern nodes
                    ForEach(patterns) { pattern in
                        if let position = layout.positions[pattern.id] {
                            PatternNodeView(
                                pattern: pattern,
                                theme: theme
                            )
                            .frame(width: nodeWidth, height: nodeHeight)
                            .position(position)
                        }
                    }
                }
            }
            .scaleEffect(scale * gestureScale)
            .offset(x: offset.width + gestureOffset.width, y: offset.height + gestureOffset.height)
            .gesture(
                MagnificationGesture()
                    .updating($gestureScale) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        scale = min(max(scale * value, 0.5), 3.0)
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .updating($gestureOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        offset.width += value.translation.width
                        offset.height += value.translation.height
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    scale = 1.0
                    offset = .zero
                }
            }
        }
    }

    // MARK: - Flow Background

    private var flowBackground: some View {
        Canvas { context, size in
            // Draw subtle grid
            let gridSpacing: CGFloat = 40
            let gridColor = Color.white.opacity(0.05)

            for x in stride(from: 0, to: size.width, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            for y in stride(from: 0, to: size.height, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Empty State

    private var emptyFlowState: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))

            Text("No patterns yet")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Text("Patterns will appear here after analysis")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Layout Calculation

    private struct LayoutResult {
        var positions: [UUID?: CGPoint] = [:]
    }

    private func calculateLayout(in size: CGSize) -> LayoutResult {
        var result = LayoutResult()

        guard !patterns.isEmpty else { return result }

        // Group patterns by time order
        let sortedPatterns = patterns.sorted { $0.timestamp < $1.timestamp }

        // Find patterns that are cascade targets (have incoming connections)
        let cascadeTargets = Set(cascades.compactMap { $0.toPattern?.id })

        // Find patterns that are cascade sources (have outgoing connections)
        let cascadeSources = Set(cascades.compactMap { $0.fromPattern?.id })

        // Calculate columns based on cascade relationships
        var columns: [[ExtractedPattern]] = []
        var assigned: Set<UUID> = []

        // First column: patterns that have no incoming cascades
        let firstColumn = sortedPatterns.filter { !cascadeTargets.contains($0.id) }
        if !firstColumn.isEmpty {
            columns.append(firstColumn)
            assigned.formUnion(firstColumn.map { $0.id })
        }

        // Subsequent columns: follow cascade chain
        var currentSources = Set(firstColumn.map { $0.id })
        while assigned.count < sortedPatterns.count {
            // Find patterns that are targets of current sources
            let nextColumn = sortedPatterns.filter { pattern in
                !assigned.contains(pattern.id) &&
                cascades.contains { cascade in
                    currentSources.contains(cascade.fromPattern?.id ?? UUID()) &&
                    cascade.toPattern?.id == pattern.id
                }
            }

            if nextColumn.isEmpty {
                // No more cascade chain, add remaining patterns
                let remaining = sortedPatterns.filter { !assigned.contains($0.id) }
                if !remaining.isEmpty {
                    columns.append(remaining)
                    assigned.formUnion(remaining.map { $0.id })
                }
                break
            } else {
                columns.append(nextColumn)
                assigned.formUnion(nextColumn.map { $0.id })
                currentSources = Set(nextColumn.map { $0.id })
            }
        }

        // If no columns created, just put all in one column
        if columns.isEmpty {
            columns = [sortedPatterns]
        }

        // Calculate positions
        let totalWidth = CGFloat(columns.count) * (nodeWidth + horizontalSpacing)
        let startX = max((size.width - totalWidth) / 2 + nodeWidth / 2, nodeWidth / 2 + 20)

        for (colIndex, column) in columns.enumerated() {
            let x = startX + CGFloat(colIndex) * (nodeWidth + horizontalSpacing)
            let columnHeight = CGFloat(column.count) * (nodeHeight + verticalSpacing)
            let startY = max((size.height - columnHeight) / 2 + nodeHeight / 2, nodeHeight / 2 + 20)

            for (rowIndex, pattern) in column.enumerated() {
                let y = startY + CGFloat(rowIndex) * (nodeHeight + verticalSpacing)
                result.positions[pattern.id] = CGPoint(x: x, y: y)
            }
        }

        return result
    }
}

// MARK: - Pattern Node

struct PatternNodeView: View {
    let pattern: ExtractedPattern
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 4) {
            // Category icon
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundStyle(categoryColor)

            // Pattern name
            Text(shortName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Intensity bar
            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < pattern.intensity / 2 ? categoryColor : Color.white.opacity(0.2))
                        .frame(width: 12, height: 4)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.5), lineWidth: 1)
        )
    }

    private var shortName: String {
        // Shorten long pattern names
        let name = pattern.patternType
        if name.count > 20 {
            return String(name.prefix(18)) + "..."
        }
        return name
    }

    private var categoryIcon: String {
        switch pattern.category {
        case "Sensory": return "ear.and.waveform"
        case "Executive Function": return "brain"
        case "Energy & Regulation": return "bolt.fill"
        case "Social & Communication": return "person.2.fill"
        case "Routine & Change": return "calendar"
        case "Demand Avoidance": return "xmark.shield.fill"
        case "Physical & Sleep": return "bed.double.fill"
        case "Special Interests": return "star.fill"
        default: return "circle.fill"
        }
    }

    private var categoryColor: Color {
        switch pattern.category {
        case "Sensory": return .red
        case "Executive Function": return .orange
        case "Energy & Regulation": return .purple
        case "Social & Communication": return .blue
        case "Routine & Change": return .yellow
        case "Demand Avoidance": return .pink
        case "Physical & Sleep": return .green
        case "Special Interests": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Cascade Line

struct CascadeLineView: View {
    let from: CGPoint
    let to: CGPoint
    let confidence: Double
    let theme: AppTheme

    var body: some View {
        Path { path in
            path.move(to: from)

            // Create curved line
            let controlPoint1 = CGPoint(
                x: from.x + (to.x - from.x) * 0.5,
                y: from.y
            )
            let controlPoint2 = CGPoint(
                x: from.x + (to.x - from.x) * 0.5,
                y: to.y
            )

            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(
            theme.primaryColor.opacity(confidence),
            style: StrokeStyle(
                lineWidth: 2 + CGFloat(confidence) * 2,
                lineCap: .round
            )
        )

        // Arrow head
        arrowHead
    }

    private var arrowHead: some View {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 10

        return Path { path in
            path.move(to: to)
            path.addLine(to: CGPoint(
                x: to.x - arrowLength * cos(angle - .pi / 6),
                y: to.y - arrowLength * sin(angle - .pi / 6)
            ))
            path.move(to: to)
            path.addLine(to: CGPoint(
                x: to.x - arrowLength * cos(angle + .pi / 6),
                y: to.y - arrowLength * sin(angle + .pi / 6)
            ))
        }
        .stroke(
            theme.primaryColor.opacity(confidence),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }
}

#Preview {
    PatternFlowView(patterns: [], cascades: [], theme: .purple)
        .frame(height: 300)
        .background(Color.black)
}
