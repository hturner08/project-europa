---
name: civ6-add-improvement
description: Add a new builder improvement to a Civilization VI mod, especially a resource-only improvement modelled on an existing one such as Fishing Boats, Camp or Mine. Use when a resource needs its own improvement, or when asked to add, clone or debug an improvement in a Civ 6 mod.
---

# Adding an improvement to a Civ 6 mod

The quickest correct route is to clone a stock improvement. First list every row
the stock one has (see `civ6-reference-lookup`: scan all tables of
`DebugGameplay.sqlite` for its type), then decide table by table what to copy.

## Ask before designing

If the spec does not give them, the name, yields and unlock tech are the user's
call. Default to mirroring the stock improvement and say that you did.

## Gameplay database

| Table | Notes |
|---|---|
| `Types` | `Kind = 'KIND_IMPROVEMENT'` |
| `Improvements` | `Name`, `Description`, `Icon`, `PrereqTech`, `Buildable = 1`, `PlunderType`/`PlunderAmount`. Water improvements need `Domain = 'DOMAIN_SEA'` |
| `Improvement_ValidBuildUnits` | `UNIT_BUILDER` |
| `Improvement_ValidResources` | The resources it connects |
| `Improvement_YieldChanges` | Base yields |
| `Improvement_BonusYieldChanges` | Later tech/civic upgrades |
| `Improvement_Tourism` | Late-game tourism from the tile |

Rules learned from the game data:

- **Resource-only improvements have no `Improvement_ValidTerrains` or
  `Improvement_ValidFeatures` rows.** Fishing Boats work this way: buildable only
  where a valid resource is. So "lake only" comes from the resource being lake
  only, not from the improvement.
- **Housing is in halves.** `Housing = 1` with `TilesRequired = 2` is the stock
  0.5 Housing.
- **Copy upgrade rows with `INSERT ... SELECT` from the stock improvement** rather
  than hard-coding them. Balance mods (BBG here) add their own rows, and a select
  keeps the clone in step under any ruleset. `Improvement_BonusYieldChanges` has
  an `Id` column in its primary key that defaults to 0; leave it out.
- **Things that name the stock improvement do not carry over**: tech boosts
  (`Boosts.ImprovementType`), civ abilities and adjacency bonuses (e.g. Kampung
  and Seastead next to Fishing Boats), and other mods' modifiers. Tell the user
  which of these the new improvement will miss.

## Text

`LOC_IMPROVEMENT_<X>_NAME` and `LOC_IMPROVEMENT_<X>_DESCRIPTION`. Stock
descriptions follow "Unlocks the Builder ability to construct ... [NEWLINE]
[NEWLINE] yields and placement rule".

## Icon

`ICON_IMPROVEMENT_<X>` in `IconDefinitions`. To borrow a stock icon, add a row
pointing at the same atlas and index the stock one uses (Fishing Boats is
`ICON_ATLAS_UNIT_ACTIONS` index 4; look others up in
`Base/Assets/UI/Icons/Icons_UnitActions.xml`).

## Map art

`ArtDefs/Improvements.artdef`: copy the stock improvement's whole `<Element>` from
`Base/ArtDefs/Improvements.artdef` and change only its `m_Name`. It carries the
landmark model, strategic-view sprites and audio by reference. List the artdef
under the `Improvements` consumer in the mod's `.dep` and in the modinfo `<Files>`.
Gathering Storm overrides some stock entries with extra variants in
`DLC/Expansion2/ArtDefs/Improvements_Shared.artdef`; the base entry is the
portable one.

## Finish

Extend the validator to cover the new type (name, description, icon, artdef) and
print its rows, then follow `civ6-validate-and-install`. The model and build icon
can only be confirmed in-game.
