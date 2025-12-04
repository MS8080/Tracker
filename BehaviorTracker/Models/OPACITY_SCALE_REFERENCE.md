# Opacity Scale Reference Guide

Quick reference for using the standardized opacity scale throughout the app.

## The Scale

```swift
enum OpacityScale {
    static let ghost: Double = 0.05       // Barely visible tint
    static let whisper: Double = 0.10     // Subtle hint
    static let soft: Double = 0.15        // Light presence
    static let gentle: Double = 0.20      // Noticeable but quiet
    static let medium: Double = 0.30      // Clear but subdued
    static let visible: Double = 0.50     // Half strength
    static let strong: Double = 0.60      // Prominent
    static let bold: Double = 0.80        // Very strong
    static let solid: Double = 1.0        // Full opacity
}
```

---

## Usage Patterns

### Background Tints
```swift
// Barely-there wash of color
.fill(theme.primaryColor.opacity(OpacityScale.ghost))

// Subtle presence
.fill(theme.primaryColor.opacity(OpacityScale.soft))

// Noticeable colored background
.fill(theme.primaryColor.opacity(OpacityScale.gentle))
```

### Borders & Strokes
```swift
// Whisper-thin outline
.stroke(Color.white.opacity(OpacityScale.whisper), lineWidth: 0.5)

// Soft definition
.stroke(Color.white.opacity(OpacityScale.soft), lineWidth: 1.0)

// Clear border
.stroke(theme.primaryColor.opacity(OpacityScale.medium), lineWidth: 1.5)
```

### Shadows
```swift
// Barely-there depth
.shadow(color: .black.opacity(OpacityScale.ghost), radius: 4)

// Subtle elevation
.shadow(color: .black.opacity(OpacityScale.whisper), radius: 6)

// Clear shadow
.shadow(color: .black.opacity(OpacityScale.soft), radius: 8)

// Prominent depth
.shadow(color: .black.opacity(OpacityScale.medium), radius: 12)
```

### Text Overlays
```swift
// De-emphasized label
.foregroundStyle(.white.opacity(OpacityScale.visible))

// Strong text on gradient
.foregroundStyle(.white.opacity(OpacityScale.bold))

// Caption text
.foregroundStyle(.white.opacity(OpacityScale.strong))
```

### Gradients
```swift
LinearGradient(
    stops: [
        .init(color: color.opacity(OpacityScale.strong), location: 0.0),
        .init(color: color.opacity(OpacityScale.medium), location: 0.3),
        .init(color: color.opacity(OpacityScale.soft), location: 0.6),
        .init(color: color.opacity(OpacityScale.whisper), location: 1.0)
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

---

## When to Use Each Value

### 🌫️ Ghost (0.05)
**Use for:**
- Card background tints that should barely be noticed
- Very subtle brand color washes
- Ultra-light material overlays

**Example:**
```swift
RoundedRectangle(cornerRadius: 12)
    .fill(theme.primaryColor.opacity(OpacityScale.ghost))
```

### 🌬️ Whisper (0.10)
**Use for:**
- Background gradient endpoints
- Subtle divider lines
- Ghost button backgrounds
- Barely-there shadows

**Example:**
```swift
Color.black.opacity(OpacityScale.whisper)  // Subtle shadow
```

### 🌤️ Soft (0.15)
**Use for:**
- Light card backgrounds
- Soft accent colors
- Secondary text
- Gentle glow effects

**Example:**
```swift
theme.primaryColor.opacity(OpacityScale.soft)  // Light accent
```

### ☁️ Gentle (0.20)
**Use for:**
- Noticeable but calm backgrounds
- Icon background circles
- Hover states
- Secondary borders

**Example:**
```swift
Circle()
    .fill(Color.blue.opacity(OpacityScale.gentle))
```

### 🌥️ Medium (0.30)
**Use for:**
- Card borders
- Active state backgrounds
- Gradient mid-points
- Secondary shadows

**Example:**
```swift
.stroke(theme.primaryColor.opacity(OpacityScale.medium))
```

### ☀️ Visible (0.50)
**Use for:**
- Half-transparent overlays
- Loading state backgrounds
- Modal scrims
- Prominent text on busy backgrounds

**Example:**
```swift
Color.black.opacity(OpacityScale.visible)  // 50% scrim
```

### 🌟 Strong (0.60)
**Use for:**
- Primary gradient starts
- Focused card backgrounds
- Vibrant accent colors
- Primary glow effects

**Example:**
```swift
primaryColor.opacity(OpacityScale.strong)  // Gradient top
```

### 💎 Bold (0.80)
**Use for:**
- High-emphasis text
- Strong accent overlays
- Active button backgrounds
- Hero section text

**Example:**
```swift
.foregroundStyle(.white.opacity(OpacityScale.bold))
```

### ⚪ Solid (1.0)
**Use for:**
- Maximum emphasis
- Pure colors
- Final gradient stops
- Critical UI elements

---

## Current Usage in App

### AppTheme.swift
```swift
gradient:
  - Top: OpacityScale.strong (0.60)
  - Mid: OpacityScale.medium (0.30)
  - Lower: OpacityScale.soft (0.15)
  - Bottom: OpacityScale.whisper (0.10)

accentLight: OpacityScale.soft (0.15)
accentMedium: OpacityScale.medium (0.30)
cardBackground: OpacityScale.ghost (0.05)
cardGlassTint: OpacityScale.ghost (0.05)
cardBorderColor: OpacityScale.medium (0.30)
cardGlowColor: OpacityScale.strong (0.60)
cardShadowColor: OpacityScale.medium (0.30)
```

### Card Modifiers
```swift
Prominent Card:
  - Tint: OpacityScale.gentle (0.20)
  - Glow: OpacityScale.soft (0.15)
  - Border: OpacityScale.gentle (0.20)
  - Shadow: OpacityScale.soft (0.15)

Standard Card:
  - Tint: OpacityScale.soft (0.15)
  - Border: OpacityScale.soft (0.15) → OpacityScale.whisper (0.10)
  - Shadow: OpacityScale.whisper (0.10)

Subtle Card:
  - Tint: OpacityScale.ghost (0.05)
  - Border: OpacityScale.whisper (0.10)
  - Shadow: OpacityScale.ghost (0.05)
```

---

## Migration Guide

### Before
```swift
.opacity(0.08)   // Mystery number
.opacity(0.35)   // What does this mean?
.opacity(0.12)   // Why 12%?
```

### After
```swift
.opacity(OpacityScale.whisper)  // Clear: subtle hint
.opacity(OpacityScale.medium)   // Clear: subdued but visible
.opacity(OpacityScale.whisper)  // Clear: very light
```

---

## Benefits

✅ **Self-documenting** - Name tells you the visual effect  
✅ **Consistent** - Same values used across app  
✅ **Predictable** - Easy to choose right value  
✅ **Maintainable** - Change scale in one place  
✅ **Discoverable** - Autocomplete shows all options  

---

**Pro Tip:** Start with `.soft` for backgrounds and `.medium` for borders. Adjust up or down based on visual weight needed.
