# App Icon Documentation

---

## Design Overview

The Behavior Tracker app icon features a **rainbow infinity symbol** on a clean white background, representing neurodiversity and autism awareness.

---

## Visual Elements

### Symbol
- **Infinity Symbol**: The lemniscate represents infinite potential and diversity
- **Rainbow Colors**: Smooth gradient from red -> orange -> yellow -> green -> cyan -> blue
- **Clean Design**: Modern, professional appearance optimized for iOS

### Background
- **Color**: Pure white (#FFFFFF)
- **Style**: Clean and minimal for maximum symbol visibility

---

## Symbolism

| Element | Meaning |
|---------|---------|
| Infinity Symbol | Infinite potential and diversity of people on the autism spectrum |
| Rainbow Colors | Diversity of the autism spectrum and neurodiversity movement |
| Clean Background | Clarity, simplicity, and accessibility |

---

## Technical Specifications

- **Size**: 1024 × 1024 pixels
- **Format**: PNG with transparency
- **Color Space**: sRGB
- **Location**: `BehaviorTracker/Assets.xcassets/AppIcon.appiconset/`
- **Filename**: `asd-icon-1024.png`
- **iOS Version**: 14.0+

---

## Generation

The icon is generated using a Swift script that leverages Core Graphics.

### Regenerate Icon

```bash
swift generate_clean_icon.swift
```

This creates a new `asd-icon-1024.png` file at exactly 1024×1024 pixels.

---

## Customization

To modify the icon, edit `generate_clean_icon.swift`:

### Change Colors

```swift
let colors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
    (255, 69, 0),     // Red-Orange
    (255, 140, 0),    // Orange
    (255, 215, 0),    // Gold/Yellow
    // ... add or modify colors
]
```

### Adjust Symbol Size

```swift
let symbolWidth = size * 0.70   // Range: 0.5 - 0.8
let symbolHeight = size * 0.32  // Range: 0.2 - 0.4
```

### Change Line Thickness

```swift
let lineWidth = size * 0.09  // Range: 0.05 - 0.12
```

---

## Credits

- **Design**: Custom for ASD Behavior Tracker
- **Symbol**: Based on neurodiversity movement's infinity symbol
- **Colors**: Rainbow spectrum representing diversity

---

## Usage

This icon is exclusive to the ASD Behavior Tracker application.

