#!/bin/bash
# Install this mod into Civ 6's user Mods folder (macOS) so edits are live on the
# next game launch. Pass --remove to uninstall.
#
# The Mods folder gets a real ProjectEuropa directory holding one symlink per mod
# file or folder (the manifest, the .dep, and each top-level folder the manifest
# names). It used to be a single symlink to the whole repository, but the game
# scans Mods recursively: a git worktree inside the repository (.claude/worktrees)
# then showed up as a second copy of the same mod id. Linking only the mod's own
# files keeps everything else in the repository out of the game's sight.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MODS="${CIV6_MODS:-$HOME/Library/Application Support/Sid Meier's Civilization VI/Sid Meier's Civilization VI/Mods}"
DEST="$MODS/ProjectEuropa"

# Remove a previous install: either the old whole-repo symlink, or a directory
# that contains nothing but symlinks. Anything else is left alone.
remove_install() {
	if [ -L "$DEST" ]; then
		rm "$DEST"
	elif [ -d "$DEST" ]; then
		if [ -n "$(find "$DEST" -mindepth 1 ! -type l -print -quit)" ]; then
			echo "$DEST contains real files, not just links; leaving it alone"; exit 1
		fi
		find "$DEST" -mindepth 1 -type l -delete
		rmdir "$DEST"
	elif [ -e "$DEST" ]; then
		echo "$DEST exists and is not a mod install; leaving it alone"; exit 1
	fi
}

if [ "${1:-}" = "--remove" ]; then
	if [ -e "$DEST" ] || [ -L "$DEST" ]; then remove_install; echo "removed $DEST"; else echo "nothing to remove"; fi
	exit 0
fi
[ -d "$MODS" ] || { echo "Mods folder not found: $MODS"; exit 1; }

# What to link: the manifest plus the first path component of every file it lists.
ITEMS="ProjectEuropa.modinfo
$(grep -o '<File[^>]*>[^<]*</File>' "$REPO/ProjectEuropa.modinfo" | sed 's/<[^>]*>//g' | cut -d/ -f1 | sort -u)"

remove_install
mkdir "$DEST"
for item in $ITEMS; do
	[ -e "$REPO/$item" ] || { echo "MISSING in repository: $item"; exit 1; }
	ln -s "$REPO/$item" "$DEST/$item"
done
echo "installed into $DEST, linking to $REPO:"
ls "$DEST" | sed 's/^/  /'
echo "Enable 'Project Europa' under Additional Content, then start a NEW game."
