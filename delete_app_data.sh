#!/bin/bash

echo "Deleting BehaviorTracker app data from all simulators..."

# Get all booted simulators
BOOTED_SIMS=$(xcrun simctl list devices | grep Booted | sed 's/.*(\(.*\)).*/\1/')

if [ -z "$BOOTED_SIMS" ]; then
    echo "No booted simulators found. Booting one..."
    # Boot iPhone 15 Pro
    DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 15 Pro (" | grep -v "Plus" | head -1 | sed 's/.*(\(.*\)).*/\1/')
    if [ ! -z "$DEVICE_ID" ]; then
        xcrun simctl boot "$DEVICE_ID"
        echo "Booted iPhone 15 Pro"
        sleep 2
    fi
fi

# Uninstall app from all simulators
echo "Uninstalling BehaviorTracker app..."
xcrun simctl uninstall booted com.behaviortracker.BehaviorTracker 2>/dev/null

echo ""
echo "App data deleted!"
echo ""
echo "Now in Xcode:"
echo "1. Press Cmd+Shift+K (Clean)"
echo "2. Press Cmd+B (Build)"
echo "3. Press Cmd+R (Run)"
echo ""
echo "The app will start fresh with a new database."
