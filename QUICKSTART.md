# Quick Start Guide

## Get Running in 5 Minutes

### Step 1: Create Xcode Project (2 minutes)

1. Open Xcode
2. File -> New -> Project
3. Choose "iOS" -> "App"
4. Configure:
   - Product Name: **BehaviorTracker**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **Core Data** [x]
   - Include Tests: [x]
5. Save in `BehaviorTrackerApp` folder

### Step 2: Import Source Files (2 minutes)

1. Delete Xcode's default files:
   - ContentView.swift
   - BehaviorTrackerApp.swift (Xcode's generated one)

2. Add project files:
   - Right-click "BehaviorTracker" folder in Xcode
   - "Add Files to BehaviorTracker..."
   - Select all Swift files and folders from the project directory
   - **Uncheck** "Copy items if needed"
   - Select "Create groups"
   - Click "Add"

### Step 3: Configure & Build (1 minute)

1. Select iPhone 15 Pro simulator
2. Press **Cmd+B** to build
3. Fix any build errors (should be minimal)
4. Press **Cmd+R** to run

### Step 4: Test the App

Try these features:
- Tap "Log" tab -> Select a category -> Log a pattern
- View the entry on "Dashboard" tab
- Check "Reports" tab for analytics (needs a few entries)
- Export data in "Settings" tab

## That's It!

You now have a fully functional behavior tracking app.

## Next Steps

- Read **README.md** for complete feature list
- Review **ARCHITECTURE.md** for code structure
- Check **IMPLEMENTATION_NOTES.md** for customization ideas
- Read **SETUP_INSTRUCTIONS.md** for detailed configuration

## Common Issues

**Build Errors?**
- Ensure all files are added to the target
- Check Core Data model is included
- Verify deployment target is iOS 17.0

**Crash on Launch?**
- Check console for Core Data errors
- Verify BehaviorTrackerModel.xcdatamodeld is in the project

**Missing Features?**
- All features are implemented in code
- Just needs Xcode project file setup

## File Overview

```
BehaviorTrackerApp/
├── BehaviorTracker/
│   ├── BehaviorTrackerApp.swift       # App entry point
│   ├── ContentView.swift              # Main tab view
│   ├── Models/                        # Data models
│   │   ├── PatternCategory.swift
│   │   ├── PatternType.swift
│   │   ├── PatternEntry+CoreDataClass.swift
│   │   ├── Tag+CoreDataClass.swift
│   │   ├── UserPreferences+CoreDataClass.swift
│   │   └── BehaviorTrackerModel.xcdatamodeld/
│   ├── Views/
│   │   ├── Logging/                   # Pattern logging UI
│   │   ├── Dashboard/                 # Main dashboard
│   │   ├── Reports/                   # Analytics
│   │   └── Settings/                  # App settings
│   ├── ViewModels/                    # Business logic
│   ├── Services/                      # Data & reports
│   └── Utilities/                     # Helpers
├── BehaviorTrackerTests/              # Unit tests
└── Documentation/
    ├── README.md
    ├── ARCHITECTURE.md
    ├── SETUP_INSTRUCTIONS.md
    ├── PRIVACY_POLICY.md
    └── IMPLEMENTATION_NOTES.md
```

## Support

- All documentation is in the markdown files
- Code is heavily commented
- Tests demonstrate usage
- Architecture is well-documented

Happy coding!
