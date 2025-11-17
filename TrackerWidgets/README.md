# Tracker Widgets Setup Guide

This directory contains widget code for the Behavior Tracker app. Follow these steps to integrate the widgets into your project.

## Prerequisites

- Xcode 14.0 or later
- iOS 16.0+ target (for lock screen widgets)
- Active Apple Developer account (for App Groups)

## Step 1: Create Widget Extension Target

1. Open `BehaviorTracker.xcodeproj` in Xcode
2. File → New → Target
3. Select "Widget Extension"
4. Configure the target:
   - Product Name: `TrackerWidgets`
   - Include Configuration Intent: No (optional)
   - Click Finish
5. When prompted, click "Activate" to activate the scheme

## Step 2: Add Files to Widget Target

1. Delete the default `TrackerWidgets.swift` file created by Xcode
2. Add these files to the widget target:
   - `TrackerWidgetBundle.swift`
   - `QuickLogWidget.swift`
   - `MedicationReminderWidget.swift`
   - `SharedDataManager.swift`

To add files:
- Right-click on TrackerWidgets folder in Xcode
- Add Files to "TrackerWidgets"
- Select the files from this directory

## Step 3: Configure App Groups

App Groups enable data sharing between the main app and widgets.

### Create App Group:

1. Go to your Apple Developer account (developer.apple.com)
2. Certificates, Identifiers & Profiles → Identifiers
3. Click "+" to create a new identifier
4. Select "App Groups" and continue
5. Description: "Behavior Tracker Shared Data"
6. Identifier: `group.com.yourcompany.behaviortracker` (replace with your own)
7. Click "Continue" and "Register"

### Enable App Groups in Xcode:

#### For Main App:
1. Select BehaviorTracker target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "App Groups"
5. Check your app group: `group.com.yourcompany.behaviortracker`

#### For Widget Extension:
1. Select TrackerWidgets target
2. Repeat steps 2-5 above
3. **Important**: Use the SAME app group identifier

### Update Code:
1. Open `SharedDataManager.swift`
2. Update line 14 with your app group identifier:
   ```swift
   private let appGroupIdentifier = "group.com.yourcompany.behaviortracker"
   ```

## Step 4: Integrate Shared Data Manager

Add widget refresh calls to your main app:

### In DataController.swift

After creating a pattern entry:
```swift
func createPatternEntry(...) -> PatternEntry {
    let entry = ...
    save()

    // Update widget data
    updateWidgetData()

    return entry
}

private func updateWidgetData() {
    let todayCount = fetchTodayEntries().count
    let preferences = getUserPreferences()

    SharedDataManager.shared.updateAfterPatternLog(
        todayCount: todayCount,
        streak: Int(preferences.streakCount),
        favoritePatterns: preferences.favoritePatterns
    )
}
```

After creating/updating medication logs:
```swift
func createMedicationLog(...) -> MedicationLog {
    let log = ...
    save()

    // Update medication widget
    updateMedicationWidgetData()

    return log
}

private func updateMedicationWidgetData() {
    let medications = getTodaysMedicationLogs()
    let adherence = calculateTodayAdherence()

    let medicationData = medications.map { log -> [String: Any] in
        return [
            "name": log.medication?.name ?? "",
            "dosage": log.medication?.dosage ?? "",
            "time": log.timestamp,
            "taken": log.taken
        ]
    }

    SharedDataManager.shared.updateAfterMedicationLog(
        medications: medicationData,
        adherence: adherence
    )
}
```

## Step 5: Build and Run

1. Select the main BehaviorTracker scheme
2. Build the project (⌘B)
3. If successful, build the TrackerWidgets scheme
4. Run the main app on a device or simulator
5. Long press on home screen → Add Widget
6. Find "Quick Log" and "Medication Reminder" widgets

## Step 6: Test Lock Screen Widgets (iOS 16+)

1. Lock your device
2. Long press on lock screen
3. Tap "Customize"
4. Tap on widget areas
5. Add "Medication Reminder" widgets

## Widget Features

### Quick Log Widget
- **Small**: Shows today's log count and streak
- **Medium**: Includes favorite patterns list
- **Purpose**: Quick access to logging statistics
- **Updates**: Every 15 minutes

### Medication Reminder Widget
- **Small**: Shows adherence percentage and upcoming count
- **Medium**: Lists today's medications with status
- **Circular (Lock Screen)**: Adherence ring with count
- **Rectangular (Lock Screen)**: Next medication details
- **Inline (Lock Screen)**: Medication count summary
- **Updates**: Every 30 minutes

## Accessibility Features

All widgets include:
- VoiceOver labels for screen readers
- Clear, high-contrast design
- Large, readable text
- Semantic color coding
- Descriptive accessibility hints

## Troubleshooting

### Widgets not appearing:
- Ensure both targets have the same App Group
- Verify App Group is registered in Developer Portal
- Check that shared data is being written
- Try deleting and re-adding the widget

### Data not updating:
- Verify `SharedDataManager.appGroupIdentifier` matches your App Group
- Check that widget refresh is called after data changes
- Review Console logs for errors

### Build errors:
- Ensure all files are added to correct target
- Check deployment target is iOS 14.0+ for widgets
- Verify signing certificates are configured

## Next Steps

- Customize widget colors and styling
- Add deep links to open specific app screens
- Implement widget configuration for user preferences
- Add more widget sizes/variants
- Consider StandBy mode optimization (iOS 17+)
