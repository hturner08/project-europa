---
name: civ6-reference-lookup
description: Find authoritative Civilization VI modding facts on this Mac by reading the installed game's own data, schema, Lua and logs instead of guessing. Use before writing or changing any Civ 6 mod file, when unsure of a table, column, type name, Lua API or file format.
---

# Civ 6 reference lookup (macOS, Steam)

Never write Civ 6 mod data from memory. The installed game is the reference; every
question below has a file that answers it.

## Paths

```
GAME=~/Library/Application\ Support/Steam/steamapps/common/Sid\ Meier\'s\ Civilization\ VI/Civ6.app/Contents/Assets
USER=~/Library/Application\ Support/Sid\ Meier\'s\ Civilization\ VI
WORKSHOP=~/Library/Application\ Support/Steam/steamapps/workshop/content/289070
```

| Need | Where |
|---|---|
| Table/column definitions, defaults, foreign keys | `$GAME/Base/Assets/Gameplay/Data/Schema/01_GameplaySchema.sql` |
| Base game data | `$GAME/Base/Assets/Gameplay/Data/*.xml` |
| Expansion / DLC data, icons, text, modinfo | `$GAME/DLC/<Pack>/` (`Expansion1`, `Expansion2`, `GranColombia_Maya`, ...) |
| Map generation Lua | `$GAME/Base/Assets/Maps/Utility/`, overridden in `$GAME/DLC/Expansion2/Maps/Utility/` |
| Art definitions | `$GAME/Base/ArtDefs/*.artdef`, `$GAME/DLC/<Pack>/ArtDefs/` |
| Live merged databases from the last game started | `$USER/Firaxis Games/Sid Meier's Civilization VI/Cache/Debug{Gameplay,Configuration,Localization}.sqlite` |
| Logs | `$USER/Firaxis Games/Sid Meier's Civilization VI/Logs/` (`Database.log`, `Modding.log`, `Lua.log`) |
| Local mods folder | `$USER/Sid Meier's Civilization VI/Mods/` |
| Subscribed workshop mods (real-world examples) | `$WORKSHOP/<id>/` |

## How to answer common questions

- **"What rows does an existing X have?"** Copy `DebugGameplay.sqlite` to a scratch
  dir and query it. To find every table that mentions a type, loop over
  `sqlite_master` tables and grep each dump for the type name. This is the fastest
  way to learn what a new thing of the same kind needs.
- **"How did Firaxis add one?"** `grep -rl RESOURCE_HONEY "$GAME/DLC"` (or any type
  from a small DLC). Small packs such as `GranColombia_Maya` are the best
  templates: data XML, icons XML, text XML, artdef and modinfo wiring in one place.
- **"Does this Lua function exist / what are its arguments?"**
  `grep -rhF --include='*.lua' -e 'Game.GetRandNum' "$GAME" "$WORKSHOP" | head`.
  Check it is used outside `/Maps/` before calling it from a gameplay script.
- **"What is the modinfo syntax for action Y?"** Grep a workshop `.modinfo`.

## Gotchas

- The cache databases reflect the **last ruleset and mods loaded**, including
  balance mods (e.g. BBG changes values and adds rows). Treat values as "what is
  loaded here", and check the DLC XML for stock values.
- The gameplay DB has triggers calling `Make_Hash()`, which only the game
  registers. The `sqlite3` CLI cannot insert into `Types`; use Python's `sqlite3`
  with `create_function("Make_Hash", 1, ...)`.
- zsh expands unquoted `--include=*.lua` and `====`; quote them.
- Grepping the whole game tree can print thousands of lines. Always `| head` or
  count first.
