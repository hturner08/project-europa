-- Project Europa: Lhasa, a Religious city-state. Suzerain bonus: Mountain Monasteries.
--   Holy Sites next to two Mountains: +2 Culture.
--   Shrines in those cities: +1 Production.
-- Shared requirements and the Europa_Tiers table come from Europa_CityStateCommon.sql.

INSERT INTO Types (Type, Kind) VALUES
	('CIVILIZATION_EUROPA_LHASA',     'KIND_CIVILIZATION'),
	('LEADER_MINOR_CIV_EUROPA_LHASA', 'KIND_LEADER'),
	('MINOR_CIV_EUROPA_LHASA_TRAIT',  'KIND_TRAIT');

INSERT INTO TypeProperties (Type, Name, Value) VALUES
	('CIVILIZATION_EUROPA_LHASA', 'CityStateCategory', 'RELIGIOUS');

INSERT INTO Civilizations (CivilizationType, Name, Description, Adjective, StartingCivilizationLevelType, RandomCityNameDepth) VALUES
	('CIVILIZATION_EUROPA_LHASA', 'LOC_CIVILIZATION_EUROPA_LHASA_NAME', 'LOC_CIVILIZATION_EUROPA_LHASA_DESCRIPTION', 'LOC_CIVILIZATION_EUROPA_LHASA_ADJECTIVE', 'CIVILIZATION_LEVEL_CITY_STATE', 1);

INSERT INTO CityNames (CivilizationType, CityName) VALUES
	('CIVILIZATION_EUROPA_LHASA', 'LOC_CITY_NAME_EUROPA_LHASA');

INSERT INTO Leaders (LeaderType, Name, InheritFrom) VALUES
	('LEADER_MINOR_CIV_EUROPA_LHASA', 'LOC_CIVILIZATION_EUROPA_LHASA_NAME', 'LEADER_MINOR_CIV_RELIGIOUS');

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
	('CIVILIZATION_EUROPA_LHASA', 'LEADER_MINOR_CIV_EUROPA_LHASA', 'LOC_CITY_NAME_EUROPA_LHASA');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('MINOR_CIV_EUROPA_LHASA_TRAIT', 'LOC_MINOR_CIV_EUROPA_LHASA_TRAIT_NAME', 'LOC_MINOR_CIV_EUROPA_LHASA_TRAIT_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_MINOR_CIV_EUROPA_LHASA', 'MINOR_CIV_EUROPA_LHASA_TRAIT');

-- Gathering Storm: which envoy bonuses (1, 3 and 6 envoys) this city-state gives.
INSERT INTO Leaders_XP2 (LeaderType, MinorCivBonusType) VALUES
	('LEADER_MINOR_CIV_EUROPA_LHASA', 'MINOR_CIV_BONUS_RELIGIOUS');

INSERT INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
	('CIVILIZATION_EUROPA_LHASA', 'TERRAIN_GRASS_MOUNTAIN', 5),
	('CIVILIZATION_EUROPA_LHASA', 'TERRAIN_PLAINS_MOUNTAIN', 5),
	('CIVILIZATION_EUROPA_LHASA', 'TERRAIN_TUNDRA_MOUNTAIN', 5),
	('CIVILIZATION_EUROPA_LHASA', 'TERRAIN_DESERT_MOUNTAIN', 5);

-- ---------------------------------------------------------------------------
-- Suzerain bonus
-- ---------------------------------------------------------------------------

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- A flat district yield, not adjacency: more Mountains add nothing.
	('EUROPA_LHASA_HOLY_SITE_CULTURE', 'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE',       'EUROPA_REQSET_CS_MONASTERY_1'),
	('EUROPA_LHASA_SHRINE_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', 'EUROPA_REQSET_CS_MONASTERY_CITY_1');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_LHASA_HOLY_SITE_CULTURE', 'YieldType',    'YIELD_CULTURE'),
	('EUROPA_LHASA_HOLY_SITE_CULTURE', 'Amount',       '2'),
	('EUROPA_LHASA_SHRINE_PRODUCTION', 'BuildingType', 'BUILDING_SHRINE'),
	('EUROPA_LHASA_SHRINE_PRODUCTION', 'YieldType',    'YIELD_PRODUCTION'),
	('EUROPA_LHASA_SHRINE_PRODUCTION', 'Amount',       '1');

-- Every bonus above reaches the Suzerain through an attach modifier on the city-state's trait.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT ModifierId || '_SUZERAIN', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_LHASA_%';
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId || '_SUZERAIN', 'ModifierId', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_LHASA_%' AND ModifierId NOT LIKE '%_SUZERAIN';
INSERT INTO TraitModifiers (TraitType, ModifierId)
	SELECT 'MINOR_CIV_EUROPA_LHASA_TRAIT', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_LHASA_%_SUZERAIN';
