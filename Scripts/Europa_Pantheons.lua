-- Project Europa: pantheons, the two facts the modifier system cannot establish.
--
-- The database can test "this plot is next to a Preserve" but not whose Preserve it
-- is, and "this city has a Wonder" without saying whether the Wonder is finished.
-- This script works both out for every major player and writes the answer onto a
-- plot; the modifiers in Data/Europa_Pantheons.sql read it back.
--
--   on every plot a city owns
--     EUROPA_PANTHEON_PRESERVE_TILE  1 while the plot touches a completed, unpillaged
--                                    Preserve belonging to the same player  (Sacred Wilderness)
--   on the city-centre plot
--     EUROPA_PANTHEON_WONDER_CITY    1 while the city owns a completed World Wonder
--                                    (Divine Inspiration, Pillars of Creation)
--
-- It never asks who holds which pantheon. The values are kept for everyone and the
-- engine attaches the modifiers that read them to the pantheon's owner only, so
-- taking a pantheon takes effect at once with nothing to recalculate here.
--
-- Everything else about those pantheons (Appeal, improvements, the civic, the
-- Market, the Art Museum, Population) is still tested by the database and reacts
-- immediately.
--
-- Multiplayer: only GameEvents (simulation-side, fired identically on every
-- machine) are used, and nothing here is random. Values refresh at the start of
-- the owner's turn, when a district or building is finished, when something is
-- pillaged and when a city is founded or changes hands. The values are plain
-- plot properties, which the game saves and loads with the map.

local PROP_PRESERVE_TILE = "EUROPA_PANTHEON_PRESERVE_TILE";
local PROP_WONDER_CITY   = "EUROPA_PANTHEON_WONDER_CITY";

local m_ePreserve = -1;

local m_Warned = {};
local function WarnOnce(sKey, sMessage)
	if not m_Warned[sKey] then
		m_Warned[sKey] = true;
		print("Europa pantheons: " .. sMessage);
	end
end

local function SetPlotProperty(pPlot, sName, iValue)
	if pPlot ~= nil and (pPlot:GetProperty(sName) or 0) ~= iValue then
		pPlot:SetProperty(sName, iValue);
	end
end

-- True for a Preserve of iPlayer's that is finished and not pillaged.
local function IsWorkingPreserveOf(pPlot, iPlayer)
	if m_ePreserve < 0 or pPlot:GetDistrictType() ~= m_ePreserve or pPlot:GetOwner() ~= iPlayer then
		return false;
	end
	if CityManager == nil or CityManager.GetDistrictAt == nil then
		WarnOnce("GetDistrictAt", "CityManager.GetDistrictAt is unavailable in this context; unfinished and pillaged Preserves are counted as working.");
		return true;
	end
	local pDistrict = CityManager.GetDistrictAt(pPlot:GetX(), pPlot:GetY());
	if pDistrict == nil then return false; end
	if pDistrict.IsComplete == nil or pDistrict.IsPillaged == nil then
		WarnOnce("DistrictState", "District:IsComplete/IsPillaged are unavailable in this context; unfinished and pillaged Preserves are counted as working.");
		return true;
	end
	return pDistrict:IsComplete() and not pDistrict:IsPillaged();
end

local function TouchesPreserveOf(pPlot, iPlayer)
	for eDirection = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pAdjacent = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), eDirection);
		if pAdjacent ~= nil and IsWorkingPreserveOf(pAdjacent, iPlayer) then
			return true;
		end
	end
	return false;
end

-- True for a plot holding a finished World Wonder. A Wonder that is only placed, or
-- part-built, does not count.
local function HasCompletedWonder(pPlot)
	if pPlot.GetWonderType == nil or pPlot.IsWonderComplete == nil then
		WarnOnce("WonderAPI", "Plot:GetWonderType/IsWonderComplete are unavailable in this context; Divine Inspiration and Pillars of Creation are inactive.");
		return false;
	end
	return pPlot:GetWonderType() ~= -1 and pPlot:IsWonderComplete() == true;
end

local function UpdateCity(pCity, iPlayer)
	local bWonder = false;
	for _, pPlot in ipairs(pCity:GetOwnedPlots()) do
		-- The Preserve may belong to another of the player's cities.
		SetPlotProperty(pPlot, PROP_PRESERVE_TILE, TouchesPreserveOf(pPlot, iPlayer) and 1 or 0);
		if not bWonder and HasCompletedWonder(pPlot) then
			bWonder = true;
		end
	end
	SetPlotProperty(Map.GetPlot(pCity:GetX(), pCity:GetY()), PROP_WONDER_CITY, bWonder and 1 or 0);
end

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
	-- The city's plots are re-examined for their new owner; the old owner may have
	-- lost a Preserve that tiles of its other cities were touching.
	UpdatePlayer(iNewOwner);
	UpdatePlayer(iOldOwner);
end

local function OnDistrictConstructed(iPlayer, eDistrictType, iX, iY)
	UpdatePlayer(iPlayer);
end

-- Fires for World Wonders too, so a city counts from the moment its Wonder is finished.
local function OnBuildingConstructed(iPlayer, iCityID, eBuilding, iPlotIndex, bOriginalConstruction)
	UpdatePlayer(iPlayer);
end

local function OnPillage(iUnitPlayer, iUnitID, eImprovement, eBuilding, eDistrict, iPlotIndex)
	local pPlot = (iPlotIndex ~= nil) and Map.GetPlotByIndex(iPlotIndex) or nil;
	if pPlot ~= nil and pPlot:GetOwner() ~= -1 then
		UpdatePlayer(pPlot:GetOwner());
	end
end

local function Initialize()
	local kPreserve = GameInfo.Districts["DISTRICT_PRESERVE"];
	if kPreserve ~= nil then
		m_ePreserve = kPreserve.Index;
	else
		print("Europa pantheons: no Preserve district in this ruleset; Sacred Wilderness is inactive.");
	end
	GameEvents.PlayerTurnStarted.Add(OnPlayerTurnStarted);
	GameEvents.CityBuilt.Add(OnCityBuilt);
	GameEvents.CityConquered.Add(OnCityConquered);
	GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed);
	GameEvents.OnPillage.Add(OnPillage);
	if GameEvents.BuildingConstructed ~= nil then
		GameEvents.BuildingConstructed.Add(OnBuildingConstructed);
	end
	print("Europa pantheons: hooks added.");
end

Initialize();
