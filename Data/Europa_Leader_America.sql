-- Project Europa: America, "The Scenic Genius" (ability: National Masterpieces).
-- Replaces the leader ability only; Founding Fathers, the Film Studio and the
-- P-51 Mustang are whatever the loaded ruleset (stock or BBG) defines.
-- Art, agenda and favoured religion are borrowed from Teddy Roosevelt (Bull Moose).

INSERT INTO Types (Type, Kind) VALUES
	('LEADER_EUROPA_SCENIC_GENIUS',       'KIND_LEADER'),
	('TRAIT_LEADER_EUROPA_SCENIC_GENIUS', 'KIND_TRAIT');

INSERT INTO Leaders (LeaderType, Name, InheritFrom, SceneLayers, Sex) VALUES
	('LEADER_EUROPA_SCENIC_GENIUS', 'LOC_LEADER_EUROPA_SCENIC_GENIUS_NAME', 'LEADER_DEFAULT', 4, 'Male');

INSERT INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName)
	SELECT 'LEADER_EUROPA_SCENIC_GENIUS', CivilizationType, CapitalName
	FROM CivilizationLeaders WHERE LeaderType = 'LEADER_T_ROOSEVELT';

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('TRAIT_LEADER_EUROPA_SCENIC_GENIUS', 'LOC_TRAIT_LEADER_EUROPA_SCENIC_GENIUS_NAME', 'LOC_TRAIT_LEADER_EUROPA_SCENIC_GENIUS_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_EUROPA_SCENIC_GENIUS', 'TRAIT_LEADER_EUROPA_SCENIC_GENIUS');

INSERT INTO HistoricalAgendas (LeaderType, AgendaType)
	SELECT 'LEADER_EUROPA_SCENIC_GENIUS', AgendaType FROM HistoricalAgendas WHERE LeaderType = 'LEADER_T_ROOSEVELT';

INSERT INTO FavoredReligions (LeaderType, ReligionType)
	SELECT 'LEADER_EUROPA_SCENIC_GENIUS', ReligionType FROM FavoredReligions WHERE LeaderType = 'LEADER_T_ROOSEVELT';

INSERT INTO LoadingInfo (LeaderType, ForegroundImage, BackgroundImage, LeaderText, PlayDawnOfManAudio) VALUES
	('LEADER_EUROPA_SCENIC_GENIUS', 'LEADER_T_ROOSEVELT_NEUTRAL', 'LEADER_T_ROOSEVELT_BACKGROUND', 'LOC_LOADING_INFO_LEADER_EUROPA_SCENIC_GENIUS', 0);

-- ---------------------------------------------------------------------------
-- Ability
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_WONDER_SITE_IS_SCENIC',   'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
	('EUROPA_REQ_PLOT_IS_BREATHTAKING',    'REQUIREMENT_PLOT_IS_APPEAL_BETWEEN'),
	('EUROPA_REQ_PLOT_NEXT_TO_WONDER',     'REQUIREMENT_PLOT_ADJACENT_TO_WONDER'),
	('EUROPA_REQ_CITY_HAS_NATIONAL_PARK',  'REQUIREMENT_CITY_HAS_NATIONAL_PARK');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	-- EUROPA_GARDEN_TILES is written to the city-centre plot by Scripts/Europa_Leaders.lua:
	-- the number of Breathtaking tiles next to the Wonder that city is building.
	('EUROPA_REQ_WONDER_SITE_IS_SCENIC', 'PropertyName',    'EUROPA_GARDEN_TILES'),
	('EUROPA_REQ_WONDER_SITE_IS_SCENIC', 'PropertyMinimum', '1'),
	('EUROPA_REQ_PLOT_IS_BREATHTAKING',  'MinimumAppeal',   '4');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_WONDER_SITE_IS_SCENIC',        'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_WILD_BREATHTAKING_BY_WONDER',  'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_CITY_HAS_NATIONAL_PARK',       'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_WONDER_SITE_IS_SCENIC',       'EUROPA_REQ_WONDER_SITE_IS_SCENIC'),
	('EUROPA_REQSET_WILD_BREATHTAKING_BY_WONDER', 'EUROPA_REQ_PLOT_IS_BREATHTAKING'),
	('EUROPA_REQSET_WILD_BREATHTAKING_BY_WONDER', 'EUROPA_REQ_PLOT_NEXT_TO_WONDER'),
	('EUROPA_REQSET_WILD_BREATHTAKING_BY_WONDER', 'EUROPA_REQ_PLOT_HAS_NO_IMPROVEMENT'),
	('EUROPA_REQSET_CITY_HAS_NATIONAL_PARK',      'EUROPA_REQ_CITY_HAS_NATIONAL_PARK');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- +30% Production toward Preserves.
	('EUROPA_AMERICA_PRESERVE_PRODUCTION',      'MODIFIER_PLAYER_CITIES_ADJUST_DISTRICT_PRODUCTION', NULL),
	-- +10% Wonder Production while the Wonder under construction touches a Breathtaking tile.
	('EUROPA_AMERICA_SCENIC_WONDER_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_WONDER_PRODUCTION',   'EUROPA_REQSET_WONDER_SITE_IS_SCENIC'),
	-- Unimproved Breathtaking tiles next to a Wonder: +1 Culture.
	('EUROPA_AMERICA_WONDER_VIEW_CULTURE',      'MODIFIER_PLAYER_ADJUST_PLOT_YIELD',                 'EUROPA_REQSET_WILD_BREATHTAKING_BY_WONDER'),
	-- A city with a National Park: +1 Appeal on all its tiles (the stock Roosevelt effect).
	('EUROPA_AMERICA_NATIONAL_PARK_APPEAL',     'MODIFIER_PLAYER_CITIES_ADJUST_CITY_APPEAL',         'EUROPA_REQSET_CITY_HAS_NATIONAL_PARK');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_AMERICA_PRESERVE_PRODUCTION',      'DistrictType', 'DISTRICT_PRESERVE'),
	('EUROPA_AMERICA_PRESERVE_PRODUCTION',      'Amount',       '30'),
	('EUROPA_AMERICA_SCENIC_WONDER_PRODUCTION', 'Amount',       '10'),
	('EUROPA_AMERICA_WONDER_VIEW_CULTURE',      'YieldType',    'YIELD_CULTURE'),
	('EUROPA_AMERICA_WONDER_VIEW_CULTURE',      'Amount',       '1'),
	('EUROPA_AMERICA_NATIONAL_PARK_APPEAL',     'Amount',       '1');

INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_LEADER_EUROPA_SCENIC_GENIUS', 'EUROPA_AMERICA_PRESERVE_PRODUCTION'),
	('TRAIT_LEADER_EUROPA_SCENIC_GENIUS', 'EUROPA_AMERICA_SCENIC_WONDER_PRODUCTION'),
	('TRAIT_LEADER_EUROPA_SCENIC_GENIUS', 'EUROPA_AMERICA_WONDER_VIEW_CULTURE'),
	('TRAIT_LEADER_EUROPA_SCENIC_GENIUS', 'EUROPA_AMERICA_NATIONAL_PARK_APPEAL');
