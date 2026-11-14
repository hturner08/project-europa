-- Project Europa: Mali, "Golden Expansion".
-- Replaces the leader ability only; Mali's civilization ability, Suguba and
-- Mandekalu Cavalry are whatever the loaded ruleset (stock or BBG) defines.
-- Art, agenda and favoured religion are borrowed from Mansa Musa.

INSERT INTO Types (Type, Kind) VALUES
	('LEADER_EUROPA_GOLDEN_EXPANSION',       'KIND_LEADER'),
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'KIND_TRAIT');

INSERT INTO Leaders (LeaderType, Name, InheritFrom, SceneLayers, Sex) VALUES
	('LEADER_EUROPA_GOLDEN_EXPANSION', 'LOC_LEADER_EUROPA_GOLDEN_EXPANSION_NAME', 'LEADER_DEFAULT', 4, 'Male');

INSERT INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName)
	SELECT 'LEADER_EUROPA_GOLDEN_EXPANSION', CivilizationType, CapitalName
	FROM CivilizationLeaders WHERE LeaderType = 'LEADER_MANSA_MUSA';

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'LOC_TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION_NAME', 'LOC_TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_EUROPA_GOLDEN_EXPANSION', 'TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION');

INSERT INTO HistoricalAgendas (LeaderType, AgendaType)
	SELECT 'LEADER_EUROPA_GOLDEN_EXPANSION', AgendaType FROM HistoricalAgendas WHERE LeaderType = 'LEADER_MANSA_MUSA';

INSERT INTO FavoredReligions (LeaderType, ReligionType)
	SELECT 'LEADER_EUROPA_GOLDEN_EXPANSION', ReligionType FROM FavoredReligions WHERE LeaderType = 'LEADER_MANSA_MUSA';

INSERT INTO LoadingInfo (LeaderType, ForegroundImage, BackgroundImage, LeaderText, PlayDawnOfManAudio) VALUES
	('LEADER_EUROPA_GOLDEN_EXPANSION', 'LEADER_MANSA_MUSA_NEUTRAL', 'LEADER_MANSA_MUSA_BACKGROUND', 'LOC_LOADING_INFO_LEADER_EUROPA_GOLDEN_EXPANSION', 0);

-- BBG gives each stock Mali leader a Suguba adjacency (Mansa Musa: Gold from
-- Holy Sites; Sundiata Keita: from Theater Squares) and switches it off for the
-- other one by trait. A new leader would otherwise inherit both. This leader
-- keeps Mansa Musa's Holy Site Gold and opts out of the rest, by copying exactly
-- the exclusions Mansa Musa's own traits have. No rows match without BBG.
INSERT OR IGNORE INTO ExcludedAdjacencies (TraitType, YieldChangeId)
	SELECT DISTINCT 'TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', YieldChangeId
	FROM ExcludedAdjacencies
	WHERE TraitType IN (SELECT TraitType FROM LeaderTraits WHERE LeaderType = 'LEADER_MANSA_MUSA');

-- ---------------------------------------------------------------------------
-- Ability
-- ---------------------------------------------------------------------------

-- Requirements
INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_CITY_HAS_SUGUBA',          'REQUIREMENT_CITY_HAS_DISTRICT'),
	('EUROPA_REQ_CITY_HAS_COMMERCIAL_HUB',  'REQUIREMENT_CITY_HAS_DISTRICT'),
	('EUROPA_REQ_CONTINENT_ROUTES_1',       'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
	('EUROPA_REQ_CONTINENT_ROUTES_2',       'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
	('EUROPA_REQ_CONTINENT_ROUTES_3',       'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
	('EUROPA_REQ_CONTINENT_ROUTES_4',       'REQUIREMENT_PLOT_PROPERTY_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_REQ_CITY_HAS_SUGUBA',         'DistrictType',    'DISTRICT_SUGUBA'),
	('EUROPA_REQ_CITY_HAS_COMMERCIAL_HUB', 'DistrictType',    'DISTRICT_COMMERCIAL_HUB'),
	-- EUROPA_CONTINENT_ROUTES is written to the capital's plot by Scripts/Europa_Leaders.lua.
	('EUROPA_REQ_CONTINENT_ROUTES_1',      'PropertyName',    'EUROPA_CONTINENT_ROUTES'),
	('EUROPA_REQ_CONTINENT_ROUTES_1',      'PropertyMinimum', '1'),
	('EUROPA_REQ_CONTINENT_ROUTES_2',      'PropertyName',    'EUROPA_CONTINENT_ROUTES'),
	('EUROPA_REQ_CONTINENT_ROUTES_2',      'PropertyMinimum', '2'),
	('EUROPA_REQ_CONTINENT_ROUTES_3',      'PropertyName',    'EUROPA_CONTINENT_ROUTES'),
	('EUROPA_REQ_CONTINENT_ROUTES_3',      'PropertyMinimum', '3'),
	('EUROPA_REQ_CONTINENT_ROUTES_4',      'PropertyName',    'EUROPA_CONTINENT_ROUTES'),
	('EUROPA_REQ_CONTINENT_ROUTES_4',      'PropertyMinimum', '4');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	-- Either type: the engine may or may not treat a unique district as its base type here.
	('EUROPA_REQSET_CITY_HAS_SUGUBA',    'REQUIREMENTSET_TEST_ANY'),
	('EUROPA_REQSET_CONTINENT_ROUTES_1', 'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_CONTINENT_ROUTES_2', 'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_CONTINENT_ROUTES_3', 'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_CONTINENT_ROUTES_4', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_CITY_HAS_SUGUBA',    'EUROPA_REQ_CITY_HAS_SUGUBA'),
	('EUROPA_REQSET_CITY_HAS_SUGUBA',    'EUROPA_REQ_CITY_HAS_COMMERCIAL_HUB'),
	('EUROPA_REQSET_CONTINENT_ROUTES_1', 'EUROPA_REQ_CONTINENT_ROUTES_1'),
	('EUROPA_REQSET_CONTINENT_ROUTES_2', 'EUROPA_REQ_CONTINENT_ROUTES_2'),
	('EUROPA_REQSET_CONTINENT_ROUTES_3', 'EUROPA_REQ_CONTINENT_ROUTES_3'),
	('EUROPA_REQSET_CONTINENT_ROUTES_4', 'EUROPA_REQ_CONTINENT_ROUTES_4');

-- Modifiers
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- Settlers cost 10% less Gold.
	('EUROPA_MALI_SETTLER_PURCHASE_DISCOUNT',   'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_PURCHASE_COST', NULL),
	-- Domestic Trade Routes sent from a city with a Suguba: +2 Production.
	('EUROPA_MALI_SUGUBA_DOMESTIC_PRODUCTION',  'EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_FOR_DOMESTIC', 'EUROPA_REQSET_CITY_HAS_SUGUBA'),
	-- +1 Trade Route capacity per continent holding three founded cities (max 4).
	-- Each tier fires once, on the capital, when its plot property is high enough.
	('EUROPA_MALI_CONTINENT_ROUTE_1',           'MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_CAPACITY', 'EUROPA_REQSET_CONTINENT_ROUTES_1'),
	('EUROPA_MALI_CONTINENT_ROUTE_2',           'MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_CAPACITY', 'EUROPA_REQSET_CONTINENT_ROUTES_2'),
	('EUROPA_MALI_CONTINENT_ROUTE_3',           'MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_CAPACITY', 'EUROPA_REQSET_CONTINENT_ROUTES_3'),
	('EUROPA_MALI_CONTINENT_ROUTE_4',           'MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_CAPACITY', 'EUROPA_REQSET_CONTINENT_ROUTES_4');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_MALI_SETTLER_PURCHASE_DISCOUNT',  'UnitType',  'UNIT_SETTLER'),
	('EUROPA_MALI_SETTLER_PURCHASE_DISCOUNT',  'Amount',    '10'),
	('EUROPA_MALI_SUGUBA_DOMESTIC_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('EUROPA_MALI_SUGUBA_DOMESTIC_PRODUCTION', 'Amount',    '2'),
	('EUROPA_MALI_CONTINENT_ROUTE_1',          'Amount',    '1'),
	('EUROPA_MALI_CONTINENT_ROUTE_2',          'Amount',    '1'),
	('EUROPA_MALI_CONTINENT_ROUTE_3',          'Amount',    '1'),
	('EUROPA_MALI_CONTINENT_ROUTE_4',          'Amount',    '1');

INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'EUROPA_MALI_SETTLER_PURCHASE_DISCOUNT'),
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'EUROPA_MALI_SUGUBA_DOMESTIC_PRODUCTION'),
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'EUROPA_MALI_CONTINENT_ROUTE_1'),
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'EUROPA_MALI_CONTINENT_ROUTE_2'),
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'EUROPA_MALI_CONTINENT_ROUTE_3'),
	('TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION', 'EUROPA_MALI_CONTINENT_ROUTE_4');
