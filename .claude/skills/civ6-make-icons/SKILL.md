---
name: civ6-make-icons
description: Draw a Civilization VI resource icon that sits acceptably next to the stock ones, by tracing a reference photo into a hand-written SVG subject and composing it on the measured stock frame. Use when adding or redrawing a resource icon in a Civ 6 mod, or when asked why a mod icon looks out of place.
---

# Civ 6 style resource icons

There is no image-generation model here; subjects are hand-written SVG. That gets
"clearly belongs to the set", not Firaxis-painter quality. Say so up front.

## 1. Look at the real icons first

Stock UI textures are inside `$GAME/<Base|DLC/Pack>/Platforms/Windows/BLPs/UI/Icons.blp`
(`$GAME` as in `civ6-reference-lookup`), readable without Windows tools:

- Header: `"CIVBLP"`, u16 version, then u32s: package offset (1024), package size,
  **big-data offset**, ... Pixel data starts at the big-data offset.
- Every atlas named in the icon XML is a "page": raw **RGBA8**, top row first,
  followed by its full mip chain to 1x1; the next page starts on the next 512-byte
  boundary. Pages are in page-index order. A texture's record sits just before its
  name string: `flags u32, page u32, x u16, y u16, w u16, h u16, hash u32, 0 u32,
  len+1 u32, len u32, name`.
- Base game: page 0 `UnitActions256` (2048x3072), page 1 `Resources256` (2048x2048,
  8x8 cells). `DLC/GranColombia_Maya`: `MayaGran_Resources256` (512x256) is page 0.

Extract to the scratchpad and compare at the same scale. Reference only: never put
Firaxis art in the repo or the mod.

## 2. The frame (measured over the 51 base-game cells, 256 px cell)

- Octagon, outer points `(72,33) (184,33) (221,70) (221,184) (193,223) (63,223)
  (35,184) (35,70)`: 45 degree top corners, steeper bottom corners.
- 12 px border, flat opaque `rgb(33,33,33)`.
- Fill is a vertical gradient at **alpha 153**: luxury `rgb(60,36,76)` ->
  `rgb(48,17,64)`; bonus `rgb(113,85,8)` -> `rgb(76,60,19)`. Strategic: unmeasured.
- The subject is drawn over the frame with a ~5 px outline in the same
  `rgb(33,33,33)`, and usually breaks out of the frame; it fills 80-95% of the cell.
  Busts are instead cut flat on the frame's inner bottom edge.
- No round badge, no coloured rim, no background scene, no glow.

`scripts/compose_icon.py SUBJECT.svg OUT.png [--kind bonus] [--bust-from Y]` builds
all of this around a subject (Pillow + headless Chrome, the only SVG renderer here).

## 3. The subject: the style the user accepted

After six rounds the user chose the plain traced drawing ("something close to B1").
Recipe, with `art/resources/tibetan_foxes.svg` and `capybaras.svg` as models:

1. **Trace, do not freehand.** `scripts/trace_grid.py PHOTO x0 y0 x1 y1 cx0 cy0 cx1 OUT`
   resamples the photo crop into the 256 cell (crop left edge lands at `cx0`, right
   at `cx1`, top at `cy0`) with a labelled 10 px grid. Read outline, joint, eye and
   nose positions off the grid and write the paths from those numbers. Let the
   subject overflow the frame on at least one side.
2. SVG `viewBox="0 0 256 256"`, transparent, **subject only**. One path per body
   part, drawn back to front, far limbs darker.
3. Colour: the animal's own colours from the photo, slightly warmed. Per part: a flat
   base fill, then lighter shapes on top surfaces and darker shapes underneath,
   clipped to the part and blurred 1.2-4.5 px (`feGaussianBlur`).
4. Short fur ticks (1.4 px strokes, lighter on the back, darker on the flank).
5. Line art `#2b211c`, 1.8 px, only where forms overlap (haunch, shoulder, jaw).
6. Eyes and nose last, small and dark with one white glint.
7. Wrap everything in `feTurbulence` (0.09, 2 octaves) + `feDisplacementMap`
   scale 2.2 so edges look hand-made.
8. Gems and other hard objects: facet polygons in 5-6 tints of one hue, pale edge
   lines, one sparkle. Accepted first time (`topaz.svg`).

Then: compose -> `art/<key>.png` -> `python3 tools/make_icons.py` -> `tools/validate.sh`.
Always review at 64 and 32 px beside a stock icon before showing the user.

## 4. What was tried and rejected (do not repeat)

| Attempt | User's verdict |
|---|---|
| Flat shapes on a round gold badge | Not Civ 6 style |
| Photo cut-out + oil or posterise filter | Blurry / blotchy photo (my own rejection) |
| Photo under the drawing as a fill | "shading is wrong", colours off |
| Stock fox's exact palette + every part dome-lit | "so much worse", "way too 3D"; hues should fit the theme, not be copied |
| Front-on face with detailed irises | "creepier" |
| Flat tones, three-quarter head, soft bands | "I don't like this" |
| Bold lines + vivid orange (cel look) | "closest" of ten, then dropped in favour of B1 |

## 5. Working with the user on art

- Show every candidate beside a stock icon, large and at in-game sizes.
- When the answer is "no" without a reason, stop refining. Show ~10 options with
  **a lot of variety** (poses x styles), each labelled with what it changes; eight
  tweaks of one drawing is not variety.
- Do not chase stock fidelity past what was asked: three rounds of "closer to
  stock" each scored worse than the simple first drawing.
