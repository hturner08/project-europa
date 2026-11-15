#!/usr/bin/env python3
"""Build the map utility overrides in Maps/Utility/: each is the installed
Gathering Storm file, verbatim, plus a short hook appended at the end.

  TerrainGenerator.lua   wraps ApplyBaseTerrain   (bigger deserts)
  RiversLakes.lua        wraps AddLakes           (great lakes)

Civ 6 has no way to extend a map utility in place; a mod can only replace the
whole file by importing one with the same name. Generating the replacement from
the installed game keeps our change to the appended block and makes it obvious
when a game patch has changed the original.

Usage: python3 tools/make_terrain_override.py           # (re)write the overrides
       python3 tools/make_terrain_override.py --check   # fail if one is out of date
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "Maps" / "Utility"
GAME = Path(os.environ.get("CIV6_ASSETS", Path.home() / "Library/Application Support/Steam/steamapps/common"
            / "Sid Meier's Civilization VI/Civ6.app/Contents/Assets"))
STOCK_DIR = GAME / "DLC/Expansion2/Maps/Utility"

MARKER = "-- ===== Project Europa hook (everything above is the stock file, unmodified) ====="
TERRAIN_HOOK = """
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

LAKES_HOOK = """
-- Every stock map script, and the BBS ones that include this file, place their
-- lakes by calling AddLakes after rivers and before features, resources and
-- start positions. Wrapping it lets the great lakes step run straight after.
include "Europa_LakeGrowth"

local Europa_StockAddLakes = AddLakes;

function AddLakes(largeLakes)
	Europa_StockAddLakes(largeLakes);
	-- pcall: a fault in the growth step must never stop a map from generating.
	local bOk, sError = pcall(Europa_GrowLakes);
	if not bOk then
		print("Europa: great lakes skipped: " .. tostring(sError));
		AreaBuilder.Recalculate();   -- in case it stopped after changing some tiles
	end
end
"""

# file name -> (global function the hook wraps, hook text)
OVERRIDES = {
    "TerrainGenerator.lua": ("ApplyBaseTerrain", TERRAIN_HOOK),
    "RiversLakes.lua": ("AddLakes", LAKES_HOOK),
}


def build(name):
    function, hook = OVERRIDES[name]
    stock = (STOCK_DIR / name).read_bytes().decode("utf-8", errors="surrogateescape")
    if f"function {function}(" not in stock:
        sys.exit(f"{STOCK_DIR / name} no longer defines {function}; the hook needs rethinking")
    newline = "\r\n" if "\r\n" in stock else "\n"
    return (stock.rstrip() + newline * 2 + (MARKER + hook).replace("\n", newline)).encode("utf-8", errors="surrogateescape")


def main():
    check = "--check" in sys.argv
    for name in OVERRIDES:
        stock, out = STOCK_DIR / name, OUT_DIR / name
        if not stock.exists():
            if check:
                print(f"SKIPPED: game file not found at {stock}")
                continue
            sys.exit(f"game file not found: {stock} (set CIV6_ASSETS)")
        data = build(name)
        if check:
            if not out.exists() or out.read_bytes() != data:
                sys.exit(f"{out.relative_to(ROOT)} is out of date with the installed game; "
                         "re-run tools/make_terrain_override.py and review the diff")
            print(f"{name} override matches the installed game file + hook")
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(data)
        print(f"wrote {out.relative_to(ROOT)} ({len(data)} bytes)")


if __name__ == "__main__":
    main()
