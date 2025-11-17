#!/bin/bash

# Generate app icons from SVG using macOS native tools

echo "Generating Behavior Tracker app icons..."

SVG_FILE="patterns.svg"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

# Check if SVG exists
if [ ! -f "$SVG_FILE" ]; then
    echo "Error: patterns.svg not found!"
    exit 1
fi

# Required icon sizes for iOS
declare -A SIZES=(
    ["1024"]="App Store"
    ["180"]="iPhone 3x"
    ["167"]="iPad Pro"
    ["152"]="iPad 2x"
    ["120"]="iPhone 2x"
    ["87"]="iPhone 3x Settings"
    ["80"]="iPad 2x Settings"
    ["76"]="iPad 1x"
    ["60"]="iPhone 2x Settings"
    ["58"]="iPhone 2x Settings"
    ["40"]="iPad 1x Settings"
    ["29"]="Settings 1x"
    ["20"]="Notification 1x"
)

# Method 1: Try using qlmanage (Quick Look)
echo "Attempting to convert using qlmanage..."
qlmanage -t -s 1024 -o . "$SVG_FILE" 2>/dev/null

if [ -f "${SVG_FILE}.png" ]; then
    mv "${SVG_FILE}.png" "patterns-1024.png"
    echo "✓ Created patterns-1024.png (1024x1024)"

    # Generate other sizes from the 1024px version using sips
    echo ""
    echo "Generating other sizes using sips..."

    for size in "${!SIZES[@]}"; do
        if [ "$size" != "1024" ]; then
            output="patterns-${size}.png"
            sips -z "$size" "$size" "patterns-1024.png" --out "$output" >/dev/null 2>&1
            if [ -f "$output" ]; then
                echo "✓ Created $output (${size}x${size}) - ${SIZES[$size]}"
            else
                echo "✗ Failed to create $output"
            fi
        fi
    done
else
    echo "Failed to convert SVG using qlmanage"
    echo ""
    echo "Alternative: Please use an online SVG to PNG converter"
    echo "1. Open https://svgtopng.com or https://cloudconvert.com/svg-to-png"
    echo "2. Upload patterns.svg"
    echo "3. Convert to 1024x1024 PNG"
    echo "4. Save as patterns-1024.png in this directory"
    echo "5. Run this script again to generate other sizes"
    exit 1
fi

echo ""
echo "Icon generation complete!"
echo "All icons saved to: $BASE_DIR"
echo ""
echo "Main icon: patterns-1024.png (for App Store and Xcode)"
echo ""
echo "To use in Xcode:"
echo "1. Open your project in Xcode"
echo "2. Select Assets.xcassets in the navigator"
echo "3. Click on AppIcon"
echo "4. Drag patterns-1024.png into the '1024pt' slot"
echo "5. Xcode will automatically generate other sizes, or:"
echo "   - Drag each patterns-XXX.png file to its matching size slot"
echo ""
echo "Note: You can also just use patterns-1024.png and let Xcode"
echo "      auto-generate all sizes from the 1024px version."
