#!/usr/bin/env python3
"""Generate polished App Store promotional screenshots for MarkScout.

Creates 5 images at 1290x2796 (iPhone 6.7") with:
- Rich mock markdown content rendered in different theme palettes
- AI/developer persona messaging
- Proper typographic hierarchy
- Device-framed screenshots where appropriate
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, math

# --- Dimensions ---
W, H = 1290, 2796

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SCRIPT_DIR, "appstore")
ICON_PATH = os.path.join(SCRIPT_DIR, "..", "MarkScout", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")
SS_DIR = SCRIPT_DIR  # raw screenshots

# --- Fonts ---
MONO = "/System/Library/Fonts/SFNSMono.ttf"
MONO_BOLD = "/System/Library/Fonts/SFNSMono.ttf"  # same file, bold weight below
SANS = "/System/Library/Fonts/Avenir Next.ttc"
SANS_BOLD = "/System/Library/Fonts/Avenir Next.ttc"

def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

# --- Theme palettes for mock content ---
THEMES = {
    "obsidian": {
        "bg": (13, 13, 13),
        "surface": (22, 22, 22),
        "border": (42, 42, 42),
        "text": (232, 224, 212),
        "muted": (136, 136, 136),
        "h1": (245, 230, 200),
        "h2": (232, 213, 163),
        "code_bg": (17, 17, 17),
        "code": (111, 196, 175),
        "accent": (200, 152, 56),
        "bold": (245, 237, 216),
        "italic": (200, 181, 216),
        "blockquote": (168, 154, 136),
        "list_marker": (200, 152, 56),
    },
    "deep_ocean": {
        "bg": (11, 16, 34),
        "surface": (16, 24, 48),
        "border": (30, 45, 74),
        "text": (205, 214, 228),
        "muted": (100, 116, 139),
        "h1": (125, 211, 252),
        "h2": (103, 184, 240),
        "code_bg": (13, 19, 48),
        "code": (52, 211, 153),
        "accent": (56, 189, 248),
        "bold": (224, 242, 254),
        "italic": (196, 181, 253),
        "blockquote": (100, 116, 139),
        "list_marker": (56, 189, 248),
    },
    "synthwave": {
        "bg": (10, 0, 20),
        "surface": (18, 0, 40),
        "border": (42, 24, 72),
        "text": (224, 208, 240),
        "muted": (107, 76, 138),
        "h1": (255, 41, 117),
        "h2": (249, 115, 22),
        "code_bg": (14, 0, 32),
        "code": (0, 229, 255),
        "accent": (255, 41, 117),
        "bold": (240, 208, 255),
        "italic": (255, 121, 198),
        "blockquote": (107, 76, 138),
        "list_marker": (255, 41, 117),
    },
    "tokyo_night": {
        "bg": (13, 16, 23),
        "surface": (19, 24, 32),
        "border": (30, 36, 56),
        "text": (169, 177, 214),
        "muted": (86, 95, 137),
        "h1": (122, 162, 247),
        "h2": (187, 154, 247),
        "code_bg": (17, 22, 32),
        "code": (158, 206, 106),
        "accent": (122, 162, 247),
        "bold": (192, 202, 245),
        "italic": (187, 154, 247),
        "blockquote": (86, 95, 137),
        "list_marker": (122, 162, 247),
    },
    "catppuccin": {
        "bg": (18, 16, 32),
        "surface": (26, 24, 48),
        "border": (46, 42, 72),
        "text": (205, 214, 244),
        "muted": (88, 91, 112),
        "h1": (245, 194, 231),
        "h2": (203, 166, 247),
        "code_bg": (22, 20, 42),
        "code": (148, 226, 213),
        "accent": (203, 166, 247),
        "bold": (205, 214, 244),
        "italic": (245, 194, 231),
        "blockquote": (88, 91, 112),
        "list_marker": (203, 166, 247),
    },
}


def gradient(w, h, top, bot):
    """Fast vertical gradient."""
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        c = tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3))
        d.line([(0, y), (w, y)], fill=c)
    return img


def lighten(color, amount=30):
    return tuple(min(255, c + amount) for c in color)


def darken(color, amount=30):
    return tuple(max(0, c - amount) for c in color)


def with_alpha(color, a):
    return color + (a,)


def round_rect_mask(w, h, r):
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=255)
    return mask


def draw_centered(draw, text, y, f, fill, w=W):
    bbox = draw.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, y), text, font=f, fill=fill)


def draw_right(draw, text, y, f, fill, right_x):
    bbox = draw.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    draw.text((right_x - tw, y), text, font=f, fill=fill)


def glow(canvas, cx, cy, radius, color, intensity):
    """Radial glow effect composited onto canvas."""
    glow_img = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(glow_img)
    for r in range(radius, 0, -3):
        a = int(intensity * ((1 - r / radius) ** 1.5))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (a,))
    comp = Image.alpha_composite(canvas.convert("RGBA"), glow_img)
    return comp.convert("RGB")


def device_frame(screenshot_path, target_h):
    """Create a device-framed screenshot scaled to target height."""
    ss = Image.open(screenshot_path).convert("RGBA")
    scale = target_h / ss.height
    new_w, new_h = int(ss.width * scale), int(ss.height * scale)
    ss = ss.resize((new_w, new_h), Image.LANCZOS)

    # Round corners
    mask = round_rect_mask(new_w, new_h, 44)
    result = Image.new("RGBA", (new_w, new_h), (0, 0, 0, 0))
    result.paste(ss, (0, 0), mask)

    # Border
    border_img = Image.new("RGBA", (new_w + 6, new_h + 6), (0, 0, 0, 0))
    d = ImageDraw.Draw(border_img)
    d.rounded_rectangle([0, 0, new_w + 5, new_h + 5], radius=47, outline=(60, 60, 60), width=3)
    border_img.paste(result, (3, 3), result)
    return border_img


# ─── Mock markdown panel rendering ───

def draw_mock_markdown(canvas, x, y, w, h, theme, content_type="architecture"):
    """Draw a mock rendered markdown panel on the canvas."""
    t = THEMES[theme]
    d = ImageDraw.Draw(canvas)

    # Panel background
    d.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=t["bg"], outline=t["border"], width=2)

    # Status bar area
    bar_y = y + 16
    bar_h = 44
    d.rounded_rectangle([x + 16, bar_y, x + w - 16, bar_y + bar_h], radius=12, fill=t["surface"])

    # Toolbar dots
    for i in range(3):
        dx = x + 36 + i * 20
        d.ellipse([dx, bar_y + 14, dx + 14, bar_y + 28], fill=t["border"])

    # Scrollbar rail on right
    rail_x = x + w - 16
    d.line([(rail_x, y + 80), (rail_x, y + h - 30)], fill=t["border"], width=4)
    # Scroll position indicator
    d.rounded_rectangle([rail_x - 3, y + 90, rail_x + 3, y + 180], radius=3, fill=t["accent"])

    # Content area
    cx = x + 36
    cy = y + 80
    cw = w - 72

    f_h1 = font(MONO_BOLD, 36)
    f_h2 = font(MONO_BOLD, 28)
    f_body = font(SANS, 22)
    f_code = font(MONO, 20)
    f_small = font(SANS, 18)

    if content_type == "architecture":
        # h1
        d.text((cx, cy), "Architecture &", font=f_h1, fill=t["h1"])
        cy += 46
        d.text((cx, cy), "Implementation Plan", font=f_h1, fill=t["h1"])
        cy += 56
        # h1 underline
        d.line([(cx, cy), (cx + cw * 0.7, cy)], fill=t["accent"], width=2)
        cy += 24

        # h2
        d.text((cx, cy), "Tech Stack", font=f_h2, fill=t["h2"])
        cy += 44

        # Table
        rows = [
            ("Layer", "Choice"),
            ("Framework", "Next.js 15"),
            ("Styling", "Tailwind CSS"),
            ("File watching", "chokidar"),
            ("Rendering", "markdown-it"),
        ]
        col1_w = int(cw * 0.35)
        for i, (c1, c2) in enumerate(rows):
            ry = cy + i * 38
            color = t["bold"] if i == 0 else t["text"]
            f_row = font(MONO_BOLD, 20) if i == 0 else font(SANS, 20)
            d.text((cx, ry), c1, font=f_row, fill=color)
            d.text((cx + col1_w, ry), c2, font=f_row, fill=t["code"] if i > 0 else color)
            if i < len(rows) - 1:
                d.line([(cx, ry + 34), (cx + cw, ry + 34)], fill=t["border"], width=1)
        cy += len(rows) * 38 + 20

        # Code block
        code_h = 100
        d.rounded_rectangle([cx, cy, cx + cw, cy + code_h], radius=12, fill=t["code_bg"])
        d.text((cx + 16, cy + 12), "const watcher = chokidar", font=f_code, fill=t["code"])
        d.text((cx + 16, cy + 38), "  .watch(dirs, opts)", font=f_code, fill=t["text"])
        d.text((cx + 16, cy + 64), "  .on('change', hash)", font=f_code, fill=t["muted"])

    elif content_type == "claude":
        # h1
        d.text((cx, cy), "CLAUDE.md", font=f_h1, fill=t["h1"])
        cy += 52
        d.line([(cx, cy), (cx + cw * 0.4, cy)], fill=t["accent"], width=2)
        cy += 24

        # h2
        d.text((cx, cy), "Project Instructions", font=f_h2, fill=t["h2"])
        cy += 44

        # Body text
        lines = [
            "Local only — no auth, no deploy",
            "Read-only — never modify files",
            "Dark theme only for V1",
            "chokidar for file watching",
            "markdown-it for rendering",
        ]
        for line in lines:
            d.ellipse([cx + 4, cy + 8, cx + 12, cy + 16], fill=t["list_marker"])
            d.text((cx + 24, cy), line, font=f_body, fill=t["text"])
            cy += 34
        cy += 16

        # Code block
        code_h = 80
        d.rounded_rectangle([cx, cy, cx + cw, cy + code_h], radius=12, fill=t["code_bg"])
        d.text((cx + 16, cy + 12), "# Key Constraints", font=f_code, fill=t["muted"])
        d.text((cx + 16, cy + 40), "security: validate paths", font=f_code, fill=t["code"])

    elif content_type == "requirements":
        d.text((cx, cy), "Requirements", font=f_h1, fill=t["h1"])
        cy += 52
        d.line([(cx, cy), (cx + cw * 0.5, cy)], fill=t["accent"], width=2)
        cy += 24

        d.text((cx, cy), "Sidebar Views", font=f_h2, fill=t["h2"])
        cy += 44

        items = [
            ("Recents", "all files by modified time"),
            ("Folders", "collapsible tree by project"),
            ("Favorites", "starred files"),
            ("History", "last 50 opened files"),
        ]
        for name, desc in items:
            d.text((cx, cy), f"{name}", font=font(SANS_BOLD, 22), fill=t["bold"])
            d.text((cx + 160, cy), f"— {desc}", font=f_body, fill=t["muted"])
            cy += 36


def draw_theme_strip(canvas, y, themes_list, content_types):
    """Draw a horizontal strip of 3 overlapping mock panels."""
    panel_w = 540
    panel_h = 680
    gap = -60  # overlap
    total_w = len(themes_list) * panel_w + (len(themes_list) - 1) * gap
    start_x = (W - total_w) // 2

    for i, (theme, ct) in enumerate(zip(themes_list, content_types)):
        px = start_x + i * (panel_w + gap)
        # Shadow
        shadow = Image.new("RGBA", (panel_w + 40, panel_h + 40), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle([0, 0, panel_w + 39, panel_h + 39], radius=28, fill=(0, 0, 0, 80))
        shadow = shadow.filter(ImageFilter.GaussianBlur(20))
        canvas.paste(Image.alpha_composite(
            canvas.crop((px - 20, y - 20, px + panel_w + 20, y + panel_h + 20)).convert("RGBA"),
            shadow
        ), (px - 20, y - 20))

        draw_mock_markdown(canvas, px, y, panel_w, panel_h, theme, ct)


# ═══════════════════════════════════════════════════
# SLIDE 1: HERO
# ═══════════════════════════════════════════════════

def slide_hero():
    bg_top = (8, 6, 14)
    bg_bot = (18, 12, 6)
    canvas = gradient(W, H, bg_top, bg_bot)

    # Ambient glow
    canvas = glow(canvas, W // 2, 600, 800, (212, 160, 74), 6)
    canvas = glow(canvas, W // 2, 2000, 600, (122, 162, 247), 4)

    d = ImageDraw.Draw(canvas)

    # App icon
    icon = Image.open(ICON_PATH).convert("RGBA").resize((280, 280), Image.LANCZOS)
    mask = round_rect_mask(280, 280, 62)
    icon_framed = Image.new("RGBA", (280, 280), (0, 0, 0, 0))
    icon_framed.paste(icon, (0, 0), mask)
    canvas.paste(icon_framed, ((W - 280) // 2, 420), icon_framed)

    d = ImageDraw.Draw(canvas)

    # App name — large
    f_name = font(MONO_BOLD, 96)
    draw_centered(d, "MarkScout", 760, f_name, (240, 232, 220))

    # Tagline
    f_tag = font(SANS, 52)
    draw_centered(d, "Read your CLAUDE.md on the go", 890, f_tag, (212, 160, 74))

    # Thin rule
    rule_w = 180
    d.line([(W // 2 - rule_w // 2, 980), (W // 2 + rule_w // 2, 980)], fill=(212, 160, 74), width=2)

    # Subtitle
    f_sub = font(SANS, 38)
    draw_centered(d, "The iOS companion for AI-assisted development", 1020, f_sub, (136, 136, 136))

    # 3 overlapping theme panels below
    draw_theme_strip(canvas, 1160, ["obsidian", "deep_ocean", "tokyo_night"],
                     ["architecture", "claude", "requirements"])

    # Bottom tagline
    f_bot = font(MONO, 30)
    draw_centered(d, "16 themes  ·  iCloud sync  ·  offline reading", 2480, f_bot, (100, 100, 100))

    # "for iOS" pill
    d = ImageDraw.Draw(canvas)
    f_pill = font(MONO, 28)
    pill_text = "for iOS"
    bbox = d.textbbox((0, 0), pill_text, font=f_pill)
    pw = bbox[2] - bbox[0] + 48
    ph = bbox[3] - bbox[1] + 20
    px = (W - pw) // 2
    py = 2560
    d.rounded_rectangle([px, py, px + pw, py + ph], radius=16, outline=(212, 160, 74), width=2)
    draw_centered(d, pill_text, py + 5, f_pill, (212, 160, 74))

    canvas.save(os.path.join(OUT, "01-hero.png"), "PNG")
    print("  01-hero.png")


# ═══════════════════════════════════════════════════
# SLIDE 2: AI WORKFLOW
# ═══════════════════════════════════════════════════

def slide_ai_workflow():
    bg_top = (8, 8, 16)
    bg_bot = (14, 8, 4)
    canvas = gradient(W, H, bg_top, bg_bot)
    canvas = glow(canvas, W // 2, 400, 600, (122, 162, 247), 6)

    d = ImageDraw.Draw(canvas)

    # Headline
    f_h = font(MONO_BOLD, 72)
    f_sub = font(SANS, 42)
    draw_centered(d, "Your AI context,", 200, f_h, (224, 224, 224))
    draw_centered(d, "in your pocket", 290, f_h, (212, 160, 74))
    draw_centered(d, "CLAUDE.md · ARCHITECTURE.md · REQUIREMENTS.md", 400, font(MONO, 28), (120, 120, 120))

    # Two-panel layout: CLAUDE.md on the left, Architecture on the right
    panel_w = 580
    panel_h = 820
    gap = 30
    lx = (W - 2 * panel_w - gap) // 2
    rx = lx + panel_w + gap
    py = 500

    # Left panel - CLAUDE.md in synthwave
    # Shadow
    shadow = Image.new("RGBA", (panel_w + 40, panel_h + 40), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([0, 0, panel_w + 39, panel_h + 39], radius=28, fill=(0, 0, 0, 100))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(Image.alpha_composite(
        canvas.crop((lx - 20, py - 20, lx + panel_w + 20, py + panel_h + 20)).convert("RGBA"), shadow
    ), (lx - 20, py - 20))
    draw_mock_markdown(canvas, lx, py, panel_w, panel_h, "catppuccin", "claude")

    # Right panel - Architecture in deep ocean
    shadow2 = Image.new("RGBA", (panel_w + 40, panel_h + 40), (0, 0, 0, 0))
    ImageDraw.Draw(shadow2).rounded_rectangle([0, 0, panel_w + 39, panel_h + 39], radius=28, fill=(0, 0, 0, 100))
    shadow2 = shadow2.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(Image.alpha_composite(
        canvas.crop((rx - 20, py - 20, rx + panel_w + 20, py + panel_h + 20)).convert("RGBA"), shadow2
    ), (rx - 20, py - 20))
    draw_mock_markdown(canvas, rx, py, panel_w, panel_h, "deep_ocean", "architecture")

    # File pills at bottom
    d = ImageDraw.Draw(canvas)
    pills = ["CLAUDE.md", "REQUIREMENTS.md", "ARCHITECTURE.md"]
    pill_f = font(MONO, 26)
    total_pill_w = 0
    pill_ws = []
    for p in pills:
        bbox = d.textbbox((0, 0), p, font=pill_f)
        pw = bbox[2] - bbox[0] + 36
        pill_ws.append(pw)
        total_pill_w += pw
    pill_gap = 20
    total_pill_w += pill_gap * (len(pills) - 1)
    pill_x = (W - total_pill_w) // 2
    pill_y = 1420
    colors = [(245, 194, 231), (148, 226, 213), (125, 211, 252)]
    for i, (p, pw, col) in enumerate(zip(pills, pill_ws, colors)):
        d.rounded_rectangle([pill_x, pill_y, pill_x + pw, pill_y + 42], radius=12, outline=col, width=2)
        bbox = d.textbbox((0, 0), p, font=pill_f)
        tw = bbox[2] - bbox[0]
        d.text((pill_x + (pw - tw) // 2, pill_y + 6), p, font=pill_f, fill=col)
        pill_x += pw + pill_gap

    # Bottom device screenshot
    frame = device_frame(os.path.join(SS_DIR, "02-filelist.png"), 1100)
    fx = (W - frame.width) // 2
    canvas.paste(frame, (fx, 1540), frame)

    # Bottom label
    d = ImageDraw.Draw(canvas)
    draw_centered(d, "Browse all your project docs", 2680, font(SANS, 34), (100, 100, 100))

    canvas.save(os.path.join(OUT, "02-ai-workflow.png"), "PNG")
    print("  02-ai-workflow.png")


# ═══════════════════════════════════════════════════
# SLIDE 3: READER EXPERIENCE
# ═══════════════════════════════════════════════════

def slide_reader():
    bg_top = (6, 10, 18)
    bg_bot = (12, 6, 6)
    canvas = gradient(W, H, bg_top, bg_bot)
    canvas = glow(canvas, W // 2, 300, 500, (187, 154, 247), 5)

    d = ImageDraw.Draw(canvas)

    # Headline
    f_h = font(MONO_BOLD, 72)
    draw_centered(d, "Beautiful on", 180, f_h, (224, 224, 224))
    draw_centered(d, "every theme", 270, f_h, (187, 154, 247))

    f_sub = font(SANS, 38)
    draw_centered(d, "16 hand-tuned palettes for comfortable reading", 380, f_sub, (120, 120, 120))

    # Real screenshot in device frame — large, centered
    frame = device_frame(os.path.join(SS_DIR, "03-reader.png"), 1700)
    fx = (W - frame.width) // 2
    canvas.paste(frame, (fx, 500), frame)

    # Theme name pills along the bottom
    d = ImageDraw.Draw(canvas)
    theme_names = ["Obsidian", "Deep Ocean", "Synthwave", "Tokyo Night", "Catppuccin", "Nord"]
    theme_colors = [
        (200, 152, 56), (125, 211, 252), (255, 41, 117),
        (122, 162, 247), (203, 166, 247), (136, 192, 208),
    ]
    pill_f = font(MONO, 24)
    pill_ws = []
    for name in theme_names:
        bbox = d.textbbox((0, 0), name, font=pill_f)
        pill_ws.append(bbox[2] - bbox[0] + 32)

    total = sum(pill_ws) + 16 * (len(theme_names) - 1)
    px = (W - total) // 2
    py = 2360

    for name, pw, col in zip(theme_names, pill_ws, theme_colors):
        d.rounded_rectangle([px, py, px + pw, py + 40], radius=12, fill=darken(col, 180), outline=col, width=2)
        bbox = d.textbbox((0, 0), name, font=pill_f)
        tw = bbox[2] - bbox[0]
        d.text((px + (pw - tw) // 2, py + 6), name, font=pill_f, fill=col)
        px += pw + 16

    # Second row
    theme_names2 = ["Dracula", "Monokai", "Solarized", "Sepia", "Sakura", "Arctic"]
    theme_colors2 = [
        (255, 121, 198), (166, 226, 46), (181, 137, 0),
        (92, 61, 26), (200, 106, 138), (49, 130, 206),
    ]
    pill_ws2 = []
    for name in theme_names2:
        bbox = d.textbbox((0, 0), name, font=pill_f)
        pill_ws2.append(bbox[2] - bbox[0] + 32)
    total2 = sum(pill_ws2) + 16 * (len(theme_names2) - 1)
    px2 = (W - total2) // 2
    py2 = py + 56
    for name, pw, col in zip(theme_names2, pill_ws2, theme_colors2):
        d.rounded_rectangle([px2, py2, px2 + pw, py2 + 40], radius=12, fill=darken(col, 180), outline=col, width=2)
        bbox = d.textbbox((0, 0), name, font=pill_f)
        tw = bbox[2] - bbox[0]
        d.text((px2 + (pw - tw) // 2, py2 + 6), name, font=pill_f, fill=col)
        px2 += pw + 16

    # Bottom text
    draw_centered(d, "Code blocks · Tables · Full formatting", 2560, font(SANS, 32), (100, 100, 100))

    canvas.save(os.path.join(OUT, "03-reader.png"), "PNG")
    print("  03-reader.png")


# ═══════════════════════════════════════════════════
# SLIDE 4: FEATURES
# ═══════════════════════════════════════════════════

def slide_features():
    bg_top = (10, 8, 4)
    bg_bot = (6, 8, 14)
    canvas = gradient(W, H, bg_top, bg_bot)
    canvas = glow(canvas, W // 2, 350, 600, (212, 160, 74), 5)

    d = ImageDraw.Draw(canvas)

    f_h = font(MONO_BOLD, 72)
    draw_centered(d, "Built for", 180, f_h, (224, 224, 224))
    draw_centered(d, "developers", 270, f_h, (212, 160, 74))

    f_sub = font(SANS, 38)
    draw_centered(d, "Every feature you need, nothing you don't", 380, f_sub, (120, 120, 120))

    # Feature grid — 2 columns, 4 rows
    features = [
        ("magnifyingglass", "Find in Page", "Native search within\nany document"),
        ("star.fill", "Favorites", "Star your most\nimportant files"),
        ("arrow.down.circle", "Offline Cache", "Read without\ninternet access"),
        ("rectangle.and.text.magnifyingglass", "Spotlight", "Files appear in\nsystem search"),
        ("paintpalette.fill", "16 Themes", "Dark, light, and\nvibrant palettes"),
        ("text.magnifyingglass", "Table of Contents", "Jump to any\nsection instantly"),
        ("icloud", "iCloud Sync", "Auto-syncs from\nyour desktop"),
        ("lock.shield", "Privacy First", "No analytics, no\ntracking, ever"),
    ]

    col_w = 540
    row_h = 230
    grid_x = (W - 2 * col_w - 40) // 2
    grid_y = 500

    f_feat_name = font(MONO_BOLD, 32)
    f_feat_desc = font(SANS, 26)

    # Feature icons as text circles
    accent = (212, 160, 74)
    icon_symbols = ["?", "★", "↓", "⊕", "◉", "≡", "☁", "🛡"]

    for i, (icon_name, name, desc) in enumerate(features):
        col = i % 2
        row = i // 2
        fx = grid_x + col * (col_w + 40)
        fy = grid_y + row * row_h

        # Card background
        d.rounded_rectangle([fx, fy, fx + col_w, fy + row_h - 20], radius=20,
                           fill=(20, 18, 16), outline=(42, 38, 34), width=1)

        # Icon circle
        icon_r = 28
        ix = fx + 30
        iy = fy + 30
        d.ellipse([ix, iy, ix + icon_r * 2, iy + icon_r * 2], fill=darken(accent, 140), outline=accent, width=2)

        # Feature name
        d.text((ix + icon_r * 2 + 20, iy + 2), name, font=f_feat_name, fill=(232, 224, 212))

        # Description
        desc_y = iy + 46
        for line in desc.split("\n"):
            d.text((ix + icon_r * 2 + 20, desc_y), line, font=f_feat_desc, fill=(136, 136, 136))
            desc_y += 30

    # Device frame at bottom
    frame = device_frame(os.path.join(SS_DIR, "04-favorites.png"), 900)
    fx = (W - frame.width) // 2
    fy = 1460
    canvas.paste(frame, (fx, fy), frame)

    # Onboarding frame overlapping
    frame2 = device_frame(os.path.join(SS_DIR, "01-onboarding.png"), 800)
    canvas.paste(frame2, (fx + frame.width - 180, fy + 100), frame2)

    d = ImageDraw.Draw(canvas)
    draw_centered(d, "Free · No account required · No data collected", 2620, font(SANS, 30), (100, 100, 100))

    canvas.save(os.path.join(OUT, "04-features.png"), "PNG")
    print("  04-features.png")


# ═══════════════════════════════════════════════════
# SLIDE 5: SYNC & PRIVACY
# ═══════════════════════════════════════════════════

def slide_sync():
    bg_top = (6, 10, 16)
    bg_bot = (10, 6, 10)
    canvas = gradient(W, H, bg_top, bg_bot)
    canvas = glow(canvas, W // 2, 350, 500, (52, 211, 153), 5)

    d = ImageDraw.Draw(canvas)

    f_h = font(MONO_BOLD, 72)
    draw_centered(d, "Syncs with", 180, f_h, (224, 224, 224))
    draw_centered(d, "iCloud Drive", 270, f_h, (52, 211, 153))

    f_sub = font(SANS, 38)
    draw_centered(d, "Pick a folder · Pull to refresh · Read anywhere", 380, f_sub, (120, 120, 120))

    # Flow diagram: Desktop → iCloud → MarkScout
    flow_y = 510
    f_flow = font(MONO, 28)
    f_flow_label = font(SANS, 24)

    # Three boxes
    box_w, box_h = 300, 100
    box_gap = 80
    total_flow = 3 * box_w + 2 * box_gap
    bx = (W - total_flow) // 2

    boxes = [
        ("Desktop", "writes .md", (200, 152, 56)),
        ("iCloud", "auto-syncs", (52, 211, 153)),
        ("MarkScout", "reads on iOS", (122, 162, 247)),
    ]

    for i, (title, subtitle, col) in enumerate(boxes):
        x = bx + i * (box_w + box_gap)
        d.rounded_rectangle([x, flow_y, x + box_w, flow_y + box_h], radius=16,
                           fill=darken(col, 200), outline=col, width=2)
        f_title = font(MONO_BOLD, 28)
        bbox_t = d.textbbox((0, 0), title, font=f_title)
        tw = bbox_t[2] - bbox_t[0]
        d.text((x + (box_w - tw) // 2, flow_y + 18), title, font=f_title, fill=col)
        bbox_s = d.textbbox((0, 0), subtitle, font=f_flow_label)
        sw = bbox_s[2] - bbox_s[0]
        d.text((x + (box_w - sw) // 2, flow_y + 58), subtitle, font=f_flow_label, fill=(120, 120, 120))

        # Arrow between boxes
        if i < 2:
            ax = x + box_w + 10
            ay = flow_y + box_h // 2
            d.line([(ax, ay), (ax + box_gap - 20, ay)], fill=(80, 80, 80), width=2)
            # Arrowhead
            d.polygon([
                (ax + box_gap - 20, ay - 8),
                (ax + box_gap - 8, ay),
                (ax + box_gap - 20, ay + 8),
            ], fill=(80, 80, 80))

    # Onboarding screenshot — large centered
    frame = device_frame(os.path.join(SS_DIR, "01-onboarding.png"), 1500)
    fx = (W - frame.width) // 2
    canvas.paste(frame, (fx, 700), frame)

    # Privacy badges at bottom
    d = ImageDraw.Draw(canvas)
    badges = [
        "No analytics",
        "No accounts",
        "No tracking",
        "100% local",
    ]
    f_badge = font(MONO, 26)
    badge_ws = []
    for b in badges:
        bbox = d.textbbox((0, 0), b, font=f_badge)
        badge_ws.append(bbox[2] - bbox[0] + 40)
    total_bw = sum(badge_ws) + 20 * (len(badges) - 1)
    bpx = (W - total_bw) // 2
    bpy = 2500
    green = (52, 211, 153)
    for b, bw in zip(badges, badge_ws):
        d.rounded_rectangle([bpx, bpy, bpx + bw, bpy + 44], radius=12,
                           fill=darken(green, 200), outline=green, width=2)
        bbox = d.textbbox((0, 0), b, font=f_badge)
        tw = bbox[2] - bbox[0]
        d.text((bpx + (bw - tw) // 2, bpy + 7), b, font=f_badge, fill=green)
        bpx += bw + 20

    draw_centered(d, "Your files never leave your device", 2600, font(SANS, 30), (100, 100, 100))

    canvas.save(os.path.join(OUT, "05-sync.png"), "PNG")
    print("  05-sync.png")


# ═══════════════════════════════════════════════════

def main():
    os.makedirs(OUT, exist_ok=True)
    # Clean old files
    for f in os.listdir(OUT):
        os.remove(os.path.join(OUT, f))

    print("Generating App Store images (1290x2796)...")
    slide_hero()
    slide_ai_workflow()
    slide_reader()
    slide_features()
    slide_sync()
    print(f"\nDone! 5 images in {OUT}")

if __name__ == "__main__":
    main()
