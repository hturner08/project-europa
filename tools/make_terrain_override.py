#!/usr/bin/env python3
"""Build Maps/Utility/TerrainGenerator.lua: the installed Gathering Storm terrain
generator, verbatim, plus a short hook appended at the end.

Civ 6 has no way to extend a map utility in place; a mod can only replace the
whole file by importing one with the same name. Generating the replacement from
the installed game keeps our change to the appended block and makes it obvious
when a game patch has changed the original.

Usage: python3 tools/make_terrain_override.py           # (re)write the override
       python3 tools/make_terrain_override.py --check   # fail if it is out of date
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Maps" / "Utility" / "TerrainGenerator.lua"
GAME = Path(os.environ.get("CIV6_ASSETS", Path.home() / "Library/Application Support/Steam/steamapps/common"
            / "Sid Meier's Civilization VI/Civ6.app/Contents/Assets"))
STOCK = GAME / "DLC/Expansion2/Maps/Utility/TerrainGenerator.lua"

MARKER = "-- ===== Project Europa hook (everything above is the stock file, unmodified) ====="
HOOK = MARKER + """
-- Every stock Gathering Storm map script, and the BBS map scripts, pass their
-- finished terrain table to ApplyBaseTerrain. Wrapping it lets the desert growth
-- run on any of them without touching the generators themselves.
include "Europa_DesertGrowth"

local Europa_StockApplyBaseTerrain = ApplyBaseTerrain;

function ApplyBaseTerrain(plotTypes, terrainTypes, iW, iH)
	-- pcall: a fault in the growth step must never stop a map from generating.
	local bOk, sError = pcall(Europa_GrowDeserts, plotTypes, terrainTypes, iW, iH);
	if not bOk then
		print("Europa: desert growth skipped: " .. tostring(sError));
	end
	return Europa_StockApplyBaseTerrain(plotTypes, terrainTypes, iW, iH);
end
"""


def build():
    stock = STOCK.read_bytes().decode("utf-8", errors="surrogateescape")
    if "function ApplyBaseTerrain(" not in stock:
        sys.exit(f"{STOCK} no longer defines ApplyBaseTerrain; the hook needs rethinking")
    newline = "\r\n" if "\r\n" in stock else "\n"
    return (stock.rstrip() + newline * 2 + HOOK.replace("\n", newline)).encode("utf-8", errors="surrogateescape")


def main():
    if not STOCK.exists():
        if "--check" in sys.argv:
            print(f"SKIPPED: game file not found at {STOCK}")
            return
        sys.exit(f"game file not found: {STOCK} (set CIV6_ASSETS)")
    data = build()
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_bytes() != data:
            sys.exit(f"{OUT.relative_to(ROOT)} is out of date with the installed game; "
                     "re-run tools/make_terrain_override.py and review the diff")
        print("terrain override matches the installed game file + hook")
        return
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(data)
    print(f"wrote {OUT.relative_to(ROOT)} ({len(data)} bytes)")


if __name__ == "__main__":
    main()
