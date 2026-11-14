---
name: civ6-change-map-generation
description: Change how Civilization VI generates maps from a mod (terrain bands, desert or tundra size, features, resource or start placement) by hooking the map-generation Lua. Use when asked to alter terrain, climate, land shape or placement rules at map creation, or to debug a mod that replaces a map utility file.
---

# Changing map generation in a Civ 6 mod

## Pick the layer first

| Layer | When it runs | Use for |
|---|---|---|
| Database rows | Read by the generators | Frequencies, valid terrains, start biases. Always prefer this if the rule can be expressed |
| Map-generation Lua | While the map is built | Terrain, features, anything later steps must see (rivers, floodplains, resources, start biases) |
| Gameplay script | After the map and start positions exist | Adding a few things to a finished map (see the lake resources script) |

Changing terrain after generation leaves resources, features and start positions
that were chosen for the old terrain. Terrain changes belong in the map-generation
layer.

## How the stock generators work

- Map scripts are in `Base/Assets/Maps/` and `DLC/Expansion2/Maps/`; shared steps
  are in `Maps/Utility/`. A script `include`s utilities by bare name and calls
  their global functions.
- `TerrainGenerator.lua`: `GenerateTerrainTypes` builds a 0-based `terrainTypes`
  table from latitude bands and two fractals, then `ApplyBaseTerrain(plotTypes,
  terrainTypes, iW, iH)` writes it to the map. All 14 Gathering Storm scripts
  call `ApplyBaseTerrain`, so it is the one choke point for terrain.
- Desert = top `iDesertPercent` of a fractal (25 stock, shifted 16 by the
  temperature option) inside a latitude band (0.2 to 0.5). Raising the percent
  enlarges deserts but also creates new small ones; to grow without adding, dilate
  the existing desert tiles instead.
- In `terrainTypes`, hills still hold the flat terrain type; `ApplyBaseTerrain`
  adds 1 for hills. Mountains have their own types. Water is `plotTypes[i] ==
  g_PLOT_TYPE_OCEAN`.
- Use `TerrainBuilder.GetRandomNumber(n, "label")` for randomness in map
  generation and keep iteration order deterministic (multiplayer builds the same
  map on every machine).

## Hooking

There is no way to extend a utility in place. A mod replaces the whole file by
`ImportFiles`-ing one with the same name:

- Give the action a `LoadOrder` above the file's other providers (expansions
  import at the default; BBS uses 1000 to 1001) and a `criteria` for the ruleset
  the copy came from. The base-game and Gathering Storm versions of a utility
  differ (base has no `ApplyBaseTerrain`).
- **Do not hand-edit the copy.** Generate it: stock file verbatim plus an appended
  block that `include`s the mod's own file and wraps a global function
  (`local stock = ApplyBaseTerrain; function ApplyBaseTerrain(...) ... return
  stock(...) end`). See `tools/make_terrain_override.py`; its `--check` mode fails
  when a game patch changes the original.
- Wrap the mod's step in `pcall` so a fault can never stop a map generating.
- Re-including the file is safe: it redefines the stock function before wrapping.

## Other mods

Check what the user's map mods do before choosing a hook (`grep` their `.modinfo`
and map scripts). On this machine the BBS map scripts include the stock
`TerrainGenerator` and call `ApplyBaseTerrain`, so a wrap there covers them; their
"DW" scripts and PerfectWorld define their own terrain step and are not covered.
Any mod that replaces the same file conflicts; say so.

## Testing

- Firaxis Lua uses typed-Lua syntax (`local x : number = 1`), so stock files do
  not compile in standard Lua. Keep mod logic in its own plain-Lua file with
  injectable neighbour and random functions.
- No Lua is installed here. `pip install lupa` in a scratch venv gives a Lua
  runtime for Python; `tools/test_desert_growth.py` stubs `Map`,
  `TerrainBuilder` and the enums and runs the real hook on synthetic hex maps.
- Hex neighbours: rows are offset, odd rows shifted right.
- Assert the user's rule directly (for example "the number of deserts never goes
  up") rather than eyeballing output.

Real map results (how much bigger, effect on starts) can only be judged in-game:
generate a few maps with and without the mod and look. Say this when reporting.
