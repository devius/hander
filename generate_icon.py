#!/usr/bin/env python3
"""
App Icon Generator for Hander - Hacker News Reader
Generates all required icon sizes for macOS with a beautiful design
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Configuration
OUTPUT_DIR = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
SIZES = [16, 32, 64, 128, 256, 512, 1024]

# Hacker News brand colors
HN_ORANGE = (255, 102, 0)  # #FF6600
HN_ORANGE_DARK = (230, 85, 0)  # Darker shade for gradient
WHITE = (255, 255, 255)

def create_rounded_rectangle(size, radius, color):
    """Create a rounded rectangle background"""
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Draw rounded rectangle
    draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=radius,
        fill=color
    )

    return image

def create_gradient_background(size):
    """Create a gradient background from orange to darker orange"""
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Create vertical gradient
    for y in range(size):
        # Calculate color interpolation
        ratio = y / size
        r = int(HN_ORANGE[0] * (1 - ratio) + HN_ORANGE_DARK[0] * ratio)
        g = int(HN_ORANGE[1] * (1 - ratio) + HN_ORANGE_DARK[1] * ratio)
        b = int(HN_ORANGE[2] * (1 - ratio) + HN_ORANGE_DARK[2] * ratio)

        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    return image

def add_shadow(image, offset=10, blur=20):
    """Add a subtle shadow effect"""
    size = image.size[0]
    shadow = Image.new('RGBA', (size + offset * 2, size + offset * 2), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)

    # Draw shadow
    shadow_draw.ellipse(
        [(offset, offset), (size + offset, size + offset)],
        fill=(0, 0, 0, 50)
    )

    # Paste original image on top
    shadow.paste(image, (offset, offset), image)

    return shadow.crop((offset, offset, size + offset, size + offset))

def create_icon(size):
    """Create a single app icon of the specified size"""
    # Create gradient background
    icon = create_gradient_background(size)

    # Add rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = int(size * 0.2)  # 20% radius for modern look
    mask_draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=corner_radius,
        fill=255
    )

    # Apply rounded corners
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(icon, (0, 0))
    output.putalpha(mask)

    # Create a white rounded square in the center for the Y
    center_size = int(size * 0.6)
    center_x = (size - center_size) // 2
    center_y = (size - center_size) // 2

    center_square = Image.new('RGBA', (center_size, center_size), (0, 0, 0, 0))
    center_draw = ImageDraw.Draw(center_square)
    center_radius = int(center_size * 0.15)
    center_draw.rounded_rectangle(
        [(0, 0), (center_size, center_size)],
        radius=center_radius,
        fill=WHITE
    )

    # Paste the white square onto the icon
    output.paste(center_square, (center_x, center_y), center_square)

    # Draw the "Y" letter
    draw = ImageDraw.Draw(output)

    # Try to use a system font, fall back to default if not available
    font_size = int(size * 0.5)
    try:
        # Try common macOS fonts
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/SFNS.ttf",
            "/Library/Fonts/Arial.ttf",
        ]
        font = None
        for font_path in font_paths:
            if os.path.exists(font_path):
                font = ImageFont.truetype(font_path, font_size)
                break

        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    # Draw "Y" in the center
    text = "Y"

    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center the text
    text_x = (size - text_width) // 2
    text_y = (size - text_height) // 2 - int(size * 0.05)  # Slight upward adjustment

    # Draw the text in Hacker News orange
    draw.text((text_x, text_y), text, font=font, fill=HN_ORANGE)

    return output

def generate_all_icons():
    """Generate all required icon sizes"""
    print("🎨 Generating Hander app icons...")

    # Ensure output directory exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for size in SIZES:
        print(f"   Creating {size}x{size} icon...")
        icon = create_icon(size)

        # Save the icon
        filename = f"app_icon_{size}.png"
        filepath = os.path.join(OUTPUT_DIR, filename)
        icon.save(filepath, "PNG")
        print(f"   ✅ Saved: {filename}")

    print("\n✨ All icons generated successfully!")
    print(f"📁 Location: {OUTPUT_DIR}")
    print("\n🚀 Your app now has a beautiful new icon!")

if __name__ == "__main__":
    try:
        generate_all_icons()
    except Exception as e:
        print(f"❌ Error generating icons: {e}")
        print("\nMake sure you have Pillow installed:")
        print("   pip install Pillow")
