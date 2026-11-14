---
name: civ6-monitor-session
description: Watch a running Civilization VI session on this Mac and flag mod problems live from the game's logs until the game closes. Use when the user says the game or mods are running and asks to monitor, watch, keep an eye on, or flag issues during a playtest of Project Europa.
---

# Monitor a live Civ 6 session (macOS, Steam)

The game exposes no telemetry API. "Telemetry" here means its log folder, which it
writes continuously while running:

`~/Library/Application Support/Sid Meier's Civilization VI/Firaxis Games/Sid Meier's Civilization VI/Logs/`

The job has three parts: a baseline of what the logs already say, a live watch
until the process exits, and a closing summary. Everything is read-only.

## 1. Baseline (one pass, before watching)

1. Confirm the game is up: `pgrep -lf Civ6_Exe` (the process is `Civ6_Exe_Child`).
   If it is not running, say so and read the logs as a finished run instead.
2. Run the watcher once in baseline mode with a **fresh** state directory in the
   scratchpad. Under the Monitor tool it prints every issue logged so far and then
   keeps watching, so steps 1 and 2 of this skill are one command:

   ```bash
   bash .claude/skills/civ6-monitor-session/watch.sh "<scratchpad>/civwatch-<date>" --from-start
   ```

   Start it with **Monitor** (`timeout_ms: 1800000`, the maximum), not plain Bash.
3. While it runs, establish the mod's own state by hand. These are successes, so
   the watcher deliberately does not print them:

   | Check | How | Good result |
   |---|---|---|
   | Every component applied | `grep -n 'Europa' Modding.log`, read the line after each `Loading Data/Europa_*` | No `Warning: ... Error Loading SQL/XML` directly after a Europa file |
   | Database accepted the rows | `grep '\[Gameplay\]' Database.log` | `Passed Validation.` after each `Validating Foreign Key Constraints...` |
   | Rows really exist | `sqlite3 "<...>/Cache/DebugGameplay.sqlite" "select Type,Kind from Types where Type like '%EUROPA%'"` | Every type the mod defines is listed |
   | Scripts registered | `grep 'GameplayScripts - Registering' Modding.log` | One line per file in `Scripts/` |
   | Leaders in the match | `grep 'is now using leader' GameCore.log` | Shows which Europa leaders were drawn |

   In `Modding.log` a failure warning names no file. The failed file is the
   `Loading ...` line **immediately above** the warning; print it with
   `grep -n -B1 'Error Loading' Modding.log`.

## 2. Live watch

- Each line the watcher prints arrives as an event. For each batch: look at the
  surrounding log lines (`grep -n -B1 -A4`), decide whether it is the mod's, and
  tell the user in a few lines. Do not go quiet, and do not re-explain a repeat.
- **Attribution test.** An error belongs to the mod only if a nearby line names one
  of its files, types or its id (`7fe8ff0a-8385-4631-b121-6032c7cce1f5`). To clear
  a suspicious line, grep the repo for the name in it (icon, atlas, map file).
  A file path under `steamapps/workshop/content/289070/<id>/` is a Workshop mod;
  find its name with `ls` on that folder's `.modinfo`.
- **Re-arm.** Monitor stops after 30 minutes. If the game is still running, start
  the same command again with the **same** state directory and no `--from-start`;
  it resumes from the saved line offsets, so nothing is skipped or repeated.
- **Silence is not proof.** When a watch expires with no events, check before
  saying "quiet": `pgrep -f Civ6_Exe`, the timestamps on `UserInterface.log` and
  `Game_PlayerScores.csv` (`ls -lT`), and `tail -1 Game_PlayerScores.csv` (first
  field is the turn number). Report the turn reached.
- The watcher ends with `WATCHER: Civ 6 process has exited`. Then go to step 3.

### What the watcher covers

Logs: `Database.log`, `Modding.log`, `Lua.log`, `GameCore.log`,
`UserInterface.log`, `ArtDef.log`, `Localization.log`.

It prints new lines containing an error keyword (error, constraint failed, fail,
unable to, not found, runtime, stack traceback, nil value, assert), any line naming
the mod (`CIV6_MOD_PATTERN`, default `europa`), leader assignment for each new
match, and the exit-to-menu line. Each distinct line is printed once per session.

### Session shape, as seen in the logs

- Logs are truncated when the **app** launches, not when a match starts. Several
  matches in one sitting append to the same files.
- Each match start re-applies every mod, so third-party failures repeat per match.
  `Resolving Random Leaders` / `is now using leader` in `GameCore.log` marks a new
  match; `UILua: Shutting down via user exit on menu.` in `UserInterface.log`
  marks its end. The process stays alive at the menu.
- A clean quit ends `UserInterface.log` with `ForgeUI shutting down.` If that line
  is missing, look in `~/Library/Logs/DiagnosticReports` for a Civ crash report.

## What to ignore

Filtered by the watcher; do not report these as findings:

| Line | Why it is noise |
|---|---|
| `UNIQUE constraint failed: LocalizedText.Language, LocalizedText.Tag` with `CLICKOUT` or `HallOfFame` context | Base-game promo and Hall of Fame text loaded twice |
| `Unable to load ../../../DLC/.../*_China.xml`, `*_Translations_Major_Text.xml`, `*_RemoveText.xml`, each followed by `LocalizedText - Failed loading XML` | Translation files that are not installed |
| `ArtDef.log: Unable to resolve Package '...' from Project '<base game or DLC>'` | Dozens per launch from the game's own content. Shown only if the project is the mod |
| `Failed to start bug helper`, ICU `fallback result (not an error)` | Harmless startup lines |
| `Leader already used`, `Civilization already used`, `Possible Values` | Normal random-leader resolution |
| `Validating Foreign Key Constraints...` | Routine; the result is on the next line |

The duplicate-text line is generic. If the mod itself duplicates a text tag, the
line that follows names the file (`...from file Text/Europa_...xml`), and that line
is printed because it names the mod.

Known third-party failures on this machine (observed 13 Nov 2026). Mention once
per session as "not ours", then only if they change:

- Better Balanced Game 7.5.1: `_dlc_indo_khmer_utils.sql`,
  `DLC_Indonesia_Khmer/Other.sql`, `LP/lp_arabia_saladin_sultan.sql` fail; about a
  dozen `ICON_POLICY_*` / `ICON_BBG_*` icons are missing.
- Better Balanced Starts 2.2.8 (Workshop 2749991372) and BBM 1.39 (3179425402)
  both register `rich_highlands_xp2.lua`: `UNIQUE constraint failed: Maps.Domain,
  Maps.File`, one `Configuration/Config.xml` fails, and two
  `IconTextureAtlases` duplicates appear in the same pass.
- `CatherineDeMedici_Modifiers.xml` and `RulersOfTheSahara_RemoveData.xml` fail.
- Text parse errors: Workshop 2357532056 `Text_BR.xml`, `LOTRv2.Civ6Map`, and a mod
  titled "Forbidden AI Build Wonder".
- Missing icons `Leaders45` and `ICON_NOTIFICATION_USER_DEFINED_5`.

This list goes stale as the user's Workshop mods update. Treat it as a hint and
re-check attribution if the wording differs.

## What the logs cannot show

- **Lua.** On this machine the game has not written `Lua.log`, so `print` output
  and runtime errors from `Scripts/*.lua` are invisible. The watcher says so at
  start and announces the file if it appears. The setting that enables it is not
  known; it lives in the user's `AppOptions.txt`, so ask before changing that file,
  and do not guess an option name. Until then, "scripts registered" is the most
  that can be claimed.
- **Art, icons, map placement.** A `.dep` accepted by the art loader says nothing
  about how things look. Only the user looking in-game confirms these.
- **Other mods overriding files.** Not logged. Check by name:
  `find "<steam>/workshop/content/289070" -name TerrainGenerator.lua` for each file
  in `Maps/Utility/`.

## 3. Closing summary

When the game exits, report in this order: how it exited (clean or crash) and when;
the mod's result across all matches (loads, validation, leaders drawn, furthest
turn); what was not verified; then third-party failures, grouped by mod. Say
plainly if the mod logged no errors, and equally plainly what that does not cover.

If the session taught something new and durable about reading these logs, propose
an update to this skill and get approval before editing it.
