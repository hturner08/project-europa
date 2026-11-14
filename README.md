# Project Europa

A Civilization VI mod: seven luxury resources, the Fish Weir, bigger deserts, and
eight custom leaders balanced against Better Balanced Game 7.5.1.

Every change is listed, BBG-style, at https://hturner08.github.io/project-europa/
(GitHub Pages serves the `docs/` folder of `main`; edit `docs/index.html` and push).

## Luxury resources

| Resource | Terrain | Improvement | Base yield |
|---|---|---|---|
| Topaz | Hills (grass, plains, desert, tundra) | Mine | +3 Gold |
| Peacocks | Grassland, Plains, Woods | Camp | +1 Culture, +1 Gold |
| Pallas's Cats | Plains / Grassland / Tundra Hills | Camp | +1 Culture, +1 Gold |
| Pygmy Rabbits | Plains, Plains Hills | Camp | +1 Food, +1 Culture |
| Tibetan Foxes | Plains / Tundra / Desert Hills | Camp | +1 Culture, +1 Production |
| Discus Fish | Lakes | Fish Weir (new) | +1 Culture, +1 Gold |
| Capybaras | Marsh, Floodplains | Camp | +1 Food, +1 Culture |

All give +4 Amenities like standard luxuries. The **Fish Weir** is a new improvement
that can only be built on Discus Fish; it unlocks at Sailing and has the same stats
and later-era upgrades as Fishing Boats (+1 Food, 0.5 Housing). Works with the base game and both
expansions; the Gathering Storm floodplain variants are picked up automatically.

## Bigger deserts

Every desert the map generator lays out is grown outward: one guaranteed ring of
tiles, plus a ragged second ring where each tile has a 50% chance. Only grassland
and plains next to an existing desert convert, so the number of deserts never goes
up (close neighbours can merge), and tundra, snow and water are never touched.
Because it runs during map generation, rivers, floodplains, resources and start
biases all see the larger deserts. Tune it in `Maps/Europa_DesertGrowth.lua`
(`FullRings`, `PartialRingChance`).

Requires the Gathering Storm ruleset. Works with the stock map scripts and the BBS
ones that use the standard terrain step.

## Custom leaders

Eight new, separately selectable leaders. Each replaces only the leader ability;
the civilization ability and uniques are whatever the loaded ruleset (stock or
BBG) defines. Gathering Storm ruleset only. BBG is optional.

| Leader | Civilization | Ability |
|---|---|---|
| Golden Expansion | Mali | Settlers cost 10% less Gold. Domestic Trade Routes sent from a Suguba city give +2 Production. +1 Trade Route capacity per continent with three cities you founded (max +4). |
| Imperial Gardens | China | +1 Appeal on every tile of a city with a Wonder. In a Grove city, +5% Wonder Production per Breathtaking tile next to the Wonder being built (max +20%). Great Wall next to Great Wall: +1 Faith. |
| Highland Empire | Ethiopia | Cities you found on Hills: +1 Production, +10% toward Settlers, +25% toward districts until the first specialty district is complete. |
| Living Paradise | Brazil | Unimproved Rainforest next to a Preserve: +1 Culture after Medieval Faires. Cities with three Rainforest tiles: +10% Wonder Production. In a city with a Wonder, Rainforest gives +1 more Appeal to adjacent tiles. |
| Borderless Empire | Cree | Settlers +1 sight. The first Trade Route from each city you found claims up to two unowned tiles near it. International Trade Routes from a city with a Camp or Pasture: +2 Food, +1 Production. |
| Endless Continent | Russia | Lavra cities: +20% toward Settlers. Cities founded on Tundra or Tundra Hills get a free Builder. Tundra Woods: +1 Food. |
| Scenic Genius | America | +30% toward Preserves. +10% toward a Wonder next to a Breathtaking tile. Unimproved Breathtaking tiles next to a Wonder: +1 Culture. +1 Appeal on every tile of a city with a National Park. |
| Palace Designer | France | +1 Appeal on every tile of a city where a Château is next to a Wonder or Preserve. Châteaux next to a Wonder or Preserve: +1 Production. +10% toward a Wonder next to a Château. |

Where these differ from the original design brief, and why, is on the changes
page. In short: Civ VI has no per-tile Appeal modifier (so Appeal effects are
per city), and domestic trade route yields go to the sending city.

**Renaming a leader:** edit its `LOC_LEADER_EUROPA_*_NAME` row at the top of
`Text/Europa_Leaders_Text_en_US.xml`. Nothing else refers to the display name.

**Some effects are worked out by script** (`Scripts/Europa_Leaders.lua`): Mali's
continents, the Wonder-site checks (China, America, France), whether a city has
a Château beside a Wonder or Preserve (France) or a Camp or Pasture (Cree), and the Cree tile claim. The
script writes a number onto a city-centre plot and modifiers read it back; the
tile claim it does itself. It only uses simulation-side events, so values
refresh at the start of the owner's turn.

## Layout

| Path | Purpose |
|---|---|
| `ProjectEuropa.modinfo` | Mod manifest: which file feeds which game system |
| `Data/Europa_Resources.sql` | Gameplay database rows (resources and the Fish Weir improvement) |
| `Data/Europa_Icons.xml` | Icon atlas and icon definitions |
| `Text/Europa_Text_en_US.xml` | Names and Civilopedia text |
| `Data/Europa_LeaderCommon.sql`, `Data/Europa_Leader_<Civ>.sql` | Leader gameplay rows, one file per leader so a missing DLC only drops that leader |
| `Config/Europa_Leaders_Config.sql` | Game-setup rows (what makes the leaders selectable); copies civilization columns from the stock leader |
| `Data/Europa_Leaders_Icons.xml`, `Data/Europa_Leaders_Colors.xml` | Leader icons (reusing stock atlases) and jersey colours |
| `Text/Europa_Leaders_Text_en_US.xml` | Leader names, ability text, loading-screen text |
| `Scripts/Europa_Leaders.lua` | Continents (Mali), Wonder sites (China, America, France), city improvement flags (France, Cree), Cree tile claims |
| `ArtDefs/Leaders.artdef`, `ArtDefs/FallbackLeaders.artdef` | Generated: stock leaders' art entries under our names (do not edit; run `tools/make_leader_art.py`) |
| `docs/index.html` | The changes page |
| `Scripts/Europa_LakeResources.lua` | Places Discus Fish on lakes at game start |
| `Maps/Europa_DesertGrowth.lua` | Desert growth logic |
| `Maps/Utility/TerrainGenerator.lua` | Generated: the stock Gathering Storm file plus a hook (do not edit; run `tools/make_terrain_override.py`) |
| `ArtDefs/*.artdef`, `ProjectEuropa.dep` | Map models, borrowed from existing resources and Fishing Boats |
| `Textures/*.dds` | Generated icon atlases (do not edit; run `tools/make_icons.py`) |
| `tools/` | `make_icons.py`, `make_terrain_override.py`, `make_leader_art.py`, `test_desert_growth.py`, `test_leaders.py`, `validate.sh`, `install.sh` |

## Use

```bash
./tools/validate.sh     # offline checks against the game's cached database
./tools/install.sh      # link the mod's files into the Civ 6 Mods folder (macOS)
```

Then enable the mod under Additional Content and start a **new** game.

## Photo credits

The changes page shows a photo of each luxury, from Wikimedia Commons, resized
and cropped (`docs/img/`). Each card on the page links to the original.

| Photo | Author | Licence |
|---|---|---|
| Topaz | Shannon Heinle | CC0 |
| Peacocks | Rhododendrites | CC BY-SA 4.0 |
| Pallas's Cats | Spencer Wright | CC BY 2.0 |
| Pygmy Rabbits | U.S. National Park Service | Public domain |
| Tibetan Foxes | James Eaton | CC0 |
| Discus Fish | Brian Gratwicke | CC BY 2.0 |
| Capybaras | Paul VanDerWerf | CC BY 2.0 |

## Known limitations

- **The leaders have not been run in the game yet.** Offline checks pass (see
  `tools/validate.sh`), but the setup screen, the borrowed 3D leader scenes and
  the Lua functions for Wonders and Appeal are only confirmed by playing. After a
  first game, check `Lua.log` for lines starting `Europa leaders:`.
- **The Cree tile claim is the least certain effect.** It reads a city's outgoing
  Trade Routes and assigns plots from a gameplay script. The game's own scenario
  scripts use the neighbouring functions, but not these exact calls, so the
  script checks each one and prints a single `Europa leaders:` line to `Lua.log`
  if one is missing instead of failing.
- **Leaders borrow stock art.** Portrait, 3D scene, icon, colours and agenda come
  from Mansa Musa, Qin Shi Huang, Menelik II, Pedro II, Poundmaker, Peter, Teddy
  Roosevelt (Bull Moose) and Catherine de Medici (Black Queen).
- **Highland Empire needs the Ethiopia Pack and Borderless Empire needs Rise and
  Fall.** Without the pack that leader is skipped and the others still load.

- **Map models are placeholders.** Each resource borrows an existing model
  (Topaz = Diamonds, Peacocks = Deer, Pallas's Cats and Tibetan Foxes = Furs,
  Pygmy Rabbits and Capybaras = Truffles, Discus Fish = Fish), and the Fish Weir
  uses the Fishing Boats model and build icon. New 3D art needs
  the Windows-only ModBuddy asset pipeline.
- **Icons are generated placeholders.** Put a 512x512 `art/<key>.png`
  (`topaz`, `peacocks`, `pallas_cats`, `pygmy_rabbits`, `tibetan_foxes`,
  `discus_fish`, `capybaras`) and re-run `tools/make_icons.py` to replace one.
- **"Woods" means any woods.** The engine checks features independently of
  terrain, so Peacocks can also appear in tundra woods (as Deer and Furs do).
- **Monopolies and Corporations mode**: no industries, corporations or products
  are defined for these resources.
- **Bigger deserts replace a game file.** `TerrainGenerator.lua` can only be
  overridden whole, so this conflicts with any other mod that replaces the same
  file, and should be regenerated if a game patch changes it (`validate.sh`
  detects that). Map scripts with their own terrain step (the BBS "DW" maps,
  PerfectWorld) are unaffected.
- **Discus Fish** are placed by script after map generation, so they are not
  part of the per-continent luxury split and do not appear in WorldBuilder maps
  until a game is started.
