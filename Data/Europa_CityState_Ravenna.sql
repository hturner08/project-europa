-- Project Europa: Ravenna, a Militaristic city-state. Suzerain bonus: Imperial Engineering.
--   +20% Production toward Harbors and Encampments.
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

-- +20% Production toward Harbors and Encampments. The effect takes one district type and
-- (going by BBG, which writes a row per unique district) does not extend to the districts
-- that replace it, so there is one modifier for each district that is, or replaces, a
-- Harbor or an Encampment in the loaded ruleset.
INSERT INTO Modifiers (ModifierId, ModifierType)
	SELECT 'EUROPA_RAVENNA_PRODUCTION_' || DistrictType, 'MODIFIER_PLAYER_CITIES_ADJUST_DISTRICT_PRODUCTION'
	FROM Districts
	WHERE DistrictType IN ('DISTRICT_HARBOR', 'DISTRICT_ENCAMPMENT')
		OR DistrictType IN (SELECT CivUniqueDistrictType FROM DistrictReplaces WHERE ReplacesDistrictType IN ('DISTRICT_HARBOR', 'DISTRICT_ENCAMPMENT'));
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId, 'DistrictType', replace(ModifierId, 'EUROPA_RAVENNA_PRODUCTION_', '') FROM Modifiers WHERE ModifierId LIKE 'EUROPA_RAVENNA_PRODUCTION_DISTRICT_%'
	UNION ALL
	SELECT ModifierId, 'Amount', '20' FROM Modifiers WHERE ModifierId LIKE 'EUROPA_RAVENNA_PRODUCTION_DISTRICT_%';

-- The engine only has percentage bonuses toward buildings, so the flat +2 is city Production
-- that the script switches on while a Harbor or Encampment building is what the city is making.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_RAVENNA_ARSENAL_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE', 'EUROPA_REQSET_CS_ARSENAL_1');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
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
