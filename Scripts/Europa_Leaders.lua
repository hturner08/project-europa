-- Project Europa: custom leaders, the effects the modifier system cannot do.
--
-- The database can test "this plot has property X >= n" but cannot count
-- continents, look at the tiles around a Wonder site, or ask whether a city owns
-- a given improvement. So this script works those out and writes the answer onto
-- a city-centre plot; modifiers in Data/Europa_Leader_*.sql read it back.
--
--   EUROPA_CONTINENT_ROUTES  (Mali, on the capital's plot)
--       continents holding >= 3 cities the player founded, capped at 4
--   EUROPA_GARDEN_TILES      (China and America, on each city's plot)
--       Breathtaking tiles next to the Wonder that city has under construction,
--       capped at 4; 0 when no Wonder is under construction there
--   EUROPA_CHATEAU_WONDER    (France, on each city's plot)
--       1 while the Wonder that city has under construction touches a Chateau
--   EUROPA_CHATEAU_CITY      (France, on each city's plot)
--       1 while the city owns at least one Chateau
--   EUROPA_HERD_CITY         (Cree, on each city's plot)
--       1 while the city owns at least one Camp or Pasture
--   EUROPA_TRADE_CLAIM       (Cree, on each city's plot)
--       1 once the city's first Trade Route has claimed its extra tiles
--
-- One effect is done here outright: the Cree leader's first Trade Route from each
-- city it founded claims up to two unowned tiles near that city.
--
-- Multiplayer: only GameEvents (simulation-side, fired identically on every
-- machine) are used, and nothing here is random. Values therefore refresh at the
-- start of the owner's turn and when a city is founded or changes hands, not the
-- instant a Wonder is placed or a Trader sets out.

local LEADER_MALI          = "LEADER_EUROPA_GOLDEN_EXPANSION";
local LEADER_CHINA         = "LEADER_EUROPA_IMPERIAL_GARDENS";
local LEADER_AMERICA       = "LEADER_EUROPA_SCENIC_GENIUS";
local LEADER_FRANCE        = "LEADER_EUROPA_PALACE_DESIGNER";
local LEADER_CREE          = "LEADER_EUROPA_BORDERLESS_EMPIRE";
local PROP_ROUTES          = "EUROPA_CONTINENT_ROUTES";
local PROP_GARDEN          = "EUROPA_GARDEN_TILES";
local PROP_CHATEAU_WONDER  = "EUROPA_CHATEAU_WONDER";
local PROP_CHATEAU_CITY    = "EUROPA_CHATEAU_CITY";
local PROP_HERD_CITY       = "EUROPA_HERD_CITY";
local PROP_TRADE_CLAIM     = "EUROPA_TRADE_CLAIM";
local CITIES_PER_CONTINENT = 3;
local MAX_ROUTES           = 4;   -- one modifier tier per point; keep in step with the SQL
local MAX_GARDEN_TILES     = 4;   -- likewise
local BREATHTAKING_APPEAL  = 4;
local CLAIM_TILES          = 2;   -- tiles the first Trade Route claims
local CLAIM_RANGE          = 3;   -- how far from the city centre they may be

local m_Warned = {};
local function WarnOnce(sKey, sMessage)
	if not m_Warned[sKey] then
		m_Warned[sKey] = true;
		print("Europa leaders: " .. sMessage);
	end
end

local function GetLeader(iPlayer)
	local pConfig = PlayerConfigurations[iPlayer];
	if pConfig == nil then return nil; end
	return pConfig:GetLeaderTypeName();
end

local function SetPlotProperty(pPlot, sName, iValue)
	if pPlot ~= nil and (pPlot:GetProperty(sName) or 0) ~= iValue then
		pPlot:SetProperty(sName, iValue);
	end
end

local function GetCityPlot(pCity)
	return Map.GetPlot(pCity:GetX(), pCity:GetY());
end

-- Index of an improvement type, or -2 (never matches a plot) when it is not in this game.
local function GetImprovementIndex(sType)
	local kRow = GameInfo.Improvements[sType];
	return (kRow ~= nil) and kRow.Index or -2;
end

local function IsFoundedBy(pCity, iPlayer)
	if pCity.GetOriginalOwner == nil then
		WarnOnce("GetOriginalOwner", "City:GetOriginalOwner is unavailable; captured cities are treated as founded.");
		return true;
	end
	return pCity:GetOriginalOwner() == iPlayer;
end

-- ---------------------------------------------------------------------------
-- Mali, Golden Expansion: +1 Trade Route per continent with three founded cities
-- ---------------------------------------------------------------------------
local function UpdateContinentRoutes(iPlayer)
	local pPlayer = Players[iPlayer];
	if pPlayer == nil then return; end
	local pCities = pPlayer:GetCities();
	if pCities == nil then return; end

	local kCount = {};
	for _, pCity in pCities:Members() do
		local bFounded = IsFoundedBy(pCity, iPlayer);
		local pPlot = GetCityPlot(pCity);
		if bFounded and pPlot ~= nil then
			local eContinent = pPlot:GetContinentType();
			kCount[eContinent] = (kCount[eContinent] or 0) + 1;
		end
	end

	local iRoutes = 0;
	for _, iCities in pairs(kCount) do
		if iCities >= CITIES_PER_CONTINENT then
			iRoutes = iRoutes + 1;
		end
	end
	iRoutes = math.min(iRoutes, MAX_ROUTES);

	-- The capital carries the value; every other city is reset so the bonus
	-- follows the capital if it moves and never counts twice.
	local pCapital = pCities:GetCapitalCity();
	local iCapitalID = (pCapital ~= nil) and pCapital:GetID() or -1;
	for _, pCity in pCities:Members() do
		SetPlotProperty(GetCityPlot(pCity), PROP_ROUTES, (pCity:GetID() == iCapitalID) and iRoutes or 0);
	end
end

-- ---------------------------------------------------------------------------
-- Wonder sites: China (Imperial Gardens), America (Scenic Genius), France (Palace Designer)
-- ---------------------------------------------------------------------------
local function CountBreathtakingNeighbours(pPlot)
	local iCount = 0;
	for eDirection = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pAdjacent = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), eDirection);
		if pAdjacent ~= nil and pAdjacent:GetAppeal() >= BREATHTAKING_APPEAL then
			iCount = iCount + 1;
		end
	end
	return iCount;
end

local function CountNeighboursWithImprovement(pPlot, eImprovement)
	local iCount = 0;
	for eDirection = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pAdjacent = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), eDirection);
		if pAdjacent ~= nil and pAdjacent:GetImprovementType() == eImprovement then
			iCount = iCount + 1;
		end
	end
	return iCount;
end

-- Highest fnScore(plot) over the unfinished Wonder plots a city owns; 0 with none.
-- If a city somehow has two unfinished Wonders, the better site counts.
local function BestWonderSite(pCity, fnScore)
	local iBest = 0;
	for _, pPlot in ipairs(pCity:GetOwnedPlots()) do
		if pPlot.GetWonderType == nil or pPlot.IsWonderComplete == nil or pPlot.GetAppeal == nil then
			WarnOnce("WonderAPI", "Plot wonder/appeal functions are unavailable in this context; the Wonder-site bonuses are inactive.");
			break;
		end
		if pPlot:GetWonderType() ~= -1 and not pPlot:IsWonderComplete() then
			iBest = math.max(iBest, fnScore(pPlot));
		end
	end
	return iBest;
end

local function CityOwnsImprovement(pCity, kImprovements)
	for _, pPlot in ipairs(pCity:GetOwnedPlots()) do
		if kImprovements[pPlot:GetImprovementType()] then
			return true;
		end
	end
	return false;
end

local function ForEachCity(iPlayer, fn)
	local pPlayer = Players[iPlayer];
	if pPlayer == nil then return; end
	local pCities = pPlayer:GetCities();
	if pCities == nil then return; end
	for _, pCity in pCities:Members() do
		fn(pCity);
	end
end

local function UpdateGardens(iPlayer)
	ForEachCity(iPlayer, function(pCity)
		local iBest = BestWonderSite(pCity, CountBreathtakingNeighbours);
		SetPlotProperty(GetCityPlot(pCity), PROP_GARDEN, math.min(iBest, MAX_GARDEN_TILES));
	end);
end

local function UpdateChateaux(iPlayer)
	local eChateau = GetImprovementIndex("IMPROVEMENT_CHATEAU");
	ForEachCity(iPlayer, function(pCity)
		local iBeside = BestWonderSite(pCity, function(pPlot) return CountNeighboursWithImprovement(pPlot, eChateau); end);
		local pCityPlot = GetCityPlot(pCity);
		SetPlotProperty(pCityPlot, PROP_CHATEAU_WONDER, (iBeside > 0) and 1 or 0);
		SetPlotProperty(pCityPlot, PROP_CHATEAU_CITY, CityOwnsImprovement(pCity, { [eChateau] = true }) and 1 or 0);
	end);
end

-- ---------------------------------------------------------------------------
-- Cree, Borderless Empire: herding cities, and tiles claimed by the first Trade Route
-- ---------------------------------------------------------------------------
local function CityHasOutgoingRoute(pCity)
	if pCity.GetTrade == nil then
		WarnOnce("CityTrade", "City:GetTrade is unavailable in this context; Trade Routes claim no extra tiles.");
		return false;
	end
	local pTrade = pCity:GetTrade();
	if pTrade == nil or pTrade.GetOutgoingRoutes == nil then
		WarnOnce("CityTrade", "CityTrade:GetOutgoingRoutes is unavailable in this context; Trade Routes claim no extra tiles.");
		return false;
	end
	local kRoutes = pTrade:GetOutgoingRoutes();
	return kRoutes ~= nil and #kRoutes > 0;
end

-- Give an unowned plot to a city. Returns true only if the plot really changed hands.
local function ClaimPlot(pPlot, iPlayer, pCity)
	if WorldBuilder ~= nil and WorldBuilder.CityManager ~= nil then
		pcall(function() WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, pCity:GetID()); end);
	end
	if pPlot:GetOwner() ~= iPlayer and pPlot.SetOwner ~= nil then
		pcall(function() pPlot:SetOwner(iPlayer, pCity:GetID()); end);
	end
	if pPlot:GetOwner() ~= iPlayer then
		WarnOnce("ClaimPlot", "Could not assign a plot to a city from this context; Trade Routes claim no extra tiles.");
		return false;
	end
	return true;
end

-- Unowned plots within CLAIM_RANGE of the city, nearest ring first, land before
-- water within a ring, then in a fixed direction order: the same on every machine.
local function ClaimNearbyPlots(pCity, iPlayer, iWanted)
	local pStart = GetCityPlot(pCity);
	if pStart == nil then return 0; end
	local kSeen = { [pStart:GetIndex()] = true };
	local kRing = { pStart };
	local iClaimed = 0;
	for _ = 1, CLAIM_RANGE do
		local kNext, kLand, kWater = {}, {}, {};
		for _, pPlot in ipairs(kRing) do
			for eDirection = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
				local pAdjacent = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), eDirection);
				if pAdjacent ~= nil and not kSeen[pAdjacent:GetIndex()] then
					kSeen[pAdjacent:GetIndex()] = true;
					table.insert(kNext, pAdjacent);
					if pAdjacent:GetOwner() == -1 then
						table.insert(pAdjacent:IsWater() and kWater or kLand, pAdjacent);
					end
				end
			end
		end
		for _, kList in ipairs({ kLand, kWater }) do
			for _, pPlot in ipairs(kList) do
				if iClaimed >= iWanted then return iClaimed; end
				if ClaimPlot(pPlot, iPlayer, pCity) then
					iClaimed = iClaimed + 1;
				end
			end
		end
		kRing = kNext;
	end
	return iClaimed;
end

local function UpdateCree(iPlayer)
	local kHerds = { [GetImprovementIndex("IMPROVEMENT_CAMP")] = true, [GetImprovementIndex("IMPROVEMENT_PASTURE")] = true };
	ForEachCity(iPlayer, function(pCity)
		local pCityPlot = GetCityPlot(pCity);
		if pCityPlot == nil then return; end
		SetPlotProperty(pCityPlot, PROP_HERD_CITY, CityOwnsImprovement(pCity, kHerds) and 1 or 0);
		-- Once per city the player founded, the first time it is seen with a route running.
		-- The flag is set even when fewer than two tiles were free: "if available".
		if (pCityPlot:GetProperty(PROP_TRADE_CLAIM) or 0) == 0 and IsFoundedBy(pCity, iPlayer) and CityHasOutgoingRoute(pCity) then
			local iClaimed = ClaimNearbyPlots(pCity, iPlayer, CLAIM_TILES);
			SetPlotProperty(pCityPlot, PROP_TRADE_CLAIM, 1);
			print("Europa leaders: first Trade Route from city " .. tostring(pCity:GetID()) .. " claimed " .. tostring(iClaimed) .. " tile(s).");
		end
	end);
end

-- ---------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------
local UPDATERS = {
	[LEADER_MALI]    = UpdateContinentRoutes,
	[LEADER_CHINA]   = UpdateGardens,
	[LEADER_AMERICA] = UpdateGardens,
	[LEADER_FRANCE]  = UpdateChateaux,
	[LEADER_CREE]    = UpdateCree,
};

local function UpdatePlayer(iPlayer)
	local fnUpdate = UPDATERS[GetLeader(iPlayer) or ""];
	if fnUpdate ~= nil then
		fnUpdate(iPlayer);
	end
end

local function OnPlayerTurnStarted(iPlayer)
	UpdatePlayer(iPlayer);
end

local function OnCityBuilt(iPlayer, iCityID, iX, iY)
	UpdatePlayer(iPlayer);
end

local function OnCityConquered(iNewOwner, iOldOwner, iCityID, iX, iY)
	-- A captured city must not carry its old owner's values to the new one.
	-- EUROPA_TRADE_CLAIM is left alone: it records that the tiles were already given.
	local pPlot = Map.GetPlot(iX, iY);
	for _, sProperty in ipairs({ PROP_ROUTES, PROP_GARDEN, PROP_CHATEAU_WONDER, PROP_CHATEAU_CITY, PROP_HERD_CITY }) do
		SetPlotProperty(pPlot, sProperty, 0);
	end
	UpdatePlayer(iNewOwner);
	UpdatePlayer(iOldOwner);
end

local function Initialize()
	local bNeeded = false;
	for _, iPlayer in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if UPDATERS[GetLeader(iPlayer) or ""] ~= nil then
			bNeeded = true;
		end
	end
	if not bNeeded then
		print("Europa leaders: no leader that needs this script is in this game; no hooks added.");
		return;
	end
	GameEvents.PlayerTurnStarted.Add(OnPlayerTurnStarted);
	GameEvents.CityBuilt.Add(OnCityBuilt);
	GameEvents.CityConquered.Add(OnCityConquered);
	print("Europa leaders: hooks added.");
end

Initialize();
