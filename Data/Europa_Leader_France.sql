-- Project Europa: France, "The Palace Designer" (ability: Gardens of Versailles).
-- Replaces the leader ability only; Grand Tour, the Chateau and the Garde
-- Imperiale are whatever the loaded ruleset (stock or BBG) defines.
-- Art, agenda and favoured religion are borrowed from Catherine de Medici
-- (Black Queen), which is also why Sex is 'Female': it matches the borrowed model.

INSERT INTO Types (Type, Kind) VALUES
	('LEADER_EUROPA_PALACE_DESIGNER',       'KIND_LEADER'),
	('TRAIT_LEADER_EUROPA_PALACE_DESIGNER', 'KIND_TRAIT');

INSERT INTO Leaders (LeaderType, Name, InheritFrom, SceneLayers, Sex) VALUES
	('LEADER_EUROPA_PALACE_DESIGNER', 'LOC_LEADER_EUROPA_PALACE_DESIGNER_NAME', 'LEADER_DEFAULT', 4, 'Female');

INSERT INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName)
	SELECT 'LEADER_EUROPA_PALACE_DESIGNER', CivilizationType, CapitalName
	FROM CivilizationLeaders WHERE LeaderType = 'LEADER_CATHERINE_DE_MEDICI';

INSERT INTO Traits (TraitType, Name, Description) VALUES
	('TRAIT_LEADER_EUROPA_PALACE_DESIGNER', 'LOC_TRAIT_LEADER_EUROPA_PALACE_DESIGNER_NAME', 'LOC_TRAIT_LEADER_EUROPA_PALACE_DESIGNER_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
	('LEADER_EUROPA_PALACE_DESIGNER', 'TRAIT_LEADER_EUROPA_PALACE_DESIGNER');

INSERT INTO HistoricalAgendas (LeaderType, AgendaType)
	SELECT 'LEADER_EUROPA_PALACE_DESIGNER', AgendaType FROM HistoricalAgendas WHERE LeaderType = 'LEADER_CATHERINE_DE_MEDICI';

INSERT INTO FavoredReligions (LeaderType, ReligionType)
	SELECT 'LEADER_EUROPA_PALACE_DESIGNER', ReligionType FROM FavoredReligions WHERE LeaderType = 'LEADER_CATHERINE_DE_MEDICI';

INSERT INTO LoadingInfo (LeaderType, ForegroundImage, BackgroundImage, LeaderText, PlayDawnOfManAudio) VALUES
	('LEADER_EUROPA_PALACE_DESIGNER', 'LEADER_CATHERINE_DE_MEDICI_NEUTRAL', 'LEADER_CATHERINE_DE_MEDICI_BACKGROUND', 'LOC_LOADING_INFO_LEADER_EUROPA_PALACE_DESIGNER', 0);

-- ---------------------------------------------------------------------------
-- Ability
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_REQ_CITY_HAS_CHATEAU',             'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
	('EUROPA_REQ_WONDER_SITE_BY_CHATEAU',       'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
	('EUROPA_REQ_PLOT_IS_CHATEAU',              'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES'),
	('EUROPA_REQ_CHATEAU_NEXT_TO_WONDER',       'REQUIREMENT_PLOT_ADJACENT_TO_WONDER'),
	('EUROPA_REQ_CHATEAU_NEXT_TO_PRESERVE',     'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'),
	('EUROPA_REQ_CHATEAU_BY_WONDER_OR_PRESERVE','REQUIREMENT_REQUIREMENTSET_IS_MET');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	-- Both properties are written to the city-centre plot by Scripts/Europa_Leaders.lua.
	-- EUROPA_CHATEAU_COMPLEX: 1 while one of the city's Chateaux touches a finished
	-- Wonder or a Preserve.
	('EUROPA_REQ_CITY_HAS_CHATEAU',              'PropertyName',     'EUROPA_CHATEAU_COMPLEX'),
	('EUROPA_REQ_CITY_HAS_CHATEAU',              'PropertyMinimum',  '1'),
	-- EUROPA_CHATEAU_WONDER: 1 while the Wonder that city is building touches a Chateau.
	('EUROPA_REQ_WONDER_SITE_BY_CHATEAU',        'PropertyName',     'EUROPA_CHATEAU_WONDER'),
	('EUROPA_REQ_WONDER_SITE_BY_CHATEAU',        'PropertyMinimum',  '1'),
	('EUROPA_REQ_PLOT_IS_CHATEAU',               'ImprovementType',  'IMPROVEMENT_CHATEAU'),
	('EUROPA_REQ_CHATEAU_NEXT_TO_PRESERVE',      'DistrictType',     'DISTRICT_PRESERVE'),
	('EUROPA_REQ_CHATEAU_BY_WONDER_OR_PRESERVE', 'RequirementSetId', 'EUROPA_REQSET_NEXT_TO_WONDER_OR_PRESERVE');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_CITY_HAS_CHATEAU',            'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_WONDER_SITE_BY_CHATEAU',      'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_REQSET_NEXT_TO_WONDER_OR_PRESERVE',  'REQUIREMENTSET_TEST_ANY'),
	('EUROPA_REQSET_CHATEAU_BY_WONDER_OR_PRESERVE','REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_CITY_HAS_CHATEAU',             'EUROPA_REQ_CITY_HAS_CHATEAU'),
	('EUROPA_REQSET_WONDER_SITE_BY_CHATEAU',       'EUROPA_REQ_WONDER_SITE_BY_CHATEAU'),
	('EUROPA_REQSET_NEXT_TO_WONDER_OR_PRESERVE',   'EUROPA_REQ_CHATEAU_NEXT_TO_WONDER'),
	('EUROPA_REQSET_NEXT_TO_WONDER_OR_PRESERVE',   'EUROPA_REQ_CHATEAU_NEXT_TO_PRESERVE'),
	('EUROPA_REQSET_CHATEAU_BY_WONDER_OR_PRESERVE','EUROPA_REQ_PLOT_IS_CHATEAU'),
	('EUROPA_REQSET_CHATEAU_BY_WONDER_OR_PRESERVE','EUROPA_REQ_CHATEAU_BY_WONDER_OR_PRESERVE');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- Chateaux raise Appeal. An improvement's Appeal is one number shared by every
	-- French leader and the engine has no per-tile Appeal modifier, so this is +1
	-- Appeal on every tile of a city where a Chateau touches a Wonder or a Preserve.
	-- (A bare "city owns a Chateau" test made it too cheap: one Builder charge per city.)
	('EUROPA_FRANCE_CHATEAU_CITY_APPEAL',       'MODIFIER_PLAYER_CITIES_ADJUST_CITY_APPEAL',       'EUROPA_REQSET_CITY_HAS_CHATEAU'),
	-- Chateaux next to a Wonder or a Preserve: +1 Production (once, not per neighbour).
	('EUROPA_FRANCE_CHATEAU_PRODUCTION',        'MODIFIER_PLAYER_ADJUST_PLOT_YIELD',               'EUROPA_REQSET_CHATEAU_BY_WONDER_OR_PRESERVE'),
	-- +10% Wonder Production while the Wonder under construction touches a Chateau.
	('EUROPA_FRANCE_CHATEAU_WONDER_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_WONDER_PRODUCTION', 'EUROPA_REQSET_WONDER_SITE_BY_CHATEAU');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_FRANCE_CHATEAU_CITY_APPEAL',       'Amount',    '1'),
	('EUROPA_FRANCE_CHATEAU_PRODUCTION',        'YieldType', 'YIELD_PRODUCTION'),
	('EUROPA_FRANCE_CHATEAU_PRODUCTION',        'Amount',    '1'),
	('EUROPA_FRANCE_CHATEAU_WONDER_PRODUCTION', 'Amount',    '10');

INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_LEADER_EUROPA_PALACE_DESIGNER', 'EUROPA_FRANCE_CHATEAU_CITY_APPEAL'),
	('TRAIT_LEADER_EUROPA_PALACE_DESIGNER', 'EUROPA_FRANCE_CHATEAU_PRODUCTION'),
	('TRAIT_LEADER_EUROPA_PALACE_DESIGNER', 'EUROPA_FRANCE_CHATEAU_WONDER_PRODUCTION');
