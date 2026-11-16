#!/usr/bin/env python3
"""Run the desert-growth Lua outside the game, against stubbed game globals.

Needs the 'lupa' package (pip install lupa). Exits 0 with a SKIPPED line when it
is not installed, so tools/validate.sh still works without it.

Checks, on a synthetic hex map:
  * every Lua file in the mod at least compiles
  * growth through the real hook (generated TerrainGenerator.lua -> ApplyBaseTerrain)
  * no desert is created that does not touch an original desert region
  * the number of separate deserts never goes up
  * only grass/plains (and their mountains) are converted; water, tundra and snow never
  * with no desert civilization among the major players, terrain is exactly stock
    (a desert-biased city-state does not count)
  * a fault inside the growth step does not stop terrain from being applied
"""
import random
import sys
from pathlib import Path

try:
    import lupa
except ImportError:
    print("SKIPPED: lupa not installed")
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent
W, H = 44, 26
T = dict(GRASS=0, GRASS_HILLS=1, GRASS_MOUNTAIN=2, PLAINS=3, PLAINS_HILLS=4, PLAINS_MOUNTAIN=5,
         DESERT=6, DESERT_HILLS=7, DESERT_MOUNTAIN=8, TUNDRA=9, TUNDRA_HILLS=10, TUNDRA_MOUNTAIN=11,
         SNOW=12, SNOW_HILLS=13, SNOW_MOUNTAIN=14, COAST=15, OCEAN=16)
P = dict(MOUNTAIN=0, HILLS=1, LAND=2, OCEAN=3)
DESERTS = {T["DESERT"], T["DESERT_HILLS"], T["DESERT_MOUNTAIN"]}


def neighbors(i):
    """Civ 6 hex grid: offset rows, odd rows shifted right, no wrap."""
    x, y = i % W, i // W
    shift = 1 if y % 2 else 0
    cells = [(x - 1, y), (x + 1, y), (x - 1 + shift, y - 1), (x + shift, y - 1),
             (x - 1 + shift, y + 1), (x + shift, y + 1)]
    return [cy * W + cx for cx, cy in cells if 0 <= cx < W and 0 <= cy < H]


def clusters(terrain):
    seen, groups = set(), []
    for start in range(W * H):
        if terrain[start] in DESERTS and start not in seen:
            group, stack = set(), [start]
            while stack:
                i = stack.pop()
                if i in group:
                    continue
                group.add(i)
                stack += [j for j in neighbors(i) if terrain[j] in DESERTS]
            seen |= group
            groups.append(group)
    return groups


def make_map(rng):
    plot = [P["OCEAN"]] * (W * H)
    terrain = [T["OCEAN"]] * (W * H)
    for i in range(W * H):
        x, y = i % W, i // W
        if 3 <= x < W - 3 and 2 <= y < H - 2 and not (20 <= x <= 22):      # two landmasses
            roll = rng.random()
            plot[i] = P["MOUNTAIN"] if roll < 0.06 else P["HILLS"] if roll < 0.3 else P["LAND"]
            base = "TUNDRA" if y >= H - 6 else "SNOW" if y < 3 else rng.choice(["GRASS", "PLAINS"])
            terrain[i] = T[base + ("_MOUNTAIN" if plot[i] == P["MOUNTAIN"] else "")]
    for cx, cy, radius in [(9, 9, 2), (14, 15, 1), (30, 10, 2), (36, 17, 1), (27, 19, 0)]:   # 5 deserts
        blob = {cy * W + cx}
        for _ in range(radius):
            blob |= {j for i in blob for j in neighbors(i)}
        for i in blob:
            if plot[i] != P["OCEAN"]:
                terrain[i] = T["DESERT_MOUNTAIN"] if plot[i] == P["MOUNTAIN"] else T["DESERT"]
    return plot, terrain


def runtime(applied, rng, break_growth=False, majors=("CIVILIZATION_MALI", "CIVILIZATION_FRANCE")):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    for name, value in T.items():
        g["g_TERRAIN_TYPE_" + name] = value
    for name, value in P.items():
        g["g_PLOT_TYPE_" + name] = value
    g.print = lambda *args: None
    g.DirectionTypes = lua.table_from({"NUM_DIRECTION_TYPES": 6})
    lua.execute("function GetGameInfoIndex() return 0 end")

    # Start biases as the loaded ruleset has them: one desert major, one desert city-state.
    lua.execute('''
        local kBiases = {
            { CivilizationType = "CIVILIZATION_MALI",   TerrainType = "TERRAIN_DESERT" },
            { CivilizationType = "CIVILIZATION_MALI",   TerrainType = "TERRAIN_DESERT_HILLS" },
            { CivilizationType = "CIVILIZATION_NAZCA",  TerrainType = "TERRAIN_DESERT" },
            { CivilizationType = "CIVILIZATION_RUSSIA", TerrainType = "TERRAIN_TUNDRA" },
        };
        GameInfo = { StartBiasTerrains = function()
            local i = 0;
            return function() i = i + 1; return kBiases[i]; end
        end };
    ''')
    civs = list(majors) + ["CIVILIZATION_NAZCA"]          # player 2 is a city-state
    g.PlayerManager = lua.table_from({"GetAliveMajorIDs": lambda: lua.table_from(list(range(len(majors))))})
    g.PlayerConfigurations = lua.table_from(
        {i: lua.table_from({"GetCivilizationTypeName": lambda self, name=name: name}) for i, name in enumerate(civs)})

    def plot_object(i):
        return lua.table_from({"GetIndex": lambda self: i, "_i": i})

    def adjacent(x, y, direction):
        x, y = int(x), int(y)
        shift = 1 if y % 2 else 0
        dx, dy = [(-1 + shift, 1), (shift, 1), (1, 0), (shift, -1), (-1 + shift, -1), (-1, 0)][int(direction)]
        cx, cy = x + dx, y + dy
        return plot_object(cy * W + cx) if 0 <= cx < W and 0 <= cy < H else None

    g.Map = lua.table_from({"GetAdjacentPlot": adjacent, "GetPlotByIndex": lambda i: plot_object(int(i)),
                            "FindSecondContinent": lambda *a: False})
    g.TerrainBuilder = lua.table_from({
        "GetRandomNumber": lambda n, label: rng.randrange(int(n)),
        "SetTerrainType": lambda plot, terrain: applied.__setitem__(plot["_i"], int(terrain))})

    files = {"Europa_DesertGrowth": ROOT / "Maps/Europa_DesertGrowth.lua"}

    def include(name):
        if name in files:
            lua.execute(files[name].read_text())
            if break_growth:
                lua.execute("function Europa_GrowDeserts() error('deliberate test fault') end")
    g.include = include
    lua.execute(override_source())
    return lua


def override_source():
    """The parts of the generated override this test exercises: the stock
    ApplyBaseTerrain and our appended hook. The rest of the stock file uses
    Firaxis's typed-Lua syntax ('local x : number'), which standard Lua rejects."""
    text = (ROOT / "Maps/Utility/TerrainGenerator.lua").read_text(errors="replace")
    stock, hook = text.split("-- ===== Project Europa hook", 1)
    start = stock.index("function ApplyBaseTerrain(")
    return stock[start:stock.index("\nend", start) + 4] + "\n-- " + hook


def to_lua(lua, values):                      # 0-based table, as the map generator builds them
    table = lua.table()
    for i, v in enumerate(values):
        table[i] = v
    return table


def main():
    compile_error = lupa.LuaRuntime().eval("function(src) local f, err = load(src); return err end")
    for path in sorted(ROOT.glob("Maps/**/*.lua")) + sorted(ROOT.glob("Scripts/*.lua")):
        stock_copy = path.name == "TerrainGenerator.lua"
        err = compile_error(override_source() if stock_copy else path.read_text(errors="replace"))
        assert err is None, f"{path.relative_to(ROOT)} does not compile: {err}"

    growth = []
    for seed in range(25):
        rng = random.Random(seed)
        plot, terrain = make_map(rng)
        applied = {}
        lua = runtime(applied, rng)
        lua.globals().ApplyBaseTerrain(to_lua(lua, plot), to_lua(lua, terrain), W, H)
        assert len(applied) == W * H, "terrain was not applied to every plot"
        after = [applied[i] for i in range(W * H)]

        before_groups, after_groups = clusters(terrain), clusters(after)
        was = {i for i in range(W * H) if terrain[i] in DESERTS}
        now = {i for i in range(W * H) if after[i] in DESERTS}
        assert was <= now, "an original desert tile was lost"
        assert len(after_groups) <= len(before_groups), "number of deserts went up"
        for group in after_groups:
            assert group & was, "a desert appeared that does not touch an original desert"
        for i in now - was:
            assert plot[i] != P["OCEAN"], "water turned into desert"
            assert terrain[i] in (T["GRASS"], T["PLAINS"], T["GRASS_MOUNTAIN"], T["PLAINS_MOUNTAIN"]), \
                "something other than grass/plains turned into desert"
        for i in range(W * H):                 # everything else is exactly what stock would apply
            if i not in now - was:
                assert after[i] == terrain[i] + (1 if plot[i] == P["HILLS"] else 0)
        assert len(now) > len(was), "deserts did not grow"
        growth.append((len(was), len(now), len(before_groups), len(after_groups)))

    rng = random.Random(0)
    plot, terrain = make_map(rng)
    applied = {}
    lua = runtime(applied, rng, majors=("CIVILIZATION_RUSSIA", "CIVILIZATION_FRANCE"))
    lua.globals().ApplyBaseTerrain(to_lua(lua, plot), to_lua(lua, terrain), W, H)
    assert [applied[i] for i in range(W * H)] == [t + (1 if p == P["HILLS"] else 0) for p, t in zip(plot, terrain)], \
        "deserts grew with no desert civilization among the major players"

    rng = random.Random(0)
    plot, terrain = make_map(rng)
    applied = {}
    lua = runtime(applied, rng, break_growth=True)
    lua.globals().ApplyBaseTerrain(to_lua(lua, plot), to_lua(lua, terrain), W, H)
    assert [applied[i] for i in range(W * H)] == [t + (1 if p == P["HILLS"] else 0) for p, t in zip(plot, terrain)], \
        "a fault in the growth step changed or blocked stock terrain"

    was, now = sum(g[0] for g in growth), sum(g[1] for g in growth)
    print("no desert civilization: terrain is stock")
    print(f"desert growth OK over {len(growth)} synthetic maps: {was / len(growth):.0f} -> {now / len(growth):.0f} "
          f"desert tiles on average ({now / was:.1f}x); deserts per map {growth[0][2]} -> "
          f"{min(g[3] for g in growth)}-{max(g[3] for g in growth)}")


if __name__ == "__main__":
    main()
