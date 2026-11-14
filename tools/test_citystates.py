#!/usr/bin/env python3
"""Run Scripts/Europa_CityStates.lua outside the game, against stubbed game globals.

Needs the 'lupa' package (pip install lupa). Exits 0 with a SKIPPED line when it
is not installed, so tools/validate.sh still works without it.

This checks the script's own counting and wiring. It cannot check that the real
game exposes the same functions to gameplay scripts; that needs a game run and a
look at Lua.log.

Checks:
  * no hooks are registered when none of the city-states is in the game
  * Syracuse: a Campus counts each adjacent completed Aqueduct and Dam (a Bath counts
    as an Aqueduct, another player's counts, an unfinished one does not)
  * Ubud: a Theater Square counts adjacent unimproved Woods and Rainforest, capped at 2
  * Sheffield: Mines and Quarries touching one of the player's own completed Industrial
    Zones are flagged; a Zone (or Hansa) is flagged with three of the player's
    unpillaged Mines or Quarries beside it, and not when it is pillaged
  * Lhasa: a Holy Site with two adjacent Mountains is flagged, and its city with it
  * Ravenna: (the district Production bonus is database-only) a city with a working Harbor and Encampment is flagged only while it is
    constructing a building of either district
  * Bruges: Hubs and Theater Squares count each other; a city with both counts the
    Trade Routes it sends, capped at 2, each city on its own
  * values are cleared when the thing they described goes away, minor players are
    ignored, unchanged values are not rewritten, and missing engine functions degrade
    to a warning instead of an error
"""
import sys
from pathlib import Path

try:
    import lupa
except ImportError:
    print("SKIPPED: lupa not installed")
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = (ROOT / "Scripts" / "Europa_CityStates.lua").read_text(encoding="utf-8")

STUBS = r"""
DirectionTypes = { NUM_DIRECTION_TYPES = 6 }
local function tbl(rows, key)
	local t = setmetatable({}, { __call = function()
		local i = 0
		return function() i = i + 1; return rows[i] end
	end })
	for i, r in ipairs(rows) do r.Index = i - 1; r.Hash = 1000 + i; t[r[key]] = r end
	return t
end
GameInfo = {
	Districts = tbl({
		{ DistrictType = "DISTRICT_CITY_CENTER" }, { DistrictType = "DISTRICT_CAMPUS" }, { DistrictType = "DISTRICT_THEATER" },
		{ DistrictType = "DISTRICT_COMMERCIAL_HUB" }, { DistrictType = "DISTRICT_INDUSTRIAL_ZONE" }, { DistrictType = "DISTRICT_HANSA" },
		{ DistrictType = "DISTRICT_HOLY_SITE" }, { DistrictType = "DISTRICT_AQUEDUCT" }, { DistrictType = "DISTRICT_BATH" },
		{ DistrictType = "DISTRICT_DAM" }, { DistrictType = "DISTRICT_HARBOR" }, { DistrictType = "DISTRICT_ENCAMPMENT" },
		{ DistrictType = "DISTRICT_IKANDA" }, { DistrictType = "DISTRICT_ENTERTAINMENT_COMPLEX" } }, "DistrictType"),
	DistrictReplaces = tbl({
		{ CivUniqueDistrictType = "DISTRICT_HANSA", ReplacesDistrictType = "DISTRICT_INDUSTRIAL_ZONE" },
		{ CivUniqueDistrictType = "DISTRICT_BATH", ReplacesDistrictType = "DISTRICT_AQUEDUCT" },
		{ CivUniqueDistrictType = "DISTRICT_IKANDA", ReplacesDistrictType = "DISTRICT_ENCAMPMENT" } }, "CivUniqueDistrictType"),
	Features = tbl({ { FeatureType = "FEATURE_FLOODPLAINS" }, { FeatureType = "FEATURE_FOREST" }, { FeatureType = "FEATURE_JUNGLE" },
		{ FeatureType = "FEATURE_MARSH" } }, "FeatureType"),
	Improvements = tbl({ { ImprovementType = "IMPROVEMENT_FARM" }, { ImprovementType = "IMPROVEMENT_MINE" },
		{ ImprovementType = "IMPROVEMENT_QUARRY" }, { ImprovementType = "IMPROVEMENT_LUMBER_MILL" } }, "ImprovementType"),
	Buildings = tbl({ { BuildingType = "BUILDING_MONUMENT", PrereqDistrict = "DISTRICT_CITY_CENTER" },
		{ BuildingType = "BUILDING_LIGHTHOUSE", PrereqDistrict = "DISTRICT_HARBOR" },
		{ BuildingType = "BUILDING_BARRACKS", PrereqDistrict = "DISTRICT_ENCAMPMENT" },
		{ BuildingType = "BUILDING_LIBRARY", PrereqDistrict = "DISTRICT_CAMPUS" },
		{ BuildingType = "BUILDING_PALACE" } }, "BuildingType"),
}
function D(name) return GameInfo.Districts[name].Index end
function F(name) return GameInfo.Features[name].Index end
function I(name) return GameInfo.Improvements[name].Index end
function B(name) return GameInfo.Buildings[name].Hash end

local W, H = 40, 20
local plots = {}
local function key(x, y) return y * W + x end
WRITES = 0
NO_PILLAGE_API = false
local function newPlot(x, y)
	local p = { x = x, y = y, props = {}, owner = -1, improvement = -1, improvementPillaged = false, feature = -1,
		mountain = false, district = -1, complete = true, pillaged = false }
	function p:GetX() return self.x end
	function p:GetY() return self.y end
	function p:GetOwner() return self.owner end
	function p:GetDistrictType() return self.district end
	function p:GetFeatureType() return self.feature end
	function p:GetImprovementType() return self.improvement end
	function p:IsMountain() return self.mountain end
	function p:GetProperty(n) return self.props[n] end
	function p:SetProperty(n, v) self.props[n] = v; WRITES = WRITES + 1 end
	return p
end
for y = 0, H - 1 do for x = 0, W - 1 do plots[key(x, y)] = newPlot(x, y) end end
function EnablePillageApi(on)
	for _, p in pairs(plots) do
		p.IsImprovementPillaged = on and function(self) return self.improvementPillaged end or nil
	end
end
EnablePillageApi(true)
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
-- The i-th neighbour (1..6) of a plot, for laying out test maps.
function Near(x, y, i) return Map.GetAdjacentPlot(x, y, i - 1) end

CityManager = {}
function CityManager.GetDistrictAt(x, y)
	local p = Map.GetPlot(x, y)
	if p == nil or p.district < 0 then return nil end
	return { IsComplete = function() return p.complete end, IsPillaged = function() return p.pillaged end }
end

PlayerConfigurations = {}
Players = {}
function AddPlayer(id, civ, major)
	PlayerConfigurations[id] = { GetCivilizationTypeName = function() return civ end }
	local cities = {}
	local C = {}
	function C:Members()
		local i = 0
		return function() i = i + 1; if cities[i] then return i, cities[i] end end
	end
	Players[id] = { GetCities = function() return C end, IsMajor = function() return major end, _cities = cities }
end
NO_TRADE_API = false
NO_QUEUE_API = false
function AddCity(owner, x, y)
	local c = { x = x, y = y, owned = {}, routes = {}, producing = 0 }
	function c:GetX() return self.x end
	function c:GetY() return self.y end
	function c:GetOwnedPlots() return self.owned end
	if not NO_TRADE_API then
		function c:GetTrade() return { GetOutgoingRoutes = function() return c.routes end } end
	end
	if not NO_QUEUE_API then
		function c:GetBuildQueue() return { GetCurrentProductionTypeHash = function() return c.producing end } end
	end
	local centre = Map.GetPlot(x, y)
	centre.owner = owner; centre.district = D("DISTRICT_CITY_CENTER")
	table.insert(c.owned, centre)
	table.insert(Players[owner]._cities, c)
	return c
end
-- Give a plot to a city and set anything else about it.
function Own(c, p, fields)
	p.owner = Map.GetPlot(c.x, c.y).owner
	table.insert(c.owned, p)
	for k, v in pairs(fields or {}) do p[k] = v end
	return p
end
function Set(p, fields) for k, v in pairs(fields) do p[k] = v end return p end
function Prop(p, n) return p.props[n] or 0 end

HOOKS = {}
local function hook(name)
	return { Add = function(f) HOOKS[name] = f end }
end
GameEvents = { PlayerTurnStarted = hook("turn"), CityBuilt = hook("built"), CityConquered = hook("conquered"),
	OnDistrictConstructed = hook("district"), OnPillage = hook("pillage") }
LOG = {}
function print(...) local t = {} for _, v in ipairs({...}) do t[#t + 1] = tostring(v) end LOG[#LOG + 1] = table.concat(t, " ") end
"""

WATER, WILD, STEEL, MONK = "EUROPA_CS_WATERWORKS", "EUROPA_CS_WILD_TILES", "EUROPA_CS_STEELWORKS", "EUROPA_CS_MONASTERY"
HUB_T, T_HUB, TILE = "EUROPA_CS_HUB_THEATERS", "EUROPA_CS_THEATER_HUBS", "EUROPA_CS_STEEL_TILE"
MONK_CITY, ARSENAL, TRADE = "EUROPA_CS_MONASTERY_CITY", "EUROPA_CS_ARSENAL", "EUROPA_CS_TRADE_CULTURE"
failures = []


def check(name, got, want):
    if got != want:
        failures.append(f"{name}: got {got!r}, want {want!r}")


def fresh(city_state="CIVILIZATION_EUROPA_SYRACUSE", setup=""):
    """Players 0 and 1 are majors, 2 is a city-state (ours unless told otherwise)."""
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    lua.execute(setup)
    g = lua.globals()
    g.AddPlayer(0, "CIVILIZATION_ROME", True)
    g.AddPlayer(1, "CIVILIZATION_GERMANY", True)
    g.AddPlayer(2, city_state, False)
    return lua, g


def table(lua, **fields):
    return lua.table_from(fields)


# --- none of our city-states in the game: nothing is hooked -----------------
lua, g = fresh("CIVILIZATION_FEZ")
lua.execute(SCRIPT)
check("no hooks without the city-states", len(list(g.HOOKS.keys())), 0)

# --- Syracuse ----------------------------------------------------------------
lua, g = fresh()
lua.execute(SCRIPT)
check("hooks registered", sorted(g.HOOKS.keys()), ["built", "conquered", "district", "pillage", "turn"])
city = g.AddCity(0, 10, 10)
other = g.AddCity(1, 16, 10)
campus = g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_CAMPUS")))
g.HOOKS["turn"](0)
check("Campus alone", g.Prop(campus, WATER), 0)
g.Own(city, g.Near(12, 10, 1), table(lua, district=g.D("DISTRICT_AQUEDUCT")))
dam = g.Own(city, g.Near(12, 10, 2), table(lua, district=g.D("DISTRICT_DAM"), complete=False))
g.Own(city, g.Near(12, 10, 3), table(lua, district=g.D("DISTRICT_ENTERTAINMENT_COMPLEX")))
g.HOOKS["turn"](0)
check("Aqueduct counts, unfinished Dam and other districts do not", g.Prop(campus, WATER), 1)
g.Set(dam, table(lua, complete=True))
g.HOOKS["district"](0, g.D("DISTRICT_DAM"), dam.x, dam.y)
check("the Dam counts once finished (district event)", g.Prop(campus, WATER), 2)
g.Own(other, g.Near(12, 10, 4), table(lua, district=g.D("DISTRICT_BATH")))
g.HOOKS["turn"](0)
check("another player's Bath counts as an Aqueduct", g.Prop(campus, WATER), 3)
writes = g.WRITES
g.HOOKS["turn"](0)
check("unchanged values are not rewritten", g.WRITES, writes)
g.Set(campus, table(lua, district=-1))
g.HOOKS["turn"](0)
check("value cleared when the Campus is gone", g.Prop(campus, WATER), 0)
# an unfinished Campus gets nothing
g.Set(campus, table(lua, district=g.D("DISTRICT_CAMPUS"), complete=False))
g.HOOKS["turn"](0)
check("unfinished Campus", g.Prop(campus, WATER), 0)
# city-states are not processed
minor = g.AddCity(2, 30, 4)
mc = g.Own(minor, g.Map.GetPlot(32, 4), table(lua, district=g.D("DISTRICT_CAMPUS")))
g.Own(minor, g.Near(32, 4, 1), table(lua, district=g.D("DISTRICT_AQUEDUCT")))
g.HOOKS["turn"](2)
check("minor players are ignored", g.Prop(mc, WATER), 0)

# --- Ubud --------------------------------------------------------------------
lua, g = fresh("CIVILIZATION_EUROPA_UBUD")
lua.execute(SCRIPT)
city = g.AddCity(0, 10, 10)
theater = g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_THEATER")))
g.Set(g.Near(12, 10, 1), table(lua, feature=g.F("FEATURE_FOREST")))                                    # unowned woods count
mill = g.Set(g.Near(12, 10, 2), table(lua, feature=g.F("FEATURE_FOREST"), improvement=g.I("IMPROVEMENT_LUMBER_MILL")))
g.Set(g.Near(12, 10, 3), table(lua, feature=g.F("FEATURE_MARSH")))
g.HOOKS["turn"](0)
check("one unimproved Woods; a Lumber Mill and Marsh do not count", g.Prop(theater, WILD), 1)
g.Set(g.Near(12, 10, 4), table(lua, feature=g.F("FEATURE_JUNGLE")))
g.HOOKS["turn"](0)
check("Woods and Rainforest", g.Prop(theater, WILD), 2)
g.Set(g.Near(12, 10, 5), table(lua, feature=g.F("FEATURE_JUNGLE")))
g.Set(mill, table(lua, improvement=-1))
g.HOOKS["turn"](0)
check("capped at 2 with four tiles", g.Prop(theater, WILD), 2)
g.Set(g.Near(12, 10, 1), table(lua, feature=-1))
g.Set(g.Near(12, 10, 4), table(lua, feature=-1))
g.Set(g.Near(12, 10, 5), table(lua, feature=-1))
g.HOOKS["turn"](0)
check("recounted after the Woods are cut", g.Prop(theater, WILD), 1)

# --- Sheffield ---------------------------------------------------------------
lua, g = fresh("CIVILIZATION_EUROPA_SHEFFIELD")
lua.execute(SCRIPT)
city = g.AddCity(0, 10, 10)
zone = g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_HANSA")))
m1 = g.Own(city, g.Near(12, 10, 1), table(lua, improvement=g.I("IMPROVEMENT_MINE")))
q1 = g.Own(city, g.Near(12, 10, 2), table(lua, improvement=g.I("IMPROVEMENT_QUARRY")))
far = g.Own(city, g.Map.GetPlot(7, 10), table(lua, improvement=g.I("IMPROVEMENT_MINE")))
farm = g.Own(city, g.Near(12, 10, 3), table(lua, improvement=g.I("IMPROVEMENT_FARM")))
g.HOOKS["turn"](0)
check("Mine beside the Zone", g.Prop(m1, TILE), 1)
check("Quarry beside the Zone", g.Prop(q1, TILE), 1)
check("Mine elsewhere", g.Prop(far, TILE), 0)
check("Farm beside the Zone", g.Prop(farm, TILE), 0)
check("two Mines/Quarries: no Great Engineer point", g.Prop(zone, STEEL), 0)
# a third, owned by the same player through another city, counts; a foreign one does not
city2 = g.AddCity(0, 16, 10)
other = g.AddCity(1, 20, 16)
foreign = g.Own(other, g.Near(12, 10, 4), table(lua, improvement=g.I("IMPROVEMENT_MINE")))
g.HOOKS["turn"](0); g.HOOKS["turn"](1)
check("a foreign Mine does not count", g.Prop(zone, STEEL), 0)
check("a foreign Mine beside our Zone gets nothing", g.Prop(foreign, TILE), 0)
m3 = g.Own(city2, g.Near(12, 10, 5), table(lua, improvement=g.I("IMPROVEMENT_MINE")))
g.HOOKS["turn"](0)
check("three of the player's Mines/Quarries, one in another city", g.Prop(zone, STEEL), 1)
check("the other city's Mine is flagged too", g.Prop(m3, TILE), 1)
g.Set(m1, table(lua, improvementPillaged=True))
g.HOOKS["pillage"](1, 5, g.I("IMPROVEMENT_MINE"), -1, -1, g.Index(m1.x, m1.y))
check("a pillaged Mine stops counting (pillage event)", g.Prop(zone, STEEL), 0)
check("... and loses its own bonus", g.Prop(m1, TILE), 0)
g.Set(m1, table(lua, improvementPillaged=False))
g.Set(zone, table(lua, pillaged=True))
g.HOOKS["turn"](0)
check("a pillaged Zone earns no point", g.Prop(zone, STEEL), 0)
g.Set(zone, table(lua, pillaged=False, complete=False))
g.HOOKS["turn"](0)
check("an unfinished Zone gives its Mines nothing", g.Prop(m1, TILE), 0)
g.Set(zone, table(lua, complete=True))
g.EnablePillageApi(False)
g.HOOKS["turn"](0)
check("without the pillage API the count still works", g.Prop(zone, STEEL), 1)
check("... and says so once", sum("IsImprovementPillaged" in str(m) for m in g.LOG.values()), 1)

# --- Lhasa -------------------------------------------------------------------
lua, g = fresh("CIVILIZATION_EUROPA_LHASA")
lua.execute(SCRIPT)
city = g.AddCity(0, 10, 10)
site = g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_HOLY_SITE")))
g.Set(g.Near(12, 10, 1), table(lua, mountain=True))
g.HOOKS["turn"](0)
check("one Mountain", (g.Prop(site, MONK), g.Prop(g.Map.GetPlot(10, 10), MONK_CITY)), (0, 0))
g.Set(g.Near(12, 10, 2), table(lua, mountain=True))
g.Set(g.Near(12, 10, 3), table(lua, mountain=True))
g.HOOKS["turn"](0)
check("three Mountains: flagged once, district and city", (g.Prop(site, MONK), g.Prop(g.Map.GetPlot(10, 10), MONK_CITY)), (1, 1))
g.Set(site, table(lua, pillaged=True))
g.HOOKS["turn"](0)
check("a pillaged Holy Site", (g.Prop(site, MONK), g.Prop(g.Map.GetPlot(10, 10), MONK_CITY)), (0, 0))

# --- Ravenna -----------------------------------------------------------------
lua, g = fresh("CIVILIZATION_EUROPA_RAVENNA")
lua.execute(SCRIPT)
city = g.AddCity(0, 10, 10)
centre = g.Map.GetPlot(10, 10)
harbor = g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_HARBOR")))
city.producing = g.B("BUILDING_LIGHTHOUSE")
g.HOOKS["turn"](0)
check("Harbor only", g.Prop(centre, ARSENAL), 0)
camp = g.Own(city, g.Map.GetPlot(8, 10), table(lua, district=g.D("DISTRICT_IKANDA")))
g.HOOKS["turn"](0)
check("Harbor and Ikanda, building a Lighthouse", g.Prop(centre, ARSENAL), 1)
city.producing = g.B("BUILDING_BARRACKS")
g.HOOKS["turn"](0)
check("building a Barracks", g.Prop(centre, ARSENAL), 1)
for name in ("BUILDING_LIBRARY", "BUILDING_MONUMENT", "BUILDING_PALACE"):
    city.producing = g.B(name)
    g.HOOKS["turn"](0)
    check(f"building {name}", g.Prop(centre, ARSENAL), 0)
city.producing = 0
g.HOOKS["turn"](0)
check("building nothing", g.Prop(centre, ARSENAL), 0)
city.producing = g.B("BUILDING_LIGHTHOUSE")
g.Set(camp, table(lua, pillaged=True))
g.HOOKS["turn"](0)
check("a pillaged Encampment", g.Prop(centre, ARSENAL), 0)
lua, g = fresh("CIVILIZATION_EUROPA_RAVENNA", "NO_QUEUE_API = true")
lua.execute(SCRIPT)
city = g.AddCity(0, 10, 10)
g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_HARBOR")))
g.Own(city, g.Map.GetPlot(8, 10), table(lua, district=g.D("DISTRICT_ENCAMPMENT")))
g.HOOKS["turn"](0); g.HOOKS["turn"](0)
check("no build-queue API: no bonus", g.Prop(g.Map.GetPlot(10, 10), ARSENAL), 0)
check("... and one warning", sum("GetBuildQueue" in str(m) for m in g.LOG.values()), 1)

# --- Bruges ------------------------------------------------------------------
lua, g = fresh("CIVILIZATION_EUROPA_BRUGES")
lua.execute(SCRIPT)
city = g.AddCity(0, 10, 10)
centre = g.Map.GetPlot(10, 10)
hub = g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_COMMERCIAL_HUB")))
lua.execute("function Routes(c, n) c.routes = {} for i = 1, n do c.routes[i] = {} end end")
g.Routes(city, 2)
g.HOOKS["turn"](0)
check("Hub only: no Trade Route Culture", g.Prop(centre, TRADE), 0)
theater = g.Own(city, g.Near(12, 10, 1), table(lua, district=g.D("DISTRICT_THEATER")))
g.HOOKS["turn"](0)
check("Hub beside a Theater Square", g.Prop(hub, HUB_T), 1)
check("Theater Square beside a Hub", g.Prop(theater, T_HUB), 1)
check("two routes", g.Prop(centre, TRADE), 2)
g.Routes(city, 5)
g.HOOKS["turn"](0)
check("five routes: capped at 2", g.Prop(centre, TRADE), 2)
g.Routes(city, 1)
g.HOOKS["turn"](0)
check("one route", g.Prop(centre, TRADE), 1)
# a second city counts on its own, and its districts need not touch
city2 = g.AddCity(0, 20, 10)
g.Own(city2, g.Map.GetPlot(22, 10), table(lua, district=g.D("DISTRICT_COMMERCIAL_HUB")))
t2 = g.Own(city2, g.Map.GetPlot(18, 10), table(lua, district=g.D("DISTRICT_THEATER")))
g.Routes(city2, 2)
g.HOOKS["built"](0, 2, 20, 10)
check("second city: its own two routes", (g.Prop(centre, TRADE), g.Prop(g.Map.GetPlot(20, 10), TRADE)), (1, 2))
check("districts apart: no adjacency", g.Prop(t2, T_HUB), 0)
# a second Theater Square (another city's) beside the first Hub
g.Own(city2, g.Near(12, 10, 2), table(lua, district=g.D("DISTRICT_THEATER")))
g.HOOKS["turn"](0)
check("Hub beside two Theater Squares", g.Prop(hub, HUB_T), 2)
# captured: the plots are recounted for the new owner
lua.execute("""function Capture(c, from, to)
	for i, x in ipairs(Players[from]._cities) do if x == c then table.remove(Players[from]._cities, i) break end end
	table.insert(Players[to]._cities, c)
	for _, p in ipairs(c.owned) do p.owner = to end
end""")
g.Capture(city, 0, 1)
g.Routes(city, 0)
g.HOOKS["conquered"](1, 0, 1, 10, 10)
check("captured city: routes recounted", g.Prop(centre, TRADE), 0)
check("captured city: adjacency kept", g.Prop(hub, HUB_T), 2)
lua, g = fresh("CIVILIZATION_EUROPA_BRUGES", "NO_TRADE_API = true")
lua.execute(SCRIPT)
city = g.AddCity(0, 10, 10)
g.Own(city, g.Map.GetPlot(12, 10), table(lua, district=g.D("DISTRICT_COMMERCIAL_HUB")))
g.Own(city, g.Map.GetPlot(8, 10), table(lua, district=g.D("DISTRICT_THEATER")))
g.HOOKS["turn"](0); g.HOOKS["turn"](0)
check("no trade API: no bonus", g.Prop(g.Map.GetPlot(10, 10), TRADE), 0)
check("... and one warning", sum("GetTrade" in str(m) for m in g.LOG.values()), 1)

if failures:
    print("CITY-STATE SCRIPT TESTS FAILED:")
    for f in failures:
        print("  " + f)
    sys.exit(1)
print("city-state script logic OK")
