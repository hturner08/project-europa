-- Project Europa: bigger deserts
--
-- Only when a desert civilization is playing (see Europa_DesertCivInGame); in any
-- other game the deserts are left exactly as the map generator made them.
--
-- Grows every desert the map generator has already laid out, without creating
-- new ones: only tiles touching an existing desert can turn into desert, so the
-- number of deserts can never go up (neighbouring deserts may merge).
--
-- Runs during map generation, on the terrain table, before terrain is applied.
-- Everything placed afterwards (rivers, floodplains, features, resources, start
-- positions and start biases) therefore sees the enlarged deserts.

EUROPA_DESERT_GROWTH = {
	FullRings         = 1,    -- rings of tiles added around each desert, guaranteed
	PartialRingChance = 50,   -- percent chance per tile for one further, ragged ring (0 = off)
	OnlyWithDesertCiv = true, -- false = grow deserts in every game
};

-- The name of a major civilization in this game that has a desert start bias in the
-- loaded ruleset (TERRAIN_DESERT, _HILLS or _MOUNTAIN in StartBiasTerrains), or nil.
-- Read from the database rather than a list here, so it follows whatever stock, BBG
-- or another mod says. City-states are ignored: several have a desert bias and some
-- are in every game. Random leaders are already resolved when the map is generated.
function Europa_DesertCivInGame()
	local bDesertCiv = {};
	for row in GameInfo.StartBiasTerrains() do
		if string.find(row.TerrainType, "TERRAIN_DESERT", 1, true) == 1 then
			bDesertCiv[row.CivilizationType] = true;
		end
	end
	for _, iPlayer in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local pConfig = PlayerConfigurations[iPlayer];
		local sCiv = pConfig and pConfig:GetCivilizationTypeName();
		if sCiv ~= nil and bDesertCiv[sCiv] then
			return sCiv;
		end
	end
	return nil;
end

local function DefaultNeighbors(i, iW)
	local aNeighbors = {};
	local iX, iY = i % iW, math.floor(i / iW);
	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pAdjacent = Map.GetAdjacentPlot(iX, iY, direction);
		if pAdjacent ~= nil then
			table.insert(aNeighbors, pAdjacent:GetIndex());
		end
	end
	return aNeighbors;
end

local function DefaultRandom(iRange)
	return TerrainBuilder.GetRandomNumber(iRange, "Europa desert growth");
end

-- plotTypes / terrainTypes are the map generator's 0-based tables. At this point
-- hills still carry their flat terrain type (ApplyBaseTerrain adds the hills
-- offset afterwards), so only flat and mountain types need handling.
-- fnNeighbors and fnRandom exist so the function can be tested outside the game.
function Europa_GrowDeserts(plotTypes, terrainTypes, iW, iH, fnNeighbors, fnRandom)
	fnNeighbors = fnNeighbors or DefaultNeighbors;
	fnRandom = fnRandom or DefaultRandom;

	if EUROPA_DESERT_GROWTH.OnlyWithDesertCiv then
		local sCiv = Europa_DesertCivInGame();
		if sCiv == nil then
			print("Europa: no desert civilization in this game; deserts left as generated.");
			return 0;
		end
		print("Europa: desert civilization in this game (" .. sCiv .. "); growing deserts.");
	end

	local kBecomes = {
		[g_TERRAIN_TYPE_GRASS]           = g_TERRAIN_TYPE_DESERT,
		[g_TERRAIN_TYPE_PLAINS]          = g_TERRAIN_TYPE_DESERT,
		[g_TERRAIN_TYPE_GRASS_MOUNTAIN]  = g_TERRAIN_TYPE_DESERT_MOUNTAIN,
		[g_TERRAIN_TYPE_PLAINS_MOUNTAIN] = g_TERRAIN_TYPE_DESERT_MOUNTAIN,
	};

	local bIsDesert = {};
	local aFrontier = {};
	for i = 0, (iW * iH) - 1 do
		local eTerrain = terrainTypes[i];
		if eTerrain == g_TERRAIN_TYPE_DESERT or eTerrain == g_TERRAIN_TYPE_DESERT_MOUNTAIN then
			bIsDesert[i] = true;
			table.insert(aFrontier, i);
		end
	end
	local iOriginal = #aFrontier;
	local iAdded = 0;

	local iRings = EUROPA_DESERT_GROWTH.FullRings;
	if EUROPA_DESERT_GROWTH.PartialRingChance > 0 then
		iRings = iRings + 1;
	end

	for iRing = 1, iRings do
		local iChance = (iRing <= EUROPA_DESERT_GROWTH.FullRings) and 100 or EUROPA_DESERT_GROWTH.PartialRingChance;
		local bConsidered = {};
		local aConverted = {};
		for _, i in ipairs(aFrontier) do
			for _, j in ipairs(fnNeighbors(i, iW)) do
				if not bIsDesert[j] and not bConsidered[j] then
					bConsidered[j] = true;
					local eTarget = kBecomes[terrainTypes[j]];
					if eTarget ~= nil and plotTypes[j] ~= g_PLOT_TYPE_OCEAN
						and (iChance >= 100 or fnRandom(100) < iChance) then
						table.insert(aConverted, { Index = j, Terrain = eTarget });
					end
				end
			end
		end
		-- Apply after the scan so a ring grows from the previous ring only.
		aFrontier = {};
		for _, kTile in ipairs(aConverted) do
			terrainTypes[kTile.Index] = kTile.Terrain;
			bIsDesert[kTile.Index] = true;
			table.insert(aFrontier, kTile.Index);
		end
		iAdded = iAdded + #aConverted;
	end

	print("Europa: grew deserts from " .. iOriginal .. " to " .. (iOriginal + iAdded) .. " tiles.");
	return iAdded;
end
