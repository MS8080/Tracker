# Apple Watch App - Setup Guide

Complete guide for integrating the Behavior Tracker Watch app

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Troubleshooting](#troubleshooting)

---

## Overview

The Behavior Tracker Apple Watch app provides quick, accessible logging and medication tracking directly from your wrist.

### What You Get

- One-tap pattern logging
- Voice-dictated journal entries
- Medication reminders
- Watch face complications
- Full VoiceOver support

---

## Features

### Dashboard
- Today's entry count (large display)
- Current logging streak
- Next medication reminder
- Connection status
- Manual sync button

### Quick Log
- Favorite patterns from iPhone
- One-tap logging workflow
- Intensity picker (1-5)
- Instant sync

### Medications
- Today's medication list
- Check-off interface
- Visual status indicators
- Dosage display

### Voice Notes
- Dictation for journal entries
- Mood selector
- One-tap save
- Success confirmations

---

## Quick Start

### Prerequisites

- Xcode 14.0+
- watchOS 9.0+
- iOS 16.0+
- Paired Apple Watch

### 5-Minute Setup

**Step 1:** Create Watch Target
- File -> New -> Target -> Watch App
- Name: BehaviorTrackerWatch

**Step 2:** Add Files
- Add all files from BehaviorTrackerWatch/ folder
- Ensure correct target membership

**Step 3:** Add iPhone Handler
- Add iPhoneWatchConnectivityService.swift to iOS app

**Step 4:** Test
- Run on Watch simulator
- Verify sync with iPhone

---

## Detailed Setup

### Step 1: Create Watch App Target

Open BehaviorTracker.xcodeproj in Xcode

Create new target:
- File -> New -> Target
- Select: Watch App (watchOS)
- Product Name: BehaviorTrackerWatch
- Interface: SwiftUI
- Language: Swift
- Click Finish, then Activate

---

### Step 2: Add Watch App Files

File structure to add:

```
BehaviorTrackerWatch/
  BehaviorTrackerWatchApp.swift
  Views/
    ContentView.swift
    DashboardView.swift
    QuickLogView.swift
    MedicationsView.swift
    VoiceNoteView.swift
  Services/
    WatchConnectivityService.swift
    ComplicationController.swift
```

How to add files:

1. Right-click BehaviorTrackerWatch in Xcode
2. Select "Add Files to BehaviorTrackerWatch"
3. Choose files from BehaviorTrackerWatch/ directory
4. Check "Copy items if needed"
5. Target: BehaviorTrackerWatch only

---

### Step 3: Add iPhone Connectivity

Add to iOS app:

```
BehaviorTracker/Services/
  iPhoneWatchConnectivityService.swift
```

Steps:

1. Right-click BehaviorTracker/Services/
2. Add Files
3. Select iPhoneWatchConnectivityService.swift
4. Target: BehaviorTracker (iOS app) only

---

### Step 4: Initialize Connectivity

Update BehaviorTrackerApp.swift (iOS app):

```swift
import SwiftUI

@main
struct BehaviorTrackerApp: App {
    @StateObject private var dataController = DataController.shared
    @StateObject private var watchConnectivity = iPhoneWatchConnectivityService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
```

---

### Step 5: Trigger Watch Updates

Update DataController.swift to notify Watch after changes:

```swift
func createPatternEntry(...) -> PatternEntry {
    let entry = ...
    save()

    // Notify Watch
    iPhoneWatchConnectivityService.shared.sendUpdateToWatch()

    return entry
}

func createMedicationLog(...) -> MedicationLog {
    let log = ...
    save()

    // Notify Watch
    iPhoneWatchConnectivityService.shared.sendUpdateToWatch()

    return log
}
```

---

### Step 6: Configure Complications

In Xcode:

1. Select BehaviorTrackerWatch target
2. Go to Signing & Capabilities tab
3. Click + Capability
4. Add "Background Modes"
5. Check "Remote notifications"

---

### Step 7: Test

**On Simulator:**

1. Select BehaviorTrackerWatch scheme
2. Choose Watch simulator (e.g., Apple Watch Series 9)
3. Click Run (Cmd+R)

**On Real Device (Recommended):**

1. Pair Apple Watch with iPhone
2. Select iPhone as destination in Xcode
3. Xcode will install Watch app automatically
4. Open app on Watch to test

**Verify These Work:**

- Dashboard shows correct data
- Logging from Watch appears in iPhone app
- Medication updates sync
- Voice notes save to iPhone

---

## Watch Features Detail

### Dashboard View

Elements displayed:

- **Entry Count**: Large number showing today's logs
- **Streak**: Days logged with flame icon
- **Next Med**: Upcoming medication name
- **Status**: iPhone connection indicator
- **Refresh**: Manual sync button

Accessibility:
- VoiceOver reads all statistics
- Large, clear numbers
- High contrast indicators

---

### Quick Log View

Workflow:

1. View favorite patterns
2. Tap pattern to select
3. Choose intensity (1-5)
4. Confirm to log

Features:
- Favorites sync from iPhone automatically
- Haptic feedback on successful log
- Visual confirmation
- Instant sync to iPhone app

---

### Medications View

Display:

- List of today's medications
- Checkmark for taken, circle for pending
- Medication name and dosage
- Tap to mark as taken

Accessibility:
- Clear visual status
- VoiceOver announces state
- Large touch targets

---

### Voice Notes View

Usage:

1. Tap microphone button
2. Speak your note (watchOS dictation)
3. Select mood level (1-5)
4. Tap save

Features:
- Uses native watchOS dictation
- No typing required
- Mood tracking included
- Saves directly to iPhone journal

---

## Troubleshooting

### Watch App Not Installing

Solutions:

- Verify iPhone and Watch are paired
- Check Bluetooth is enabled
- Wait a few moments after build
- Restart both devices if needed

---

### Data Not Syncing

Check:

- Are both apps running?
- Is Bluetooth connection active?
- Check Console for WCSession errors

Fix:

- Force quit both apps
- Restart both devices
- Verify isReachable status in code

---

### Complications Not Updating

Solutions:

- Remove and re-add complication to watch face
- Verify Background Modes capability is enabled
- Check CLKComplicationServer is reloading
- Force touch watch face -> Customize

---

### Voice Dictation Not Working

Check:

- Microphone permissions granted
- Dictation enabled in Watch settings
- Correct language settings

Fix:

- Force quit Watch app
- Restart Watch
- Re-enable dictation in Settings

---

## Performance

### Battery Life

- Complications update hourly (not real-time)
- Background updates use ApplicationContext
- Efficient data transfer protocols

### Data Transfer

- Minimal payload sizes
- Only essential data sent
- Data cached when iPhone unreachable

---

## Requirements

- watchOS 9.0 or later
- iOS 16.0 or later
- Xcode 14.0 or later
- Apple Watch paired with iPhone

---

## Support

For issues:

- Check Xcode Console for error messages
- Verify target configurations
- Review this setup guide
- Test on real device (not just simulator)

---

End of Watch App Setup Guide
