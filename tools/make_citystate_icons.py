#!/usr/bin/env python3
"""Generate the city-state icon atlases in Textures/ (requires Pillow).

Stock city-state icons are plain white emblems on a transparent background; the
game draws them over the city-state type's colour. These are simple placeholder
emblems in that style. Every atlas is 4 columns x 2 rows; the cell order must
match the Index values in Data/Europa_CityStates_Icons.xml. To use hand-made art
instead, drop a 512x512 PNG named after the key (e.g. art/syracuse.png) and re-run.

Usage: python3 tools/make_citystate_icons.py [--preview preview.png]
       python3 tools/make_citystate_icons.py --check   # fail if Textures/ is out of date
"""
import math
import sys

from PIL import Image, ImageDraw

from make_icons import ART, OUT, S, atlas, write_dds

ORDER = ["syracuse", "ubud", "sheffield", "ravenna", "lhasa", "bruges"]
SIZES = (22, 30, 32, 36, 44, 45, 48, 50, 64, 80, 128, 200, 256)   # the stock city-state atlas sizes
W = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)


def syracuse(d):
    """A cog: applied engineering."""
    cx = cy = 256
    for i in range(8):
        a = math.radians(i * 45)
        c, s = math.cos(a), math.sin(a)
        d.polygon([(cx + 120 * c - 38 * s, cy + 120 * s + 38 * c), (cx + 200 * c - 30 * s, cy + 200 * s + 30 * c),
                   (cx + 200 * c + 30 * s, cy + 200 * s - 30 * c), (cx + 120 * c + 38 * s, cy + 120 * s - 38 * c)], fill=W)
    d.ellipse([cx - 150, cy - 150, cx + 150, cy + 150], fill=W)
    d.ellipse([cx - 62, cy - 62, cx + 62, cy + 62], fill=CLEAR)


def ubud(d):
    """A tree: art in nature."""
    d.ellipse([116, 60, 396, 340], fill=W)
    d.ellipse([70, 170, 270, 370], fill=W)
    d.ellipse([242, 170, 442, 370], fill=W)
    d.polygon([(226, 330), (286, 330), (306, 452), (206, 452)], fill=W)


def sheffield(d):
    """An anvil: masters of steel."""
    d.polygon([(70, 150), (400, 150), (400, 196), (450, 196), (450, 236), (330, 250), (300, 300), (212, 300), (190, 250), (70, 190)], fill=W)
    d.rectangle([212, 300, 300, 370], fill=W)
    d.polygon([(170, 370), (342, 370), (386, 440), (126, 440)], fill=W)


def ravenna(d):
    """A crenellated tower with an arched gate: imperial engineering."""
    d.rectangle([136, 170, 376, 450], fill=W)
    for x in (116, 216, 316):
        d.rectangle([x, 80, x + 80, 190], fill=W)
    d.rectangle([116, 150, 396, 200], fill=W)
    d.ellipse([206, 280, 306, 380], fill=CLEAR)
    d.rectangle([206, 330, 306, 452], fill=CLEAR)


def lhasa(d):
    """Two peaks with a snow line: mountain monasteries."""
    d.polygon([(40, 440), (200, 130), (360, 440)], fill=W)
    d.polygon([(210, 440), (340, 210), (472, 440)], fill=W)
    d.polygon([(154, 220), (200, 130), (246, 220), (222, 256), (200, 226), (178, 256)], fill=CLEAR)
    d.polygon([(200, 130), (236, 200), (164, 200)], fill=W)


def bruges(d):
    """A stepped-gable merchant's house: mercantile renaissance."""
    steps = [(136, 452), (136, 250), (176, 250), (176, 200), (216, 200), (216, 150), (236, 150), (236, 90),
             (276, 90), (276, 150), (296, 150), (296, 200), (336, 200), (336, 250), (376, 250), (376, 452)]
    d.polygon(steps, fill=W)
    d.rectangle([226, 360, 286, 452], fill=CLEAR)
    for x in (170, 292):
        d.rectangle([x, 286, x + 50, 336], fill=CLEAR)
    d.rectangle([236, 196, 276, 246], fill=CLEAR)


DRAW = {"syracuse": syracuse, "ubud": ubud, "sheffield": sheffield, "ravenna": ravenna, "lhasa": lhasa, "bruges": bruges}


def cell(key):
    override = ART / f"{key}.png"
    if override.exists():
        return Image.open(override).convert("RGBA").resize((S, S), Image.LANCZOS)
    img = Image.new("RGBA", (S, S), CLEAR)
    DRAW[key](ImageDraw.Draw(img))
    return img


def main():
    OUT.mkdir(exist_ok=True)
    cells = [cell(k) for k in ORDER]
    if "--check" in sys.argv:
        tmp = OUT / ".check.dds"
        stale = []
        for size in SIZES:
            write_dds(atlas(cells, size), tmp)
            path = OUT / f"Europa_CityStates{size}.dds"
            if not path.exists() or path.read_bytes() != tmp.read_bytes():
                stale.append(path.name)
        tmp.unlink()
        if stale:
            print("OUT OF DATE (run tools/make_citystate_icons.py):", ", ".join(stale))
            sys.exit(1)
        print("city-state icon atlases match the generator")
        return
    for size in SIZES:
        write_dds(atlas(cells, size), OUT / f"Europa_CityStates{size}.dds")
    if "--preview" in sys.argv:
        sheet = Image.new("RGBA", atlas(cells, 256).size, (40, 70, 110, 255))   # dark backing so white shows
        sheet.alpha_composite(atlas(cells, 256))
        sheet.save(sys.argv[sys.argv.index("--preview") + 1])
    print(f"wrote {len(SIZES)} atlases to {OUT}")


if __name__ == "__main__":
    main()
