#!/usr/bin/env python3
"""Run the great-lakes Lua outside the game, against stubbed game globals.

Needs the 'lupa' package (pip install lupa). Exits 0 with a SKIPPED line when it
is not installed, so tools/validate.sh still works without it.

Checks, on synthetic hex maps, through the real hook (generated RiversLakes.lua:
the stock AddLakes, then ours):
  * no new body of water appears and none merge: only existing lakes grow
  * the sea is untouched and no lake ends up larger than LAKE_MAX_AREA_SIZE
  * rivers and their banks, volcanoes, natural wonders and the tiles around a
    wonder are never flooded
  * the expected number of lakes is grown, they reach a useful size, and they
    are spread over both halves of the map
  * a fault inside the growth step does not stop the map or undo the stock lakes
"""
import random
import re
import sys
from pathlib import Path

try:
    import lupa
except ImportError:
    print("SKIPPED: lupa not installed")
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent
W, H = 60, 38                     # a Tiny map
LAKE_MAX, COAST, VOLCANO = 9, 15, 7
OFFSETS = lambda shift: [(-1 + shift, 1), (shift, 1), (1, 0), (shift, -1), (-1 + shift, -1), (-1, 0)]


def neighbors(i):
    """Civ 6 hex grid: offset rows, odd rows shifted right, no wrap."""
    x, y = i % W, i // W
    cells = [(x + dx, y + dy) for dx, dy in OFFSETS(y % 2)]
    return [cy * W + cx for cx, cy in cells if 0 <= cx < W and 0 <= cy < H]


def distance(a, b):
    def cube(i):
        col, row = i % W, i // W
        x = col - (row - (row & 1)) // 2
        return x, row, -x - row
    return max(abs(p - q) for p, q in zip(cube(a), cube(b)))


def bodies(water):
    seen, groups = set(), []
    for start in sorted(water):
        if start not in seen:
            group, stack = set(), [start]
            while stack:
                i = stack.pop()
                if i not in group:
                    group.add(i)
                    stack += [j for j in neighbors(i) if j in water]
            seen |= group
            groups.append(frozenset(group))
    return groups


class World:
    def __init__(self, rng):
        self.rng = rng
        self.water = {i for i in range(W * H)
                      if not (5 <= i % W < W - 5 and 4 <= i // W < H - 4)}      # one landmass in a sea
        land = sorted(set(range(W * H)) - self.water)
        self.river = set()
        for _ in range(10):                                                     # wandering rivers
            i = rng.choice(land)
            for _ in range(14):
                self.river.add(i)
                i = rng.choice([j for j in neighbors(i) if j not in self.water] or [i])
        self.bank = {j for i in self.river for j in neighbors(i)} - self.river - self.water
        free = [i for i in land if i not in self.river and i not in self.bank]
        self.volcano = set(rng.sample(free, 6))
        self.wonder = set(rng.sample(free, 3))
        self.after_stock = None
        self.log = []

    def runtime(self, break_growth=False):
        lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        g = lua.globals()
        g.g_TERRAIN_TYPE_COAST, g.g_FEATURE_VOLCANO = COAST, VOLCANO
        g.print = lambda *args: self.log.append(" ".join(str(a) for a in args))
        g.DirectionTypes = lua.table_from({"NUM_DIRECTION_TYPES": 6})
        g.GlobalParameters = lua.table_from({"LAKE_PLOT_RANDOM": 40, "LAKE_MAX_AREA_SIZE": LAKE_MAX})
        plots = {}

        def is_lake(i):
            return i in self.water and any(i in b and len(b) <= LAKE_MAX for b in bodies(self.water))

        def plot(i):
            if i not in plots:
                plots[i] = lua.table_from({
                    "_i": i,
                    "GetIndex": lambda self_: i, "GetX": lambda self_: i % W, "GetY": lambda self_: i // W,
                    "IsWater": lambda self_: i in self.water,
                    "IsCoastalLand": lambda self_: i not in self.water and any(j in self.water for j in neighbors(i)),
                    "IsRiver": lambda self_: i in self.river,
                    "IsRiverAdjacent": lambda self_: i in self.bank,
                    "IsNaturalWonder": lambda self_: i in self.wonder,
                    "IsLake": lambda self_: is_lake(i),
                    "GetFeatureType": lambda self_: VOLCANO if i in self.volcano else -1})
            return plots[i]

        def adjacent(x, y, direction):
            x, y = int(x), int(y)
            dx, dy = OFFSETS(y % 2)[int(direction)]
            cx, cy = x + dx, y + dy
            return plot(cy * W + cx) if 0 <= cx < W and 0 <= cy < H else None

        def recalculate():
            if self.after_stock is None:
                self.after_stock = set(self.water)

        g.Map = lua.table_from({"GetGridSize": lambda: (W, H), "GetPlotByIndex": lambda i: plot(int(i)),
                                "GetAdjacentPlot": adjacent, "GetPlotDistance": lambda a, b: distance(int(a), int(b))})
        g.TerrainBuilder = lua.table_from({
            "GetRandomNumber": lambda n, label: self.rng.randrange(int(n)),
            "SetTerrainType": lambda p, terrain: self.water.add(p["_i"])})
        g.AreaBuilder = lua.table_from({"Recalculate": recalculate})

        def include(name):
            assert name == "Europa_LakeGrowth", f"unexpected include: {name}"
            lua.execute((ROOT / "Maps/Europa_LakeGrowth.lua").read_text())
            if break_growth:
                lua.execute("function Europa_GrowLakes() error('deliberate test fault') end")
        g.include = include
        lua.execute(override_source())
        return lua


def override_source():
    """The parts of the generated override this test exercises: the stock lake
    functions and our appended hook."""
    text = (ROOT / "Maps/Utility/RiversLakes.lua").read_text(errors="replace")
    stock, hook = text.split("-- ===== Project Europa hook", 1)
    return stock[stock.index("function AddLakes("):] + "\n-- " + hook


def main():
    results = []
    for seed in range(25):
        world = World(random.Random(seed))
        sea = max(bodies(world.water), key=len)
        world.runtime().globals().AddLakes(3)
        before, after = bodies(world.after_stock), bodies(world.water)
        added = world.water - world.after_stock

        assert len(after) == len(before), "a body of water appeared or two merged"
        assert sea in after, "the sea changed"
        for body in after:
            assert body == sea or len(body) <= LAKE_MAX, f"a lake has {len(body)} tiles"
        assert not added & (world.river | world.bank), "a river or river bank was flooded"
        assert not added & world.volcano, "a volcano was flooded"
        assert not added & (world.wonder | {j for i in world.wonder for j in neighbors(i)}), \
            "a natural wonder or a tile next to one was flooded"

        summary = next(line for line in world.log if line.startswith("Europa: grew"))
        assert not any("WARNING" in line or "skipped" in line for line in world.log), world.log
        grown, lakes, tiles, land = map(int, re.match(
            r"Europa: grew (\d+) of (\d+) lakes by (\d+) tiles; .*\((\d+) land tiles\)", summary).groups())
        assert tiles == len(added)
        assert grown == min(lakes, max(3, round(land / 120))), summary
        great = [b for b in after if b != sea and len(b) >= 6]
        assert len(great) >= grown * 0.7, f"only {len(great)} of {grown} chosen lakes reached 6 tiles"
        assert {min(b) % W < W // 2 for b in great} == {True, False}, "great lakes are all in one half of the map"
        results.append((len(before) - 1, grown, len(added), sorted(len(b) for b in great)))

    world = World(random.Random(0))
    world.runtime(break_growth=True).globals().AddLakes(3)
    assert world.after_stock and world.water == world.after_stock, "a fault in the growth step changed the stock lakes"
    assert any("great lakes skipped" in line for line in world.log)

    n = len(results)
    sizes = [s for r in results for s in r[3]]
    print(f"lake growth OK over {n} synthetic Tiny maps: {sum(r[0] for r in results) / n:.0f} lakes per map, "
          f"{sum(r[1] for r in results) / n:.1f} grown, +{sum(r[2] for r in results) / n:.0f} water tiles; "
          f"great lakes average {sum(sizes) / len(sizes):.1f} tiles (max {max(sizes)})")


if __name__ == "__main__":
    main()
