#!/usr/bin/env python3
"""
Generate ASD Behavior Tracker app icon with rainbow infinity symbol on purple background
"""

from PIL import Image, ImageDraw
import math

def create_gradient_background(size, color1, color2):
    """Create a radial gradient background"""
    base = Image.new('RGB', (size, size), color1)
    draw = ImageDraw.Draw(base)

    # Create radial gradient
    center_x, center_y = size // 2, size // 2
    max_radius = math.sqrt(center_x**2 + center_y**2)

    for y in range(size):
        for x in range(size):
            # Calculate distance from center
            distance = math.sqrt((x - center_x)**2 + (y - center_y)**2)
            ratio = distance / max_radius

            # Interpolate colors
            r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
            g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
            b = int(color1[2] * (1 - ratio) + color2[2] * ratio)

            base.putpixel((x, y), (r, g, b))

    return base

def draw_infinity_symbol(draw, center_x, center_y, width, height, num_points=200):
    """
    Draw infinity symbol and return points for coloring
    The infinity symbol is a lemniscate: x = a*cos(t), y = a*sin(t)*cos(t)
    """
    points = []
    a = width / 2  # Scale factor
    b = height / 2

    for i in range(num_points):
        t = (2 * math.pi * i) / num_points

        # Lemniscate parametric equations
        denominator = 1 + math.sin(t)**2
        x = center_x + (a * math.cos(t)) / denominator
        y = center_y + (b * math.sin(t) * math.cos(t)) / denominator

        points.append((x, y))

    return points

def get_rainbow_color(position):
    """Get rainbow color based on position (0.0 to 1.0)"""
    # Rainbow: Red -> Orange -> Yellow -> Green -> Blue -> Indigo -> Violet
    colors = [
        (255, 0, 0),      # Red
        (255, 127, 0),    # Orange
        (255, 255, 0),    # Yellow
        (0, 255, 0),      # Green
        (0, 127, 255),    # Blue
        (75, 0, 130),     # Indigo
        (148, 0, 211),    # Violet
    ]

    # Determine which two colors to interpolate between
    scaled_pos = position * (len(colors) - 1)
    idx = int(scaled_pos)
    if idx >= len(colors) - 1:
        return colors[-1]

    # Interpolate between two adjacent colors
    ratio = scaled_pos - idx
    c1 = colors[idx]
    c2 = colors[idx + 1]

    r = int(c1[0] * (1 - ratio) + c2[0] * ratio)
    g = int(c1[1] * (1 - ratio) + c2[1] * ratio)
    b = int(c1[2] * (1 - ratio) + c2[2] * ratio)

    return (r, g, b)

def create_app_icon(output_path, size=1024):
    """Create the app icon"""
    # Purple gradient colors (lighter in center, darker on edges)
    color1 = (147, 112, 219)  # Medium Purple (center)
    color2 = (75, 0, 130)     # Indigo (edges)

    # Create base image with gradient
    img = create_gradient_background(size, color1, color2)
    draw = ImageDraw.Draw(img)

    # Calculate infinity symbol dimensions
    center_x = size // 2
    center_y = size // 2
    symbol_width = int(size * 0.65)
    symbol_height = int(size * 0.3)

    # Draw infinity symbol with rainbow colors
    points = draw_infinity_symbol(draw, center_x, center_y, symbol_width, symbol_height, 400)

    # Draw the infinity symbol with thick rainbow-colored lines
    line_width = int(size * 0.08)  # Thick line

    for i in range(len(points) - 1):
        # Get rainbow color based on position along the curve
        position = i / len(points)
        color = get_rainbow_color(position)

        # Draw thick line segment
        x1, y1 = points[i]
        x2, y2 = points[i + 1]

        # Draw multiple lines to create thickness
        for offset in range(-line_width//2, line_width//2):
            draw.line(
                [(x1, y1 + offset), (x2, y2 + offset)],
                fill=color,
                width=3
            )
            draw.line(
                [(x1 + offset, y1), (x2 + offset, y2)],
                fill=color,
                width=3
            )

    # Add rounded corners for iOS app icon style
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)

    # iOS icon corner radius is approximately 22.37% of the icon size
    corner_radius = int(size * 0.2237)
    mask_draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=corner_radius,
        fill=255
    )

    # Apply rounded corners
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(img, (0, 0))
    output.putalpha(mask)

    # Convert back to RGB for PNG
    final = Image.new('RGB', (size, size), (255, 255, 255))
    final.paste(output, (0, 0), output)

    # Save the icon
    final.save(output_path, 'PNG', quality=100)
    print(f"Icon saved to: {output_path}")

if __name__ == "__main__":
    output_file = "BehaviorTracker/Assets.xcassets/AppIcon.appiconset/asd-icon-1024.png"
    create_app_icon(output_file, 1024)
    print("\nApp icon created successfully!")
    print(f"Size: 1024x1024")
    print("Features:")
    print("  - Purple gradient background (lighter to darker)")
    print("  - Rainbow infinity symbol (neurodiversity/ASD symbol)")
    print("  - Rounded corners for iOS style")
    print("\nNext steps:")
    print("  1. Update Contents.json to use 'asd-icon-1024.png'")
    print("  2. Delete old 'patterns-1024.png'")
    print("  3. Build and run the app to see the new icon")
