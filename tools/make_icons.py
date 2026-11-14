#!/usr/bin/env python3
"""Generate the resource icon atlases in Textures/ (requires Pillow).

Civ 6 loads loose, uncompressed 32-bit BGRA .dds files imported through the
modinfo's ImportFiles action, so no ModBuddy / texture pipeline is needed.

Every atlas is 4 columns x 2 rows; the cell order must match the Index values
in Data/Europa_Icons.xml. To use hand-made art instead, drop a 512x512 PNG
named after the resource key (e.g. art/topaz.png) and re-run.

Usage: python3 tools/make_icons.py [--preview preview.png]
"""
import math
import struct
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Textures"
ART = ROOT / "art"
S = 512                       # master cell size
COLS, ROWS = 4, 2
ORDER = ["topaz", "peacocks", "pallas_cats", "pygmy_rabbits",
         "tibetan_foxes", "discus_fish", "capybaras"]


def badge(d, fill, rim):
    d.ellipse([24, 24, S - 24, S - 24], fill=rim)
    d.ellipse([44, 44, S - 44, S - 44], fill=fill)


def eye(d, x, y, r=14, colour=(25, 20, 15)):
    d.ellipse([x - r, y - r, x + r, y + r], fill=colour)


def topaz(d):
    badge(d, (70, 52, 92), (232, 196, 120))
    top, mid, bot = 150, 230, 400
    outline = [(176, top), (336, top), (410, mid), (256, bot), (102, mid)]
    d.polygon(outline, fill=(244, 160, 40))
    d.polygon([(176, top), (336, top), (300, mid), (212, mid)], fill=(255, 214, 110))
    d.polygon([(102, mid), (176, top), (212, mid)], fill=(250, 186, 70))
    d.polygon([(410, mid), (336, top), (300, mid)], fill=(226, 136, 30))
    d.polygon([(212, mid), (300, mid), (256, bot)], fill=(255, 190, 80))
    d.polygon([(300, mid), (410, mid), (256, bot)], fill=(204, 112, 24))
    d.line(outline + [outline[0]], fill=(120, 60, 10), width=8)


def peacocks(d):
    badge(d, (24, 92, 84), (232, 196, 120))
    cx, cy = 256, 380
    for i in range(7):                                  # tail fan
        a = math.radians(200 + i * 23.3)
        x, y = cx + 250 * math.cos(a), cy + 250 * math.sin(a)
        d.line([(cx, cy), (x, y)], fill=(40, 160, 110), width=30)
        ex, ey = cx + 215 * math.cos(a), cy + 215 * math.sin(a)
        d.ellipse([ex - 30, ey - 30, ex + 30, ey + 30], fill=(230, 190, 60))
        d.ellipse([ex - 17, ey - 17, ex + 17, ey + 17], fill=(30, 70, 190))
    d.ellipse([206, 290, 306, 440], fill=(30, 80, 200))  # body
    d.rectangle([240, 220, 272, 320], fill=(30, 80, 200))  # neck
    d.ellipse([222, 186, 290, 254], fill=(30, 80, 200))  # head
    d.polygon([(286, 212), (326, 224), (286, 236)], fill=(240, 200, 80))
    eye(d, 262, 214, 8, (255, 255, 255))
    for dx in (-18, 0, 18):                             # crest
        d.line([(256, 190), (256 + dx, 150)], fill=(30, 80, 200), width=6)
        d.ellipse([248 + dx, 140, 264 + dx, 156], fill=(60, 200, 170))


def pallas_cats(d):
    badge(d, (86, 104, 122), (232, 196, 120))
    fur, dark = (176, 170, 158), (96, 90, 84)
    d.polygon([(110, 250), (96, 150), (190, 196)], fill=fur)    # low, wide ears
    d.polygon([(402, 250), (416, 150), (322, 196)], fill=fur)
    d.ellipse([84, 160, 428, 430], fill=fur)                    # broad flat face
    d.ellipse([70, 270, 190, 400], fill=fur)                    # cheek ruffs
    d.ellipse([322, 270, 442, 400], fill=fur)
    for x in (176, 336):
        d.ellipse([x - 38, 250, x + 38, 310], fill=(226, 204, 90))
        eye(d, x, 280, 13)
    d.polygon([(236, 330), (276, 330), (256, 356)], fill=(150, 90, 90))
    d.line([(256, 356), (256, 378)], fill=dark, width=6)
    d.arc([216, 356, 256, 400], 0, 180, fill=dark, width=6)
    d.arc([256, 356, 296, 400], 0, 180, fill=dark, width=6)
    for y in (196, 216):                                        # forehead spots
        for x in (226, 256, 286):
            d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=dark)
    for y in (322, 346):                                        # cheek stripes
        d.line([(96, y), (150, y + 8)], fill=dark, width=7)
        d.line([(416, y), (362, y + 8)], fill=dark, width=7)


def pygmy_rabbits(d):
    badge(d, (150, 134, 84), (232, 196, 120))
    fur, inner = (142, 118, 100), (214, 170, 160)
    for x in (206, 286):                                        # short upright ears
        d.ellipse([x - 34, 96, x + 34, 260], fill=fur)
        d.ellipse([x - 16, 124, x + 16, 240], fill=inner)
    d.ellipse([116, 250, 396, 440], fill=fur)                   # round body
    d.ellipse([156, 196, 356, 370], fill=fur)                   # head
    eye(d, 206, 276, 16)
    eye(d, 306, 276, 16)
    d.ellipse([200, 268, 208, 276], fill=(255, 255, 255))
    d.ellipse([300, 268, 308, 276], fill=(255, 255, 255))
    d.polygon([(240, 310), (272, 310), (256, 330)], fill=(190, 110, 120))
    d.ellipse([368, 356, 420, 408], fill=(236, 228, 214))       # tail


def tibetan_foxes(d):
    badge(d, (108, 132, 150), (232, 196, 120))
    tan, grey, white = (206, 150, 84), (150, 150, 150), (240, 234, 222)
    d.polygon([(132, 200), (150, 96), (214, 190)], fill=tan)    # ears
    d.polygon([(380, 200), (362, 96), (298, 190)], fill=tan)
    d.rounded_rectangle([110, 170, 402, 400], radius=56, fill=tan)   # square face
    d.rounded_rectangle([110, 262, 190, 400], radius=40, fill=grey)  # grey cheeks
    d.rounded_rectangle([322, 262, 402, 400], radius=40, fill=grey)
    d.polygon([(196, 300), (316, 300), (280, 410), (232, 410)], fill=white)  # muzzle
    d.ellipse([234, 384, 278, 420], fill=(30, 26, 24))          # nose
    for x in (186, 326):                                        # narrow, unimpressed eyes
        d.ellipse([x - 30, 250, x + 30, 274], fill=(236, 190, 70))
        d.ellipse([x - 9, 252, x + 9, 272], fill=(25, 20, 15))
        d.line([(x - 34, 246), (x + 34, 246)], fill=(120, 80, 40), width=8)


def discus_fish(d):
    badge(d, (34, 92, 140), (232, 196, 120))
    body, stripe = (244, 150, 50), (40, 110, 190)
    d.polygon([(372, 256), (446, 190), (430, 256), (446, 322)], fill=(250, 200, 90))  # tail
    d.polygon([(170, 150), (256, 96), (340, 150)], fill=(250, 200, 90))    # dorsal fin
    d.polygon([(170, 362), (256, 416), (340, 362)], fill=(250, 200, 90))   # anal fin
    d.ellipse([96, 126, 396, 386], fill=body)                              # disc body
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([96, 126, 396, 386], fill=255)
    stripes = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stripes)
    for x in (190, 240, 290, 340):
        sd.rectangle([x, 100, x + 20, 420], fill=stripe)
    d.bitmap((0, 0), Image.composite(stripes.split()[3], Image.new("L", (S, S), 0), mask), fill=stripe)
    d.ellipse([128, 216, 176, 264], fill=(255, 255, 255))
    eye(d, 152, 240, 13, (190, 30, 30))
    d.arc([92, 262, 132, 300], 300, 60, fill=(120, 60, 20), width=6)       # mouth


def capybaras(d):
    badge(d, (72, 124, 86), (232, 196, 120))
    fur, dark = (150, 104, 62), (86, 56, 34)
    d.rounded_rectangle([120, 236, 420, 400], radius=74, fill=fur)         # barrel body
    d.rounded_rectangle([84, 150, 270, 300], radius=56, fill=fur)          # blocky head
    d.rounded_rectangle([70, 196, 150, 292], radius=30, fill=(166, 120, 76))  # blunt snout
    d.ellipse([196, 126, 244, 174], fill=dark)                             # small ear
    eye(d, 176, 196, 12)
    d.ellipse([84, 214, 100, 230], fill=dark)                              # nostril
    d.line([(78, 262), (132, 268)], fill=dark, width=6)                    # mouth
    for x in (160, 230, 310, 372):                                         # short legs
        d.rounded_rectangle([x, 372, x + 40, 432], radius=14, fill=dark)


DRAW = {"topaz": topaz, "peacocks": peacocks, "pallas_cats": pallas_cats,
        "pygmy_rabbits": pygmy_rabbits, "tibetan_foxes": tibetan_foxes,
        "discus_fish": discus_fish, "capybaras": capybaras}


def cell(key):
    override = ART / f"{key}.png"
    if override.exists():
        return Image.open(override).convert("RGBA").resize((S, S), Image.LANCZOS)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    DRAW[key](ImageDraw.Draw(img))
    return img


def atlas(cells, size):
    sheet = Image.new("RGBA", (COLS * size, ROWS * size), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        sheet.paste(c.resize((size, size), Image.LANCZOS), ((i % COLS) * size, (i // COLS) * size))
    return sheet


def fog(img):
    r, g, b, a = img.split()
    grey = ImageEnhance.Brightness(Image.merge("RGB", (r, g, b)).convert("L").convert("RGB")).enhance(0.75)
    return Image.merge("RGBA", (*grey.split(), a))


def write_dds(img, path):
    """Uncompressed A8R8G8B8 DDS, no mipmaps."""
    w, h = img.size
    r, g, b, a = img.split()
    pixels = Image.merge("RGBA", (b, g, r, a)).tobytes()
    DDSD = 0x1 | 0x2 | 0x4 | 0x8 | 0x1000            # CAPS|HEIGHT|WIDTH|PITCH|PIXELFORMAT
    pixel_format = struct.pack("<II4sIIIII", 32, 0x41, b"\0\0\0\0", 32,
                               0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
    header = struct.pack("<4sIIIIIII44s", b"DDS ", 124, DDSD, h, w, w * 4, 0, 0, b"\0" * 44)
    header += pixel_format + struct.pack("<IIIII", 0x1000, 0, 0, 0, 0)
    assert len(header) == 128
    path.write_bytes(header + pixels)


def main():
    OUT.mkdir(exist_ok=True)
    cells = [cell(k) for k in ORDER]
    for size in (32, 38, 50, 64, 256):
        write_dds(atlas(cells, size), OUT / f"Europa_Resources{size}.dds")
    write_dds(atlas([fog(c) for c in cells], 256), OUT / "Europa_Resources256_FOW.dds")
    write_dds(atlas(cells, 22), OUT / "Europa_FontIcons22.dds")
    if "--preview" in sys.argv:
        atlas(cells, 256).save(sys.argv[sys.argv.index("--preview") + 1])
    print(f"wrote 7 atlases to {OUT}")


if __name__ == "__main__":
    main()
