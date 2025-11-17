#!/usr/bin/env python3
"""
Generate app icon for Behavior Tracker
Creates a patterns-themed icon with geometric shapes
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_gradient_background(size, color1, color2):
    """Create a gradient background"""
    base = Image.new('RGB', size, color1)
    draw = ImageDraw.Draw(base)

    for y in range(size[1]):
        r = int(color1[0] + (color2[0] - color1[0]) * y / size[1])
        g = int(color1[1] + (color2[1] - color1[1]) * y / size[1])
        b = int(color1[2] + (color2[2] - color1[2]) * y / size[1])
        draw.line([(0, y), (size[0], y)], fill=(r, g, b))

    return base

def draw_pattern_circles(draw, size, color, alpha=255):
    """Draw circular pattern elements"""
    width, height = size
    center_x, center_y = width // 2, height // 2

    # Create overlay for alpha
    overlay = Image.new('RGBA', size, (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)

    # Main brain-like pattern with circles
    radius_base = min(width, height) // 6

    # Central circle
    overlay_draw.ellipse(
        [center_x - radius_base, center_y - radius_base,
         center_x + radius_base, center_y + radius_base],
        fill=(*color, alpha)
    )

    # Surrounding circles (neural network pattern)
    angles = [0, 60, 120, 180, 240, 300]
    offset = radius_base * 1.8

    for angle in angles:
        import math
        rad = math.radians(angle)
        x = center_x + offset * math.cos(rad)
        y = center_y + offset * math.sin(rad)
        r = radius_base * 0.7

        overlay_draw.ellipse(
            [x - r, y - r, x + r, y + r],
            fill=(*color, alpha)
        )

    # Smaller connecting circles
    for angle in [30, 90, 150, 210, 270, 330]:
        rad = math.radians(angle)
        x = center_x + offset * 0.6 * math.cos(rad)
        y = center_y + offset * 0.6 * math.sin(rad)
        r = radius_base * 0.4

        overlay_draw.ellipse(
            [x - r, y - r, x + r, y + r],
            fill=(*color, alpha)
        )

    return overlay

def draw_connecting_lines(draw, size, color, alpha=180):
    """Draw connecting lines between pattern elements"""
    width, height = size
    center_x, center_y = width // 2, height // 2

    overlay = Image.new('RGBA', size, (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)

    radius_base = min(width, height) // 6
    offset = radius_base * 1.8

    angles = [0, 60, 120, 180, 240, 300]

    for i, angle in enumerate(angles):
        import math
        rad = math.radians(angle)
        x1 = center_x + offset * math.cos(rad)
        y1 = center_y + offset * math.sin(rad)

        # Connect to center
        overlay_draw.line(
            [(center_x, center_y), (x1, y1)],
            fill=(*color, alpha),
            width=max(3, width // 150)
        )

        # Connect to next circle
        next_angle = angles[(i + 1) % len(angles)]
        next_rad = math.radians(next_angle)
        x2 = center_x + offset * math.cos(next_rad)
        y2 = center_y + offset * math.sin(next_rad)

        overlay_draw.line(
            [(x1, y1), (x2, y2)],
            fill=(*color, alpha // 2),
            width=max(2, width // 200)
        )

    return overlay

def create_icon(size):
    """Create the app icon at specified size"""
    # Color scheme - blue gradient with white patterns
    gradient_start = (58, 123, 213)   # iOS blue
    gradient_end = (88, 86, 214)      # Purple-blue
    pattern_color = (255, 255, 255)   # White

    # Create base with gradient
    img = create_gradient_background((size, size), gradient_start, gradient_end)
    img = img.convert('RGBA')

    draw = ImageDraw.Draw(img)

    # Add connecting lines
    lines_overlay = draw_connecting_lines(draw, (size, size), pattern_color, alpha=150)
    img = Image.alpha_composite(img, lines_overlay)

    # Add pattern circles
    circles_overlay = draw_pattern_circles(draw, (size, size), pattern_color, alpha=230)
    img = Image.alpha_composite(img, circles_overlay)

    # Add subtle glow effect
    glow_overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    center_x, center_y = size // 2, size // 2

    # Radial glow
    for i in range(20):
        alpha = int(30 - i * 1.5)
        radius = size // 2 - i * 5
        glow_draw.ellipse(
            [center_x - radius, center_y - radius,
             center_x + radius, center_y + radius],
            fill=(255, 255, 255, alpha)
        )

    img = Image.alpha_composite(img, glow_overlay)

    # Add rounded corners for iOS icon
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)

    # iOS icon corner radius is ~22.37% of icon size
    corner_radius = int(size * 0.2237)
    mask_draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=corner_radius,
        fill=255
    )

    # Apply mask
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(img, (0, 0))
    output.putalpha(mask)

    return output

def main():
    """Generate all required icon sizes"""
    # iOS App Icon sizes
    sizes = {
        'patterns-1024.png': 1024,  # App Store
        'patterns-180.png': 180,    # iPhone 3x
        'patterns-167.png': 167,    # iPad Pro
        'patterns-152.png': 152,    # iPad 2x
        'patterns-120.png': 120,    # iPhone 2x
        'patterns-87.png': 87,      # iPhone 3x Settings
        'patterns-80.png': 80,      # iPad 2x Settings
        'patterns-76.png': 76,      # iPad 1x
        'patterns-60.png': 60,      # iPhone 2x Settings
        'patterns-58.png': 58,      # iPhone 2x Settings
        'patterns-40.png': 40,      # iPad 1x Settings
        'patterns-29.png': 29,      # Settings 1x
        'patterns-20.png': 20,      # Notification 1x
    }

    # Create output directory
    output_dir = os.path.dirname(os.path.abspath(__file__))

    print("Generating Behavior Tracker app icons...")
    print(f"Output directory: {output_dir}")

    for filename, size in sizes.items():
        print(f"Creating {filename} ({size}x{size})")
        icon = create_icon(size)
        icon.save(os.path.join(output_dir, filename))

    print("\nIcon generation complete!")
    print(f"\nMain icon: patterns-1024.png (for App Store)")
    print(f"All icons saved to: {output_dir}")
    print("\nTo use in Xcode:")
    print("1. Open Assets.xcassets")
    print("2. Select AppIcon")
    print("3. Drag and drop each icon to its corresponding size slot")

if __name__ == '__main__':
    main()
