# App Icon Installation Guide

## Quick Start

Your app icon "patterns" has been generated and is ready to use!

## Location

All icon files are in: `BehaviorTrackerApp/Resources/`

## Main Icon

**patterns-1024.png** - This is your primary app icon (1024x1024px)

## Installation Steps

### Option 1: Automatic (Easiest - 30 seconds)

1. Open your Xcode project
2. In Project Navigator, click `Assets.xcassets`
3. Click `AppIcon` in the list
4. Drag `Resources/patterns-1024.png` onto the **1024pt** box
5. Done! Xcode auto-generates all other sizes

### Option 2: Manual (All sizes)

1. Open Xcode -> `Assets.xcassets` -> `AppIcon`
2. Drag each file from `Resources/` to its matching size:
   - patterns-1024.png -> 1024pt slot
   - patterns-180.png -> iPhone 60pt @3x slot
   - patterns-167.png -> iPad Pro 83.5pt @2x slot
   - patterns-152.png -> iPad 76pt @2x slot
   - patterns-120.png -> iPhone 60pt @2x slot
   - (and so on for remaining sizes)

## Verification

After adding the icon:

1. Build your project (Cmd+B)
2. Run on simulator (Cmd+R)
3. Go to home screen (Cmd+Shift+H on simulator)
4. You should see the blue neural pattern icon!

## Icon Design

The "patterns" icon features:
- **Blue-to-purple gradient background** (iOS native blue colors)
- **White neural network pattern** (6 nodes + connections)
- **Represents**: Behavioral patterns, connections, insights
- **Style**: Modern, scientific, clean

## Files Generated

13 PNG files covering all iOS requirements:
- 1024x1024 (App Store)
- 180x180 (iPhone @3x)
- 167x167 (iPad Pro)
- 152x152 (iPad @2x)
- 120x120 (iPhone @2x)
- 87x87 (Settings @3x)
- 80x80 (Settings @2x)
- 76x76 (iPad)
- 60x60 (Settings @2x)
- 58x58 (Settings @2x)
- 40x40 (Settings)
- 29x29 (Settings)
- 20x20 (Notifications)

## Need to Customize?

Edit `Resources/patterns.svg` and run `Resources/generate_icons.sh` to regenerate.

See `Resources/ICON_README.md` for detailed customization options.

## That's It!

Your Behavior Tracker app now has a professional icon ready for the App Store.
