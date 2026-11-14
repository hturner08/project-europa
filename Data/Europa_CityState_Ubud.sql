-- Project Europa: Ubud, a Cultural city-state. Suzerain bonus: Art in Nature.
--   Theater Squares: +1 Culture for each adjacent unimproved Woods or Rainforest (max +2).
--   After Flight, Theater Squares next to two such tiles: +2 Tourism.
-- Shared requirements and the Europa_Tiers table come from Europa_CityStateCommon.sql.

INSERT INTO Types (Type, Kind) VALUES
	('CIVILIZATION_EUROPA_UBUD',     'KIND_CIVILIZATION'),
	('LEADER_MINOR_CIV_EUROPA_UBUD', 'KIND_LEADER'),
	('MINOR_CIV_EUROPA_UBUD_TRAIT',  'KIND_TRAIT');

INSERT INTO TypeProperties (Type, Name, Value) VALUES
	('CIVILIZATION_EUROPA_UBUD', 'CityStateCategory', 'CULTURAL');

INSERT INTO Civilizations (CivilizationType, Name, Description, Adjective, StartingCivilizationLevelType, RandomCityNameDepth) VALUES
	('CIVILIZATION_EUROPA_UBUD', 'LOC_CIVILIZATION_EUROPA_UBUD_NAME', 'LOC_CIVILIZATION_EUROPA_UBUD_DESCRIPTION', 'LOC_CIVILIZATION_EUROPA_UBUD_ADJECTIVE', 'CIVILIZATION_LEVEL_CITY_STATE', 1);

INSERT INTO CityNames (CivilizationType, CityName) VALUES
	('CIVILIZATION_EUROPA_UBUD', 'LOC_CITY_NAME_EUROPA_UBUD');

INSERT INTO Leaders (LeaderType, Name, InheritFrom) VALUES
	('LEADER_MINOR_CIV_EUROPA_UBUD', 'LOC_CIVILIZATION_EUROPA_UBUD_NAME', 'LEADER_MINOR_CIV_CULTURAL');

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
	('CIVILIZATION_EUROPA_UBUD', 'LEADER_MINOR_CIV_EUROPA_UBUD', 'LOC_CITY_NAME_EUROPA_UBUD');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('MINOR_CIV_EUROPA_UBUD_TRAIT', 'LOC_MINOR_CIV_EUROPA_UBUD_TRAIT_NAME', 'LOC_MINOR_CIV_EUROPA_UBUD_TRAIT_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_MINOR_CIV_EUROPA_UBUD', 'MINOR_CIV_EUROPA_UBUD_TRAIT');

-- Gathering Storm: which envoy bonuses (1, 3 and 6 envoys) this city-state gives.
INSERT INTO Leaders_XP2 (LeaderType, MinorCivBonusType) VALUES
	('LEADER_MINOR_CIV_EUROPA_UBUD', 'MINOR_CIV_BONUS_CULTURAL');

INSERT INTO StartBiasFeatures (CivilizationType, FeatureType, Tier) VALUES
	('CIVILIZATION_EUROPA_UBUD', 'FEATURE_JUNGLE', 5),
	('CIVILIZATION_EUROPA_UBUD', 'FEATURE_FOREST', 5);

-- ---------------------------------------------------------------------------
-- Suzerain bonus
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_PLAYER_HAS_FLIGHT', 'REQUIREMENT_PLAYER_HAS_TECHNOLOGY');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_REQ_PLAYER_HAS_FLIGHT', 'TechnologyType', 'TECH_FLIGHT');
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_PLAYER_HAS_FLIGHT', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_PLAYER_HAS_FLIGHT', 'EUROPA_REQ_PLAYER_HAS_FLIGHT');

-- +1 Culture per adjacent unimproved Woods or Rainforest; the script caps the count at 2.
-- (The engine's feature-adjacency effect can neither skip improved tiles nor stop at 2.)
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_UBUD_THEATER_CULTURE_1', 'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE', 'EUROPA_REQSET_CS_WILD_TILES_1'),
	('EUROPA_UBUD_THEATER_CULTURE_2', 'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE', 'EUROPA_REQSET_CS_WILD_TILES_2');
-- A flat +2 Tourism per Theater Square with two such tiles, once the Suzerain has Flight.
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
	('EUROPA_UBUD_THEATER_TOURISM', 'MODIFIER_PLAYER_DISTRICTS_ADJUST_TOURISM_CHANGE', 'EUROPA_REQSET_PLAYER_HAS_FLIGHT', 'EUROPA_REQSET_CS_WILD_TILES_2');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_UBUD_THEATER_CULTURE_1', 'YieldType', 'YIELD_CULTURE'),
	('EUROPA_UBUD_THEATER_CULTURE_1', 'Amount',    '1'),
	('EUROPA_UBUD_THEATER_CULTURE_2', 'YieldType', 'YIELD_CULTURE'),
	('EUROPA_UBUD_THEATER_CULTURE_2', 'Amount',    '1'),
	('EUROPA_UBUD_THEATER_TOURISM',   'Amount',    '2');

-- Every bonus above reaches the Suzerain through an attach modifier on the city-state's trait.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT ModifierId || '_SUZERAIN', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_UBUD_%';
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId || '_SUZERAIN', 'ModifierId', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_UBUD_%' AND ModifierId NOT LIKE '%_SUZERAIN';
INSERT INTO TraitModifiers (TraitType, ModifierId)
	SELECT 'MINOR_CIV_EUROPA_UBUD_TRAIT', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_UBUD_%_SUZERAIN';
