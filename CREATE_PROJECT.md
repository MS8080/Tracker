# Create Xcode Project - Step by Step

Follow these exact steps to create your Xcode project and get the app running.

## Step 1: Open Xcode

1. Open **Xcode** (version 15.0 or later)
2. If you see the welcome screen, close it
3. Go to **File -> New -> Project** (or press Cmd+Shift+N)

## Step 2: Choose Template

1. In the template chooser, select **iOS** at the top
2. Select **App** template
3. Click **Next**

## Step 3: Configure Project

Fill in the following details EXACTLY:

| Field | Value |
|-------|-------|
| Product Name | `BehaviorTracker` |
| Team | Select your Apple ID/Team |
| Organization Identifier | `com.yourname` (or your preferred) |
| Bundle Identifier | (auto-generated, should be com.yourname.BehaviorTracker) |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Storage | **[x] Core Data** (CHECK THIS BOX!) |
| Include Tests | **[x] Checked** |

Click **Next**

## Step 4: Save Location

1. Navigate to: `/Users/ms/Tracker/`
2. You'll see the `BehaviorTrackerApp` folder
3. **IMPORTANT**: Save the project INSIDE the BehaviorTrackerApp folder
4. Uncheck "Create Git repository" (we already have .gitignore)
5. Click **Create**

## Step 5: Delete Generated Files

Xcode creates some default files we don't need:

1. In the Project Navigator (left sidebar), find and DELETE:
   - `ContentView.swift` (select and press Delete)
   - Choose **Move to Trash**
   - `BehaviorTrackerApp.swift` (select and press Delete)
   - Choose **Move to Trash**
   - `BehaviorTracker.xcdatamodeld` (if it exists)
   - Choose **Move to Trash**

## Step 6: Add Source Files

Now we'll add all the Swift files we created:

1. In Xcode, right-click on the **BehaviorTracker** folder (the blue one, not the yellow)
2. Select **Add Files to "BehaviorTracker"...**
3. Navigate to the BehaviorTrackerApp folder
4. Select these folders/files:
   - `BehaviorTracker/` folder (the one with all .swift files)
   - Make sure you see all the subfolders: Models, Views, ViewModels, Services, Utilities
5. **IMPORTANT**: Configure options at the bottom:
   - **[ ] UNCHECK** "Copy items if needed"
   - **[x] CHECK** "Create groups"
   - **[x] CHECK** "BehaviorTracker" under "Add to targets"
6. Click **Add**

## Step 7: Add Test Files

1. In Project Navigator, right-click on **BehaviorTrackerTests** folder
2. Select **Add Files to "BehaviorTracker"...**
3. Navigate to and select the `BehaviorTrackerTests/` folder
4. **UNCHECK** "Copy items if needed"
5. **CHECK** "Create groups"
6. **CHECK** "BehaviorTrackerTests" under "Add to targets"
7. Click **Add**

## Step 8: Configure Project Settings

1. Click on the **BehaviorTracker** project (top of navigator, blue icon)
2. Select the **BehaviorTracker** target (under TARGETS)
3. Go to **General** tab:
   - Set **Minimum Deployments** to **iOS 17.0**
   - Verify **iPhone** and **iPad** are checked under Supported Destinations

4. Go to **Signing & Capabilities** tab:
   - Check **Automatically manage signing**
   - Select your **Team**
   - Verify Bundle Identifier is set

5. Go to **Info** tab (or find Info.plist):
   - Add these entries (click + to add new):

   ```
   Key: NSUserNotificationsUsageDescription
   Type: String
   Value: We'd like to send you daily reminders to log your behavioral patterns
   ```

## Step 9: Add App Icon

1. In Project Navigator, find and click **Assets.xcassets**
2. Click on **AppIcon** in the list
3. In Finder, navigate to `BehaviorTrackerApp/Resources/`
4. Drag `patterns-1024.png` into the **1024pt** box in Xcode
5. Xcode will automatically handle the icon

(Alternatively, drag all patterns-*.png files to their matching size slots)

## Step 10: Build the Project

1. Select a simulator: **iPhone 15 Pro** (or any iOS 17+ simulator)
2. Press **Cmd+B** to build
3. Watch the build progress at the top
4. If you get errors, check the troubleshooting section below

## Step 11: Run the App

1. Press **Cmd+R** to build and run
2. The simulator will launch
3. The Behavior Tracker app should appear!
4. Try logging a pattern to test

## Step 12: Run Tests

1. Press **Cmd+U** to run unit tests
2. All tests should pass (green checkmarks)
3. View test results in the Test Navigator (Cmd+6)

## Troubleshooting

### Build Errors

**"No such module 'CoreData'"**
- Solution: Make sure the BehaviorTrackerModel.xcdatamodeld file is included in the target

**"Cannot find 'PatternEntry' in scope"**
- Solution: Ensure all files in Models/ are added to the target
- Check Target Membership in File Inspector (right sidebar)

**"Use of unresolved identifier"**
- Solution: Clean build folder (Cmd+Shift+K) and rebuild

### Missing Files

1. Check that all files are visible in Project Navigator
2. Select a file and open File Inspector (Cmd+Option+1)
3. Under "Target Membership", check "BehaviorTracker"

### Core Data Errors

1. Verify BehaviorTrackerModel.xcdatamodeld is in the project
2. Check that the model name matches in DataController.swift
3. Clean and rebuild

### Icon Not Showing

1. Delete the app from simulator (long press, click X)
2. Clean build folder (Cmd+Shift+K)
3. Rebuild and run

## Success Checklist

You've successfully set up the project when:

- [x] Project builds without errors (Cmd+B succeeds)
- [x] App runs in simulator (you see the tab bar)
- [x] Can navigate between tabs (Dashboard, Log, Reports, Settings)
- [x] Can log a pattern entry
- [x] Entry appears on Dashboard
- [x] App icon shows on simulator home screen
- [x] All unit tests pass (Cmd+U shows green)

## Project Structure Check

Your Project Navigator should look like this:

```
BehaviorTracker
├── BehaviorTracker
│   ├── BehaviorTrackerApp.swift
│   ├── ContentView.swift
│   ├── Models
│   │   ├── PatternCategory.swift
│   │   ├── PatternType.swift
│   │   ├── PatternEntry+CoreDataClass.swift
│   │   ├── Tag+CoreDataClass.swift
│   │   ├── UserPreferences+CoreDataClass.swift
│   │   └── BehaviorTrackerModel.xcdatamodeld
│   ├── Views
│   │   ├── Logging/
│   │   ├── Dashboard/
│   │   ├── Reports/
│   │   └── Settings/
│   ├── ViewModels
│   ├── Services
│   ├── Utilities
│   └── Assets.xcassets
│       └── AppIcon
├── BehaviorTrackerTests
│   ├── DataControllerTests.swift
│   ├── PatternTypeTests.swift
│   └── ReportGeneratorTests.swift
└── Products
    └── BehaviorTracker.app
```

## Next Steps

After successful setup:

1. **Test all features**:
   - Log different pattern types
   - Check dashboard statistics
   - View weekly/monthly reports
   - Test data export
   - Try search and filtering

2. **Customize** (optional):
   - Modify colors in code
   - Add custom patterns
   - Adjust UI layouts

3. **Prepare for distribution**:
   - Take screenshots
   - Write App Store description
   - Archive for TestFlight

## Getting Help

If you encounter issues:

1. Check this document's Troubleshooting section
2. Review SETUP_INSTRUCTIONS.md for detailed info
3. Check inline code comments
4. Verify all files are in correct locations
5. Clean build folder and restart Xcode

## Time Estimate

- Steps 1-7: ~5 minutes
- Steps 8-9: ~2 minutes
- Steps 10-12: ~1 minute
- **Total: ~8 minutes**

You're now ready to use your Behavior Tracker app!
