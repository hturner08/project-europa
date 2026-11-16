-- Project Europa: start biases.
--
-- Nubia gets its desert start bias back. Stock Gathering Storm has Nubia on Desert
-- and Desert Hills at Tier 2; Better Balanced Game deletes both rows (and so does
-- BBS/BBM's bbs_bias_master.sql), which leaves the Nubian Pyramid's civilization
-- starting on plains. These are the stock rows again, at the stock tier.
--
-- Must load after BBG (last gameplay action 100000000) and BBS (2000), or their
-- DELETEs remove the rows again. BBG's own Plains / Plains Hills rows for Nubia are
-- left alone. Does nothing without the Nubia DLC: the SELECT then matches no row.
--
-- This also makes Nubia a "desert civilization" for Maps/Europa_DesertGrowth.lua,
-- which reads this table: deserts grow in any game with Nubia in it.

INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
	SELECT c.CivilizationType, t.TerrainType, 2
	FROM Civilizations c, Terrains t
	WHERE c.CivilizationType = 'CIVILIZATION_NUBIA'
	  AND t.TerrainType IN ('TERRAIN_DESERT', 'TERRAIN_DESERT_HILLS');
