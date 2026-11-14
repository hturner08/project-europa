#!/bin/bash
# Live watcher for a running Civ 6 session (macOS, Steam).
# Prints one line per NEW issue found in the game's logs and exits when the game
# process exits. Meant to be run under the Monitor tool: each stdout line is an event.
#
#   watch.sh <state-dir> [--from-start]
#
# <state-dir>   holds per-log line offsets and the list of lines already reported,
#               so a re-armed watcher resumes where the last one stopped. Use a
#               fresh directory for a fresh session.
# --from-start  scan each log from its first line (a baseline of the whole session
#               so far) instead of from its current end. Only applies to logs with
#               no saved offset.
#
# Environment:
#   CIV6_MOD_PATTERN  case-insensitive regex naming the mod under test (default: europa)
#   CIV6_LOGS         logs folder override
#   CIV6_POLL         seconds between polls (default 5)

STATE="$1"
[ -n "$STATE" ] || { echo "usage: watch.sh <state-dir> [--from-start]" >&2; exit 2; }
FROM_START=0
[ "$2" = "--from-start" ] && FROM_START=1

# Plain assignment first: bash 3.2 (macOS) mis-parses apostrophes inside "${VAR:-...}".
LOGS_DEFAULT="$HOME/Library/Application Support/Sid Meier's Civilization VI/Firaxis Games/Sid Meier's Civilization VI/Logs"
LOGS="${CIV6_LOGS:-$LOGS_DEFAULT}"
MOD="${CIV6_MOD_PATTERN:-europa}"
POLL="${CIV6_POLL:-5}"
PROC="Civ6_Exe"
MAX=25   # most lines printed per log per poll; Monitor stops a watcher that floods

FILES="Database.log Modding.log Lua.log GameCore.log UserInterface.log ArtDef.log Localization.log"

# Lines worth a look. "constraint failed" rather than "constraint", so the routine
# "Validating Foreign Key Constraints..." line does not fire.
MATCH="error|constraint failed|invalid reference|fail|runtime|stack traceback|attempt to|nil value|assert|unable to|not found|is now using leader|Shutting down via user exit|$MOD"

# Known noise, seen on every load of an unmodded or third-party-modded game.
NOISE="CLICKOUT|HallOfFame|HALL_OF_FAME"                                   # base-game promo text loaded twice
NOISE="$NOISE|_China\.xml|Translations_Major_Text\.xml|_RemoveText\.xml"   # translation files not installed
NOISE="$NOISE|LocalizedText - Failed loading XML"                          # pairs with the line above
NOISE="$NOISE|LocalizedText\.Language, LocalizedText\.Tag"                 # generic duplicate-text line; the file name follows on its own line
NOISE="$NOISE|Failed to start bug helper|not an error|StackControl"
NOISE="$NOISE|Possible Values|LEADER_VALUES|already used"                  # leader-pool chatter
# Routine, successful lines that merely name the mod under test.
NOISE="$NOISE|GameplayScripts - Registering|Applying Component - |^\* |^\([^)]*\)$|^[0-9a-fA-F{}-]{36,38} \("
NOISE="$NOISE|^[A-Za-z ]+ - Loading |^Loading Mod - |Added art file|StartupErrorMessages"
# Noise only when the line does NOT name the mod under test: the base game and DLC
# log dozens of these art-package lines on every launch.
NOISE_UNLESS_MOD="Unable to resolve Package"

mkdir -p "$STATE" || exit 2
SEEN="$STATE/seen.txt"; touch "$SEEN"

cd "$LOGS" || { echo "WATCHER: logs folder not found: $LOGS"; exit 1; }
pgrep -f "$PROC" >/dev/null 2>&1 || { echo "WATCHER: Civ 6 is not running"; exit 0; }

for f in $FILES; do
	k="$STATE/$f.off"
	[ -f "$k" ] && continue
	if [ $FROM_START = 1 ] || [ ! -f "$f" ]; then echo 0 > "$k"; else wc -l < "$f" | tr -d ' ' > "$k"; fi
done
[ -f Lua.log ] && lua=1 || lua=0
[ $lua = 0 ] && ! grep -qxF "WATCHER: no Lua.log" "$SEEN" && {
	echo "WATCHER: no Lua.log" >> "$SEEN"
	echo "WATCHER: no Lua.log in the logs folder; gameplay script output and Lua errors are NOT covered"
}

while pgrep -f "$PROC" >/dev/null 2>&1; do
	if [ $lua = 0 ] && [ -f Lua.log ]; then lua=1; echo "WATCHER: Lua.log now exists"; fi
	for f in $FILES; do
		[ -f "$f" ] || continue
		k="$STATE/$f.off"; off=$(cat "$k" 2>/dev/null || echo 0)
		n=$(wc -l < "$f" | tr -d ' ')
		if [ "$n" -lt "$off" ]; then off=0; echo "WATCHER: $f was reset (the game was relaunched)"; fi
		[ "$n" -gt "$off" ] || continue
		out=$(tail -n +"$((off+1))" "$f" | head -n "$((n-off))" \
			| sed -E 's/^\[[0-9. :-]+\][[:space:]]*//' \
			| grep -iE "$MATCH" | grep -vE "$NOISE" \
			| M="$MOD" N="$NOISE_UNLESS_MOD" perl -ne 'print unless /$ENV{N}/ && !/$ENV{M}/i' \
			| cut -c1-240 \
			| while IFS= read -r line; do
				grep -qxF -- "$f: $line" "$SEEN" && continue
				echo "$f: $line" >> "$SEEN"
				echo "$f: $line"
			done)
		if [ -n "$out" ]; then
			c=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
			printf '%s\n' "$out" | head -n "$MAX"
			# Never drop lines silently: the offset moves on, so say how many were cut.
			[ "$c" -gt "$MAX" ] && echo "WATCHER: $((c-MAX)) more new lines in $f not shown (see $SEEN)"
		fi
		echo "$n" > "$k"
	done
	sleep "$POLL"
done
echo "WATCHER: Civ 6 process has exited"
