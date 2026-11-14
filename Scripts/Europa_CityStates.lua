-- Project Europa: city-states, the counting the modifier system cannot do.
--
-- The database can test "this plot has property X >= n" but cannot count the tiles
-- round a district, tell which district a neighbour is, or see what a city is
-- building. This script works those out for every major player and writes the
-- answer onto a plot; modifiers in Data/Europa_CityState_*.sql read it back.
--
-- It never asks who the Suzerain is. The numbers are kept for everyone and the
-- engine attaches the modifiers that read them to the Suzerain only, so a change
-- of Suzerain takes effect at once with nothing to recalculate here.
--
--   on a district's own plot
--     EUROPA_CS_WATERWORKS     Campus: adjacent completed Aqueducts and Dams           (Syracuse)
--     EUROPA_CS_WILD_TILES     Theater Square: adjacent unimproved Woods or Rainforest,
--                              capped at 2                                             (Ubud)
--     EUROPA_CS_STEELWORKS     Industrial Zone: 1 with three adjacent Mines or Quarries (Sheffield)
--     EUROPA_CS_MONASTERY      Holy Site: 1 with two adjacent Mountains                (Lhasa)
--     EUROPA_CS_HUB_THEATERS   Commercial Hub: adjacent completed Theater Squares      (Bruges)
--     EUROPA_CS_THEATER_HUBS   Theater Square: adjacent completed Commercial Hubs      (Bruges)
--   on a Mine or Quarry plot
--     EUROPA_CS_STEEL_TILE     1 while it touches one of its owner's Industrial Zones  (Sheffield)
--   on the city-centre plot
--     EUROPA_CS_MONASTERY_CITY 1 while the city's Holy Site has EUROPA_CS_MONASTERY    (Lhasa)
--     EUROPA_CS_ARSENAL        1 while a city with a Harbor and an Encampment is
--                              constructing a building of either district              (Ravenna)
--     EUROPA_CS_TRADE_CULTURE  Trade Routes sent by a city with a Commercial Hub and a
--                              Theater Square, capped at 2                             (Bruges)
--
-- A civilization's unique district counts as the district it replaces (a Hansa is
-- an Industrial Zone, a Seowon a Campus).
--
-- Multiplayer: only GameEvents (simulation-side, fired identically on every
-- machine) are used, and nothing here is random. Values therefore refresh at the
-- start of the owner's turn, when a district is finished, when something is
-- pillaged and when a city is founded or changes hands; not the instant a Builder
-- finishes a Mine or a city changes what it is producing.

local CITY_STATES = {
	"CIVILIZATION_EUROPA_SYRACUSE", "CIVILIZATION_EUROPA_UBUD", "CIVILIZATION_EUROPA_SHEFFIELD",
	"CIVILIZATION_EUROPA_RAVENNA", "CIVILIZATION_EUROPA_LHASA", "CIVILIZATION_EUROPA_BRUGES",
};

local PROP_WATERWORKS     = "EUROPA_CS_WATERWORKS";
local PROP_WILD_TILES     = "EUROPA_CS_WILD_TILES";
local PROP_STEELWORKS     = "EUROPA_CS_STEELWORKS";
local PROP_MONASTERY      = "EUROPA_CS_MONASTERY";
local PROP_HUB_THEATERS   = "EUROPA_CS_HUB_THEATERS";
local PROP_THEATER_HUBS   = "EUROPA_CS_THEATER_HUBS";
local PROP_STEEL_TILE     = "EUROPA_CS_STEEL_TILE";
local PROP_MONASTERY_CITY = "EUROPA_CS_MONASTERY_CITY";
local PROP_ARSENAL        = "EUROPA_CS_ARSENAL";
local PROP_TRADE_CULTURE  = "EUROPA_CS_TRADE_CULTURE";
-- Written on every plot a city owns (0 where they do not apply), so a value can
-- never outlive the district or improvement it described.
local PLOT_PROPERTIES = { PROP_WATERWORKS, PROP_WILD_TILES, PROP_STEELWORKS, PROP_MONASTERY,
	PROP_HUB_THEATERS, PROP_THEATER_HUBS, PROP_STEEL_TILE };

local MAX_WILD_TILES      = 2;   -- one modifier tier per point; keep in step with the SQL
local MAX_TRADE_CULTURE   = 2;   -- likewise
local STEELWORKS_TILES    = 3;   -- Mines or Quarries an Industrial Zone needs
local MONASTERY_MOUNTAINS = 2;   -- Mountains a Holy Site needs
local MAX_PLAYER_SLOTS     = 64;  -- majors, city-states, free cities and barbarians all fit below this

local m_Warned = {};
local function WarnOnce(sKey, sMessage)
	if not m_Warned[sKey] then
		m_Warned[sKey] = true;
		print("Europa city-states: " .. sMessage);
	end
end

local function SetPlotProperty(pPlot, sName, iValue)
	if pPlot ~= nil and (pPlot:GetProperty(sName) or 0) ~= iValue then
		pPlot:SetProperty(sName, iValue);
	end
end

-- ---------------------------------------------------------------------------
-- Game data, looked up once
-- ---------------------------------------------------------------------------
local m_BaseDistrict = {};   -- district index -> the type name it stands for ("DISTRICT_HANSA" -> "DISTRICT_INDUSTRIAL_ZONE")
local m_Wild         = {};   -- feature index -> true for Woods and Rainforest
local m_Diggings     = {};   -- improvement index -> true for Mines and Quarries
local m_ArsenalBuilding = {};   -- building hash -> true for buildings of a Harbor or an Encampment

local function LoadGameData()
	local kReplaces = {};
	for kRow in GameInfo.DistrictReplaces() do
		kReplaces[kRow.CivUniqueDistrictType] = kRow.ReplacesDistrictType;
	end
	local kBaseByName = {};
	for kRow in GameInfo.Districts() do
		kBaseByName[kRow.DistrictType] = kReplaces[kRow.DistrictType] or kRow.DistrictType;
		m_BaseDistrict[kRow.Index] = kBaseByName[kRow.DistrictType];
	end
	for _, sType in ipairs({ "FEATURE_FOREST", "FEATURE_JUNGLE" }) do
		local kRow = GameInfo.Features[sType];
		if kRow ~= nil then m_Wild[kRow.Index] = true; end
	end
	for _, sType in ipairs({ "IMPROVEMENT_MINE", "IMPROVEMENT_QUARRY" }) do
		local kRow = GameInfo.Improvements[sType];
		if kRow ~= nil then m_Diggings[kRow.Index] = true; end
	end
	for kRow in GameInfo.Buildings() do
		local sBase = kRow.PrereqDistrict and kBaseByName[kRow.PrereqDistrict] or nil;
		if sBase == "DISTRICT_HARBOR" or sBase == "DISTRICT_ENCAMPMENT" then
			m_ArsenalBuilding[kRow.Hash] = true;
		end
	end
end

-- ---------------------------------------------------------------------------
-- Reading the map
-- ---------------------------------------------------------------------------

-- The district on a plot as (base type name, pillaged), or nil when there is none
-- or it is still under construction.
local function GetCompletedDistrict(pPlot)
	local eDistrict = pPlot:GetDistrictType();
	if eDistrict == nil or eDistrict < 0 then return nil; end
	local sBase = m_BaseDistrict[eDistrict];
	if sBase == nil then return nil; end
	if CityManager == nil or CityManager.GetDistrictAt == nil then
		WarnOnce("GetDistrictAt", "CityManager.GetDistrictAt is unavailable in this context; unfinished and pillaged districts are counted as working.");
		return sBase, false;
	end
	local pDistrict = CityManager.GetDistrictAt(pPlot:GetX(), pPlot:GetY());
	if pDistrict == nil then return nil; end
	if pDistrict.IsComplete == nil or pDistrict.IsPillaged == nil then
		WarnOnce("DistrictState", "District:IsComplete/IsPillaged are unavailable in this context; unfinished and pillaged districts are counted as working.");
		return sBase, false;
	end
	if not pDistrict:IsComplete() then return nil; end
	return sBase, pDistrict:IsPillaged();
end

local function CountNeighbours(pPlot, fnMatches)
	local iCount = 0;
	for eDirection = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pAdjacent = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), eDirection);
		if pAdjacent ~= nil and fnMatches(pAdjacent) then
			iCount = iCount + 1;
		end
	end
	return iCount;
end

-- Neighbouring completed districts of the given kinds, whoever owns them and pillaged or
-- not: the same things the game's own district adjacency counts.
local function CountAdjacentDistricts(pPlot, kTypes)
	return CountNeighbours(pPlot, function(pAdjacent)
		local sBase = GetCompletedDistrict(pAdjacent);
		return sBase ~= nil and kTypes[sBase] == true;
	end);
end

local function IsWildTile(pPlot)
	return m_Wild[pPlot:GetFeatureType()] == true and pPlot:GetImprovementType() == -1;
end

-- A Mine or Quarry that is in working order.
local function IsDigging(pPlot)
	if not m_Diggings[pPlot:GetImprovementType()] then return false; end
	if pPlot.IsImprovementPillaged == nil then
		WarnOnce("IsImprovementPillaged", "Plot:IsImprovementPillaged is unavailable in this context; pillaged Mines and Quarries are counted.");
		return true;
	end
	return not pPlot:IsImprovementPillaged();
end

local function IsMountain(pPlot)
	return pPlot:IsMountain();
end

-- Trade Routes a city is sending right now, or 0 when that cannot be read.
local function CountOutgoingRoutes(pCity)
	if pCity.GetTrade == nil then
		WarnOnce("CityTrade", "City:GetTrade is unavailable in this context; Bruges gives no Culture for Trade Routes.");
		return 0;
	end
	local pTrade = pCity:GetTrade();
	if pTrade == nil or pTrade.GetOutgoingRoutes == nil then
		WarnOnce("CityTrade", "CityTrade:GetOutgoingRoutes is unavailable in this context; Bruges gives no Culture for Trade Routes.");
		return 0;
	end
	local kRoutes = pTrade:GetOutgoingRoutes();
	return (kRoutes ~= nil) and #kRoutes or 0;
end

-- True while the thing the city is producing is a Harbor or Encampment building.
local function IsBuildingForArsenal(pCity)
	if pCity.GetBuildQueue == nil then
		WarnOnce("BuildQueue", "City:GetBuildQueue is unavailable in this context; Ravenna gives no Production toward buildings.");
		return false;
	end
	local pQueue = pCity:GetBuildQueue();
	if pQueue == nil or pQueue.GetCurrentProductionTypeHash == nil then
		WarnOnce("BuildQueue", "BuildQueue:GetCurrentProductionTypeHash is unavailable in this context; Ravenna gives no Production toward buildings.");
		return false;
	end
	return m_ArsenalBuilding[pQueue:GetCurrentProductionTypeHash()] == true;
end

-- ---------------------------------------------------------------------------
-- One city
-- ---------------------------------------------------------------------------
local AQUEDUCT_OR_DAM = { DISTRICT_AQUEDUCT = true, DISTRICT_DAM = true };
local THEATER         = { DISTRICT_THEATER = true };
local COMMERCIAL_HUB  = { DISTRICT_COMMERCIAL_HUB = true };

local function UpdateCity(pCity, iPlayer)
	local kHas     = {};      -- base district type -> true: completed
	local kWorking = {};      -- base district type -> true: completed and not pillaged
	local bMonastery = false;

	for _, pPlot in ipairs(pCity:GetOwnedPlots()) do
		local kValue = {};
		local sDistrict, bPillaged = GetCompletedDistrict(pPlot);
		if sDistrict ~= nil then
			kHas[sDistrict] = true;
			if not bPillaged then kWorking[sDistrict] = true; end

			if sDistrict == "DISTRICT_CAMPUS" then
				kValue[PROP_WATERWORKS] = CountAdjacentDistricts(pPlot, AQUEDUCT_OR_DAM);
			elseif sDistrict == "DISTRICT_THEATER" then
				kValue[PROP_WILD_TILES] = math.min(CountNeighbours(pPlot, IsWildTile), MAX_WILD_TILES);
				kValue[PROP_THEATER_HUBS] = CountAdjacentDistricts(pPlot, COMMERCIAL_HUB);
			elseif sDistrict == "DISTRICT_COMMERCIAL_HUB" then
				kValue[PROP_HUB_THEATERS] = CountAdjacentDistricts(pPlot, THEATER);
			elseif sDistrict == "DISTRICT_INDUSTRIAL_ZONE" and not bPillaged then
				-- Mines and Quarries the player owns; they need not belong to this city.
				local iDiggings = CountNeighbours(pPlot, function(pAdjacent)
					return pAdjacent:GetOwner() == iPlayer and IsDigging(pAdjacent);
				end);
				kValue[PROP_STEELWORKS] = (iDiggings >= STEELWORKS_TILES) and 1 or 0;
			elseif sDistrict == "DISTRICT_HOLY_SITE" and not bPillaged then
				if CountNeighbours(pPlot, IsMountain) >= MONASTERY_MOUNTAINS then
					kValue[PROP_MONASTERY] = 1;
					bMonastery = true;
				end
			end
		elseif IsDigging(pPlot) then
			-- Next to any Industrial Zone of the same player, in this city or another.
			local iZones = CountNeighbours(pPlot, function(pAdjacent)
				return pAdjacent:GetOwner() == iPlayer and GetCompletedDistrict(pAdjacent) == "DISTRICT_INDUSTRIAL_ZONE";
			end);
			kValue[PROP_STEEL_TILE] = (iZones > 0) and 1 or 0;
		end
		for _, sProperty in ipairs(PLOT_PROPERTIES) do
			SetPlotProperty(pPlot, sProperty, kValue[sProperty] or 0);
		end
	end

	local pCityPlot = Map.GetPlot(pCity:GetX(), pCity:GetY());
	SetPlotProperty(pCityPlot, PROP_MONASTERY_CITY, bMonastery and 1 or 0);

	local bArsenal = kWorking["DISTRICT_HARBOR"] and kWorking["DISTRICT_ENCAMPMENT"] and IsBuildingForArsenal(pCity);
	SetPlotProperty(pCityPlot, PROP_ARSENAL, bArsenal and 1 or 0);

	local iRoutes = 0;
	if kHas["DISTRICT_COMMERCIAL_HUB"] and kHas["DISTRICT_THEATER"] then
		iRoutes = math.min(CountOutgoingRoutes(pCity), MAX_TRADE_CULTURE);
	end
	SetPlotProperty(pCityPlot, PROP_TRADE_CULTURE, iRoutes);
end

-- ---------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------
local function UpdatePlayer(iPlayer)
	local pPlayer = Players[iPlayer];
	if pPlayer == nil or not pPlayer:IsMajor() then return; end
	local pCities = pPlayer:GetCities();
	if pCities == nil then return; end
	for _, pCity in pCities:Members() do
		UpdateCity(pCity, iPlayer);
	end
end

local function OnPlayerTurnStarted(iPlayer)
	UpdatePlayer(iPlayer);
end

local function OnCityBuilt(iPlayer, iCityID, iX, iY)
	UpdatePlayer(iPlayer);
end

local function OnCityConquered(iNewOwner, iOldOwner, iCityID, iX, iY)
	-- The city's plots are recounted for their new owner; the old owner may have
	-- lost a district or a Mine that one of its other cities was counting.
	UpdatePlayer(iNewOwner);
	UpdatePlayer(iOldOwner);
end

local function OnDistrictConstructed(iPlayer, eDistrictType, iX, iY)
	UpdatePlayer(iPlayer);
end

local function OnPillage(iUnitPlayer, iUnitID, eImprovement, eBuilding, eDistrict, iPlotIndex)
	local pPlot = (iPlotIndex ~= nil) and Map.GetPlotByIndex(iPlotIndex) or nil;
	if pPlot ~= nil and pPlot:GetOwner() ~= -1 then
		UpdatePlayer(pPlot:GetOwner());
	end
end

local function IsAnyCityStateInGame()
	local kOurs = {};
	for _, sType in ipairs(CITY_STATES) do kOurs[sType] = true; end
	for iPlayer = 0, MAX_PLAYER_SLOTS - 1 do
		local pConfig = PlayerConfigurations[iPlayer];
		if pConfig ~= nil and kOurs[pConfig:GetCivilizationTypeName() or ""] then
			return true;
		end
	end
	return false;
end

local function Initialize()
	if not IsAnyCityStateInGame() then
		print("Europa city-states: none of the mod's city-states is in this game; no hooks added.");
		return;
	end
	LoadGameData();
	GameEvents.PlayerTurnStarted.Add(OnPlayerTurnStarted);
	GameEvents.CityBuilt.Add(OnCityBuilt);
	GameEvents.CityConquered.Add(OnCityConquered);
	GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed);
	GameEvents.OnPillage.Add(OnPillage);
	print("Europa city-states: hooks added.");
end

Initialize();
