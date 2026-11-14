---
name: civ6-add-resource
description: Add a new bonus, luxury or strategic resource to a Civilization VI mod, covering database rows, icons, text, map art and map placement. Use when asked to add, change or debug a resource in a Civ 6 mod.
---

# Adding a resource to a Civ 6 mod

A resource touches five game systems. Missing any one gives a resource that
half-works (no name, blank icon, never spawns). Do all five, then validate.

## 1. Gameplay database (UpdateDatabase)

Prefix the type (`RESOURCE_<MOD>_<NAME>`) so it cannot collide with other mods.

| Table | What it needs |
|---|---|
| `Types` | `Kind = 'KIND_RESOURCE'` |
| `Resources` | `Name`, `ResourceClassType` (`RESOURCECLASS_LUXURY` / `_BONUS` / `_STRATEGIC`), `Happiness` (4 for luxuries), `Frequency` (land) or `SeaFrequency` (water) |
| `Resource_ValidTerrains` | One row per terrain. Hills are separate terrains (`TERRAIN_PLAINS_HILLS`) |
| `Resource_ValidFeatures` | Woods = `FEATURE_FOREST`, rainforest = `FEATURE_JUNGLE`, plus `FEATURE_MARSH`, `FEATURE_FLOODPLAINS` |
| `Resource_YieldChanges` | Base yields |
| `Improvement_ValidResources` | Which improvement connects it; `MustRemoveFeature = 0` to keep woods/marsh |
| `TypeTags` | `CLASS_FOOD` / `CLASS_GOLD` / `CLASS_PRODUCTION` / `CLASS_CULTURE` ... matching the yields |

Rules learned from the game data:

- **Frequency** 2 is what stock land luxuries use. Water resources use
  `Frequency = 0` and `SeaFrequency > 0`.
- **Features are checked independently of terrain.** A resource valid on
  `FEATURE_FOREST` appears in woods on any terrain (stock Deer and Furs do this).
- **Gathering Storm splits floodplains** into `FEATURE_FLOODPLAINS`,
  `_GRASSLAND` and `_PLAINS`. To support every ruleset without modinfo criteria,
  insert with `INSERT ... SELECT ... FROM Features WHERE FeatureType IN (...)`
  and give the UpdateDatabase action `<LoadOrder>` above 0 so expansion rows exist
  first. The same trick works for optional `Tags`.
- **Lakes are `TERRAIN_COAST` plots with a lake flag.** There is no lake terrain
  and no lakes-only column. `LakeEligible` (default 1) only *allows* lakes. For a
  lakes-only resource set `Frequency = 0`, `SeaFrequency = 0`, valid terrain
  `TERRAIN_COAST`, and place it from a gameplay script (section 5).
- Luxuries need no `Resource_Harvests` row. Strategics need extra XP2 rows
  (`Resource_Consumption`); check an existing strategic first.
- Monopolies and Corporations mode needs its own rows per luxury (industry and
  corporation effects, products, project). See
  `DLC/KublaiKhan_Vietnam/Data/KublaiKhan_Vietnam_Monopolies_XP1_MODE.xml`.
  Without them the resource works but cannot host an Industry.

## 2. Text (UpdateText)

`<GameData><LocalizedText><Replace Tag="..." Language="en_US"><Text>`:

- `LOC_RESOURCE_<X>_NAME`
- `LOC_PEDIA_RESOURCES_PAGE_RESOURCE_<X>_CHAPTER_HISTORY_PARA_1` (Civilopedia)

## 3. Icons (UpdateIcons + ImportFiles)

- `IconTextureAtlases`: one atlas name with a row per size: 32, 38, 50, 64, 256.
  A second `_FOW` atlas at 256 (greyed) for fog of war.
- `IconDefinitions`: `ICON_RESOURCE_<X>` and `ICON_RESOURCE_<X>_FOW`.
- **Font icon** for inline `[ICON_RESOURCE_<X>]`: a 22px atlas with
  `Baseline="6"`, and a definition named `RESOURCE_<X>` (no `ICON_` prefix).
- Textures can be loose, uncompressed 32-bit BGRA `.dds` files listed under
  `ImportFiles`; no ModBuddy needed. `tools/make_icons.py` in this repo writes
  them from Pillow images.

## 4. Map art (UpdateArt)

- `ArtDefs/Resources.artdef`: one element per resource whose `Clutter` child
  names an existing clutter set by `XrefName` (`CLUTTER_DIAMONDS`, `CLUTTER_FURS`,
  `CLUTTER_DEER`, `CLUTTER_TRUFFLE`, `RES_FISH`, ...). Read the names out of
  `Base/ArtDefs/Resources.artdef`. Optional `Audio` child for ambient sound.
- `<Mod>.dep` lists the artdef under the `Resources` consumer and is the file the
  `UpdateArt` action points at.
- Reusing existing models is the only option on macOS. New models need the
  Windows-only ModBuddy asset tools; say so rather than promising new art.

## 5. Placement

The stock `ResourceGenerator.lua` picks luxuries per continent from every
`RESOURCECLASS_LUXURY` row with `Frequency > 0`, and coastal ones from
`SeaFrequency > 0`, testing each plot with `ResourceBuilder.CanHaveResource`.
New resources join automatically; do not replace the map script (it conflicts
with map-overhaul mods).

For rules the database cannot express, use an `AddGameplayScripts` Lua file that
runs once per game: guard with `Game:GetProperty` / `Game:SetProperty`, iterate
`Map.GetPlotByIndex`, test `plot:IsLake()` etc. and
`ResourceBuilder.CanHaveResource`, then `ResourceBuilder.SetResourceType(plot, index, 1)`.
Use `Game.GetRandNum(n, "label")` for multiplayer-safe randomness.

## Finish

Run the `civ6-validate-and-install` steps. Tell the user plainly which parts were
checked offline and which still need an in-game look (art and placement always do).
