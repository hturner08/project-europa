"""grid.py photo x0 y0 x1 y1 cx0 cy0 cx1 out : enlarge a photo crop with a grid labelled in 256-cell coords."""
import sys
from PIL import Image, ImageDraw
p, x0, y0, x1, y1, cx0, cy0, cx1, out = sys.argv[1:]
x0, y0, x1, y1, cx0, cy0, cx1 = map(float, (x0, y0, x1, y1, cx0, cy0, cx1))
s = (cx1 - cx0) / (x1 - x0)            # photo px -> cell px
Z = 6                                   # cell px -> output px
im = Image.open(p).convert("RGB")
# output covers whole 256 cell
out_im = Image.new("RGB", (256 * Z, 256 * Z), (40, 40, 40))
crop = im.crop((int(x0 - cx0 / s), int(y0 - cy0 / s), int(x0 + (256 - cx0) / s), int(y0 + (256 - cy0) / s)))
out_im.paste(crop.resize((256 * Z, 256 * Z), Image.LANCZOS))
d = ImageDraw.Draw(out_im)
for v in range(0, 257, 10):
    c = (255, 255, 0) if v % 50 == 0 else (255, 255, 255)
    w = 2 if v % 50 == 0 else 1
    d.line([(v * Z, 0), (v * Z, 256 * Z)], fill=c, width=w)
    d.line([(0, v * Z), (256 * Z, v * Z)], fill=c, width=w)
    if v % 20 == 0:
        for k in (0, 100, 200):
            d.text((v * Z + 2, k * Z + 2), str(v), fill=(255, 0, 255), font_size=16)
            d.text((k * Z + 2, v * Z + 2), str(v), fill=(0, 255, 255), font_size=16)
out_im.save(out)
print("scale", s)
