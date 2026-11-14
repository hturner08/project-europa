---
name: civ6-validate-and-install
description: Check a Civilization VI mod offline against the installed game's database, install it into the local Mods folder, and read the game logs after a test run. Use after editing any Civ 6 mod file, before telling the user a mod change works, or when a mod fails to load.
---

# Validate and install a Civ 6 mod

One bad row makes Civ 6 roll back a mod's whole database file, usually silently.
Catch it offline first.

## Offline checks (`tools/validate.sh` in this repo)

1. **XML is well formed**: `xmllint --noout` on the `.modinfo`, `.dep`, `.artdef`
   and every data/text XML.
2. **Manifest agrees with disk**: every `<File>` in the modinfo exists, and every
   shipped file is listed in `<Files>` *and* in the action that uses it. A file
   present on disk but absent from the modinfo is ignored by the game.
3. **SQL applies with foreign keys on** to a copy of
   `Cache/DebugGameplay.sqlite`, followed by `PRAGMA foreign_key_check`. Use
   Python's `sqlite3` and stub `Make_Hash` (the `Types` table has a trigger that
   calls it). Print the resulting rows and compare them with the spec.
4. **Cross-system completeness**: each new type has its name text, pedia text,
   icon, FOW icon, font icon and artdef entry.

The cache DB is the last ruleset the user played, with their other mods applied.
A pass means "valid against that setup", not every ruleset. Rows that depend on
an expansion should be written to adapt (see `civ6-add-resource`).

## Install

Symlink the repo into
`~/Library/Application Support/Sid Meier's Civilization VI/Sid Meier's Civilization VI/Mods/`
(`tools/install.sh`). This writes outside the project, so ask before doing it the
first time. The mod then appears under Additional Content. Changes to gameplay
data need a **new game**; saves keep the database they started with.

## After a test run, read the logs

In `~/Library/Application Support/Sid Meier's Civilization VI/Firaxis Games/Sid Meier's Civilization VI/Logs/`:

| Log | Look for |
|---|---|
| `Database.log` | `ERROR`, `FOREIGN KEY constraint failed`, `Invalid Reference` near the mod's file names |
| `Modding.log` | The mod's id; whether each action loaded its files |
| `Lua.log` (if present) | The script's `print` lines and any runtime error |

If a log is missing or has no lines for the mod, say so rather than assuming
success. Logging options live in `AppOptions.txt`; that is a user setting, so ask
before changing it.

## Reporting

State what was verified offline and what was not run in the game. Art, icons in
the UI, and map placement can only be confirmed in-game; never report them as
working from offline checks alone.
