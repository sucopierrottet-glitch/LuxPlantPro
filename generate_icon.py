import math
import os
from PIL import Image, ImageDraw

def create_app_icon(output_path="assets/icon/app_icon.png"):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Base Background Squircle (Obsidian #0B0F19 to Slate #161F30)
    bg_margin = 32
    bg_radius = 220

    gradient_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(gradient_img)
    for y in range(size):
        ratio = y / size
        r = int(11 + (22 - 11) * ratio)
        g = int(15 + (31 - 15) * ratio)
        b = int(25 + (48 - 25) * ratio)
        grad_draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [bg_margin, bg_margin, size - bg_margin, size - bg_margin],
        radius=bg_radius,
        fill=255,
    )
    img.paste(gradient_img, (0, 0), mask)

    # Outer emerald glow rim
    draw.rounded_rectangle(
        [bg_margin, bg_margin, size - bg_margin, size - bg_margin],
        radius=bg_radius,
        outline=(16, 185, 129, 110),
        width=6,
    )

    cx, cy = 512, 540

    # 2. Photometer Dial Arc & Calibration Ticks
    dial_r = 350
    draw.arc(
        [cx - dial_r, cy - dial_r, cx + dial_r, cy + dial_r],
        start=145,
        end=395,
        fill=(30, 41, 59, 255),
        width=36,
    )
    # Active Emerald & Gold Photometric Arc
    draw.arc(
        [cx - dial_r, cy - dial_r, cx + dial_r, cy + dial_r],
        start=145,
        end=310,
        fill=(16, 185, 129, 255),
        width=36,
    )
    draw.arc(
        [cx - dial_r, cy - dial_r, cx + dial_r, cy + dial_r],
        start=310,
        end=375,
        fill=(245, 158, 11, 255),
        width=36,
    )

    # Radial degree ticks
    for deg in range(150, 391, 20):
        rad = math.radians(deg)
        r1 = dial_r - 58
        r2 = dial_r - 32
        x1, y1 = cx + r1 * math.cos(rad), cy + r1 * math.sin(rad)
        x2, y2 = cx + r2 * math.cos(rad), cy + r2 * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=(148, 163, 184, 200), width=6)

    # 3. Warm Gold Sun / Photon Source (Top Right)
    sun_x, sun_y = 665, 310
    sun_r = 68
    draw.ellipse(
        [sun_x - sun_r - 18, sun_y - sun_r - 18, sun_x + sun_r + 18, sun_y + sun_r + 18],
        fill=(245, 158, 11, 55),
    )
    draw.ellipse(
        [sun_x - sun_r, sun_y - sun_r, sun_x + sun_r, sun_y + sun_r],
        fill=(245, 158, 11, 255),
        outline=(254, 243, 199, 255),
        width=6,
    )
    for ray_deg in range(0, 360, 45):
        rad = math.radians(ray_deg)
        rx1 = sun_x + (sun_r + 16) * math.cos(rad)
        ry1 = sun_y + (sun_r + 16) * math.sin(rad)
        rx2 = sun_x + (sun_r + 38) * math.cos(rad)
        ry2 = sun_y + (sun_r + 38) * math.sin(rad)
        draw.line([(rx1, ry1), (rx2, ry2)], fill=(251, 191, 36, 255), width=8)

    # 4. Botanical Emerald Leaf Emblem (Centerpiece)
    leaf_pts = [
        (340, 720),
        (330, 560),
        (385, 430),
        (500, 350),
        (630, 360),
        (615, 505),
        (545, 635),
        (430, 710),
    ]
    shadow_pts = [(x + 8, y + 14) for (x, y) in leaf_pts]
    draw.polygon(shadow_pts, fill=(4, 12, 24, 190))
    draw.polygon(leaf_pts, fill=(16, 185, 129, 255), outline=(110, 231, 183, 255))

    # Central leaf vein & side ribs
    draw.line([(335, 730), (595, 385)], fill=(6, 78, 59, 255), width=12)
    draw.line([(415, 625), (365, 545)], fill=(6, 78, 59, 230), width=8)
    draw.line([(465, 555), (555, 575)], fill=(6, 78, 59, 230), width=8)
    draw.line([(510, 495), (445, 430)], fill=(6, 78, 59, 230), width=8)

    img.save(output_path, "PNG")
    print(f"Generated LuxPlant Pro icon successfully at {output_path}")

if __name__ == "__main__":
    create_app_icon()
