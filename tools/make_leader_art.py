#!/usr/bin/env python3
"""Build ArtDefs/Leaders.artdef and ArtDefs/FallbackLeaders.artdef.

The custom leaders have no art of their own: each one reuses the animated scene
and the static fallback portrait of a stock leader. Those are defined as one
<Element> per leader in the game's artdef files, so this copies the stock
leader's element verbatim from the installed game and changes only its name.
New 3D leader art needs the Windows-only ModBuddy asset pipeline.

Usage: python3 tools/make_leader_art.py           # (re)write both files
       python3 tools/make_leader_art.py --check   # fail if they are out of date
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = Path(os.environ.get("CIV6_ASSETS", Path.home() / "Library/Application Support/Steam/steamapps/common"
            / "Sid Meier's Civilization VI/Civ6.app/Contents/Assets"))

# our leader -> (stock leader whose art is borrowed, pack that defines it)
LEADERS = {
    "LEADER_EUROPA_GOLDEN_EXPANSION": ("LEADER_MANSA_MUSA", "DLC/Expansion2"),
    "LEADER_EUROPA_IMPERIAL_GARDENS": ("LEADER_QIN", "Base"),
    "LEADER_EUROPA_HIGHLAND_EMPIRE": ("LEADER_MENELIK", "DLC/Ethiopia"),
    "LEADER_EUROPA_LIVING_PARADISE": ("LEADER_PEDRO", "Base"),
}
FILES = {"Leaders.artdef": "Leaders", "FallbackLeaders.artdef": "LeaderFallback"}

HEADER = """<?xml version="1.0" encoding="UTF-8" ?>
<AssetObjects..ArtDefSet>
	<m_Version>
		<major>4</major>
		<minor>0</minor>
		<build>700</build>
		<revision>531</revision>
	</m_Version>
	<m_TemplateName text="{template}"/>
	<m_RootCollections>
		<Element>
			<m_CollectionName text="Leaders"/>
			<m_ReplaceMergedCollectionElements>false</m_ReplaceMergedCollectionElements>
"""
FOOTER = """		</Element>
	</m_RootCollections>
</AssetObjects..ArtDefSet>
"""


def extract(text, name):
    """Return the depth-3 <Element>...</Element> block whose own m_Name is `name`."""
    lines = text.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if line.startswith("\t\t\t<Element>"):          # a leader entry opens at exactly three tabs
            for j in range(i + 1, len(lines)):
                if lines[j].startswith("\t\t\t</Element>"):
                    block = "".join(lines[i:j + 1])
                    if re.search(r'^\t\t\t\t<m_Name text="%s"/>' % re.escape(name), block, re.M):
                        return block
                    break
    raise SystemExit(f"{name} not found")


def build(filename, template):
    out = HEADER.format(template=template)
    for ours, (stock, pack) in LEADERS.items():
        src = GAME / pack / "ArtDefs" / filename
        block = extract(src.read_text(encoding="utf-8"), stock)
        out += block.replace(f'<m_Name text="{stock}"/>', f'<m_Name text="{ours}"/>')
    return out + FOOTER


def main():
    check = "--check" in sys.argv
    stale = False
    for filename, template in FILES.items():
        path = ROOT / "ArtDefs" / filename
        want = build(filename, template)
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != want:
                print(f"OUT OF DATE: {path.relative_to(ROOT)} (run tools/make_leader_art.py)")
                stale = True
        else:
            path.write_text(want, encoding="utf-8")
            print(f"wrote {path.relative_to(ROOT)}")
    if check and not stale:
        print("leader artdefs match the installed game")
    sys.exit(1 if stale else 0)


if __name__ == "__main__":
    main()
