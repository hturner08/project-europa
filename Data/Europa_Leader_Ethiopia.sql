-- Project Europa: Ethiopia, "Highland Empire".
-- Replaces the leader ability only; Aksumite Legacy, the Rock-Hewn Church and
-- the Oromo Cavalry are whatever the loaded ruleset (stock or BBG) defines.
-- Art, agenda and favoured religion are borrowed from Menelik II.
-- Needs the Ethiopia Pack: without it the first INSERT ... SELECT below finds no
-- civilization, the foreign keys fail, and only this file is rolled back.

INSERT INTO Types (Type, Kind) VALUES
	('LEADER_EUROPA_HIGHLAND_EMPIRE',       'KIND_LEADER'),
	('TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE', 'KIND_TRAIT');

INSERT INTO Leaders (LeaderType, Name, InheritFrom, SceneLayers, Sex) VALUES
	('LEADER_EUROPA_HIGHLAND_EMPIRE', 'LOC_LEADER_EUROPA_HIGHLAND_EMPIRE_NAME', 'LEADER_DEFAULT', 4, 'Male');

-- Hard-coded civilization on purpose: this is the row that must fail without the DLC.
INSERT INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName) VALUES
	('LEADER_EUROPA_HIGHLAND_EMPIRE', 'CIVILIZATION_ETHIOPIA', 'LOC_CITY_NAME_ADDIS_ABABA');

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE', 'LOC_TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE_NAME', 'LOC_TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_EUROPA_HIGHLAND_EMPIRE', 'TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE');

INSERT INTO HistoricalAgendas (LeaderType, AgendaType)
	SELECT 'LEADER_EUROPA_HIGHLAND_EMPIRE', AgendaType FROM HistoricalAgendas WHERE LeaderType = 'LEADER_MENELIK';

INSERT INTO FavoredReligions (LeaderType, ReligionType)
	SELECT 'LEADER_EUROPA_HIGHLAND_EMPIRE', ReligionType FROM FavoredReligions WHERE LeaderType = 'LEADER_MENELIK';

INSERT INTO LoadingInfo (LeaderType, ForegroundImage, BackgroundImage, LeaderText, PlayDawnOfManAudio) VALUES
	('LEADER_EUROPA_HIGHLAND_EMPIRE', 'LEADER_MENELIK_NEUTRAL', 'LEADER_MENELIK_BACKGROUND', 'LOC_LOADING_INFO_LEADER_EUROPA_HIGHLAND_EMPIRE', 0);

-- ---------------------------------------------------------------------------
-- Ability
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType, Inverse) VALUES
	('EUROPA_REQ_CITY_ON_HILLS',                 'REQUIREMENT_PLOT_IS_HILLS',                  0),
	('EUROPA_REQ_CITY_FOUNDED_BY_OWNER',         'REQUIREMENT_CITY_IS_ORIGINAL_OWNER',         0),
	('EUROPA_REQ_CITY_HAS_NO_SPECIALTY_DISTRICT','REQUIREMENT_CITY_HAS_X_SPECIALTY_DISTRICTS', 1);

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_REQ_CITY_HAS_NO_SPECIALTY_DISTRICT', 'Amount', '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_FOUNDED_HILL_CITY',             'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_FOUNDED_HILL_CITY_NO_DISTRICT', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_FOUNDED_HILL_CITY',             'EUROPA_REQ_CITY_ON_HILLS'),
	('EUROPA_REQSET_FOUNDED_HILL_CITY',             'EUROPA_REQ_CITY_FOUNDED_BY_OWNER'),
	('EUROPA_REQSET_FOUNDED_HILL_CITY_NO_DISTRICT', 'EUROPA_REQ_CITY_ON_HILLS'),
	('EUROPA_REQSET_FOUNDED_HILL_CITY_NO_DISTRICT', 'EUROPA_REQ_CITY_FOUNDED_BY_OWNER'),
	('EUROPA_REQSET_FOUNDED_HILL_CITY_NO_DISTRICT', 'EUROPA_REQ_CITY_HAS_NO_SPECIALTY_DISTRICT');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- Cities you founded on Hills: +1 Production.
	('EUROPA_ETHIOPIA_HILL_CITY_PRODUCTION',     'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE',            'EUROPA_REQSET_FOUNDED_HILL_CITY'),
	-- ... and +10% Production toward Settlers.
	('EUROPA_ETHIOPIA_HILL_CITY_SETTLERS',       'EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_UNIT_PRODUCTION',       'EUROPA_REQSET_FOUNDED_HILL_CITY'),
	-- ... and +25% Production toward districts until the first specialty district is finished.
	('EUROPA_ETHIOPIA_HILL_CITY_FIRST_DISTRICT', 'MODIFIER_PLAYER_CITIES_ADJUST_DISTRICT_PRODUCTION_MODIFIER', 'EUROPA_REQSET_FOUNDED_HILL_CITY_NO_DISTRICT');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_ETHIOPIA_HILL_CITY_PRODUCTION',     'YieldType', 'YIELD_PRODUCTION'),
	('EUROPA_ETHIOPIA_HILL_CITY_PRODUCTION',     'Amount',    '1'),
	('EUROPA_ETHIOPIA_HILL_CITY_SETTLERS',       'UnitType',  'UNIT_SETTLER'),
	('EUROPA_ETHIOPIA_HILL_CITY_SETTLERS',       'Amount',    '10'),
	('EUROPA_ETHIOPIA_HILL_CITY_FIRST_DISTRICT', 'Amount',    '25');

INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE', 'EUROPA_ETHIOPIA_HILL_CITY_PRODUCTION'),
	('TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE', 'EUROPA_ETHIOPIA_HILL_CITY_SETTLERS'),
	('TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE', 'EUROPA_ETHIOPIA_HILL_CITY_FIRST_DISTRICT');
