-- Project Europa: custom leaders, the two effects the modifier system cannot count.
--
-- The database can test "this plot has property X >= n" but cannot count
-- continents or look at the tiles around a Wonder site. So this script does the
-- counting and writes the answer onto a city-centre plot; the tiered modifiers in
-- Data/Europa_Leader_Mali.sql and Data/Europa_Leader_China.sql read it back.
--
--   EUROPA_CONTINENT_ROUTES  (Mali, on the capital's plot)
--       continents holding >= 3 cities the player founded, capped at 4
--   EUROPA_GARDEN_TILES      (China, on each city's plot)
--       Breathtaking tiles next to the Wonder that city has under construction,
--       capped at 4; 0 when no Wonder is under construction there
--
-- Multiplayer: only GameEvents (simulation-side, fired identically on every
-- machine) are used, and nothing here is random. Values therefore refresh at the
-- start of the owner's turn and when a city is founded or changes hands, not the
-- instant a Wonder is placed.

local LEADER_MALI          = "LEADER_EUROPA_GOLDEN_EXPANSION";
local LEADER_CHINA         = "LEADER_EUROPA_IMPERIAL_GARDENS";
local PROP_ROUTES          = "EUROPA_CONTINENT_ROUTES";
local PROP_GARDEN          = "EUROPA_GARDEN_TILES";
local CITIES_PER_CONTINENT = 3;
local MAX_ROUTES           = 4;   -- one modifier tier per point; keep in step with the SQL
local MAX_GARDEN_TILES     = 4;   -- likewise
local BREATHTAKING_APPEAL  = 4;

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
		local bFounded = true;
		if pCity.GetOriginalOwner ~= nil then
			bFounded = (pCity:GetOriginalOwner() == iPlayer);
		else
			WarnOnce("GetOriginalOwner", "City:GetOriginalOwner is unavailable; captured cities count toward continents too.");
		end
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
-- China, Imperial Gardens: Breathtaking tiles around the Wonder being built
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

local function UpdateGardens(iPlayer)
	local pPlayer = Players[iPlayer];
	if pPlayer == nil then return; end
	local pCities = pPlayer:GetCities();
	if pCities == nil then return; end

	for _, pCity in pCities:Members() do
		local iBest = 0;
		for _, pPlot in ipairs(pCity:GetOwnedPlots()) do
			if pPlot.GetWonderType == nil or pPlot.IsWonderComplete == nil or pPlot.GetAppeal == nil then
				WarnOnce("WonderAPI", "Plot wonder/appeal functions are unavailable in this context; the Grove Wonder bonus is inactive.");
				break;
			end
			-- If a city somehow has two unfinished Wonders, the better site counts.
			if pPlot:GetWonderType() ~= -1 and not pPlot:IsWonderComplete() then
				iBest = math.max(iBest, CountBreathtakingNeighbours(pPlot));
			end
		end
		SetPlotProperty(GetCityPlot(pCity), PROP_GARDEN, math.min(iBest, MAX_GARDEN_TILES));
	end
end

-- ---------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------
local function UpdatePlayer(iPlayer)
	local sLeader = GetLeader(iPlayer);
	if sLeader == LEADER_MALI then
		UpdateContinentRoutes(iPlayer);
	elseif sLeader == LEADER_CHINA then
		UpdateGardens(iPlayer);
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
	local pPlot = Map.GetPlot(iX, iY);
	SetPlotProperty(pPlot, PROP_ROUTES, 0);
	SetPlotProperty(pPlot, PROP_GARDEN, 0);
	UpdatePlayer(iNewOwner);
	UpdatePlayer(iOldOwner);
end

local function Initialize()
	local bNeeded = false;
	for _, iPlayer in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local sLeader = GetLeader(iPlayer);
		if sLeader == LEADER_MALI or sLeader == LEADER_CHINA then
			bNeeded = true;
		end
	end
	if not bNeeded then
		print("Europa leaders: neither Golden Expansion nor Imperial Gardens is in this game; no hooks added.");
		return;
	end
	GameEvents.PlayerTurnStarted.Add(OnPlayerTurnStarted);
	GameEvents.CityBuilt.Add(OnCityBuilt);
	GameEvents.CityConquered.Add(OnCityConquered);
	print("Europa leaders: hooks added.");
end

Initialize();
