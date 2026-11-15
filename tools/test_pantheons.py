#!/usr/bin/env python3
"""Run Scripts/Europa_Pantheons.lua outside the game, against stubbed game globals.

Needs the 'lupa' package (pip install lupa). Exits 0 with a SKIPPED line when it
is not installed, so tools/validate.sh still works without it.

This checks the script's own logic and wiring. It cannot check that the real game
exposes the same functions to gameplay scripts; that needs a game run and a look
at Lua.log for lines starting "Europa pantheons:".

Checks:
  * Sacred Wilderness: a tile is flagged while it touches a completed, unpillaged
    Preserve of the same player, also when the Preserve is in another of that
    player's cities; not for an unfinished or pillaged Preserve, and not for the
    other player's Preserve
  * Wonders: a city is flagged only once it owns a completed Wonder; one that is
    placed but unfinished does not count; several Wonders still give 1
  * a captured city is re-examined for its new owner and the old owner's tiles
    lose a Preserve that went with it
  * values refresh on turn start, district and building completion and pillage
  * nothing is written when nothing changed
  * city-states are ignored
  * with the district or Wonder functions missing it degrades as documented
"""
import sys
from pathlib import Path

try:
    import lupa
except ImportError:
    print("SKIPPED: lupa not installed")
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = (ROOT / "Scripts" / "Europa_Pantheons.lua").read_text(encoding="utf-8")

STUBS = r"""
DirectionTypes = { NUM_DIRECTION_TYPES = 6 }
PRESERVE, CAMPUS, CENTRE = 21, 3, 0
GameInfo = { Districts = { DISTRICT_PRESERVE = { Index = PRESERVE } } }
local W, H = 40, 20
local plots = {}
local function key(x, y) return y * W + x end
WRITES = 0
local function newPlot(x, y)
	local p = { x = x, y = y, props = {}, owner = -1, district = -1, complete = true, pillaged = false,
		wonder = -1, wonderComplete = false }
	function p:GetX() return self.x end
	function p:GetY() return self.y end
	function p:GetOwner() return self.owner end
	function p:GetDistrictType() return self.district end
	function p:GetProperty(n) return self.props[n] end
	function p:SetProperty(n, v) self.props[n] = v; WRITES = WRITES + 1 end
	return p
end
for y = 0, H - 1 do for x = 0, W - 1 do plots[key(x, y)] = newPlot(x, y) end end
function EnableWonderApi(on)
	for _, p in pairs(plots) do
		p.GetWonderType = on and function(self) return self.wonder end or nil
		p.IsWonderComplete = on and function(self) return self.wonderComplete end or nil
	end
end
EnableWonderApi(true)
Map = {}
function Map.GetPlot(x, y) if x < 0 or y < 0 or x >= W or y >= H then return nil end return plots[key(x, y)] end
function Map.GetPlotByIndex(i) return plots[i] end
function Index(x, y) return key(x, y) end
local EVEN = { {1,0}, {0,-1}, {-1,-1}, {-1,0}, {-1,1}, {0,1} }
local ODD  = { {1,0}, {1,-1}, {0,-1}, {-1,0}, {0,1}, {1,1} }
function Map.GetAdjacentPlot(x, y, d)
	local o = ((y % 2 == 0) and EVEN or ODD)[d + 1]
	return Map.GetPlot(x + o[1], y + o[2])
end
function Near(x, y, i) return Map.GetAdjacentPlot(x, y, i - 1) end

NO_DISTRICT_API = false
CityManager = {}
function CityManager.GetDistrictAt(x, y)
	local p = Map.GetPlot(x, y)
	if p == nil or p.district < 0 then return nil end
	if NO_DISTRICT_API then return {} end
	return { IsComplete = function() return p.complete end, IsPillaged = function() return p.pillaged end }
end

Players = {}
function AddPlayer(id, major)
	local cities = {}
	local C = {}
	function C:Members()
		local i = 0
		return function() i = i + 1; if cities[i] then return i, cities[i] end end
	end
	Players[id] = { GetCities = function() return C end, IsMajor = function() return major end, _cities = cities }
end
function AddCity(owner, x, y)
	local c = { x = x, y = y, owned = {} }
	function c:GetX() return self.x end
	function c:GetY() return self.y end
	function c:GetOwnedPlots() return self.owned end
	local centre = Map.GetPlot(x, y)
	centre.owner = owner; centre.district = CENTRE
	table.insert(c.owned, centre)
	table.insert(Players[owner]._cities, c)
	return c
end
function Own(c, p, fields)
	p.owner = Map.GetPlot(c.x, c.y).owner
	table.insert(c.owned, p)
	for k, v in pairs(fields or {}) do p[k] = v end
	return p
end
function Set(p, fields) for k, v in pairs(fields) do p[k] = v end return p end
function Prop(p, n) return p.props[n] or 0 end
-- Move a city (and its plots) from one player to another.
function Capture(c, from, to)
	for i, v in ipairs(Players[from]._cities) do if v == c then table.remove(Players[from]._cities, i) break end end
	table.insert(Players[to]._cities, c)
	for _, p in ipairs(c.owned) do p.owner = to end
end

HOOKS = {}
local function hook(name)
	return { Add = function(f) HOOKS[name] = f end }
end
GameEvents = { PlayerTurnStarted = hook("turn"), CityBuilt = hook("built"), CityConquered = hook("conquered"),
	OnDistrictConstructed = hook("district"), OnPillage = hook("pillage"), BuildingConstructed = hook("building") }
LOG = {}
function print(...) local t = {} for _, v in ipairs({...}) do t[#t + 1] = tostring(v) end LOG[#LOG + 1] = table.concat(t, " ") end
"""

TILE, CITY = "EUROPA_PANTHEON_PRESERVE_TILE", "EUROPA_PANTHEON_WONDER_CITY"
failures = []


def check(name, got, want):
    if got != want:
        failures.append(f"{name}: got {got!r}, want {want!r}")


def fresh(setup=""):
    """Players 0 and 1 are majors, 2 is a city-state."""
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    lua.execute(setup)
    g = lua.globals()
    g.AddPlayer(0, True)
    g.AddPlayer(1, True)
    g.AddPlayer(2, False)
    return lua, g


def fields(lua, **kw):
    return lua.table_from(kw)


# --- wiring ------------------------------------------------------------------
lua, g = fresh()
lua.execute(SCRIPT)
check("hooks", sorted(g.HOOKS.keys()), ["building", "built", "conquered", "district", "pillage", "turn"])
check("log", list(g.LOG.values()), ["Europa pantheons: hooks added."])

# The building event is optional: without it the script still loads.
lua, g = fresh("GameEvents.BuildingConstructed = nil")
lua.execute(SCRIPT)
check("hooks without BuildingConstructed", sorted(g.HOOKS.keys()), ["built", "conquered", "district", "pillage", "turn"])

# --- Sacred Wilderness ---------------------------------------------------------
lua, g = fresh()
lua.execute(SCRIPT)
a = g.AddCity(0, 10, 10)
preserve = g.Own(a, g.Map.GetPlot(13, 10), fields(lua, district=g.PRESERVE))
beside = g.Own(a, g.Near(13, 10, 1))             # touches the Preserve
far = g.Own(a, g.Map.GetPlot(10, 12))            # does not
# A second city of the same player owns a tile on the other side of the Preserve.
b = g.AddCity(0, 16, 10)
other_city_tile = g.Own(b, g.Near(13, 10, 4))
# The other player owns a tile that touches player 0's Preserve.
c = g.AddCity(1, 13, 14)
foreign_tile = g.Own(c, g.Near(13, 10, 5))

g.HOOKS.turn(0); g.HOOKS.turn(1)
check("tile beside own Preserve", g.Prop(beside, TILE), 1)
check("tile away from Preserve", g.Prop(far, TILE), 0)
check("tile of another city, same player", g.Prop(other_city_tile, TILE), 1)
check("other player's tile beside our Preserve", g.Prop(foreign_tile, TILE), 0)
check("the Preserve's own plot", g.Prop(preserve, TILE), 0)

writes = g.WRITES
g.HOOKS.turn(0)
check("no writes when nothing changed", g.WRITES, writes)

g.Set(preserve, fields(lua, pillaged=True))
g.HOOKS.pillage(1, 0, -1, -1, g.PRESERVE, g.Index(13, 10))
check("pillaged Preserve", g.Prop(beside, TILE), 0)
check("pillaged Preserve, other city", g.Prop(other_city_tile, TILE), 0)
g.Set(preserve, fields(lua, pillaged=False, complete=False))
g.HOOKS.turn(0)
check("unfinished Preserve", g.Prop(beside, TILE), 0)
g.Set(preserve, fields(lua, complete=True))
g.HOOKS.district(0, g.PRESERVE, 13, 10)
check("Preserve finished", g.Prop(beside, TILE), 1)

# A different district in the same spot is not a Preserve.
g.Set(preserve, fields(lua, district=g.CAMPUS))
g.HOOKS.turn(0)
check("Campus is not a Preserve", g.Prop(beside, TILE), 0)
g.Set(preserve, fields(lua, district=g.PRESERVE))

# Player 1 captures city A (with the Preserve). City B's tile loses it; the
# captured tiles count for player 1, and so does player 1's old border tile.
g.Capture(a, 0, 1)
g.HOOKS.conquered(1, 0, 1, 10, 10)
check("old owner's tile after losing the Preserve", g.Prop(other_city_tile, TILE), 0)
check("captured tile beside captured Preserve", g.Prop(beside, TILE), 1)
check("new owner's border tile", g.Prop(foreign_tile, TILE), 1)

# --- Wonders -------------------------------------------------------------------
lua, g = fresh()
lua.execute(SCRIPT)
a = g.AddCity(0, 10, 10)
site = g.Own(a, g.Map.GetPlot(11, 10))
g.HOOKS.turn(0)
check("no Wonder", g.Prop(g.Map.GetPlot(10, 10), CITY), 0)
g.Set(site, fields(lua, wonder=7, wonderComplete=False))
g.HOOKS.turn(0)
check("Wonder under construction", g.Prop(g.Map.GetPlot(10, 10), CITY), 0)
g.Set(site, fields(lua, wonderComplete=True))
g.HOOKS.building(0, 1, 7, g.Index(11, 10), True)
check("Wonder completed", g.Prop(g.Map.GetPlot(10, 10), CITY), 1)
g.Own(a, g.Map.GetPlot(12, 10), fields(lua, wonder=8, wonderComplete=True))
g.Own(a, g.Map.GetPlot(9, 10), fields(lua, wonder=9, wonderComplete=False))
g.HOOKS.turn(0)
check("several Wonders still 1", g.Prop(g.Map.GetPlot(10, 10), CITY), 1)
check("only the city centre carries it", g.Prop(site, CITY), 0)
# A second city of the same player without a Wonder is not flagged.
b = g.AddCity(0, 20, 10)
g.HOOKS.built(0, 2, 20, 10)
check("other city without a Wonder", g.Prop(g.Map.GetPlot(20, 10), CITY), 0)
# Captured: still a Wonder city, now examined for the new owner.
g.Capture(a, 0, 1)
g.Set(g.Map.GetPlot(10, 10), fields(lua, props=lua.table_from({})))
g.HOOKS.conquered(1, 0, 1, 10, 10)
check("captured Wonder city", g.Prop(g.Map.GetPlot(10, 10), CITY), 1)

# --- city-states are ignored ---------------------------------------------------
lua, g = fresh()
lua.execute(SCRIPT)
cs = g.AddCity(2, 5, 5)
g.Own(cs, g.Map.GetPlot(6, 5), fields(lua, wonder=1, wonderComplete=True))
g.HOOKS.turn(2)
check("city-state not examined", g.Prop(g.Map.GetPlot(5, 5), CITY), 0)

# --- missing engine functions --------------------------------------------------
lua, g = fresh("NO_DISTRICT_API = true")
lua.execute(SCRIPT)
a = g.AddCity(0, 10, 10)
g.Own(a, g.Map.GetPlot(13, 10), fields(lua, district=g.PRESERVE, complete=False))
beside = g.Own(a, g.Near(13, 10, 1))
g.HOOKS.turn(0); g.HOOKS.turn(0)
check("no district state: Preserve counted", g.Prop(beside, TILE), 1)
check("no district state: one warning", sum("IsComplete/IsPillaged" in m for m in g.LOG.values()), 1)

lua, g = fresh("EnableWonderApi(false)")
lua.execute(SCRIPT)
a = g.AddCity(0, 10, 10)
g.Own(a, g.Map.GetPlot(11, 10), fields(lua, wonder=7, wonderComplete=True))
g.HOOKS.turn(0); g.HOOKS.turn(0)
check("no Wonder functions: inactive", g.Prop(g.Map.GetPlot(10, 10), CITY), 0)
check("no Wonder functions: one warning", sum("GetWonderType" in m for m in g.LOG.values()), 1)

# --- no Preserve district in the ruleset ----------------------------------------
lua, g = fresh("GameInfo.Districts.DISTRICT_PRESERVE = nil")
lua.execute(SCRIPT)
a = g.AddCity(0, 10, 10)
g.Own(a, g.Map.GetPlot(13, 10), fields(lua, district=g.PRESERVE))
beside = g.Own(a, g.Near(13, 10, 1))
g.HOOKS.turn(0)
check("no Preserve district: inactive", g.Prop(beside, TILE), 0)

if failures:
    print("FAILED:")
    for f in failures:
        print("  " + f)
    sys.exit(1)
print("pantheon script logic OK")
