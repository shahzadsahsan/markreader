#!/usr/bin/env python3
"""
MarkScout — App Store Screenshot Compositor
Resizes raw screenshots to 2880x1800 and adds text overlays with
Mac window chrome, matching MarkScout's visual identity.
"""

import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# --- Config ---
OUTPUT_W, OUTPUT_H = 2880, 1800
AMBER = (212, 160, 74)  # #d4a04a
WHITE = (255, 255, 255)
BG_DARK = (13, 13, 13)  # #0d0d0d

# Background gradients (tinted center)
BG_TINTS = [
    (26, 18, 7),    # warm amber tint
    (13, 26, 20),   # teal tint
    (26, 13, 26),   # purple tint
    (13, 19, 32),   # blue tint
    (26, 18, 7),    # warm amber tint
]

SLIDES = [
    {
        "input": "01-file-browser.png",
        "output": "01-file-browser.png",
        "headline": "Your Markdown, Beautiful",
        "sub": "16 palettes. 5 typography presets. Zero distractions.",
    },
    {
        "input": "02-reader-view.png",
        "output": "02-reader-view.png",
        "headline": "Read, Don't Edit",
        "sub": "Syntax highlighting, tables, task lists \u2014 all rendered perfectly.",
    },
    {
        "input": "03-themes.png",
        "output": "03-themes.png",
        "headline": "Customize Everything",
        "sub": "Typography presets, iCloud sync, smart noise filters.",
    },
    {
        "input": "04-search.png",
        "output": "04-search.png",
        "headline": "Find Anything Instantly",
        "sub": "Full-text search across all your files with highlighted results.",
    },
    {
        "input": "05-alt-view.png",
        "output": "05-code-view.png",
        "headline": "Built for AI Developers",
        "sub": "Watches your folders. Filters the noise. Shows what matters.",
    },
]

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
RAW_DIR = os.path.join(PROJECT_DIR, "mac-screenshots", "raw")
OUT_DIR = os.path.join(PROJECT_DIR, "mac-screenshots")

# Fonts
FONT_HEADLINE = "/System/Library/Fonts/SFNS.ttf"
FONT_SUB = "/System/Library/Fonts/Menlo.ttc"


def create_gradient_bg(tint, w=OUTPUT_W, h=OUTPUT_H):
    """Create a subtle radial gradient background."""
    img = Image.new("RGB", (w, h), BG_DARK)
    draw = ImageDraw.Draw(img)

    # Draw a soft elliptical glow in the center
    cx, cy = w // 2, h // 2
    max_r = int(w * 0.6)

    for r in range(max_r, 0, -4):
        alpha = r / max_r
        color = tuple(
            int(BG_DARK[i] + (tint[i] - BG_DARK[i]) * (1 - alpha) * 0.7)
            for i in range(3)
        )
        x0, y0 = cx - r, cy - int(r * 0.7)
        x1, y1 = cx + r, cy + int(r * 0.7)
        draw.ellipse([x0, y0, x1, y1], fill=color)

    return img


def draw_window_chrome(draw, x, y, w):
    """Draw macOS window chrome (title bar with traffic lights)."""
    chrome_h = 48
    # Title bar background
    draw.rounded_rectangle(
        [x, y, x + w, y + chrome_h],
        radius=12,
        fill=(30, 30, 30),
    )
    # Cover bottom rounded corners (rectangle below)
    draw.rectangle([x, y + 24, x + w, y + chrome_h], fill=(30, 30, 30))

    # Border bottom
    draw.rectangle([x, y + chrome_h - 1, x + w, y + chrome_h], fill=(42, 42, 42))

    # Traffic lights
    colors = [(255, 95, 87), (254, 188, 46), (40, 200, 64)]
    for i, c in enumerate(colors):
        cx = x + 22 + i * 28
        cy = y + 24
        draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=c)

    # Window title
    try:
        title_font = ImageFont.truetype(FONT_SUB, 18)
    except:
        title_font = ImageFont.load_default()
    title = "MarkScout"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    tw = bbox[2] - bbox[0]
    draw.text((x + w // 2 - tw // 2, y + 14), title, fill=(136, 136, 136), font=title_font)

    return chrome_h


def compose_slide(slide, tint):
    """Compose a single App Store screenshot."""
    # Create background
    bg = create_gradient_bg(tint)
    draw = ImageDraw.Draw(bg)

    # Load fonts
    try:
        font_headline = ImageFont.truetype(FONT_HEADLINE, 72)
    except:
        font_headline = ImageFont.load_default()
    try:
        font_sub = ImageFont.truetype(FONT_SUB, 30)
    except:
        font_sub = ImageFont.load_default()

    # Draw headline (centered)
    headline = slide["headline"]
    bbox = draw.textbbox((0, 0), headline, font=font_headline)
    hw = bbox[2] - bbox[0]
    hx = (OUTPUT_W - hw) // 2
    hy = 70

    # Text shadow
    for dx, dy in [(2, 2), (-1, -1), (0, 3)]:
        draw.text((hx + dx, hy + dy), headline, fill=(0, 0, 0), font=font_headline)
    draw.text((hx, hy), headline, fill=WHITE, font=font_headline)

    # Draw subheadline
    sub = slide["sub"]
    bbox = draw.textbbox((0, 0), sub, font=font_sub)
    sw = bbox[2] - bbox[0]
    sx = (OUTPUT_W - sw) // 2
    sy = hy + 90
    draw.text((sx, sy), sub, fill=AMBER, font=font_sub)

    # Load and resize raw screenshot
    raw_path = os.path.join(RAW_DIR, slide["input"])
    if os.path.exists(raw_path):
        raw = Image.open(raw_path)

        # Target: screenshot fills bottom portion with slight margins
        screenshot_w = 2500
        margin_top = 280  # space for text + chrome
        chrome_h = 48
        available_h = OUTPUT_H - margin_top

        # Scale raw screenshot to fit
        raw_aspect = raw.width / raw.height
        target_h = available_h - chrome_h
        target_w = screenshot_w

        # Maintain aspect ratio, crop to fill
        scale = max(target_w / raw.width, target_h / raw.height)
        resized_w = int(raw.width * scale)
        resized_h = int(raw.height * scale)
        raw_resized = raw.resize((resized_w, resized_h), Image.LANCZOS)

        # Center crop
        left = (resized_w - target_w) // 2
        top = 0  # Crop from the top of the resized image
        raw_cropped = raw_resized.crop((left, top, left + target_w, top + target_h))

        # Position
        sx = (OUTPUT_W - screenshot_w) // 2
        sy = margin_top

        # Draw window chrome
        chrome_h_actual = draw_window_chrome(draw, sx, sy, screenshot_w)

        # Add subtle shadow behind screenshot
        shadow = Image.new("RGBA", (screenshot_w + 40, target_h + chrome_h_actual + 40), (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow)
        shadow_draw.rectangle([0, 0, screenshot_w + 40, target_h + chrome_h_actual + 40], fill=(0, 0, 0, 120))
        shadow = shadow.filter(ImageFilter.GaussianBlur(20))
        bg.paste(Image.new("RGB", shadow.size, BG_DARK), (sx - 20, sy - 10), shadow)

        # Re-draw chrome (shadow may have overlapped)
        draw = ImageDraw.Draw(bg)
        draw_window_chrome(draw, sx, sy, screenshot_w)

        # Paste screenshot below chrome
        bg.paste(raw_cropped, (sx, sy + chrome_h_actual))
    else:
        # Placeholder
        draw.rectangle(
            [190, 300, OUTPUT_W - 190, OUTPUT_H - 40],
            fill=(22, 22, 22),
            outline=(42, 42, 42),
        )
        draw.text(
            (OUTPUT_W // 2 - 150, OUTPUT_H // 2),
            f"Missing: {slide['input']}",
            fill=(85, 85, 85),
            font=font_sub,
        )

    # Save
    out_path = os.path.join(OUT_DIR, slide["output"])
    bg.save(out_path, "PNG")
    print(f"  {slide['output']} ({bg.size[0]}x{bg.size[1]})")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print("Composing App Store screenshots...")
    for i, slide in enumerate(SLIDES):
        compose_slide(slide, BG_TINTS[i])
    print(f"\nDone! {len(SLIDES)} screenshots saved to {OUT_DIR}/")


if __name__ == "__main__":
    main()
