#!/usr/bin/env python3
"""Turn a subject SVG into a finished Civ 6 style resource icon cell (requires Pillow + Google Chrome).

    compose_icon.py SUBJECT.svg OUT.png [--kind luxury|bonus] [--bust-from Y] [--outline PX] [--size 512]

SUBJECT.svg: the subject only, viewBox "0 0 256 256", transparent background, positioned
where it should sit in the cell. The script rasterises it with headless Chrome, draws the
stock octagonal frame behind it, and adds the dark silhouette outline.

--bust-from Y  below row Y (256 space) the subject is clipped to the frame interior, the
               way stock busts (Deer, Truffles) end flat on the bottom border.
"""
import argparse
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
M = 1024                        # working size; stock cell is 256
K = M // 256
DARK = (33, 33, 33)
# Stock frame, measured on the base-game Resources256 atlas (256 px cell).
OCT = [(72, 33), (184, 33), (221, 70), (221, 184), (193, 223), (63, 223), (35, 184), (35, 70)]
BORDER = 12
FILL = {"luxury": ((60, 36, 76), (48, 17, 64)), "bonus": ((113, 85, 8), (76, 60, 19))}
FILL_ALPHA = 153


def inset(poly, d):
    """Offset a convex clockwise polygon inward by d."""
    n = len(poly)
    lines = []
    for i in range(n):
        (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % n]
        dx, dy = x1 - x0, y1 - y0
        ln = (dx * dx + dy * dy) ** 0.5
        nx, ny = -dy / ln, dx / ln                     # inward normal for clockwise (y down)
        lines.append((x0 + nx * d, y0 + ny * d, dx, dy))
    out = []
    for i in range(n):
        ax, ay, adx, ady = lines[i - 1]
        bx, by, bdx, bdy = lines[i]
        t = ((bx - ax) * bdy - (by - ay) * bdx) / (adx * bdy - ady * bdx)
        out.append((ax + adx * t, ay + ady * t))
    return out


def frame(kind):
    S = 2                                              # extra supersample for clean edges
    big = M * S
    outer = Image.new("L", (big, big), 0)
    ImageDraw.Draw(outer).polygon([(x * K * S, y * K * S) for x, y in OCT], fill=255)
    inner = Image.new("L", (big, big), 0)
    ImageDraw.Draw(inner).polygon([(x * K * S, y * K * S) for x, y in inset(OCT, BORDER)], fill=255)
    outer, inner = outer.resize((M, M), Image.LANCZOS), inner.resize((M, M), Image.LANCZOS)
    top, bot = FILL[kind]
    grad = Image.new("RGB", (1, M))
    y0, y1 = 45 * K, 211 * K
    for y in range(M):
        t = min(1, max(0, (y - y0) / (y1 - y0)))
        grad.putpixel((0, y), tuple(round(a * (1 - t) + b * t) for a, b in zip(top, bot)))
    grad = grad.resize((M, M))
    rgb = Image.composite(grad, Image.new("RGB", (M, M), DARK), inner)
    # alpha: 255 on the border, FILL_ALPHA inside
    alpha = ImageChops.subtract(outer, inner.point(lambda v: v * (255 - FILL_ALPHA) // 255))
    img = rgb.convert("RGBA")
    img.putalpha(alpha)
    return img, inner, outer


def rasterise(svg, png):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", f"--window-size={M},{M}",
                    f"--screenshot={png}", f"file://{Path(svg).resolve()}"],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def compose(svg, kind="luxury", bust_from=None, outline=5):
    with tempfile.TemporaryDirectory() as tmp:
        png = Path(tmp) / "subject.png"
        rasterise(svg, png)
        art = Image.open(png).convert("RGBA").resize((M, M), Image.LANCZOS)
    base, inner, outer = frame(kind)
    limit = None
    if bust_from is not None:
        top = Image.new("L", (M, M), 0)
        ImageDraw.Draw(top).rectangle([0, 0, M, int(bust_from * K)], fill=255)
        art.putalpha(ImageChops.multiply(art.getchannel("A"), ImageChops.lighter(top, inner)))
        limit = ImageChops.lighter(top, outer)
    solid = art.getchannel("A").point(lambda v: 255 if v > 100 else 0)
    r = outline * K
    ol = solid.filter(ImageFilter.GaussianBlur(r / 2)).point(lambda v: 255 if v > 8 else 0)   # cheap dilate
    ol = ol.filter(ImageFilter.MaxFilter(2 * (r // 2) + 1)).filter(ImageFilter.GaussianBlur(K / 2))
    if limit is not None:
        ol = ImageChops.multiply(ol, limit)
    out = base.copy()
    out.paste(Image.new("RGBA", (M, M), DARK + (255,)), (0, 0), ol)
    out.alpha_composite(art)
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("svg"); ap.add_argument("out")
    ap.add_argument("--kind", default="luxury", choices=sorted(FILL))
    ap.add_argument("--bust-from", type=float)
    ap.add_argument("--outline", type=int, default=5)
    ap.add_argument("--size", type=int, default=512)
    a = ap.parse_args()
    compose(a.svg, a.kind, a.bust_from, a.outline).resize((a.size, a.size), Image.LANCZOS).save(a.out)
    print("wrote", a.out)
