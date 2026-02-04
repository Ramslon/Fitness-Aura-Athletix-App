from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


REPO_ROOT = Path(__file__).resolve().parents[1]


def make_base_icon(size: int = 1024) -> Image.Image:
    """Create a simple fitness-themed launcher icon.

    Design: gradient background + aura ring + dumbbell + "FA" monogram.
    """

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Gradient background with subtle vignette
    pixels = img.load()
    for y in range(size):
        t = y / (size - 1)
        # deep navy -> teal
        r0, g0, b0 = 10, 18, 44
        r1, g1, b1 = 0, 160, 175
        r = int(r0 * (1 - t) + r1 * t)
        g = int(g0 * (1 - t) + g1 * t)
        b = int(b0 * (1 - t) + b1 * t)
        for x in range(size):
            dx = (x - size / 2) / (size / 2)
            dy = (y - size / 2) / (size / 2)
            v = 1 - 0.22 * min(1.0, dx * dx + dy * dy)
            pixels[x, y] = (int(r * v), int(g * v), int(b * v), 255)

    d = ImageDraw.Draw(img)

    # Aura ring
    cx, cy = size // 2, size // 2
    ring_r = int(size * 0.36)
    ring_w = int(size * 0.05)
    for i in range(ring_w):
        a = int(95 * (1 - i / max(1, ring_w - 1)))
        d.ellipse(
            (cx - ring_r - i, cy - ring_r - i, cx + ring_r + i, cy + ring_r + i),
            outline=(120, 245, 255, a),
            width=2,
        )

    # Dumbbell
    bar_w = int(size * 0.44)
    bar_h = int(size * 0.06)
    bar_x0 = cx - bar_w // 2
    bar_y0 = cy - bar_h // 2
    bar_x1 = cx + bar_w // 2
    bar_y1 = cy + bar_h // 2
    white = (245, 250, 255, 255)

    d.rounded_rectangle(
        (bar_x0, bar_y0, bar_x1, bar_y1), radius=bar_h // 2, fill=white
    )

    plate_w = int(size * 0.09)
    plate_h = int(size * 0.24)
    plate_gap = int(size * 0.03)

    lx1 = bar_x0 - plate_gap
    lx0 = lx1 - plate_w
    ly0 = cy - plate_h // 2
    ly1 = cy + plate_h // 2
    d.rounded_rectangle((lx0, ly0, lx1, ly1), radius=int(size * 0.03), fill=white)

    rx0 = bar_x1 + plate_gap
    rx1 = rx0 + plate_w
    d.rounded_rectangle((rx0, ly0, rx1, ly1), radius=int(size * 0.03), fill=white)

    # Plate inner detail
    for x0, x1 in [(lx0, lx1), (rx0, rx1)]:
        d.rounded_rectangle(
            (
                x0 + int(plate_w * 0.25),
                ly0 + int(plate_h * 0.12),
                x1 - int(plate_w * 0.25),
                ly1 - int(plate_h * 0.12),
            ),
            radius=int(size * 0.02),
            outline=(255, 255, 255, 80),
            width=max(1, int(size * 0.008)),
        )

    # FA monogram
    text = "FA"
    try:
        font = ImageFont.truetype("arial.ttf", int(size * 0.12))
    except Exception:
        font = ImageFont.load_default()

    bbox = d.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    d.text(
        (cx - tw / 2, int(size * 0.68)),
        text,
        font=font,
        fill=(235, 255, 255, 235),
    )

    return img


def save_resized(src_img: Image.Image, out_path: Path, size: int) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    im = src_img.resize((size, size), Image.Resampling.LANCZOS)
    im.save(out_path)


def main() -> None:
    base = make_base_icon(1024)

    # Source copy (handy for future tweaks)
    source_png = REPO_ROOT / "assets" / "icons" / "app_icon.png"
    source_png.parent.mkdir(parents=True, exist_ok=True)
    base.save(source_png)

    # Android launcher icons
    android_targets = [
        ("android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48),
        ("android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72),
        ("android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96),
        ("android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144),
        ("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192),
    ]
    for rel, s in android_targets:
        save_resized(base, REPO_ROOT / rel, s)

    # iOS AppIcon assets
    ios_dir = REPO_ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_targets = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for name, s in ios_targets:
        save_resized(base, ios_dir / name, s)

    # macOS AppIcon assets
    mac_dir = REPO_ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    mac_targets = [
        ("app_icon_16.png", 16),
        ("app_icon_32.png", 32),
        ("app_icon_64.png", 64),
        ("app_icon_128.png", 128),
        ("app_icon_256.png", 256),
        ("app_icon_512.png", 512),
        ("app_icon_1024.png", 1024),
    ]
    for name, s in mac_targets:
        save_resized(base, mac_dir / name, s)

    # Web icons
    web_targets = [
        ("web/icons/Icon-192.png", 192),
        ("web/icons/Icon-512.png", 512),
        ("web/icons/Icon-maskable-192.png", 192),
        ("web/icons/Icon-maskable-512.png", 512),
    ]
    for rel, s in web_targets:
        save_resized(base, REPO_ROOT / rel, s)

    # Windows icon (.ico) with multiple sizes
    win_ico_path = REPO_ROOT / "windows/runner/resources/app_icon.ico"
    win_ico_path.parent.mkdir(parents=True, exist_ok=True)
    ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    base.save(win_ico_path, sizes=ico_sizes)

    print("Generated icon and replaced platform launcher assets successfully.")
    print(f"Source icon: {source_png}")


if __name__ == "__main__":
    main()
