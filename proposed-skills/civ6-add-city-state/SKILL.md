---
name: civ6-add-city-state
description: Add a new city-state with a Suzerain bonus to a Civilization VI mod, covering gameplay rows, the city-state picker, text, icons, colours and Lua-counted bonuses. Use when asked to add, change or debug a city-state, a Suzerain bonus, or a city-state that does not appear in the picker or the game.
---

# Add a city-state to a Civ 6 mod

STATUS: draft. Everything below passed offline validation in this repo against
BBG 7.5.1; none of it has been confirmed in a running game yet. Update after the
first in-game test.

Best template: Fez in `DLC/Expansion2` (`Data/Expansion2_Civilizations.xml`,
`Expansion2_Leaders.xml`, `Config/Expansion2_Config.xml`). Dump every row that
mentions it with the "find every table" loop in `civ6-reference-lookup`.

## The pieces

| Piece | Where | Notes |
|---|---|---|
| Gameplay rows | `UpdateDatabase` (InGame) | `Types` (KIND_CIVILIZATION, KIND_LEADER, KIND_TRAIT), `TypeProperties` (`CityStateCategory`), `Civilizations` (`StartingCivilizationLevelType = CIVILIZATION_LEVEL_CITY_STATE`), `CityNames`, `Leaders` (`InheritFrom = LEADER_MINOR_CIV_<TYPE>`), `CivilizationLeaders`, `Traits`, `LeaderTraits`, `Leaders_XP2` (`MinorCivBonusType = MINOR_CIV_BONUS_<TYPE>`, Gathering Storm), optional `StartBias*` |
| Picker row | `UpdateDatabase` in **`FrontEndActions`** | Configuration DB `CityStates`, one row per `Domain` (`Expansion2CityStates` for Gathering Storm) |
| Text | `UpdateText` in both | name, description, adjective, city name, trait name and description, `LOC_PEDIA_CITYSTATES_PAGE_<CIV>_CHAPTER_HISTORY_PARA_1` |
| Icon | `UpdateIcons` + `ImportFiles` in both | `ICON_<CIV>`; stock atlases come in 13 sizes (22, 30, 32, 36, 44, 45, 48, 50, 64, 80, 128, 200, 256), white emblem on transparent |
| Colours | `UpdateColors` in both | `PlayerColors` row, `Usage` = `Minor`, `COLOR_PLAYER_CITY_STATE_PRIMARY` + `COLOR_PLAYER_CITY_STATE_<TYPE>_SECONDARY` (scientific is `SCIENCE`) |

The six types are SCIENTIFIC, CULTURAL, INDUSTRIAL, MILITARISTIC, RELIGIOUS, TRADE.

## Suzerain bonus

Trait modifier `MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER` with
`SubjectRequirementSetId = 'PLAYER_IS_SUZERAIN'` (stock set) and argument
`ModifierId` = an ordinary player modifier. The engine attaches and detaches it as
suzerainty changes, so Lua never needs to know who the Suzerain is. A tech gate on
the Suzerain goes in the attached modifier's `OwnerRequirementSetId`.

What the modifier system cannot do (checked in the loaded DB):

- **District adjacency from a named neighbour.** `EFFECT_DISTRICT_ADJACENCY` takes
  only the receiving `DistrictType`; the neighbour is "any district" (Japan,
  Ludwig). `Adjacency_YieldChanges` can name the neighbour but applies to everyone
  and can only be switched off per trait.
- **Feature adjacency that skips improved tiles or stops at a cap.**
- **A flat Production bonus toward a class of buildings** (only percentages).
- **"At least N adjacent X"** for N > 1.

For those, count in Lua and use the plot property pattern (`civ6-add-leader`):
write the number on the district's own plot and read it with
`REQUIREMENT_PLOT_PROPERTY_MATCHES` on a `COLLECTION_PLAYER_DISTRICTS` modifier
(`MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE`, `..._ADJUST_TOURISM_CHANGE`,
`..._ADJUST_GREAT_PERSON_POINTS`), one modifier per point. Stock data uses plot
and city requirements on district subjects, so this should resolve. Compute the
values for **every major player**; the attach modifier decides who benefits.
Write 0 on every owned plot the value does not apply to, so nothing goes stale.

Things it can do directly: build charges on newly trained units
(`MODIFIER_PLAYER_TRAINED_UNITS_ADJUST_BUILDER_CHARGES`, `Permanent = 1`, unit-type
requirement, as Serfdom does); a building yield in cities with a district
(`MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE` + `REQUIREMENT_CITY_HAS_DISTRICT`).

## Lua found gameplay-side (Firaxis scenario scripts or BBG)

`CityManager.GetDistrictAt(x, y)`, `pPlot:GetDistrictType()`,
`pPlot:IsImprovementPillaged()`, `pCity:GetTrade():GetOutgoingRoutes()`,
`GameEvents.OnDistrictConstructed(iPlayer, eDistrict, iX, iY)`,
`GameEvents.OnPillage(iUnitPlayer, iUnitID, eImprovement, eBuilding, eDistrict, iPlotIndex)`.
Only seen in UI files, so guard them: `pDistrict:IsComplete()`, `:IsPillaged()`,
`pCity:GetBuildQueue():GetCurrentProductionTypeHash()`. Map unique districts to
the one they replace with `GameInfo.DistrictReplaces`.

## Balance-mod trap (BBG)

BBG hand-writes one modifier per stock city-state for "per city-state you are
Suzerain of" bonuses (Pericles, Huszar, Varangian longship), keyed by
`LEADER_MINOR_CIV_<NAME>` inside the ids. Copy Fez's rows with
`INSERT ... SELECT replace(...)` in a separate file loaded after BBG.

## Validation

- Files named `X_Common.sql` sort after `X_<Name>.sql` in a shell glob; name the
  shared file so it sorts first if a tool applies `Data/*.sql` in glob order.
- Check: category, `InheritFrom` and `MinorCivBonusType` agree; every trait
  modifier is an attach modifier whose target exists; every plot property a
  requirement reads is written by the script; picker row, text, icon, colours.
