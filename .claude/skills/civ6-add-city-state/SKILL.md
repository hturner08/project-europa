---
name: civ6-add-city-state
description: Add a new city-state with a Suzerain bonus to a Civilization VI mod, covering gameplay rows, the city-state picker, text, icons, colours, Lua-counted bonuses and balance-mod compatibility. Use when asked to add, change, rebalance or debug a city-state or a Suzerain bonus, or when a city-state does not appear in the picker or the game.
---

# Add a city-state to a Civ 6 mod

STATUS: everything below passed offline validation in this repo against Gathering
Storm + BBG 7.5.1. None of it has been confirmed in a running game yet. After the
first in-game test, move what held up into a "Confirmed in game" section and fix
what did not.

Worked example: the six city-states in this repo (`Data/Europa_CityState_*.sql`).
Ubud is the shortest complete one. Stock template: Fez in `DLC/Expansion2`
(`Data/Expansion2_Civilizations.xml`, `Expansion2_Leaders.xml`,
`Config/Expansion2_Config.xml`). Dump every row that mentions it with the "find
every table" loop in `civ6-reference-lookup`.

## 1. The pieces

A city-state is a civilization plus a leader plus a trait, in **two databases**.

| Piece | Action | Notes |
|---|---|---|
| Gameplay rows | `UpdateDatabase` (InGame) | see below |
| Picker row | `UpdateDatabase` in **FrontEndActions** | Configuration DB table `CityStates`, one row per `Domain` (`Expansion2CityStates` for Gathering Storm): `CivilizationType, CityStateCategory, Name, Icon, Bonus`. This also puts it in the pool the game draws from |
| Text | `UpdateText` in both | `LOC_CIVILIZATION_<X>_NAME`, `_DESCRIPTION`, `_ADJECTIVE`, `LOC_CITY_NAME_<X>`, trait `_NAME` ("<City> Suzerain Bonus: <Title>") and `_DESCRIPTION`, `LOC_PEDIA_CITYSTATES_PAGE_<CivilizationType>_CHAPTER_HISTORY_PARA_1` |
| Icon | `UpdateIcons` + `ImportFiles` in both | `ICON_<CivilizationType>`. White emblem on transparent; the game draws it over the type colour. Stock atlases come in 13 sizes: 22, 30, 32, 36, 44, 45, 48, 50, 64, 80, 128, 200, 256 |
| Colours | `UpdateColors` in both | `PlayerColors`: `Usage = Minor`, `COLOR_PLAYER_CITY_STATE_PRIMARY`, `COLOR_PLAYER_CITY_STATE_<TYPE>_SECONDARY` (Scientific is `SCIENCE`, not `SCIENTIFIC`) |
| Script | `AddGameplayScripts` (InGame) | only if a bonus needs counting |

Gameplay rows, in order:

- `Types`: the civilization (`KIND_CIVILIZATION`), `LEADER_MINOR_CIV_<X>`
  (`KIND_LEADER`), `MINOR_CIV_<X>_TRAIT` (`KIND_TRAIT`).
- `TypeProperties`: `(civilization, 'CityStateCategory', <TYPE>)`.
- `Civilizations`: `StartingCivilizationLevelType = 'CIVILIZATION_LEVEL_CITY_STATE'`.
- `CityNames`, and `CivilizationLeaders` with `CapitalName`.
- `Leaders`: `InheritFrom = 'LEADER_MINOR_CIV_<TYPE>'`. This is where the 1, 3 and
  6 envoy bonuses come from before Gathering Storm.
- `Traits`, `LeaderTraits`.
- `Leaders_XP2`: `MinorCivBonusType = 'MINOR_CIV_BONUS_<TYPE>'` (Gathering Storm's
  envoy bonuses).
- Optional `StartBiasTerrains` / `StartBiasFeatures` / `StartBiasRivers`, so the
  bonus is usable where the city-state lands.

The type appears three times (`CityStateCategory`, `InheritFrom`,
`MinorCivBonusType`) plus once in the picker row; all four must agree. Types are
SCIENTIFIC, CULTURAL, INDUSTRIAL, MILITARISTIC, RELIGIOUS, TRADE.

No artdef is needed to load. Without one the city uses a default building style
(not yet looked at in game).

## 2. Suzerain bonus wiring

Two layers, the way stock city-states do it:

```sql
-- the bonus itself: an ordinary player-level modifier
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_UBUD_THEATER_CULTURE_1', 'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE', 'EUROPA_REQSET_CS_WILD_TILES_1');

-- generic tail, the same in every file: wrap each one for the Suzerain
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT ModifierId || '_SUZERAIN', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_UBUD_%';
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId || '_SUZERAIN', 'ModifierId', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_UBUD_%' AND ModifierId NOT LIKE '%_SUZERAIN';
INSERT INTO TraitModifiers (TraitType, ModifierId)
	SELECT 'MINOR_CIV_EUROPA_UBUD_TRAIT', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_UBUD_%_SUZERAIN';
```

- `PLAYER_IS_SUZERAIN` is a stock requirement set. The engine attaches and
  removes the inner modifier as suzerainty changes, so **Lua never needs to know
  who the Suzerain is**.
- A condition on the Suzerain (a tech, a civic) goes in the inner modifier's
  `OwnerRequirementSetId`; a condition on each city, district or plot goes in its
  `SubjectRequirementSetId`.
- Give every inner modifier the prefix the tail selects on, and nothing else that
  prefix.

## 3. What the modifier system can and cannot do

Look before designing:
`SELECT ModifierType, CollectionType, EffectType FROM DynamicModifiers WHERE EffectType LIKE '%X%'`,
then copy the argument names from an existing modifier of that type.

Cannot (checked in the loaded DB):

- **District adjacency from a named neighbour, for one player.**
  `EFFECT_DISTRICT_ADJACENCY` takes only the receiving `DistrictType`; the
  neighbour is "any district" (Japan, Ludwig). `Adjacency_YieldChanges` can name
  the neighbour but applies to everyone.
- **Feature adjacency that skips improved tiles, or stops at a cap.**
- **A flat Production bonus toward a class of buildings.** Only percentages.
- **"At least N adjacent X"** for N above 1.
- **Count** anything per city (Trade Routes sent, tiles round a plot).

Can, directly:

- Building yield in cities that have a district:
  `MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE` + `REQUIREMENT_CITY_HAS_DISTRICT`.
- Percentage Production toward a district:
  `MODIFIER_PLAYER_CITIES_ADJUST_DISTRICT_PRODUCTION` (`DistrictType`, `Amount`).
  It takes **one** district type, and BBG writes a separate row for each unique
  replacement, so generate one modifier per district from `DistrictReplaces`
  instead of assuming Cothon or Ikanda are covered (see Ravenna's file).
- Flat yield on a district, on a plot or in a city, each gated by a requirement
  set: `MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE`,
  `MODIFIER_PLAYER_DISTRICTS_ADJUST_TOURISM_CHANGE`,
  `MODIFIER_PLAYER_DISTRICTS_ADJUST_GREAT_PERSON_POINTS`,
  `MODIFIER_PLAYER_ADJUST_PLOT_YIELD`,
  `MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE`.
- Charges on newly trained units
  (`MODIFIER_PLAYER_TRAINED_UNITS_ADJUST_BUILDER_CHARGES`, `Permanent = 1`, as
  Serfdom does).

A yield added with `..._DISTRICTS_ADJUST_YIELD_CHANGE` is a flat district yield,
not adjacency. Whether adjacency-doubling policy cards multiply it is untested;
describe it in the bonus text as a plain "+N", and note the difference in the
README if the brief said "adjacency".

## 4. Counting in Lua: the plot property pattern

For everything in the "cannot" list:

1. A gameplay script counts and writes the number with
   `pPlot:SetProperty('EUROPA_CS_<NAME>', n)` on the plot the modifier's subject
   sits on: the district's own plot for district modifiers, the improved plot for
   plot modifiers, the city-centre plot for city modifiers.
2. `REQUIREMENT_PLOT_PROPERTY_MATCHES` (`PropertyName`, `PropertyMinimum`) reads
   it. One requirement, one set and **one modifier per point**: "+1 per adjacent
   X" up to 6 is six modifiers of +1 with minimums 1 to 6. A cap is simply fewer
   tiers plus a clamp in the script.

In this repo `Data/Europa_CityStateCommon.sql` generates the requirements and
sets from one list (`EUROPA_REQ_CS_<NAME>_<n>` / `EUROPA_REQSET_CS_<NAME>_<n>`):
add a `UNION ALL SELECT '<NAME>', <top tier>` line there, and document the
property in the comment block above it.

Script rules (`Scripts/Europa_CityStates.lua`):

- **Compute for every major player**, not for the Suzerain. The attach modifier
  decides who benefits, and the values are already right the turn suzerainty
  changes hands.
- **Write 0 where the value no longer applies**, on every owned plot the property
  could be on, so nothing goes stale when a district is pillaged or a feature is
  removed. Skip the write when the value is unchanged.
- **`GameEvents` only** (simulation-side, identical on both machines; `Events.*`
  are UI-side). Recompute on `PlayerTurnStarted`, `CityBuilt`, `CityConquered`,
  `OnDistrictConstructed(iPlayer, eDistrict, iX, iY)` and
  `OnPillage(iUnitPlayer, iUnitID, eImprovement, eBuilding, eDistrict, iPlotIndex)`.
  No randomness.
- **Do nothing if none of the city-states is in the game**: check the player
  slots once at load and register no hooks otherwise. Use a local constant for
  the slot count (64); `GameDefines.MAX_PLAYERS` was not found gameplay-side.
- Map unique districts to the one they replace with `GameInfo.DistrictReplaces`,
  so a Hansa counts as an Industrial Zone.
- Found in gameplay scripts (Firaxis scenarios or BBG): `CityManager.GetDistrictAt(x, y)`,
  `pPlot:GetDistrictType()`, `pPlot:IsImprovementPillaged()`,
  `pCity:GetTrade():GetOutgoingRoutes()`, `pCity:GetOwnedPlots()`.
  Found only in UI files, so nil-check them and warn once to `Lua.log`, falling
  back to the generous reading: `pDistrict:IsComplete()`, `:IsPillaged()`,
  `pCity:GetBuildQueue():GetCurrentProductionTypeHash()`.
- A value that depends on what a city is building (Ravenna) is only refreshed by
  those events, so it can lag a mid-turn production change by a turn. Say so in
  the README.

## 5. Balance-mod trap (BBG)

BBG replaces "per city-state you are Suzerain of" bonuses (Pericles' Culture, the
Huszar, the Varangian longship) with one hand-written modifier per stock
city-state, with `LEADER_MINOR_CIV_<NAME>` inside the ids. A new city-state counts
toward none of them. `Data/Europa_CityStates_BBG.sql` copies every row BBG made
for Fez with `INSERT OR IGNORE ... SELECT replace(...)` across `Requirements`,
`RequirementArguments`, `RequirementSets`, `RequirementSetRequirements`,
`Modifiers`, `ModifierArguments`, `ModifierStrings`, `TraitModifiers` and
`UnitAbilityModifiers`. It matches on the `LEADER_MINOR_CIV_EUROPA_` prefix, so a
new city-state is picked up with no edit. It is its own file and its own action,
loaded after the city-states (and after BBG), so a BBG change that breaks it
cannot take a city-state down with it; without BBG it matches nothing.

## 6. Files to touch in this repo

Naming: `CIVILIZATION_EUROPA_<X>`, `LEADER_MINOR_CIV_EUROPA_<X>`,
`MINOR_CIV_EUROPA_<X>_TRAIT`, modifiers `EUROPA_<X>_...`.

1. `Data/Europa_CityState_<Name>.sql`: one file per city-state. Civ 6 rolls back
   a whole file on its first bad row, so a mistake only drops that city-state.
2. `Data/Europa_CityStateCommon.sql`: any new plot property. It must load first.
   It is named `CityStateCommon`, not `CityStates_Common`, because the validator
   applies `Data/*.sql` in glob order and `_Common` would sort after the others.
3. `Config/Europa_CityStates_Config.sql`: picker row.
4. `Text/Europa_CityStates_Text_en_US.xml`, `Data/Europa_CityStates_Colors.xml`,
   `Data/Europa_CityStates_Icons.xml` (next free `Index`).
5. `tools/make_citystate_icons.py`: add the key to `ORDER` and a draw function,
   then run it to regenerate `Textures/Europa_CityStates*.dds`. The atlas is
   4 x 2, so it holds eight; a ninth city-state needs a bigger grid, in the script
   and in every `IconTextureAtlases` row.
6. `Scripts/Europa_CityStates.lua`: add the civilization to the list it checks
   for, and the counting if any. Add cases to `tools/test_citystates.py`.
7. `ProjectEuropa.modinfo`: the new SQL file in the `EuropaCityStates` action
   (LoadOrder 100000100, after BBG's 100000000, `criteria="Expansion2"`) and in
   `<Files>`. The other files are already wired for InGame and FrontEnd.
8. `tools/validate.sh`: the two "EXPECTED 6" counts.
9. `README.md` (city-states section, known limitations) and `docs/index.html`
   ("As designed" or "Adjusted").

## 7. Validate

Run `./tools/validate.sh` (see `civ6-validate-and-install`). For city-states it
checks that the four type fields agree, every trait modifier is an attach
modifier whose target exists, every plot property a requirement reads is written
by the script, the BBG copy has as many rows as Fez, and each city-state has a
picker row, text, pedia text, icon and colours. The Lua tests need `lupa` and are
skipped without it; run them from a venv that has it before calling a script
change done.

Then read each city-state's modifiers with their requirement sets against the
brief, line by line. Offline checks do not show whether a modifier pays out; that
needs a game with the city-state present (pick it in the city-state picker) and a
look at `Lua.log` for the `Europa city-states:` lines.
