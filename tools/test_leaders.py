#!/usr/bin/env python3
"""Run Scripts/Europa_Leaders.lua outside the game, against stubbed game globals.

Needs the 'lupa' package (pip install lupa). Exits 0 with a SKIPPED line when it
is not installed, so tools/validate.sh still works without it.

This checks the script's own arithmetic and wiring. It cannot check that the
real game exposes the same functions to gameplay scripts; that needs a game run
and a look at Lua.log.

Checks:
  * Mali: continents with >= 3 founded cities are counted, captured cities are not,
    the value sits on the capital only, follows the capital, and is capped at 4
  * China and America: the value is the number of Breathtaking tiles around an
    unfinished Wonder, 0 with no Wonder or a finished one, capped at 4, best site wins
  * France: a city with a Chateau is flagged, and so is an unfinished Wonder
    that touches a Chateau
  * Cree: a city with a Camp or Pasture is flagged; the first Trade Route from a
    founded city claims the two nearest unowned tiles (land first), once only,
    never for a captured city, and degrades when the trade API is missing
  * a captured city's plot is cleared
  * no hooks are registered when neither leader is in the game
"""
import sys
from pathlib import Path

try:
    import lupa
except ImportError:
    print("SKIPPED: lupa not installed")
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = (ROOT / "Scripts" / "Europa_Leaders.lua").read_text(encoding="utf-8")

STUBS = r"""
DirectionTypes = { NUM_DIRECTION_TYPES = 6 }
GameInfo = { Improvements = {
	IMPROVEMENT_CHATEAU = { Index = 7 }, IMPROVEMENT_CAMP = { Index = 3 }, IMPROVEMENT_PASTURE = { Index = 4 } } }
CLAIMS = {}
NO_CLAIM_API = false
WorldBuilder = {}
function WorldBuilder.CityManager()
	return { SetPlotOwner = function(self, x, y, iPlayer, iCity)
		if NO_CLAIM_API then return end
		local p = Map.GetPlot(x, y)
		p.owner = iPlayer; p.ownerCity = iCity
		CLAIMS[#CLAIMS + 1] = { x = x, y = y, city = iCity }
	end }
end
local W, H = 40, 20
local plots = {}
local function key(x, y) return y * W + x end
local function newPlot(x, y)
	local p = { x = x, y = y, props = {}, appeal = 0, continent = 0, wonder = -1, complete = false,
		owner = -1, ownerCity = -1, improvement = -1, water = false }
	function p:GetIndex() return key(self.x, self.y) end
	function p:GetOwner() return self.owner end
	function p:IsWater() return self.water end
	function p:GetImprovementType() return self.improvement end
	function p:GetX() return self.x end
	function p:GetY() return self.y end
	function p:GetProperty(n) return self.props[n] end
	function p:SetProperty(n, v) self.props[n] = v; WRITES = WRITES + 1 end
	function p:GetAppeal() return self.appeal end
	function p:GetContinentType() return self.continent end
	function p:GetWonderType() return self.wonder end
	function p:IsWonderComplete() return self.complete end
	return p
end
for y = 0, H - 1 do for x = 0, W - 1 do plots[key(x, y)] = newPlot(x, y) end end
WRITES = 0
Map = {}
function Map.GetPlot(x, y) if x < 0 or y < 0 or x >= W or y >= H then return nil end return plots[key(x, y)] end
local EVEN = { {1,0}, {0,-1}, {-1,-1}, {-1,0}, {-1,1}, {0,1} }
local ODD  = { {1,0}, {1,-1}, {0,-1}, {-1,0}, {0,1}, {1,1} }
function Map.GetAdjacentPlot(x, y, d)
	local o = ((y % 2 == 0) and EVEN or ODD)[d + 1]
	return Map.GetPlot(x + o[1], y + o[2])
end

PlayerConfigurations = {}
Players = {}
local nextCity = 1
function AddPlayer(id, leader)
	PlayerConfigurations[id] = { GetLeaderTypeName = function() return leader end }
	local cities, capital = {}, nil
	local C = {}
	function C:Members()
		local i = 0
		return function() i = i + 1; if cities[i] then return i, cities[i] end end
	end
	function C:GetCapitalCity() return capital end
	Players[id] = { GetCities = function() return C end, _cities = cities,
		_setCapital = function(c) capital = c end }
end
function AddCity(owner, x, y, continent, original, isCapital, noOriginalOwnerApi)
	local c = { x = x, y = y, id = nextCity, owned = {}, routes = {} }
	nextCity = nextCity + 1
	function c:GetX() return self.x end
	function c:GetY() return self.y end
	function c:GetID() return self.id end
	function c:GetOwnedPlots() return self.owned end
	if not NO_TRADE_API then
		function c:GetTrade() return { GetOutgoingRoutes = function() return c.routes end } end
	end
	Map.GetPlot(x, y).owner = owner
	if not noOriginalOwnerApi then
		function c:GetOriginalOwner() return original or owner end
	end
	Map.GetPlot(x, y).continent = continent
	table.insert(c.owned, Map.GetPlot(x, y))
	table.insert(Players[owner]._cities, c)
	if isCapital then Players[owner]._setCapital(c) end
	return c
end
function RemoveCity(owner, city)
	local t = Players[owner]._cities
	for i, c in ipairs(t) do if c == city then table.remove(t, i) return end end
end
function SetCapital(owner, city) Players[owner]._setCapital(city) end
function Prop(x, y, n) return Map.GetPlot(x, y).props[n] or 0 end

PlayerManager = {}
function PlayerManager.GetAliveMajorIDs()
	local ids = {}
	for id in pairs(Players) do table.insert(ids, id) end
	table.sort(ids)
	return ids
end
HOOKS = {}
local function hook(name)
	return { Add = function(f) HOOKS[name] = f end }
end
GameEvents = { PlayerTurnStarted = hook("turn"), CityBuilt = hook("built"), CityConquered = hook("conquered") }
LOG = {}
function print(...) local t = {} for _, v in ipairs({...}) do t[#t + 1] = tostring(v) end LOG[#LOG + 1] = table.concat(t, " ") end
"""

MALI, CHINA = "LEADER_EUROPA_GOLDEN_EXPANSION", "LEADER_EUROPA_IMPERIAL_GARDENS"
AMERICA, FRANCE, CREE = "LEADER_EUROPA_SCENIC_GENIUS", "LEADER_EUROPA_PALACE_DESIGNER", "LEADER_EUROPA_BORDERLESS_EMPIRE"
ROUTES, GARDEN = "EUROPA_CONTINENT_ROUTES", "EUROPA_GARDEN_TILES"
CH_WONDER, CH_CITY, HERD, CLAIM = "EUROPA_CHATEAU_WONDER", "EUROPA_CHATEAU_CITY", "EUROPA_HERD_CITY", "EUROPA_TRADE_CLAIM"
OWN = "function Own(c, p) table.insert(c.owned, p) end"
failures = []


def check(name, got, want):
    if got != want:
        failures.append(f"{name}: got {got!r}, want {want!r}")


def fresh(players):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    g = lua.globals()
    for pid, leader in players.items():
        g.AddPlayer(pid, leader)
    return lua, g


def run(lua):
    lua.execute(SCRIPT)


# --- no custom leader: nothing is hooked ------------------------------------
lua, g = fresh({0: "LEADER_TRAJAN"})
run(lua)
check("no hooks without the leaders", len(list(g.HOOKS.keys())), 0)

# --- Mali --------------------------------------------------------------------
lua, g = fresh({0: MALI, 1: "LEADER_TRAJAN"})
cap = g.AddCity(0, 2, 2, 7, 0, True)
g.AddCity(0, 6, 2, 7, 0, False)
run(lua)
check("hooks registered", sorted(g.HOOKS.keys()), ["built", "conquered", "turn"])
g.HOOKS["turn"](0)
check("two cities on a continent: no route", g.Prop(2, 2, ROUTES), 0)
g.AddCity(0, 10, 2, 7, 0, False)
g.HOOKS["built"](0, 3, 10, 2)
check("third city: one route, on the capital", g.Prop(2, 2, ROUTES), 1)
check("... and not on the other cities", g.Prop(10, 2, ROUTES), 0)
# three captured cities on a second continent do not count
for x in (2, 6, 10):
    g.AddCity(0, x, 8, 9, 1, False)
g.HOOKS["turn"](0)
check("captured cities do not count", g.Prop(2, 2, ROUTES), 1)
# three founded cities on a third continent do
second = None
for x in (2, 6, 10):
    c = g.AddCity(0, x, 14, 11, 0, False)
    second = second or c
g.HOOKS["turn"](0)
check("second qualifying continent", g.Prop(2, 2, ROUTES), 2)
writes = g.WRITES
g.HOOKS["turn"](0)
check("unchanged values are not rewritten", g.WRITES, writes)
# the capital moves: the value follows it
g.SetCapital(0, second)
g.HOOKS["turn"](0)
check("old capital cleared", g.Prop(2, 2, ROUTES), 0)
check("new capital carries the value", g.Prop(2, 14, ROUTES), 2)
# the capital is captured by another player
g.RemoveCity(0, second)
g.SetCapital(0, cap)
g.HOOKS["conquered"](1, 0, second.id, 2, 14)
check("captured city's plot is cleared", g.Prop(2, 14, ROUTES), 0)
check("losing a city drops that continent below three", g.Prop(2, 2, ROUTES), 1)
# another player's turn never touches Mali's plots
g.HOOKS["turn"](1)
check("other players are ignored", g.Prop(2, 2, ROUTES), 1)

# cap at four continents
lua, g = fresh({0: MALI})
first = True
for cont in range(6):
    for i in range(3):
        g.AddCity(0, 2 + i * 4, 1 + cont * 3, 100 + cont, 0, first)
        first = False
run(lua)
g.HOOKS["turn"](0)
check("six continents are capped at four routes", g.Prop(2, 1, ROUTES), 4)

# without City:GetOriginalOwner the script degrades instead of erroring
lua, g = fresh({0: MALI})
for i in range(3):
    g.AddCity(0, 2 + i * 4, 2, 5, 0, i == 0, True)
run(lua)
g.HOOKS["turn"](0)
check("missing GetOriginalOwner: counts all cities", g.Prop(2, 2, ROUTES), 1)
check("missing GetOriginalOwner: says so once", sum("GetOriginalOwner" in str(m) for m in g.LOG.values()), 1)

# --- China -------------------------------------------------------------------
lua, g = fresh({0: CHINA})
city = g.AddCity(0, 10, 10, 3, 0, True)
site = g.Map.GetPlot(11, 10)
far = g.Map.GetPlot(20, 10)
lua.execute("function Own(c, p) table.insert(c.owned, p) end")
g.Own(city, site)
g.Own(city, far)
run(lua)
g.HOOKS["turn"](0)
check("no Wonder under construction", g.Prop(10, 10, GARDEN), 0)
site.wonder = 42
neighbours = [g.Map.GetAdjacentPlot(11, 10, d) for d in range(6)]
check("stub gives six distinct neighbours", len({(p.x, p.y) for p in neighbours}), 6)
neighbours[0].appeal = 4
neighbours[1].appeal = 7
neighbours[2].appeal = 3      # Charming, not Breathtaking
g.HOOKS["turn"](0)
check("two Breathtaking neighbours", g.Prop(10, 10, GARDEN), 2)
for p in neighbours:
    p.appeal = 5
g.HOOKS["turn"](0)
check("six Breathtaking neighbours are capped at four", g.Prop(10, 10, GARDEN), 4)
for p in neighbours[1:]:
    p.appeal = 0
far.wonder = 43
for d in range(3):
    g.Map.GetAdjacentPlot(20, 10, d).appeal = 4
g.HOOKS["turn"](0)
check("the better of two unfinished sites counts", g.Prop(10, 10, GARDEN), 3)
site.complete = True
far.complete = True
g.HOOKS["turn"](0)
check("finished Wonders no longer count", g.Prop(10, 10, GARDEN), 0)
check("China never writes the Mali property", g.Prop(10, 10, ROUTES), 0)

# --- America: the same Wonder-site count as China ---------------------------
lua, g = fresh({0: AMERICA})
city = g.AddCity(0, 10, 10, 3, 0, True)
lua.execute(OWN)
site = g.Map.GetPlot(11, 10)
g.Own(city, site)
run(lua)
check("America: hooks registered", sorted(g.HOOKS.keys()), ["built", "conquered", "turn"])
site.wonder = 5
g.HOOKS["turn"](0)
check("America: Wonder site with no Breathtaking neighbour", g.Prop(10, 10, GARDEN), 0)
g.Map.GetAdjacentPlot(11, 10, 2).appeal = 4
g.HOOKS["turn"](0)
check("America: one Breathtaking neighbour", g.Prop(10, 10, GARDEN), 1)
site.complete = True
g.HOOKS["turn"](0)
check("America: finished Wonder no longer counts", g.Prop(10, 10, GARDEN), 0)

# --- France ------------------------------------------------------------------
lua, g = fresh({0: FRANCE, 1: "LEADER_TRAJAN"})
city = g.AddCity(0, 10, 10, 3, 0, True)
other = g.AddCity(0, 25, 10, 3, 0, False)
lua.execute(OWN)
site = g.Map.GetPlot(11, 10)
chateau = g.Map.GetAdjacentPlot(11, 10, 0)
g.Own(city, site)
g.Own(city, chateau)
run(lua)
g.HOOKS["turn"](0)
check("France: no Chateau yet", (g.Prop(10, 10, CH_CITY), g.Prop(10, 10, CH_WONDER)), (0, 0))
chateau.improvement = 7
g.HOOKS["turn"](0)
check("France: city with a Chateau is flagged", g.Prop(10, 10, CH_CITY), 1)
check("France: no Wonder under construction", g.Prop(10, 10, CH_WONDER), 0)
check("France: the other city is not flagged", g.Prop(25, 10, CH_CITY), 0)
site.wonder = 9
g.HOOKS["turn"](0)
check("France: Wonder site touching a Chateau", g.Prop(10, 10, CH_WONDER), 1)
chateau.improvement = 3      # some other improvement
g.HOOKS["turn"](0)
check("France: another improvement is not a Chateau", (g.Prop(10, 10, CH_CITY), g.Prop(10, 10, CH_WONDER)), (0, 0))
chateau.improvement = 7
site.complete = True
g.HOOKS["turn"](0)
check("France: finished Wonder no longer counts", (g.Prop(10, 10, CH_CITY), g.Prop(10, 10, CH_WONDER)), (1, 0))
g.RemoveCity(0, city)
g.HOOKS["conquered"](1, 0, city.id, 10, 10)
check("France: captured city's flags are cleared", g.Prop(10, 10, CH_CITY), 0)

# --- Cree --------------------------------------------------------------------
lua, g = fresh({0: CREE, 1: "LEADER_TRAJAN"})
city = g.AddCity(0, 10, 10, 3, 0, True)
captured = g.AddCity(0, 30, 10, 3, 1, False)
lua.execute(OWN)
ring1 = [g.Map.GetAdjacentPlot(10, 10, d) for d in range(6)]
for p in ring1:
    p.owner = 0                       # the city's first ring is already owned
    g.Own(city, p)
run(lua)
g.HOOKS["turn"](0)
check("Cree: no Camp or Pasture", g.Prop(10, 10, HERD), 0)
check("Cree: no Trade Route, nothing claimed", (len(list(g.CLAIMS.values())), g.Prop(10, 10, CLAIM)), (0, 0))
ring1[0].improvement = 4
g.HOOKS["turn"](0)
check("Cree: Pasture flags the city", g.Prop(10, 10, HERD), 1)
ring1[0].improvement = 3
g.HOOKS["turn"](0)
check("Cree: Camp flags the city", g.Prop(10, 10, HERD), 1)
ring1[0].improvement = 7
g.HOOKS["turn"](0)
check("Cree: another improvement does not", g.Prop(10, 10, HERD), 0)
# second ring: make the first candidates water or foreign so land is preferred
lua.execute("""
function Ring2()
	local seen, out = {}, {}
	seen[Map.GetPlot(10, 10):GetIndex()] = true
	for d = 0, 5 do seen[Map.GetAdjacentPlot(10, 10, d):GetIndex()] = true end
	for d = 0, 5 do
		local a = Map.GetAdjacentPlot(10, 10, d)
		for e = 0, 5 do
			local b = Map.GetAdjacentPlot(a.x, a.y, e)
			if not seen[b:GetIndex()] then seen[b:GetIndex()] = true; out[#out + 1] = b end
		end
	end
	return out
end
function Push(t, v) t[#t + 1] = v end
""")
ring2 = list(g.Ring2().values())
check("stub gives twelve second-ring plots", len(ring2), 12)
ring2[0].water = True
ring2[1].owner = 1
g.Push(city.routes, lua.table())
g.Push(captured.routes, lua.table())
g.HOOKS["turn"](0)
claims = [(c.x, c.y, c.city) for c in g.CLAIMS.values()]
check("Cree: first route claims the two nearest free land tiles",
      claims, [(ring2[2].x, ring2[2].y, city.id), (ring2[3].x, ring2[3].y, city.id)])
check("Cree: water and foreign tiles were passed over", (ring2[0].owner, ring2[1].owner), (-1, 1))
check("Cree: city is marked", g.Prop(10, 10, CLAIM), 1)
check("Cree: captured city claims nothing", g.Prop(30, 10, CLAIM), 0)
g.HOOKS["turn"](0)
check("Cree: only once per city", len(list(g.CLAIMS.values())), 2)
g.HOOKS["conquered"](1, 0, city.id, 10, 10)
check("Cree: the claim flag survives capture", g.Prop(10, 10, CLAIM), 1)

# water is used when no land is free within range
lua, g = fresh({0: CREE})
city = g.AddCity(0, 10, 10, 3, 0, True)
lua.execute("for y = 0, 19 do for x = 0, 39 do local p = Map.GetPlot(x, y); if p.owner == -1 then p.water = true end end end")
lua.execute("function Push(t, v) t[#t + 1] = v end")
g.Push(city.routes, lua.table())
run(lua)
g.HOOKS["turn"](0)
check("Cree: water tiles are claimed when no land is free", len(list(g.CLAIMS.values())), 2)

# nothing free within three tiles: flag set, nothing claimed
lua, g = fresh({0: CREE})
city = g.AddCity(0, 10, 10, 3, 0, True)
lua.execute("for y = 0, 19 do for x = 0, 39 do Map.GetPlot(x, y).owner = 0 end end")
lua.execute("function Push(t, v) t[#t + 1] = v end")
g.Push(city.routes, lua.table())
run(lua)
g.HOOKS["turn"](0)
check("Cree: no free tile, nothing claimed but marked", (len(list(g.CLAIMS.values())), g.Prop(10, 10, CLAIM)), (0, 1))

# the game refuses the assignment: counted as nothing, reported once
lua, g = fresh({0: CREE})
city = g.AddCity(0, 10, 10, 3, 0, True)
lua.execute("NO_CLAIM_API = true; function Push(t, v) t[#t + 1] = v end")
g.Push(city.routes, lua.table())
run(lua)
g.HOOKS["turn"](0)
check("Cree: refused assignment claims nothing", sum(1 for y in range(20) for x in range(40) if g.Map.GetPlot(x, y).owner == 0), 1)
check("Cree: refused assignment is reported once", sum("Could not assign" in str(m) for m in g.LOG.values()), 1)

# no City:GetTrade in this context: degrade, say so once
lua = lupa.LuaRuntime(unpack_returned_tuples=True)
lua.execute("NO_TRADE_API = true")
lua.execute(STUBS)
g = lua.globals()
g.AddPlayer(0, CREE)
g.AddCity(0, 10, 10, 3, 0, True)
run(lua)
g.HOOKS["turn"](0)
g.HOOKS["turn"](0)
check("Cree: missing trade API claims nothing", g.Prop(10, 10, CLAIM), 0)
check("Cree: missing trade API is reported once", sum("GetTrade" in str(m) for m in g.LOG.values()), 1)

if failures:
    print("LEADER SCRIPT TEST FAILED")
    for f in failures:
        print("  " + f)
    sys.exit(1)
print("leader script: all checks passed")
