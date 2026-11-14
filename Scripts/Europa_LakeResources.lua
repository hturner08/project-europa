-- Project Europa: New Luxuries
-- Places Discus Fish on lakes once, at the start of a new game.
--
-- Why a script: the stock ResourceGenerator only knows "land luxury" (Frequency)
-- and "coastal luxury" (SeaFrequency, any TERRAIN_COAST plot). There is no
-- lakes-only rule in the database, so Discus Fish opts out of both passes
-- (Frequency = 0, SeaFrequency = 0) and is seeded here instead. This also keeps
-- the mod compatible with map-script overhauls, since no map script is replaced.

local RESOURCE_TYPE   = "RESOURCE_EUROPA_DISCUS_FISH";
local PROPERTY_SEEDED = "EUROPA_LAKE_RESOURCES_SEEDED";
local CHANCE_PERCENT  = 20;   -- per eligible lake plot

local function HasAdjacentCopy(pPlot, eResource)
	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pAdjacent = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), direction);
		if pAdjacent ~= nil and pAdjacent:GetResourceType() == eResource then
			return true;
		end
	end
	return false;
end

local function SeedLakeResources()
	if Game:GetProperty(PROPERTY_SEEDED) ~= nil then
		return;
	end
	Game:SetProperty(PROPERTY_SEEDED, 1);

	local kResource = GameInfo.Resources[RESOURCE_TYPE];
	if kResource == nil then
		print("Europa: " .. RESOURCE_TYPE .. " is not in the database; nothing to place.");
		return;
	end
	local eResource = kResource.Index;

	local aCandidates = {};
	for i = 0, Map.GetPlotCount() - 1 do
		local pPlot = Map.GetPlotByIndex(i);
		if pPlot ~= nil and pPlot:IsLake() and pPlot:GetResourceType() == -1
			and ResourceBuilder.CanHaveResource(pPlot, eResource) then
			table.insert(aCandidates, pPlot);
		end
	end

	local iPlaced = 0;
	for _, pPlot in ipairs(aCandidates) do
		if not HasAdjacentCopy(pPlot, eResource)
			and Game.GetRandNum(100, "Europa lake resource") < CHANCE_PERCENT then
			ResourceBuilder.SetResourceType(pPlot, eResource, 1);
			iPlaced = iPlaced + 1;
		end
	end

	-- Guarantee at least one copy on any map that has a usable lake.
	if iPlaced == 0 and #aCandidates > 0 then
		local pPlot = aCandidates[Game.GetRandNum(#aCandidates, "Europa lake resource fallback") + 1];
		ResourceBuilder.SetResourceType(pPlot, eResource, 1);
		iPlaced = 1;
	end

	print("Europa: placed " .. iPlaced .. " Discus Fish on " .. #aCandidates .. " eligible lake plots.");
end

SeedLakeResources();
