#!/bin/bash

echo "Behavior Tracker Project Verification"
echo "======================================"
echo ""

# Check for Xcode project
if [ -d "BehaviorTracker.xcodeproj" ]; then
    echo "[OK] Xcode project file exists"
else
    echo "[FAIL] Xcode project file missing"
    exit 1
fi

# Check for source files
echo ""
echo "Checking source files:"

SWIFT_FILES=$(find BehaviorTracker -name "*.swift" -not -path "*/Preview Content/*" 2>/dev/null | wc -l)
echo "  Swift files found: $SWIFT_FILES (expected: 29)"

if [ -f "BehaviorTracker/BehaviorTrackerApp.swift" ]; then
    echo "  [OK] BehaviorTrackerApp.swift"
else
    echo "  [FAIL] BehaviorTrackerApp.swift missing"
fi

if [ -f "BehaviorTracker/ContentView.swift" ]; then
    echo "  [OK] ContentView.swift"
else
    echo "  [FAIL] ContentView.swift missing"
fi

# Check for Models
if [ -d "BehaviorTracker/Models" ]; then
    MODEL_COUNT=$(find BehaviorTracker/Models -name "*.swift" | wc -l)
    echo "  [OK] Models/ folder ($MODEL_COUNT files)"
else
    echo "  [FAIL] Models/ folder missing"
fi

# Check for Views
if [ -d "BehaviorTracker/Views" ]; then
    VIEW_COUNT=$(find BehaviorTracker/Views -name "*.swift" | wc -l)
    echo "  [OK] Views/ folder ($VIEW_COUNT files)"
else
    echo "  [FAIL] Views/ folder missing"
fi

# Check for ViewModels
if [ -d "BehaviorTracker/ViewModels" ]; then
    VM_COUNT=$(find BehaviorTracker/ViewModels -name "*.swift" | wc -l)
    echo "  [OK] ViewModels/ folder ($VM_COUNT files)"
else
    echo "  [FAIL] ViewModels/ folder missing"
fi

# Check for Services
if [ -d "BehaviorTracker/Services" ]; then
    SERVICE_COUNT=$(find BehaviorTracker/Services -name "*.swift" | wc -l)
    echo "  [OK] Services/ folder ($SERVICE_COUNT files)"
else
    echo "  [FAIL] Services/ folder missing"
fi

# Check for Utilities
if [ -d "BehaviorTracker/Utilities" ]; then
    UTIL_COUNT=$(find BehaviorTracker/Utilities -name "*.swift" | wc -l)
    echo "  [OK] Utilities/ folder ($UTIL_COUNT files)"
else
    echo "  [FAIL] Utilities/ folder missing"
fi

# Check for Core Data model
if [ -d "BehaviorTracker/Models/BehaviorTrackerModel.xcdatamodeld" ]; then
    echo "  [OK] Core Data model"
else
    echo "  [FAIL] Core Data model missing"
fi

# Check for Assets
echo ""
echo "Checking assets:"

if [ -d "BehaviorTracker/Assets.xcassets" ]; then
    echo "  [OK] Assets.xcassets exists"
else
    echo "  [FAIL] Assets.xcassets missing"
fi

if [ -d "BehaviorTracker/Assets.xcassets/AppIcon.appiconset" ]; then
    echo "  [OK] AppIcon asset catalog"
else
    echo "  [FAIL] AppIcon asset catalog missing"
fi

if [ -f "BehaviorTracker/Assets.xcassets/AppIcon.appiconset/patterns-1024.png" ]; then
    echo "  [OK] App icon (patterns-1024.png)"
else
    echo "  [FAIL] App icon not copied to Assets"
fi

# Check for icon source files
echo ""
echo "Checking icon resources:"
ICON_COUNT=$(find Resources -name "patterns-*.png" 2>/dev/null | wc -l)
echo "  Icon PNG files in Resources/: $ICON_COUNT (expected: 13)"

# Check for documentation
echo ""
echo "Checking documentation:"
DOC_COUNT=$(find . -maxdepth 1 -name "*.md" | wc -l)
echo "  Documentation files: $DOC_COUNT"

# Check for tests
echo ""
echo "Checking tests:"
if [ -d "BehaviorTrackerTests" ]; then
    TEST_COUNT=$(find BehaviorTrackerTests -name "*.swift" | wc -l)
    echo "  [OK] Test files: $TEST_COUNT (expected: 3)"
else
    echo "  [FAIL] BehaviorTrackerTests folder missing"
fi

echo ""
echo "======================================"
echo "Verification complete!"
echo ""
echo "Next step:"
echo "  Run: open BehaviorTracker.xcodeproj"
echo "  Then follow instructions in OPEN_PROJECT.md"
