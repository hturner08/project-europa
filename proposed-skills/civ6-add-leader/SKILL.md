---
name: civ6-add-leader
description: Add a new selectable leader to an existing Civilization VI civilization from a mod, borrowing a stock leader's art, and build its ability from modifiers plus Lua where the modifier system cannot count. Use when asked to add, change or debug a custom or alternate leader, a leader ability, or a leader that does not appear on the setup screen.
---

# Add a leader to a Civ 6 mod

STATUS: draft. Everything below passed offline validation in this repo against
BBG 7.5.1; none of it has been confirmed in a running game yet. Update after the
first in-game test.

A leader lives in **two databases** and needs **front-end actions** as well as
in-game ones. Missing the front-end half is why a leader "does not show up".

## The pieces

| Piece | Where | Notes |
|---|---|---|
| Gameplay rows | `UpdateDatabase` (InGame) | `Types` (KIND_LEADER, KIND_TRAIT), `Leaders` (InheritFrom LEADER_DEFAULT), `CivilizationLeaders`, `Traits`, `LeaderTraits`, `TraitModifiers`, `HistoricalAgendas`, `FavoredReligions`, `LoadingInfo` |
| Setup-screen rows | `UpdateDatabase` in **`FrontEndActions`** | Configuration DB: `Players` and `PlayerItems`, one row per `Domain` (`Players:Expansion2_Players` for Gathering Storm) |
| Text | `UpdateText` in both InGame and FrontEnd | Leader name, trait name and description, loading text |
| Icons | `UpdateIcons` in both | `ICON_<LeaderType>` is looked up by name in game; point it at a stock atlas and index |
| Colours | `UpdateColors` in both | `PlayerColors` row with `Type` = the leader type |
| Art | `UpdateArt` (.dep) in both | `Leaders.artdef` and `FallbackLeaders.artdef` entries |

Best template: `DLC/JuliusCaesar` (one leader, existing civilization).

## Borrowing a stock leader (no new art needed)

- Setup portrait: `Players.Portrait = 'LEADER_<STOCK>_NEUTRAL'`,
  `PortraitBackground = 'LEADER_<STOCK>_BACKGROUND'`. Same names in `LoadingInfo`.
- Icon: find the stock row with
  `grep -rh 'Name="ICON_LEADER_<STOCK>"' "$GAME" --include='*.xml'` and reuse its
  `Atlas` and `Index` under the new name.
- 3D scene and fallback image: copy the stock leader's `<Element>` from the
  pack's `ArtDefs/Leaders.artdef` and `FallbackLeaders.artdef`, changing only
  `m_Name`. List both artdefs in the .dep under the `Leaders` and
  `LeaderFallback` consumers and under `ArtDefDependencies`. Generate these from
  the installed game (`tools/make_leader_art.py`) rather than hand-copying.
- Config rows: `INSERT ... SELECT` the civilization columns and `PlayerItems`
  from the stock leader's rows. The new leader then shows whatever names a
  balance mod uses, and is simply not offered if the DLC is missing. Needs a
  high `LoadOrder` so the stock rows exist first.

## Abilities

1. List what the engine offers before designing:
   `SELECT ModifierType, CollectionType, EffectType FROM DynamicModifiers WHERE EffectType LIKE '%X%'`
   and `SELECT DISTINCT RequirementType FROM Requirements`. Then find an existing
   modifier of that type and copy its argument names.
2. Things the modifier system **cannot** do (checked in the loaded DB):
   - Change Appeal on chosen tiles. Only whole-city (`EFFECT_ADJUST_CITY_APPEAL`)
     or what a feature radiates (`EFFECT_ADJUST_FEATURE_APPEAL_MODIFIER`).
   - Pay a domestic trade route's yield to the destination. Domestic yields go to
     the origin city.
   - Count things (continents, tiles round a plot).
3. For counting, use the **plot property pattern** (BBG uses it too): a gameplay
   script writes a number with `plot:SetProperty(name, n)` on the city-centre
   plot; one modifier per tier on `COLLECTION_PLAYER_CITIES` reads it with
   `REQUIREMENT_PLOT_PROPERTY_MATCHES` (`PropertyName`, `PropertyMinimum`).
   Plot requirements (`PLOT_IS_HILLS`, `PLOT_PROPERTY_MATCHES`, ...) do work on
   city subjects.
4. Modifier types that only DLC packs define (names ending `_WARLORDS`,
   `_GRANCOLOMBIA_MAYA`, ...) make the file depend on that pack. Add your own
   `Types` + `DynamicModifiers` row pointing at the same collection and effect.

## Multiplayer-safe Lua

Use `GameEvents.*` only (`PlayerTurnStarted`, `CityBuilt`, `CityConquered`).
`Events.*` are UI-side; BBG routes them through the UI rather than writing game
state from them. No randomness. Guard functions you could only find in UI files
(`if pPlot.GetWonderType == nil then ... end`) and print once to `Lua.log`.

## Balance-mod traps (BBG)

- **Per-leader bonuses on shared uniques.** BBG gives each Chinese leader a
  different Great Wall yield via their leader trait. A new leader gets none
  unless you add one.
- **Trait-keyed exclusions.** BBG gives each Mali leader a Suguba adjacency and
  removes it from the other with `ExcludedAdjacencies`. A new leader inherits
  both unless it is excluded too. Check every table for the sibling leaders'
  trait names, not just `TraitModifiers`.
- Load after the balance mod (BBG's last gameplay action is LoadOrder
  100000000) if your SQL reads its rows.

## Confirmed from a real game launch (Database.log, Modding.log)

- **Icon rows need a late LoadOrder.** The icon database has a foreign key on
  `Atlas`. A mod's `UpdateIcons` with no `LoadOrder` loaded before
  `Expansion2_Icons_Leaders.xml`, so reusing `ICON_ATLAS_EXPANSION_2_LEADERS`
  failed with "FOREIGN KEY constraint failed" and the whole file was dropped. Put
  borrowed-atlas icons in their own action with a high `LoadOrder`, in both
  InGame and FrontEnd.
- **The setup-screen `INSERT ... SELECT` works**: after launch,
  `DebugConfiguration.sqlite` held all four leaders.
- **The game scans the Mods folder recursively.** With the repo symlinked into
  Mods, a git worktree inside it (`.claude/worktrees/...`) was loaded as a second
  copy of the same mod id. Keep worktrees outside the linked folder, or link only
  the mod's own files.
- **`DebugGameplay.sqlite` is rewritten at every launch** with base rules until a
  game is started, so it is only a valid check target right after a game under
  the ruleset (and balance mod) you care about.

## Layout and validation

- One SQL file per leader plus a shared file listed first. Civ 6 rolls back a
  whole file on the first bad row, so a missing DLC civilization then only drops
  that leader.
- Validate gameplay SQL against `DebugGameplay.sqlite` and config SQL against
  `DebugConfiguration.sqlite`. Print each leader's modifiers with their
  requirement sets and read them against the spec.
- Check: every `LOC_` key used is defined; every plot property a requirement
  reads is written by the script; no modifier is unattached.
