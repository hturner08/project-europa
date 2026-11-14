-- Project Europa: Sheffield, an Industrial city-state. Suzerain bonus: Masters of Steel.
--   Mines and Quarries next to one of your Industrial Zones: +1 Production.
--   Industrial Zones with a Workshop and three adjacent Mines or Quarries: +1 Great Engineer point.
-- Shared requirements and the Europa_Tiers table come from Europa_CityStateCommon.sql.

INSERT INTO Types (Type, Kind) VALUES
	('CIVILIZATION_EUROPA_SHEFFIELD',     'KIND_CIVILIZATION'),
	('LEADER_MINOR_CIV_EUROPA_SHEFFIELD', 'KIND_LEADER'),
	('MINOR_CIV_EUROPA_SHEFFIELD_TRAIT',  'KIND_TRAIT');

INSERT INTO TypeProperties (Type, Name, Value) VALUES
	('CIVILIZATION_EUROPA_SHEFFIELD', 'CityStateCategory', 'INDUSTRIAL');

INSERT INTO Civilizations (CivilizationType, Name, Description, Adjective, StartingCivilizationLevelType, RandomCityNameDepth) VALUES
	('CIVILIZATION_EUROPA_SHEFFIELD', 'LOC_CIVILIZATION_EUROPA_SHEFFIELD_NAME', 'LOC_CIVILIZATION_EUROPA_SHEFFIELD_DESCRIPTION', 'LOC_CIVILIZATION_EUROPA_SHEFFIELD_ADJECTIVE', 'CIVILIZATION_LEVEL_CITY_STATE', 1);

INSERT INTO CityNames (CivilizationType, CityName) VALUES
	('CIVILIZATION_EUROPA_SHEFFIELD', 'LOC_CITY_NAME_EUROPA_SHEFFIELD');

INSERT INTO Leaders (LeaderType, Name, InheritFrom) VALUES
	('LEADER_MINOR_CIV_EUROPA_SHEFFIELD', 'LOC_CIVILIZATION_EUROPA_SHEFFIELD_NAME', 'LEADER_MINOR_CIV_INDUSTRIAL');

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
	('CIVILIZATION_EUROPA_SHEFFIELD', 'LEADER_MINOR_CIV_EUROPA_SHEFFIELD', 'LOC_CITY_NAME_EUROPA_SHEFFIELD');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('MINOR_CIV_EUROPA_SHEFFIELD_TRAIT', 'LOC_MINOR_CIV_EUROPA_SHEFFIELD_TRAIT_NAME', 'LOC_MINOR_CIV_EUROPA_SHEFFIELD_TRAIT_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_MINOR_CIV_EUROPA_SHEFFIELD', 'MINOR_CIV_EUROPA_SHEFFIELD_TRAIT');

-- Gathering Storm: which envoy bonuses (1, 3 and 6 envoys) this city-state gives.
INSERT INTO Leaders_XP2 (LeaderType, MinorCivBonusType) VALUES
	('LEADER_MINOR_CIV_EUROPA_SHEFFIELD', 'MINOR_CIV_BONUS_INDUSTRIAL');

INSERT INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
	('CIVILIZATION_EUROPA_SHEFFIELD', 'TERRAIN_GRASS_HILLS', 5),
	('CIVILIZATION_EUROPA_SHEFFIELD', 'TERRAIN_PLAINS_HILLS', 5);

-- ---------------------------------------------------------------------------
-- Suzerain bonus
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_CITY_HAS_WORKSHOP', 'REQUIREMENT_CITY_HAS_BUILDING');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_REQ_CITY_HAS_WORKSHOP', 'BuildingType', 'BUILDING_WORKSHOP');
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_STEELWORKS_WITH_WORKSHOP', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_STEELWORKS_WITH_WORKSHOP', 'EUROPA_REQ_CS_STEELWORKS_1'),
	('EUROPA_REQSET_STEELWORKS_WITH_WORKSHOP', 'EUROPA_REQ_CITY_HAS_WORKSHOP');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- The script flags each Mine or Quarry that touches one of its owner's Industrial Zones,
	-- so a tile between two Zones still gets +1, and another player's Zone does not count.
	('EUROPA_SHEFFIELD_TILE_PRODUCTION', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD',                    'EUROPA_REQSET_CS_STEEL_TILE_1'),
	-- +1 point per qualifying Industrial Zone, with no empire-wide cap: the subject is each district.
	('EUROPA_SHEFFIELD_ENGINEER_POINT',  'MODIFIER_PLAYER_DISTRICTS_ADJUST_GREAT_PERSON_POINTS', 'EUROPA_REQSET_STEELWORKS_WITH_WORKSHOP');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_SHEFFIELD_TILE_PRODUCTION', 'YieldType',            'YIELD_PRODUCTION'),
	('EUROPA_SHEFFIELD_TILE_PRODUCTION', 'Amount',               '1'),
	('EUROPA_SHEFFIELD_ENGINEER_POINT',  'GreatPersonClassType', 'GREAT_PERSON_CLASS_ENGINEER'),
	('EUROPA_SHEFFIELD_ENGINEER_POINT',  'Amount',               '1');

-- Every bonus above reaches the Suzerain through an attach modifier on the city-state's trait.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT ModifierId || '_SUZERAIN', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_SHEFFIELD_%';
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId || '_SUZERAIN', 'ModifierId', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_SHEFFIELD_%' AND ModifierId NOT LIKE '%_SUZERAIN';
INSERT INTO TraitModifiers (TraitType, ModifierId)
	SELECT 'MINOR_CIV_EUROPA_SHEFFIELD_TRAIT', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_SHEFFIELD_%_SUZERAIN';
