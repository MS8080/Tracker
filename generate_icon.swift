#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

// MARK: - Helper Functions

func createGradientBackground(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext

    // Purple gradient colors
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 147/255, green: 112/255, blue: 219/255, alpha: 1.0), // Medium Purple (center)
        CGColor(red: 75/255, green: 0/255, blue: 130/255, alpha: 1.0)      // Indigo (edges)
    ]

    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: colors as CFArray,
        locations: [0.0, 1.0]
    )!

    // Draw radial gradient
    let center = CGPoint(x: size/2, y: size/2)
    let radius = size * 0.7

    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    image.unlockFocus()
    return image
}

func getRainbowColor(position: CGFloat) -> NSColor {
    // Rainbow colors array
    let colors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
        (255, 0, 0),      // Red
        (255, 127, 0),    // Orange
        (255, 255, 0),    // Yellow
        (0, 255, 0),      // Green
        (0, 127, 255),    // Blue
        (75, 0, 130),     // Indigo
        (148, 0, 211),    // Violet
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

func drawInfinitySymbol(context: CGContext, centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat, lineWidth: CGFloat) {
    let numPoints = 500
    let a = width / 2
    let b = height / 2

    // Generate points for infinity symbol (lemniscate)
    for i in 0..<numPoints {
        let t = (2 * CGFloat.pi * CGFloat(i)) / CGFloat(numPoints)
        let position = CGFloat(i) / CGFloat(numPoints)

        // Lemniscate parametric equations
        let denominator = 1 + sin(t) * sin(t)
        let x = centerX + (a * cos(t)) / denominator
        let y = centerY + (b * sin(t) * cos(t)) / denominator

        // Get rainbow color for this position
        let color = getRainbowColor(position: position)

        // Draw thick point
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(x: x - lineWidth/2, y: y - lineWidth/2, width: lineWidth, height: lineWidth))
    }
}

func createAppIcon(size: CGFloat, outputPath: String) {
    // Create background
    let background = createGradientBackground(size: size)

    // Create final image
    let finalImage = NSImage(size: NSSize(width: size, height: size))
    finalImage.lockFocus()

    // Draw background
    background.draw(at: .zero, from: NSRect(x: 0, y: 0, width: size, height: size), operation: .copy, fraction: 1.0)

    // Get graphics context
    guard let context = NSGraphicsContext.current?.cgContext else {
        print("Failed to get graphics context")
        return
    }

    // Draw infinity symbol
    let symbolWidth = size * 0.65
    let symbolHeight = size * 0.3
    let lineWidth = size * 0.08

    drawInfinitySymbol(
        context: context,
        centerX: size / 2,
        centerY: size / 2,
        width: symbolWidth,
        height: symbolHeight,
        lineWidth: lineWidth
    )

    finalImage.unlockFocus()

    // Save as PNG with exact size
    guard let tiffData = finalImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData) else {
        print("Failed to create bitmap data")
        return
    }

    // Force exact pixel size
    bitmapImage.size = NSSize(width: size, height: size)

    guard let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Icon saved to: \(outputPath)")
        print("Size: \(Int(size))x\(Int(size))")
        print("Features: Purple gradient background with rainbow infinity symbol")
    } catch {
        print("Error saving icon: \(error)")
    }
}

// MARK: - Main

let outputPath = "BehaviorTracker/Assets.xcassets/AppIcon.appiconset/asd-icon-1024.png"

// Remove old icon if it exists
let fileManager = FileManager.default
if fileManager.fileExists(atPath: outputPath) {
    try? fileManager.removeItem(atPath: outputPath)
}

createAppIcon(size: 1024, outputPath: outputPath)

print("\nApp icon created successfully!")
print("\nNext steps:")
print("  1. Update Contents.json to use 'asd-icon-1024.png'")
print("  2. Delete old 'patterns-1024.png'")
print("  3. Build and run the app to see the new icon")
