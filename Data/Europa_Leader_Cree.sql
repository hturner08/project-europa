-- Project Europa: Cree, "The Borderless Empire" (ability: Land Through Commerce).
-- Replaces the leader ability only; Nihithaw, the Mekewap and the Okihtcitaw are
-- whatever the loaded ruleset (stock or BBG) defines.
-- Art, agenda and favoured religion are borrowed from Poundmaker.
-- Needs Rise and Fall: without it the CivilizationLeaders row below fails its
-- foreign key and only this file is rolled back.

INSERT INTO Types (Type, Kind) VALUES
	('LEADER_EUROPA_BORDERLESS_EMPIRE',       'KIND_LEADER'),
	('TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE', 'KIND_TRAIT');

INSERT INTO Leaders (LeaderType, Name, InheritFrom, SceneLayers, Sex) VALUES
	('LEADER_EUROPA_BORDERLESS_EMPIRE', 'LOC_LEADER_EUROPA_BORDERLESS_EMPIRE_NAME', 'LEADER_DEFAULT', 4, 'Male');

-- Hard-coded civilization on purpose: this is the row that must fail without the DLC.
INSERT INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName) VALUES
	('LEADER_EUROPA_BORDERLESS_EMPIRE', 'CIVILIZATION_CREE', 'LOC_CITY_NAME_MIKISIW_WACIHK');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE', 'LOC_TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE_NAME', 'LOC_TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_EUROPA_BORDERLESS_EMPIRE', 'TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE');

INSERT INTO HistoricalAgendas (LeaderType, AgendaType)
	SELECT 'LEADER_EUROPA_BORDERLESS_EMPIRE', AgendaType FROM HistoricalAgendas WHERE LeaderType = 'LEADER_POUNDMAKER';

INSERT INTO FavoredReligions (LeaderType, ReligionType)
	SELECT 'LEADER_EUROPA_BORDERLESS_EMPIRE', ReligionType FROM FavoredReligions WHERE LeaderType = 'LEADER_POUNDMAKER';

INSERT INTO LoadingInfo (LeaderType, ForegroundImage, BackgroundImage, LeaderText, PlayDawnOfManAudio) VALUES
	('LEADER_EUROPA_BORDERLESS_EMPIRE', 'LEADER_POUNDMAKER_NEUTRAL', 'LEADER_POUNDMAKER_BACKGROUND', 'LOC_LOADING_INFO_LEADER_EUROPA_BORDERLESS_EMPIRE', 0);

-- ---------------------------------------------------------------------------
-- Ability
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_UNIT_IS_SETTLER',     'REQUIREMENT_UNIT_TYPE_MATCHES'),
	('EUROPA_REQ_CITY_HAS_HERD',       'REQUIREMENT_PLOT_PROPERTY_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_REQ_UNIT_IS_SETTLER', 'UnitType',        'UNIT_SETTLER'),
	-- EUROPA_HERD_CITY is written to the city-centre plot by Scripts/Europa_Leaders.lua:
	-- 1 while the city owns at least one Camp or Pasture. There is no
	-- "city has improvement X" requirement in the database.
	('EUROPA_REQ_CITY_HAS_HERD',   'PropertyName',    'EUROPA_HERD_CITY'),
	('EUROPA_REQ_CITY_HAS_HERD',   'PropertyMinimum', '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_UNIT_IS_SETTLER', 'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_CITY_HAS_HERD',   'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_UNIT_IS_SETTLER', 'EUROPA_REQ_UNIT_IS_SETTLER'),
	('EUROPA_REQSET_CITY_HAS_HERD',   'EUROPA_REQ_CITY_HAS_HERD');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- Settlers: +1 Sight.
	('EUROPA_CREE_SETTLER_SIGHT',         'EUROPA_MODIFIER_PLAYER_UNITS_ADJUST_SIGHT', 'EUROPA_REQSET_UNIT_IS_SETTLER'),
	-- International Trade Routes sent from a city with a Camp or Pasture: +2 Food, +1 Production.
	('EUROPA_CREE_HERD_TRADE_FOOD',       'EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_FOR_INTERNATIONAL', 'EUROPA_REQSET_CITY_HAS_HERD'),
	('EUROPA_CREE_HERD_TRADE_PRODUCTION', 'EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_FOR_INTERNATIONAL', 'EUROPA_REQSET_CITY_HAS_HERD');
	-- The third effect (the first Trade Route from each founded city claims two
	-- neutral tiles) has no modifier; Scripts/Europa_Leaders.lua does it.

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_CREE_SETTLER_SIGHT',         'Amount',    '1'),
	('EUROPA_CREE_HERD_TRADE_FOOD',       'YieldType', 'YIELD_FOOD'),
	('EUROPA_CREE_HERD_TRADE_FOOD',       'Amount',    '2'),
	('EUROPA_CREE_HERD_TRADE_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('EUROPA_CREE_HERD_TRADE_PRODUCTION', 'Amount',    '1');

INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE', 'EUROPA_CREE_SETTLER_SIGHT'),
	('TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE', 'EUROPA_CREE_HERD_TRADE_FOOD'),
	('TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE', 'EUROPA_CREE_HERD_TRADE_PRODUCTION');
