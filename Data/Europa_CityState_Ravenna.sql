-- Project Europa: Ravenna, a Militaristic city-state. Suzerain bonus: Imperial Engineering.
--   Military Engineers trained or bought while Suzerain: +1 build charge (kept afterwards).
--   Cities with a Harbor and an Encampment: +2 Production while constructing a building of either.
-- Shared requirements and the Europa_Tiers table come from Europa_CityStateCommon.sql.

INSERT INTO Types (Type, Kind) VALUES
	('CIVILIZATION_EUROPA_RAVENNA',     'KIND_CIVILIZATION'),
	('LEADER_MINOR_CIV_EUROPA_RAVENNA', 'KIND_LEADER'),
	('MINOR_CIV_EUROPA_RAVENNA_TRAIT',  'KIND_TRAIT');

INSERT INTO TypeProperties (Type, Name, Value) VALUES
	('CIVILIZATION_EUROPA_RAVENNA', 'CityStateCategory', 'MILITARISTIC');

INSERT INTO Civilizations (CivilizationType, Name, Description, Adjective, StartingCivilizationLevelType, RandomCityNameDepth) VALUES
	('CIVILIZATION_EUROPA_RAVENNA', 'LOC_CIVILIZATION_EUROPA_RAVENNA_NAME', 'LOC_CIVILIZATION_EUROPA_RAVENNA_DESCRIPTION', 'LOC_CIVILIZATION_EUROPA_RAVENNA_ADJECTIVE', 'CIVILIZATION_LEVEL_CITY_STATE', 1);

INSERT INTO CityNames (CivilizationType, CityName) VALUES
	('CIVILIZATION_EUROPA_RAVENNA', 'LOC_CITY_NAME_EUROPA_RAVENNA');

INSERT INTO Leaders (LeaderType, Name, InheritFrom) VALUES
	('LEADER_MINOR_CIV_EUROPA_RAVENNA', 'LOC_CIVILIZATION_EUROPA_RAVENNA_NAME', 'LEADER_MINOR_CIV_MILITARISTIC');

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
	('CIVILIZATION_EUROPA_RAVENNA', 'LEADER_MINOR_CIV_EUROPA_RAVENNA', 'LOC_CITY_NAME_EUROPA_RAVENNA');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('MINOR_CIV_EUROPA_RAVENNA_TRAIT', 'LOC_MINOR_CIV_EUROPA_RAVENNA_TRAIT_NAME', 'LOC_MINOR_CIV_EUROPA_RAVENNA_TRAIT_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_MINOR_CIV_EUROPA_RAVENNA', 'MINOR_CIV_EUROPA_RAVENNA_TRAIT');

-- Gathering Storm: which envoy bonuses (1, 3 and 6 envoys) this city-state gives.
INSERT INTO Leaders_XP2 (LeaderType, MinorCivBonusType) VALUES
	('LEADER_MINOR_CIV_EUROPA_RAVENNA', 'MINOR_CIV_BONUS_MILITARISTIC');

INSERT INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
	('CIVILIZATION_EUROPA_RAVENNA', 'TERRAIN_COAST', 5);

-- ---------------------------------------------------------------------------
-- Suzerain bonus
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_UNIT_IS_MILITARY_ENGINEER', 'REQUIREMENT_UNIT_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_REQ_UNIT_IS_MILITARY_ENGINEER', 'UnitType', 'UNIT_MILITARY_ENGINEER');
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_UNIT_IS_MILITARY_ENGINEER', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_UNIT_IS_MILITARY_ENGINEER', 'EUROPA_REQ_UNIT_IS_MILITARY_ENGINEER');

-- Same shape as Serfdom's Builder charges: it acts on units as they are trained or bought and
-- is Permanent, so the charge stays on the unit when suzerainty is lost and units that already
-- exist get nothing.
INSERT INTO Modifiers (ModifierId, ModifierType, Permanent, SubjectRequirementSetId) VALUES
	('EUROPA_RAVENNA_ENGINEER_CHARGE', 'MODIFIER_PLAYER_TRAINED_UNITS_ADJUST_BUILDER_CHARGES', 1, 'EUROPA_REQSET_UNIT_IS_MILITARY_ENGINEER');
-- The engine only has percentage bonuses toward buildings, so the flat +2 is city Production
-- that the script switches on while a Harbor or Encampment building is what the city is making.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_RAVENNA_ARSENAL_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE', 'EUROPA_REQSET_CS_ARSENAL_1');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_RAVENNA_ENGINEER_CHARGE',    'Amount',    '1'),
	('EUROPA_RAVENNA_ARSENAL_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('EUROPA_RAVENNA_ARSENAL_PRODUCTION', 'Amount',    '2');

-- Every bonus above reaches the Suzerain through an attach modifier on the city-state's trait.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT ModifierId || '_SUZERAIN', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_RAVENNA_%';
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId || '_SUZERAIN', 'ModifierId', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_RAVENNA_%' AND ModifierId NOT LIKE '%_SUZERAIN';
INSERT INTO TraitModifiers (TraitType, ModifierId)
	SELECT 'MINOR_CIV_EUROPA_RAVENNA_TRAIT', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_RAVENNA_%_SUZERAIN';
