#!/usr/bin/env python3
"""Pack the resource icon atlases in Textures/ from the finished cells in art/ (requires Pillow).

Civ 6 loads loose, uncompressed 32-bit BGRA .dds files imported through the
modinfo's ImportFiles action, so no ModBuddy / texture pipeline is needed.

Every atlas is 4 columns x 2 rows; the cell order must match the Index values
in Data/Europa_Icons.xml. Each cell comes from art/<key>.png (square, 512 px),
which is the frame + outlined subject built from art/resources/<key>.svg. How
those are drawn and composed is described in the civ6-make-icons skill.

Usage: python3 tools/make_icons.py [--preview preview.png]
"""
import struct
import sys
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Textures"
ART = ROOT / "art"
S = 512                       # master cell size
COLS, ROWS = 4, 2
ORDER = ["topaz", "peacocks", "pallas_cats", "pygmy_rabbits",
         "tibetan_foxes", "discus_fish", "capybaras"]


def cell(key):
    return Image.open(ART / f"{key}.png").convert("RGBA").resize((S, S), Image.LANCZOS)


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
