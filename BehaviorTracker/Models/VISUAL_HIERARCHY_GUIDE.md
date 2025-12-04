# Visual Hierarchy System

A comprehensive guide to the new three-tier card system for creating clear information architecture.

---

## Overview

The app now uses **three distinct card styles** to communicate importance and guide user attention:

1. **Prominent** - High priority, interactive elements
2. **Standard** - Primary content and information
3. **Subtle** - Secondary, supporting details

---

## 1. Prominent Card Style

### Purpose
Used for **the most important interactive elements** that deserve immediate attention.

### Visual Characteristics
- **Material:** `.thinMaterial` (less blur = more visible)
- **Tint:** 20% theme color (OpacityScale.gentle)
- **Glow:** Radial gradient from top (15% opacity)
- **Border:** 1.5pt gradient (white → theme color)
- **Shadow:** Dual-layer for depth
  - Primary: Theme color at 15% opacity, radius 12
  - Secondary: Black at 10% opacity, radius 6

### When to Use
✅ Primary input fields ("What's special today?")  
✅ Call-to-action cards  
✅ Important interactive prompts  
✅ Feature announcements  

❌ Don't overuse - limit to 1-2 per screen

### Code Example
```swift
VStack(spacing: Spacing.sm) {
    Text("What's special today?")
        .font(.headline)
    
    TextField("A thought...", text: $note)
        .padding(Spacing.md)
}
.prominentCardStyle(theme: theme)
```

### Visual Impact
- **Stands out** from other cards
- **Draws the eye** naturally
- **Feels elevated** and important
- **Invites interaction**

---

## 2. Standard Card Style

### Purpose
The **default card** for most content - balanced visibility without stealing focus.

### Visual Characteristics
- **Material:** `.ultraThinMaterial` (balanced blur)
- **Tint:** 15% theme color (OpacityScale.soft)
- **Border:** Gradient with white highlight
- **Shadow:** Medium depth
- **Interactive:** Responds to press with scale and shadow

### When to Use
✅ Streak counters  
✅ Day summary buttons  
✅ Recent context cards  
✅ Achievement cards  
✅ Feature tiles  
✅ Most content cards  

### Code Example
```swift
HStack(spacing: Spacing.lg) {
    StreakCounter(currentStreak: 5)
    
    VStack(alignment: .leading) {
        Text("Tracking Streak")
            .font(.headline)
        Text("Keep it up!")
            .font(.subheadline)
    }
}
.padding(Spacing.xl)
.cardStyle(theme: theme, interactive: true)
```

### Interactive Behavior
```swift
// When pressed:
- Scale: 0.98 (subtle squeeze)
- Shadow: Increases from 4 → 8 radius
- Border: White opacity 0.15 → 0.25
```

### Visual Impact
- **Clear presence** on screen
- **Not overwhelming** - works in groups
- **Feels responsive** to touch
- **Professional** and polished

---

## 3. Subtle Card Style

### Purpose
For **secondary information** that should be available but not compete for attention.

### Visual Characteristics
- **Material:** `.ultraThinMaterial` (maximum transparency)
- **Tint:** 5% theme color (OpacityScale.ghost)
- **Border:** 0.5pt white at 10% opacity
- **Shadow:** Minimal (radius 4, 5% opacity)
- **Effect:** Recedes into background

### When to Use
✅ Memory cards  
✅ Historical information  
✅ Background context  
✅ Supporting details  
✅ List items in groups  

❌ Don't use for primary actions  
❌ Avoid for critical information

### Code Example
```swift
VStack(alignment: .leading, spacing: Spacing.sm) {
    HStack {
        Image(systemName: "clock.arrow.circlepath")
            .font(.title3)
        Text("A year ago")
            .font(.headline)
    }
    
    Text("You wrote about...")
        .font(.subheadline)
}
.padding(Spacing.lg)
.subtleCardStyle(theme: theme)
```

### Visual Impact
- **Doesn't distract** from primary content
- **Provides context** without shouting
- **Elegant** and understated
- **Blends** with gradient background

---

## Comparison Table

| Feature | Prominent | Standard | Subtle |
|---------|-----------|----------|--------|
| **Blur** | Thin | Ultra-thin | Ultra-thin |
| **Tint Opacity** | 20% | 15% | 5% |
| **Border Width** | 1.5pt | 1.0pt | 0.5pt |
| **Shadow Radius** | 12px | 4-8px | 4px |
| **Glow Effect** | ✅ Yes | ❌ No | ❌ No |
| **Interactive** | Optional | ✅ Yes | ❌ No |
| **Visual Weight** | Heavy | Medium | Light |
| **Use Frequency** | 1-2/screen | 3-5/screen | 5+/screen |

---

## HomeView Hierarchy Example

### Current Implementation

```
┌─────────────────────────────────────┐
│ 👋 Good morning, Sarah!              │  ← .largeTitle (hero)
│    (.largeTitle, bold)               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📝 What's special today?             │  ← PROMINENT
│    (.headline)                       │     (most important)
│ ┌─────────────────────────────────┐ │
│ │ [Input field with send button]  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🔥 Tracking Streak                   │  ← STANDARD
│    (.headline)                       │     (primary content)
│    Keep it up! You've been...       │
│    (.subheadline)                    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ▶️ Your Day So Far                   │  ← STANDARD
│    (.headline)                       │     (primary action)
│    Tap to see a summary              │
│    (.subheadline)                    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ⚡ Recently                          │  ← STANDARD
│    (.headline)                       │     (important context)
│    You felt energized after...      │
│    (.subheadline)                    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🕐 A year ago                        │  ← SUBTLE
│    (.headline)                       │     (background info)
│    You wrote about starting...      │
│    (.subheadline)                    │
└─────────────────────────────────────┘
```

---

## Decision Tree

```
Is this the most important thing on screen?
└─ YES → Use .prominentCardStyle()
└─ NO ↓

Is this primary content or an action?
└─ YES → Use .cardStyle()
└─ NO ↓

Is this supporting/historical info?
└─ YES → Use .subtleCardStyle()
```

---

## Design Principles

### 1. Scarcity Creates Value
- Limit prominent cards to 1-2 per screen
- More prominent cards = less impact for each

### 2. Consistent Grouping
- Similar information types use same style
- All memories = subtle
- All actions = standard
- Primary prompt = prominent

### 3. Proximity Matters
- Prominent cards get more spacing
- Subtle cards can be closer together
- Use `Spacing.xl` for prominent, `Spacing.md` for subtle

### 4. Color Harmony
- All styles use same theme color
- Only opacity changes
- Creates unified look while showing hierarchy

---

## Migration Checklist

When updating existing views:

1. **Identify card types**
   - [ ] What's the most important element?
   - [ ] What's primary content?
   - [ ] What's supporting detail?

2. **Apply styles**
   - [ ] Prominent: 1-2 per screen max
   - [ ] Standard: Main content
   - [ ] Subtle: Background info

3. **Update typography**
   - [ ] Titles: `.headline`
   - [ ] Body: `.subheadline`
   - [ ] Details: `.callout`

4. **Test hierarchy**
   - [ ] Does eye naturally go to prominent card?
   - [ ] Is important info visible?
   - [ ] Is secondary info unobtrusive?

---

## Examples in Context

### Good ✅
```swift
// Clear hierarchy with one prominent card
VStack(spacing: Spacing.lg) {
    // Primary action - PROMINENT
    specialTodayInput
        .prominentCardStyle(theme: theme)
    
    // Main content - STANDARD
    streakCard
        .cardStyle(theme: theme)
    
    daySummaryButton
        .cardStyle(theme: theme)
    
    // Background info - SUBTLE
    ForEach(memories) { memory in
        memoryCard(memory)
            .subtleCardStyle(theme: theme)
    }
}
```

### Avoid ❌
```swift
// Everything prominent = nothing prominent
VStack {
    inputCard.prominentCardStyle(theme: theme)
    actionCard.prominentCardStyle(theme: theme)
    statsCard.prominentCardStyle(theme: theme)
    infoCard.prominentCardStyle(theme: theme)
}

// Everything subtle = no hierarchy
VStack {
    importantAction.subtleCardStyle(theme: theme)  // Wrong!
    criticalInfo.subtleCardStyle(theme: theme)     // Wrong!
}
```

---

## Future Enhancements

### Potential Additions

1. **Alert Card Style**
   - Red/yellow tint for warnings
   - Stronger border
   - Pulsing animation

2. **Success Card Style**
   - Green tint
   - Celebration animation
   - Auto-dismiss

3. **Loading Card Style**
   - Shimmer effect
   - Reduced opacity
   - Skeleton UI

4. **Compact Card Style**
   - For dense lists
   - Tighter padding
   - Smaller text

---

**Remember:** Visual hierarchy is about **making important things obvious** and **keeping secondary things accessible**. When in doubt, start with standard and adjust based on actual importance.
