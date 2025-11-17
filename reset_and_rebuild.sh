#!/bin/bash

echo "Resetting Xcode project and Core Data..."

# Kill Xcode if running
echo "1. Closing Xcode..."
killall Xcode 2>/dev/null
sleep 2

# Delete all derived data
echo "2. Deleting derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/BehaviorTracker-*

# Delete simulator app data
echo "3. Resetting simulator..."
xcrun simctl shutdown all 2>/dev/null
xcrun simctl erase all 2>/dev/null

# Clean project build artifacts
echo "4. Cleaning build artifacts..."
rm -rf BehaviorTracker.xcodeproj/project.xcworkspace/xcuserdata
rm -rf BehaviorTracker.xcodeproj/xcuserdata

echo ""
echo "Reset complete!"
echo ""
echo "Now do this:"
echo "1. Open the project: open BehaviorTracker.xcodeproj"
echo "2. Wait for Xcode to fully load"
echo "3. Clean: Press Cmd+Shift+K"
echo "4. Build: Press Cmd+B"
echo "5. Run: Press Cmd+R"
echo ""
echo "The Core Data error should be gone."
