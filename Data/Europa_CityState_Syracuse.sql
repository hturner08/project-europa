-- Project Europa: Syracuse, a Scientific city-state. Suzerain bonus: Applied Engineering.
--   Campuses: +1 Science for each adjacent Aqueduct or Dam.
--   Workshops: +1 Science in cities with a Campus.
-- Shared requirements and the Europa_Tiers table come from Europa_CityStateCommon.sql.

INSERT INTO Types (Type, Kind) VALUES
	('CIVILIZATION_EUROPA_SYRACUSE',     'KIND_CIVILIZATION'),
	('LEADER_MINOR_CIV_EUROPA_SYRACUSE', 'KIND_LEADER'),
	('MINOR_CIV_EUROPA_SYRACUSE_TRAIT',  'KIND_TRAIT');

INSERT INTO TypeProperties (Type, Name, Value) VALUES
	('CIVILIZATION_EUROPA_SYRACUSE', 'CityStateCategory', 'SCIENTIFIC');

INSERT INTO Civilizations (CivilizationType, Name, Description, Adjective, StartingCivilizationLevelType, RandomCityNameDepth) VALUES
	('CIVILIZATION_EUROPA_SYRACUSE', 'LOC_CIVILIZATION_EUROPA_SYRACUSE_NAME', 'LOC_CIVILIZATION_EUROPA_SYRACUSE_DESCRIPTION', 'LOC_CIVILIZATION_EUROPA_SYRACUSE_ADJECTIVE', 'CIVILIZATION_LEVEL_CITY_STATE', 1);

INSERT INTO CityNames (CivilizationType, CityName) VALUES
	('CIVILIZATION_EUROPA_SYRACUSE', 'LOC_CITY_NAME_EUROPA_SYRACUSE');

INSERT INTO Leaders (LeaderType, Name, InheritFrom) VALUES
	('LEADER_MINOR_CIV_EUROPA_SYRACUSE', 'LOC_CIVILIZATION_EUROPA_SYRACUSE_NAME', 'LEADER_MINOR_CIV_SCIENTIFIC');

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
	('CIVILIZATION_EUROPA_SYRACUSE', 'LEADER_MINOR_CIV_EUROPA_SYRACUSE', 'LOC_CITY_NAME_EUROPA_SYRACUSE');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('MINOR_CIV_EUROPA_SYRACUSE_TRAIT', 'LOC_MINOR_CIV_EUROPA_SYRACUSE_TRAIT_NAME', 'LOC_MINOR_CIV_EUROPA_SYRACUSE_TRAIT_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_MINOR_CIV_EUROPA_SYRACUSE', 'MINOR_CIV_EUROPA_SYRACUSE_TRAIT');

-- Gathering Storm: which envoy bonuses (1, 3 and 6 envoys) this city-state gives.
INSERT INTO Leaders_XP2 (LeaderType, MinorCivBonusType) VALUES
	('LEADER_MINOR_CIV_EUROPA_SYRACUSE', 'MINOR_CIV_BONUS_SCIENTIFIC');

INSERT INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
	('CIVILIZATION_EUROPA_SYRACUSE', 'TERRAIN_COAST', 5);

-- ---------------------------------------------------------------------------
-- Suzerain bonus
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_CITY_HAS_CAMPUS', 'REQUIREMENT_CITY_HAS_DISTRICT');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_REQ_CITY_HAS_CAMPUS', 'DistrictType', 'DISTRICT_CAMPUS');
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_CITY_HAS_CAMPUS', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_CITY_HAS_CAMPUS', 'EUROPA_REQ_CITY_HAS_CAMPUS');

-- +1 Science on the Campus per adjacent Aqueduct or Dam: one modifier per neighbour counted.
-- The engine's district-adjacency effect cannot name the neighbouring district (it is
-- "any district"), so the script counts and this adds the Science to the district itself.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT 'EUROPA_SYRACUSE_CAMPUS_SCIENCE_' || n, 'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE', 'EUROPA_REQSET_CS_WATERWORKS_' || n
	FROM Europa_Tiers;
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT 'EUROPA_SYRACUSE_CAMPUS_SCIENCE_' || n, 'YieldType', 'YIELD_SCIENCE' FROM Europa_Tiers
	UNION ALL
	SELECT 'EUROPA_SYRACUSE_CAMPUS_SCIENCE_' || n, 'Amount', '1' FROM Europa_Tiers;

-- Workshops: +1 Science in a city with a Campus, wherever the two districts stand.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_SYRACUSE_WORKSHOP_SCIENCE', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', 'EUROPA_REQSET_CITY_HAS_CAMPUS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_SYRACUSE_WORKSHOP_SCIENCE', 'BuildingType', 'BUILDING_WORKSHOP'),
	('EUROPA_SYRACUSE_WORKSHOP_SCIENCE', 'YieldType',    'YIELD_SCIENCE'),
	('EUROPA_SYRACUSE_WORKSHOP_SCIENCE', 'Amount',       '1');

-- Every bonus above reaches the Suzerain through an attach modifier on the city-state's trait.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT ModifierId || '_SUZERAIN', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_SYRACUSE_%';
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId || '_SUZERAIN', 'ModifierId', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_SYRACUSE_%' AND ModifierId NOT LIKE '%_SUZERAIN';
INSERT INTO TraitModifiers (TraitType, ModifierId)
	SELECT 'MINOR_CIV_EUROPA_SYRACUSE_TRAIT', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_SYRACUSE_%_SUZERAIN';
