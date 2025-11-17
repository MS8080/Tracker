#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

func getRainbowColor(position: CGFloat) -> NSColor {
    // Rainbow gradient colors matching the reference image
    let colors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
        (255, 69, 0),     // Red-Orange
        (255, 140, 0),    // Orange
        (255, 215, 0),    // Gold/Yellow
        (173, 255, 47),   // Yellow-Green
        (0, 255, 127),    // Spring Green
        (0, 191, 255),    // Deep Sky Blue
        (65, 105, 225),   // Royal Blue
    ]

    let scaledPos = position * CGFloat(colors.count - 1)
    let idx = Int(scaledPos)

    guard idx < colors.count - 1 else {
        let last = colors.last!
        return NSColor(red: last.r/255, green: last.g/255, blue: last.b/255, alpha: 1.0)
    }

    let ratio = scaledPos - CGFloat(idx)
    let c1 = colors[idx]
    let c2 = colors[idx + 1]

    let r = (c1.r * (1 - ratio) + c2.r * ratio) / 255
    let g = (c1.g * (1 - ratio) + c2.g * ratio) / 255
    let b = (c1.b * (1 - ratio) + c2.b * ratio) / 255

    return NSColor(red: r, green: g, blue: b, alpha: 1.0)
}

func createCleanAppIcon(size: CGFloat, outputPath: String) {
    let finalImage = NSImage(size: NSSize(width: size, height: size))
    finalImage.lockFocus()

    // White background
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    guard let context = NSGraphicsContext.current?.cgContext else {
        print("Failed to get graphics context")
        return
    }

    // Draw smooth infinity symbol
    let centerX = size / 2
    let centerY = size / 2
    let symbolWidth = size * 0.70
    let symbolHeight = size * 0.32
    let lineWidth = size * 0.09

    // Create path for infinity symbol
    let numPoints = 1000
    let a = symbolWidth / 2
    let b = symbolHeight / 2

    var points: [(x: CGFloat, y: CGFloat, position: CGFloat)] = []

    for i in 0..<numPoints {
        let t = (2 * CGFloat.pi * CGFloat(i)) / CGFloat(numPoints)
        let position = CGFloat(i) / CGFloat(numPoints)

        let denominator = 1 + sin(t) * sin(t)
        let x = centerX + (a * cos(t)) / denominator
        let y = centerY + (b * sin(t) * cos(t)) / denominator

        points.append((x: x, y: y, position: position))
    }

    // Draw with smooth gradient
    for i in 0..<points.count {
        let point = points[i]
        let color = getRainbowColor(position: point.position)

        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(
            x: point.x - lineWidth/2,
            y: point.y - lineWidth/2,
            width: lineWidth,
            height: lineWidth
        ))
    }

    finalImage.unlockFocus()

    // Convert to bitmap at exact size
    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    bitmapRep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
    finalImage.draw(at: .zero, from: NSRect(origin: .zero, size: finalImage.size), operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Clean icon saved to: \(outputPath)")
        print("Size: \(Int(size))x\(Int(size))")
        print("Design: Rainbow infinity symbol on white background")
    } catch {
        print("Error saving icon: \(error)")
    }
}

// MARK: - Main

let outputPath = "BehaviorTracker/Assets.xcassets/AppIcon.appiconset/asd-icon-1024.png"

// Remove old icon
let fileManager = FileManager.default
if fileManager.fileExists(atPath: outputPath) {
    try? fileManager.removeItem(atPath: outputPath)
}

createCleanAppIcon(size: 1024, outputPath: outputPath)

print("\nApp icon created successfully!")
print("Design matches the reference image:")
print("  - Clean white background")
print("  - Smooth rainbow infinity symbol")
print("  - Professional appearance")
