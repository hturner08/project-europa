-- Project Europa: great lakes
--
-- The stock generator makes lakes that are almost all one tile, which leaves a
-- Harbor with one possible spot and nothing to work. This step picks a few of
-- the lakes the generator has already placed, spread across the map, and grows
-- each into a "great lake" of several tiles.
--
-- Rules it keeps:
--   * No new lakes: only existing lakes grow.
--   * A grown lake never touches another body of water, so it cannot join the
--     sea or another lake, and never exceeds LAKE_MAX_AREA_SIZE (above that the
--     game treats water as sea: no fresh water, no lake resources).
--   * The same tiles the stock lake step refuses are refused here: rivers and
--     their banks, volcanoes, and tiles next to a natural wonder.
--
-- Runs during map generation, straight after the stock AddLakes (so after
-- rivers, before features, resources and start positions).

EUROPA_LAKE_GROWTH = {
	LandPerGreatLake = 120,   -- one great lake per this many land tiles on the map
	MinGreatLakes    = 3,     -- but never aim for fewer than this
	MinSize          = 4,     -- each great lake aims for a random size in MinSize..MaxSize
	MaxSize          = 5,     -- capped at LAKE_MAX_AREA_SIZE whatever is written here
};

local function Neighbors(pPlot)
	local aNeighbors = {};
	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pAdjacent = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), direction);
		if pAdjacent ~= nil then
			table.insert(aNeighbors, pAdjacent);
		end
	end
	return aNeighbors;
end

-- Returns the number of tiles turned into lake.
function Europa_GrowLakes()
	local kConfig = EUROPA_LAKE_GROWTH;
	local iW, iH = Map.GetGridSize();
	local iPlots = iW * iH;
	local iLimit = math.min(kConfig.MaxSize, GlobalParameters.LAKE_MAX_AREA_SIZE or 9);
	local iMinSize = math.min(kConfig.MinSize, iLimit);

	-- Our own picture of the water, kept up to date as tiles are added. The
	-- engine's lake and coastal-land flags are only refreshed by
	-- AreaBuilder.Recalculate, so they cannot be trusted mid-growth.
	local kBodyOf = {};      -- plot index -> body (water plots only)
	local aLakes = {};
	local iLand = 0;
	for i = 0, iPlots - 1 do
		local pPlot = Map.GetPlotByIndex(i);
		if pPlot ~= nil and not pPlot:IsWater() then
			iLand = iLand + 1;
		elseif pPlot ~= nil and kBodyOf[i] == nil then
			local kBody = { Plots = {}, First = i };
			local aStack = { pPlot };
			kBodyOf[i] = kBody;
			while #aStack > 0 do
				local pNext = table.remove(aStack);
				table.insert(kBody.Plots, pNext);
				for _, pAdjacent in ipairs(Neighbors(pNext)) do
					local j = pAdjacent:GetIndex();
					if pAdjacent:IsWater() and kBodyOf[j] == nil then
						kBodyOf[j] = kBody;
						table.insert(aStack, pAdjacent);
					end
				end
			end
			if #kBody.Plots <= iLimit then
				table.insert(aLakes, kBody);
			end
		end
	end

	-- Choose which lakes to grow: the largest first, then repeatedly the lake
	-- farthest from every lake already chosen, so they end up spread out rather
	-- than bunched in one player's half.
	local iWanted = math.max(kConfig.MinGreatLakes, math.floor(iLand / kConfig.LandPerGreatLake + 0.5));
	local aChosen = {};
	while #aChosen < iWanted and #aChosen < #aLakes do
		local kBest, iBestScore = nil, -1;
		for _, kLake in ipairs(aLakes) do
			if not kLake.Chosen then
				local iScore = #kLake.Plots;
				if #aChosen > 0 then
					iScore = nil;
					for _, kOther in ipairs(aChosen) do
						local iDistance = Map.GetPlotDistance(kLake.First, kOther.First);
						if iScore == nil or iDistance < iScore then
							iScore = iDistance;
						end
					end
				end
				if iScore > iBestScore then
					kBest, iBestScore = kLake, iScore;
				end
			end
		end
		kBest.Chosen = true;
		table.insert(aChosen, kBest);
	end

	local function CanJoin(pPlot, kLake)
		if pPlot:IsWater() or kBodyOf[pPlot:GetIndex()] ~= nil then
			return false;
		end
		if pPlot:IsRiver() or pPlot:IsRiverAdjacent() or pPlot:IsNaturalWonder() then
			return false;
		end
		if g_FEATURE_VOLCANO ~= nil and pPlot:GetFeatureType() == g_FEATURE_VOLCANO then
			return false;
		end
		for _, pAdjacent in ipairs(Neighbors(pPlot)) do
			local kOther = kBodyOf[pAdjacent:GetIndex()];
			if (kOther ~= nil and kOther ~= kLake) or pAdjacent:IsNaturalWonder() then
				return false;   -- would join another body of water, or crowd a wonder
			end
		end
		return true;
	end

	local iAdded = 0;
	local aSizes = {};
	for _, kLake in ipairs(aChosen) do
		local iGoal = iMinSize + TerrainBuilder.GetRandomNumber(iLimit - iMinSize + 1, "Europa lake size");
		while #kLake.Plots < iGoal do
			-- Every land tile that touches this lake and may join it. A tile is
			-- listed once per lake tile it touches, so tiles that fill a bay are
			-- likelier than ones that stretch the lake into a line.
			local aDraw = {};
			for _, pLakePlot in ipairs(kLake.Plots) do
				for _, pAdjacent in ipairs(Neighbors(pLakePlot)) do
					if CanJoin(pAdjacent, kLake) then
						table.insert(aDraw, pAdjacent);
					end
				end
			end
			if #aDraw == 0 then
				break;   -- boxed in by rivers, coast or other water
			end
			local pNew = aDraw[TerrainBuilder.GetRandomNumber(#aDraw, "Europa lake growth") + 1];
			TerrainBuilder.SetTerrainType(pNew, g_TERRAIN_TYPE_COAST);
			kBodyOf[pNew:GetIndex()] = kLake;
			table.insert(kLake.Plots, pNew);
			iAdded = iAdded + 1;
		end
		table.insert(aSizes, #kLake.Plots);
	end

	if iAdded > 0 then
		AreaBuilder.Recalculate();
		-- Written to Lua.log so a playtest shows whether the engine really does
		-- treat every grown body as a lake.
		local iNotLake = 0;
		for _, kLake in ipairs(aChosen) do
			for _, pPlot in ipairs(kLake.Plots) do
				if not pPlot:IsLake() then
					iNotLake = iNotLake + 1;
				end
			end
		end
		if iNotLake > 0 then
			print("Europa: WARNING: " .. iNotLake .. " great lake tiles are not flagged as lake by the game.");
		end
	end
	print("Europa: grew " .. #aChosen .. " of " .. #aLakes .. " lakes by " .. iAdded .. " tiles; sizes now "
		.. table.concat(aSizes, ", ") .. " (" .. iLand .. " land tiles).");
	return iAdded;
end
