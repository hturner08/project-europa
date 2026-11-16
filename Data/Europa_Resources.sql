-- Project Europa: New Luxuries
-- Gameplay database. Loaded by the UpdateDatabase action in ProjectEuropa.modinfo.
-- All types are prefixed EUROPA_ so they cannot collide with other resource mods.

INSERT INTO Types (Type, Kind) VALUES
	('RESOURCE_EUROPA_TOPAZ',         'KIND_RESOURCE'),
	('RESOURCE_EUROPA_PEACOCKS',      'KIND_RESOURCE'),
	('RESOURCE_EUROPA_PALLAS_CATS',   'KIND_RESOURCE'),
	('RESOURCE_EUROPA_PYGMY_RABBITS', 'KIND_RESOURCE'),
	('RESOURCE_EUROPA_TIBETAN_FOXES', 'KIND_RESOURCE'),
	('RESOURCE_EUROPA_DISCUS_FISH',   'KIND_RESOURCE'),
	('RESOURCE_EUROPA_CAPYBARAS',     'KIND_RESOURCE');

-- Frequency drives the map generator's land-luxury pass (2 = same as most base luxuries).
-- Discus Fish has Frequency 0 and SeaFrequency 0 on purpose: the generator has no
-- "lakes only" rule, so Scripts/Europa_LakeResources.lua places it instead.
INSERT INTO Resources (ResourceType, Name, ResourceClassType, Happiness, Frequency, SeaFrequency, LakeEligible) VALUES
	('RESOURCE_EUROPA_TOPAZ',         'LOC_RESOURCE_EUROPA_TOPAZ_NAME',         'RESOURCECLASS_LUXURY', 4, 2, 0, 1),
	('RESOURCE_EUROPA_PEACOCKS',      'LOC_RESOURCE_EUROPA_PEACOCKS_NAME',      'RESOURCECLASS_LUXURY', 4, 2, 0, 1),
	('RESOURCE_EUROPA_PALLAS_CATS',   'LOC_RESOURCE_EUROPA_PALLAS_CATS_NAME',   'RESOURCECLASS_LUXURY', 4, 2, 0, 1),
	('RESOURCE_EUROPA_PYGMY_RABBITS', 'LOC_RESOURCE_EUROPA_PYGMY_RABBITS_NAME', 'RESOURCECLASS_LUXURY', 4, 2, 0, 1),
	('RESOURCE_EUROPA_TIBETAN_FOXES', 'LOC_RESOURCE_EUROPA_TIBETAN_FOXES_NAME', 'RESOURCECLASS_LUXURY', 4, 2, 0, 1),
	('RESOURCE_EUROPA_DISCUS_FISH',   'LOC_RESOURCE_EUROPA_DISCUS_FISH_NAME',   'RESOURCECLASS_LUXURY', 4, 0, 0, 1),
	('RESOURCE_EUROPA_CAPYBARAS',     'LOC_RESOURCE_EUROPA_CAPYBARAS_NAME',     'RESOURCECLASS_LUXURY', 4, 2, 0, 1);

INSERT INTO Resource_ValidTerrains (ResourceType, TerrainType) VALUES
	-- Topaz: any hills (same set as Diamonds)
	('RESOURCE_EUROPA_TOPAZ',         'TERRAIN_GRASS_HILLS'),
	('RESOURCE_EUROPA_TOPAZ',         'TERRAIN_PLAINS_HILLS'),
	('RESOURCE_EUROPA_TOPAZ',         'TERRAIN_DESERT_HILLS'),
	('RESOURCE_EUROPA_TOPAZ',         'TERRAIN_TUNDRA_HILLS'),
	-- Peacocks: Grassland, Plains (+ Woods below)
	('RESOURCE_EUROPA_PEACOCKS',      'TERRAIN_GRASS'),
	('RESOURCE_EUROPA_PEACOCKS',      'TERRAIN_PLAINS'),
	-- Pallas's Cats: Plains / Grassland / Tundra hills
	('RESOURCE_EUROPA_PALLAS_CATS',   'TERRAIN_PLAINS_HILLS'),
	('RESOURCE_EUROPA_PALLAS_CATS',   'TERRAIN_GRASS_HILLS'),
	('RESOURCE_EUROPA_PALLAS_CATS',   'TERRAIN_TUNDRA_HILLS'),
	-- Pygmy Rabbits: Plains, Plains hills
	('RESOURCE_EUROPA_PYGMY_RABBITS', 'TERRAIN_PLAINS'),
	('RESOURCE_EUROPA_PYGMY_RABBITS', 'TERRAIN_PLAINS_HILLS'),
	-- Tibetan Foxes: Plains / Tundra / Desert hills
	('RESOURCE_EUROPA_TIBETAN_FOXES', 'TERRAIN_PLAINS_HILLS'),
	('RESOURCE_EUROPA_TIBETAN_FOXES', 'TERRAIN_TUNDRA_HILLS'),
	('RESOURCE_EUROPA_TIBETAN_FOXES', 'TERRAIN_DESERT_HILLS'),
	-- Discus Fish: lakes are TERRAIN_COAST plots flagged as lake; the Lua script
	-- only ever places it on lake plots.
	('RESOURCE_EUROPA_DISCUS_FISH',   'TERRAIN_COAST');

-- Features. Selected from the Features table so the Gathering Storm floodplain
-- variants are picked up when present and silently skipped when not.
INSERT INTO Resource_ValidFeatures (ResourceType, FeatureType)
	SELECT 'RESOURCE_EUROPA_PEACOCKS', FeatureType FROM Features
	WHERE FeatureType IN ('FEATURE_FOREST');

INSERT INTO Resource_ValidFeatures (ResourceType, FeatureType)
	SELECT 'RESOURCE_EUROPA_CAPYBARAS', FeatureType FROM Features
	WHERE FeatureType IN ('FEATURE_MARSH', 'FEATURE_FLOODPLAINS',
	                      'FEATURE_FLOODPLAINS_GRASSLAND', 'FEATURE_FLOODPLAINS_PLAINS');

INSERT INTO Resource_YieldChanges (ResourceType, YieldType, YieldChange) VALUES
	('RESOURCE_EUROPA_TOPAZ',         'YIELD_GOLD',       3),
	('RESOURCE_EUROPA_PEACOCKS',      'YIELD_CULTURE',    1),
	('RESOURCE_EUROPA_PEACOCKS',      'YIELD_GOLD',       1),
	('RESOURCE_EUROPA_PALLAS_CATS',   'YIELD_CULTURE',    1),
	('RESOURCE_EUROPA_PALLAS_CATS',   'YIELD_GOLD',       1),
	('RESOURCE_EUROPA_PYGMY_RABBITS', 'YIELD_FOOD',       1),
	('RESOURCE_EUROPA_PYGMY_RABBITS', 'YIELD_CULTURE',    1),
	('RESOURCE_EUROPA_TIBETAN_FOXES', 'YIELD_CULTURE',    1),
	('RESOURCE_EUROPA_TIBETAN_FOXES', 'YIELD_PRODUCTION', 1),
	('RESOURCE_EUROPA_DISCUS_FISH',   'YIELD_CULTURE',    1),
	('RESOURCE_EUROPA_DISCUS_FISH',   'YIELD_GOLD',       1),
	('RESOURCE_EUROPA_CAPYBARAS',     'YIELD_FOOD',       1),
	('RESOURCE_EUROPA_CAPYBARAS',     'YIELD_CULTURE',    1);

-- Discus Fish are improved by the stock Fishing Boats. Fishing Boats have no valid
-- terrains or features of their own, so they can only be built on a listed resource,
-- and Discus Fish only exist on lakes. Everything that keys off Fishing Boats (tech
-- boost, pantheons, adjacencies, balance-mod yields) therefore applies to them too.
INSERT INTO Improvement_ValidResources (ImprovementType, ResourceType, MustRemoveFeature) VALUES
	('IMPROVEMENT_MINE',          'RESOURCE_EUROPA_TOPAZ',         0),
	('IMPROVEMENT_CAMP',          'RESOURCE_EUROPA_PEACOCKS',      0),
	('IMPROVEMENT_CAMP',          'RESOURCE_EUROPA_PALLAS_CATS',   0),
	('IMPROVEMENT_CAMP',          'RESOURCE_EUROPA_PYGMY_RABBITS', 0),
	('IMPROVEMENT_CAMP',          'RESOURCE_EUROPA_TIBETAN_FOXES', 0),
	('IMPROVEMENT_FISHING_BOATS', 'RESOURCE_EUROPA_DISCUS_FISH',   0),
	('IMPROVEMENT_CAMP',          'RESOURCE_EUROPA_CAPYBARAS',     0);

-- CLASS_* tags mirror the yields; the AI and several pantheons/abilities key off them.
-- Selected from Tags so a tag missing from the active ruleset is skipped, not an error.
INSERT INTO TypeTags (Type, Tag)
	SELECT r.ResourceType,
	       CASE r.YieldType
	           WHEN 'YIELD_FOOD'       THEN 'CLASS_FOOD'
	           WHEN 'YIELD_GOLD'       THEN 'CLASS_GOLD'
	           WHEN 'YIELD_PRODUCTION' THEN 'CLASS_PRODUCTION'
	           WHEN 'YIELD_CULTURE'    THEN 'CLASS_CULTURE'
	       END
	FROM Resource_YieldChanges r
	WHERE r.ResourceType LIKE 'RESOURCE_EUROPA_%'
	  AND CASE r.YieldType
	           WHEN 'YIELD_FOOD'       THEN 'CLASS_FOOD'
	           WHEN 'YIELD_GOLD'       THEN 'CLASS_GOLD'
	           WHEN 'YIELD_PRODUCTION' THEN 'CLASS_PRODUCTION'
	           WHEN 'YIELD_CULTURE'    THEN 'CLASS_CULTURE'
	      END IN (SELECT Tag FROM Tags);
