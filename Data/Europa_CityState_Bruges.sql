-- Project Europa: Bruges, a Trade city-state. Suzerain bonus: Mercantile Renaissance.
--   Commercial Hubs: +1 Gold for each adjacent Theater Square.
--   Theater Squares: +1 Culture for each adjacent Commercial Hub.
--   Cities with both: +1 Culture per Trade Route they send (max +2 per city).
-- Shared requirements and the Europa_Tiers table come from Europa_CityStateCommon.sql.

INSERT INTO Types (Type, Kind) VALUES
	('CIVILIZATION_EUROPA_BRUGES',     'KIND_CIVILIZATION'),
	('LEADER_MINOR_CIV_EUROPA_BRUGES', 'KIND_LEADER'),
	('MINOR_CIV_EUROPA_BRUGES_TRAIT',  'KIND_TRAIT');

INSERT INTO TypeProperties (Type, Name, Value) VALUES
	('CIVILIZATION_EUROPA_BRUGES', 'CityStateCategory', 'TRADE');

INSERT INTO Civilizations (CivilizationType, Name, Description, Adjective, StartingCivilizationLevelType, RandomCityNameDepth) VALUES
	('CIVILIZATION_EUROPA_BRUGES', 'LOC_CIVILIZATION_EUROPA_BRUGES_NAME', 'LOC_CIVILIZATION_EUROPA_BRUGES_DESCRIPTION', 'LOC_CIVILIZATION_EUROPA_BRUGES_ADJECTIVE', 'CIVILIZATION_LEVEL_CITY_STATE', 1);

INSERT INTO CityNames (CivilizationType, CityName) VALUES
	('CIVILIZATION_EUROPA_BRUGES', 'LOC_CITY_NAME_EUROPA_BRUGES');

INSERT INTO Leaders (LeaderType, Name, InheritFrom) VALUES
	('LEADER_MINOR_CIV_EUROPA_BRUGES', 'LOC_CIVILIZATION_EUROPA_BRUGES_NAME', 'LEADER_MINOR_CIV_TRADE');

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
	('CIVILIZATION_EUROPA_BRUGES', 'LEADER_MINOR_CIV_EUROPA_BRUGES', 'LOC_CITY_NAME_EUROPA_BRUGES');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('MINOR_CIV_EUROPA_BRUGES_TRAIT', 'LOC_MINOR_CIV_EUROPA_BRUGES_TRAIT_NAME', 'LOC_MINOR_CIV_EUROPA_BRUGES_TRAIT_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_MINOR_CIV_EUROPA_BRUGES', 'MINOR_CIV_EUROPA_BRUGES_TRAIT');

-- Gathering Storm: which envoy bonuses (1, 3 and 6 envoys) this city-state gives.
INSERT INTO Leaders_XP2 (LeaderType, MinorCivBonusType) VALUES
	('LEADER_MINOR_CIV_EUROPA_BRUGES', 'MINOR_CIV_BONUS_TRADE');

INSERT INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
	('CIVILIZATION_EUROPA_BRUGES', 'TERRAIN_COAST', 5);

-- ---------------------------------------------------------------------------
-- Suzerain bonus
-- ---------------------------------------------------------------------------

-- One modifier per neighbour counted; see Europa_CityState_Syracuse.sql for why these are
-- added to the district rather than declared as adjacency.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT 'EUROPA_BRUGES_HUB_GOLD_' || n, 'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE', 'EUROPA_REQSET_CS_HUB_THEATERS_' || n FROM Europa_Tiers
	UNION ALL
	SELECT 'EUROPA_BRUGES_THEATER_CULTURE_' || n, 'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE', 'EUROPA_REQSET_CS_THEATER_HUBS_' || n FROM Europa_Tiers;
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT 'EUROPA_BRUGES_HUB_GOLD_' || n, 'YieldType', 'YIELD_GOLD' FROM Europa_Tiers
	UNION ALL
	SELECT 'EUROPA_BRUGES_HUB_GOLD_' || n, 'Amount', '1' FROM Europa_Tiers
	UNION ALL
	SELECT 'EUROPA_BRUGES_THEATER_CULTURE_' || n, 'YieldType', 'YIELD_CULTURE' FROM Europa_Tiers
	UNION ALL
	SELECT 'EUROPA_BRUGES_THEATER_CULTURE_' || n, 'Amount', '1' FROM Europa_Tiers;

-- +1 Culture in the origin city for its first Trade Route and +1 for its second; the script
-- stops counting at 2, and counts each city on its own.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_BRUGES_ROUTE_CULTURE_1', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE', 'EUROPA_REQSET_CS_TRADE_CULTURE_1'),
	('EUROPA_BRUGES_ROUTE_CULTURE_2', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE', 'EUROPA_REQSET_CS_TRADE_CULTURE_2');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_BRUGES_ROUTE_CULTURE_1', 'YieldType', 'YIELD_CULTURE'),
	('EUROPA_BRUGES_ROUTE_CULTURE_1', 'Amount',    '1'),
	('EUROPA_BRUGES_ROUTE_CULTURE_2', 'YieldType', 'YIELD_CULTURE'),
	('EUROPA_BRUGES_ROUTE_CULTURE_2', 'Amount',    '1');

-- Every bonus above reaches the Suzerain through an attach modifier on the city-state's trait.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
	SELECT ModifierId || '_SUZERAIN', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_BRUGES_%';
INSERT INTO ModifierArguments (ModifierId, Name, Value)
	SELECT ModifierId || '_SUZERAIN', 'ModifierId', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_BRUGES_%' AND ModifierId NOT LIKE '%_SUZERAIN';
INSERT INTO TraitModifiers (TraitType, ModifierId)
	SELECT 'MINOR_CIV_EUROPA_BRUGES_TRAIT', ModifierId
	FROM Modifiers WHERE ModifierId LIKE 'EUROPA_BRUGES_%_SUZERAIN';
