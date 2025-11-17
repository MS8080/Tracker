# Setup Instructions

## Prerequisites

Before building the Behavior Tracker app, ensure you have:

1. **macOS Sonoma** (14.0) or later
2. **Xcode 15.0** or later
3. **iOS 17.0** SDK or later
4. An **Apple Developer Account** (free tier is sufficient for local testing)

## Initial Setup

### 1. Project Files

The project structure is already created with all necessary Swift files. You now need to create the Xcode project file.

### 2. Create Xcode Project

Since the source files are already organized, you need to create an Xcode project:

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "iOS" -> "App"
4. Fill in project details:
   - **Product Name**: BehaviorTracker
   - **Team**: Select your development team
   - **Organization Identifier**: com.yourname (or your preferred identifier)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: Core Data (check this box)
   - **Include Tests**: Yes

5. Save the project in the `BehaviorTrackerApp` directory

### 3. Import Source Files

After creating the project:

1. Delete the default files Xcode created (ContentView.swift, etc.)
2. In Xcode's Project Navigator, right-click on "BehaviorTracker" folder
3. Select "Add Files to BehaviorTracker..."
4. Navigate to the project directory and select all folders:
   - Models
   - Views
   - ViewModels
   - Services
   - Utilities
   - Resources

5. Ensure "Copy items if needed" is unchecked (files are already in place)
6. Select "Create groups" for folder organization
7. Click "Add"

### 4. Configure Core Data Model

1. In Xcode, locate the `BehaviorTrackerModel.xcdatamodeld` file
2. Verify all entities are present:
   - PatternEntry
   - Tag
   - UserPreferences

3. For each entity, ensure "Codegen" is set to "Manual/None" in the Data Model Inspector
4. The Core Data classes are already created manually in the Models folder

### 5. Configure App Settings

1. Select the project in Project Navigator
2. Select the "BehaviorTracker" target
3. Go to "Signing & Capabilities":
   - Select your team
   - Ensure "Automatically manage signing" is checked
   - Bundle Identifier will be auto-generated

4. Go to "General" tab:
   - **Deployment Target**: iOS 17.0
   - **Supported Destinations**: iPhone and iPad

5. Optional: Add iCloud capability (for user-optional sync):
   - Click "+ Capability"
   - Add "iCloud"
   - Check "CloudKit"
   - Check "Key-value storage"

### 6. Configure Info.plist

Add the following keys to Info.plist:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>We'd like to send you daily reminders to log your behavioral patterns</string>

<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>AccentColor</string>
    <key>UIImageName</key>
    <string>brain.head.profile</string>
</dict>
```

### 7. Build Configuration

1. Select your target device or simulator
2. Ensure build configuration is set to "Debug" for development
3. Build the project (Cmd+B)
4. Resolve any build errors (should be minimal if all files are properly added)

## Running the App

### On Simulator

1. Select an iOS 17+ simulator (e.g., iPhone 15 Pro)
2. Press Cmd+R to build and run
3. The app will launch in the simulator

### On Physical Device

1. Connect your iPhone/iPad via USB
2. Trust the computer on your device if prompted
3. Select your device in Xcode's device selector
4. Press Cmd+R to build and run
5. On first launch, you may need to trust the developer certificate:
   - Go to Settings -> General -> VPN & Device Management
   - Trust your developer certificate

## Testing

### Run Unit Tests

```bash
Cmd+U
```

or

1. Select Product -> Test from menu
2. View test results in the Test Navigator

### Test Coverage

To view test coverage:
1. Edit the scheme (Product -> Scheme -> Edit Scheme)
2. Select "Test" in the sidebar
3. Go to "Options" tab
4. Check "Gather coverage for some targets"
5. Select BehaviorTracker
6. Run tests
7. View coverage in Report Navigator (Cmd+9)

## Troubleshooting

### Build Errors

**Missing Files**
- Ensure all source files are added to the target
- Check "Target Membership" in File Inspector

**Core Data Errors**
- Verify the .xcdatamodeld file is included
- Check entity names match class names exactly
- Ensure Codegen is set to "Manual/None"

**Import Issues**
- Ensure all files use correct module name
- Verify `@testable import BehaviorTracker` in test files

### Runtime Issues

**App Crashes on Launch**
- Check Core Data model initialization
- Verify persistent store creation
- Review console logs for specific errors

**UI Not Displaying**
- Verify SwiftUI preview functionality
- Check view hierarchy in debug view hierarchy (Debug -> View Debugging -> Capture View Hierarchy)

### Simulator Issues

**Slow Performance**
- Use iPhone 15 or newer simulator models
- Ensure Mac has sufficient resources
- Restart Xcode and simulator if needed

## Development Tips

### Xcode Configuration

**Editor**
- Enable "Show line numbers"
- Enable "Show minimap"
- Use "Adjust indentation on paste"

**Navigation**
- Use Cmd+Shift+O for quick file open
- Use Cmd+Shift+J to reveal current file in navigator
- Use Cmd+0 to toggle navigator
- Use Cmd+Option+0 to toggle inspector

### SwiftUI Previews

Enable previews for faster iteration:
1. Click "Resume" in canvas (Option+Cmd+P)
2. Interact with live previews
3. Pin previews for multiple views

### Debugging

**Breakpoints**
- Set breakpoints by clicking line numbers
- Use conditional breakpoints for specific scenarios
- Enable "All Exceptions" breakpoint for crash debugging

**Console**
- Use `print()` for basic logging
- Use `dump()` for detailed object inspection
- Check Core Data debug output

## Next Steps

After successful setup:

1. Review the README.md for feature overview
2. Read ARCHITECTURE.md for code structure understanding
3. Explore the codebase starting with ContentView.swift
4. Run the app and test core functionality
5. Review and run unit tests
6. Customize as needed for your requirements

## Additional Resources

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [Swift Charts Documentation](https://developer.apple.com/documentation/charts)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## Support

For project-specific questions:
- Review inline code comments
- Check unit tests for usage examples
- Examine ViewModels for business logic patterns
- Refer to ARCHITECTURE.md for design decisions

## Version Control

Initialize git repository (if not already done):

```bash
cd BehaviorTrackerApp
git init
git add .
git commit -m "Initial commit: Behavior Tracker iOS app"
```

## Building for Distribution

When ready to distribute:

1. Change build configuration to "Release"
2. Archive the app (Product -> Archive)
3. Validate the archive
4. Distribute via TestFlight or App Store
5. Follow App Store submission guidelines

Note: Full App Store submission requires a paid Apple Developer account.
