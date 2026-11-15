#!/usr/bin/env python3
"""Generate the pantheon icon atlases in Textures/ (requires Pillow).

Simple one-colour glyphs on a transparent background, like the stock pantheon
icons. The atlas is 4 columns x 2 rows; the cell order must match the Index
values in Data/Europa_Pantheons_Icons.xml. To use hand-made art instead, drop a
512x512 PNG named after the key (e.g. art/pantheon_first_settlers.png) and re-run.

Usage: python3 tools/make_pantheon_icons.py [--preview preview.png]
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_icons import ART, OUT, S, atlas, write_dds  # noqa: E402

ORDER = ["first_settlers", "sacred_companions", "new_realm_guilds",
         "sacred_wilderness", "artistic_inspiration", "pillars_of_creation"]
INK = (238, 228, 200, 255)
CLEAR = (0, 0, 0, 0)


def first_settlers(d):
    """A hearth: a flame over two crossed logs."""
    d.polygon([(256, 60), (330, 190), (356, 280), (320, 350), (256, 372),
               (192, 350), (156, 280), (190, 200), (226, 250)], fill=INK)
    d.polygon([(256, 230), (296, 300), (256, 340), (216, 300)], fill=CLEAR)
    d.line([(110, 400), (402, 462)], fill=INK, width=44)
    d.line([(402, 400), (110, 462)], fill=INK, width=44)


def sacred_companions(d):
    """A paw print."""
    d.ellipse([156, 250, 356, 440], fill=INK)
    for cx, cy, rx, ry in ((120, 240, 40, 54), (206, 150, 42, 58), (306, 150, 42, 58), (392, 240, 40, 54)):
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=INK)


def new_realm_guilds(d):
    """A merchant's balance."""
    d.rectangle([242, 90, 270, 420], fill=INK)
    d.rectangle([170, 420, 342, 452], fill=INK)
    d.line([(96, 150), (416, 150)], fill=INK, width=26)
    d.ellipse([228, 62, 284, 118], fill=INK)
    for cx in (110, 402):
        d.line([(cx, 150), (cx - 62, 300)], fill=INK, width=10)
        d.line([(cx, 150), (cx + 62, 300)], fill=INK, width=10)
        d.pieslice([cx - 74, 226, cx + 74, 374], 0, 180, fill=INK)


def sacred_wilderness(d):
    """A pine in front of a mountain."""
    d.polygon([(250, 430), (380, 170), (480, 430)], fill=INK)
    d.polygon([(380, 170), (352, 226), (380, 250), (408, 226)], fill=CLEAR)
    d.polygon([(40, 440), (180, 40), (320, 440)], fill=CLEAR)        # gap around the tree
    for top, half, bottom in ((60, 78, 200), (140, 104, 300), (230, 128, 410)):
        d.polygon([(180, top), (180 - half, bottom), (180 + half, bottom)], fill=INK)
    d.rectangle([164, 410, 196, 466], fill=INK)


def artistic_inspiration(d):
    """A painter's palette."""
    d.ellipse([56, 110, 456, 420], fill=INK)
    d.ellipse([300, 300, 400, 380], fill=CLEAR)                     # thumb hole
    for i in range(5):                                              # paint wells
        a = math.radians(150 + i * 42)
        x, y = 256 + 140 * math.cos(a), 265 + 100 * math.sin(a)
        d.ellipse([x - 26, y - 26, x + 26, y + 26], fill=CLEAR)


def pillars_of_creation(d):
    """Three columns under a lintel."""
    d.rectangle([70, 90, 442, 138], fill=INK)
    d.rectangle([70, 404, 442, 452], fill=INK)
    for cx in (130, 256, 382):
        d.rectangle([cx - 46, 138, cx + 46, 168], fill=INK)
        d.rectangle([cx - 30, 168, cx + 30, 374], fill=INK)
        d.rectangle([cx - 46, 374, cx + 46, 404], fill=INK)
        d.line([(cx, 186), (cx, 356)], fill=CLEAR, width=10)


DRAW = {f.__name__: f for f in (first_settlers, sacred_companions, new_realm_guilds,
                                sacred_wilderness, artistic_inspiration, pillars_of_creation)}


def cell(key):
    override = ART / f"pantheon_{key}.png"
    if override.exists():
        return Image.open(override).convert("RGBA").resize((S, S), Image.LANCZOS)
    img = Image.new("RGBA", (S, S), CLEAR)
    DRAW[key](ImageDraw.Draw(img))
    return img


def main():
    OUT.mkdir(exist_ok=True)
    cells = [cell(k) for k in ORDER]
    for size in (32, 50, 64, 256):
        write_dds(atlas(cells, size), OUT / f"Europa_Pantheons{size}.dds")
    if "--preview" in sys.argv:
        atlas(cells, 256).save(sys.argv[sys.argv.index("--preview") + 1])
    print(f"wrote 4 atlases to {OUT}")


if __name__ == "__main__":
    main()
