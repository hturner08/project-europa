-- Project Europa: custom pantheons that need only the stock game.
-- (Sacred Companions depends on our luxury resources and lives in its own file,
-- Europa_Pantheon_SacredCompanions.sql, so a problem there cannot drop these five.)
--
-- Additions only: no stock or Better Balanced Game belief is touched. The beliefs use
-- BELIEF_CUSTOM_* ids; in particular "Divine Inspiration" is BELIEF_CUSTOM_ARTISTIC_INSPIRATION
-- and is unrelated to the stock Follower belief BELIEF_DIVINE_INSPIRATION.
--
-- Every effect follows the same shape as the stock God of the Forge:
--   belief -> MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER, limited to the player who holds the
--   pantheon (PLAYER_HAS_PANTHEON_REQUIREMENTS) -> a player-owned modifier.
-- So the bonus belongs to the pantheon's owner and does not depend on which religion
-- or pantheon an individual city follows.
--
-- Two facts come from Scripts/Europa_Pantheons.lua, which writes them onto plots as
-- properties because no stock requirement can establish them:
--   EUROPA_PANTHEON_PRESERVE_TILE  the tile touches a working Preserve of the same player
--   EUROPA_PANTHEON_WONDER_CITY    the city owns a completed World Wonder (one under
--                                  construction does not count)
-- Everything else is tested here and reacts at once. The Builder charge is granted by
-- the engine, not the script, so it cannot be applied twice on load.
--
-- Load order: after the expansions, before the "Spare Beliefs" mod (1000005), which
-- copies every belief so both players can take the same one.

INSERT INTO Types (Type, Kind) VALUES
	('BELIEF_CUSTOM_FIRST_SETTLERS',       'KIND_BELIEF'),
	('BELIEF_CUSTOM_NEW_REALM_GUILDS',     'KIND_BELIEF'),
	('BELIEF_CUSTOM_SACRED_WILDERNESS',    'KIND_BELIEF'),
	('BELIEF_CUSTOM_ARTISTIC_INSPIRATION', 'KIND_BELIEF'),
	('BELIEF_CUSTOM_PILLARS_OF_CREATION',  'KIND_BELIEF');

INSERT INTO Beliefs (BeliefType, Name, Description, BeliefClassType) VALUES
	('BELIEF_CUSTOM_FIRST_SETTLERS',       'LOC_BELIEF_CUSTOM_FIRST_SETTLERS_NAME',       'LOC_BELIEF_CUSTOM_FIRST_SETTLERS_DESCRIPTION',       'BELIEF_CLASS_PANTHEON'),
	('BELIEF_CUSTOM_NEW_REALM_GUILDS',     'LOC_BELIEF_CUSTOM_NEW_REALM_GUILDS_NAME',     'LOC_BELIEF_CUSTOM_NEW_REALM_GUILDS_DESCRIPTION',     'BELIEF_CLASS_PANTHEON'),
	('BELIEF_CUSTOM_SACRED_WILDERNESS',    'LOC_BELIEF_CUSTOM_SACRED_WILDERNESS_NAME',    'LOC_BELIEF_CUSTOM_SACRED_WILDERNESS_DESCRIPTION',    'BELIEF_CLASS_PANTHEON'),
	('BELIEF_CUSTOM_ARTISTIC_INSPIRATION', 'LOC_BELIEF_CUSTOM_ARTISTIC_INSPIRATION_NAME', 'LOC_BELIEF_CUSTOM_ARTISTIC_INSPIRATION_DESCRIPTION', 'BELIEF_CLASS_PANTHEON'),
	('BELIEF_CUSTOM_PILLARS_OF_CREATION',  'LOC_BELIEF_CUSTOM_PILLARS_OF_CREATION_NAME',  'LOC_BELIEF_CUSTOM_PILLARS_OF_CREATION_DESCRIPTION',  'BELIEF_CLASS_PANTHEON');

-- ---------------------------------------------------------------------------
-- Requirements
-- ---------------------------------------------------------------------------

INSERT INTO Requirements (RequirementId, RequirementType, Inverse) VALUES
	('EUROPA_PANTHEON_REQ_CITY_FOUNDED_BY_OWNER',  'REQUIREMENT_CITY_IS_ORIGINAL_OWNER',             0),
	-- "at least 4 Population", inverted: 1 to 3.
	('EUROPA_PANTHEON_REQ_CITY_POP_UNDER_4',       'REQUIREMENT_CITY_HAS_X_POPULATION',              1),
	('EUROPA_PANTHEON_REQ_CITY_HAS_MARKET',        'REQUIREMENT_CITY_HAS_BUILDING',                  0),
	('EUROPA_PANTHEON_REQ_CITY_HAS_ART_MUSEUM',    'REQUIREMENT_CITY_HAS_BUILDING',                  0),
	-- Set by the script on the city-centre plot, which is the plot a city requirement tests.
	('EUROPA_PANTHEON_REQ_CITY_HAS_WONDER',        'REQUIREMENT_PLOT_PROPERTY_MATCHES',              0),
	('EUROPA_PANTHEON_REQ_PLOT_NO_IMPROVEMENT',    'REQUIREMENT_PLOT_HAS_ANY_IMPROVEMENT',           1),
	-- Districts, Wonders and the City Centre are all districts to the engine.
	('EUROPA_PANTHEON_REQ_PLOT_NO_DISTRICT',       'REQUIREMENT_PLOT_HAS_ANY_DISTRICT',              1),
	-- Set by the script: completed, unpillaged, and the same player's.
	('EUROPA_PANTHEON_REQ_PLOT_NEXT_TO_PRESERVE',  'REQUIREMENT_PLOT_PROPERTY_MATCHES',              0),
	('EUROPA_PANTHEON_REQ_HAS_MEDIEVAL_FAIRES',    'REQUIREMENT_PLAYER_HAS_CIVIC',                   0);

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_PANTHEON_REQ_CITY_POP_UNDER_4',      'Amount',            '4'),
	('EUROPA_PANTHEON_REQ_CITY_HAS_MARKET',       'BuildingType',      'BUILDING_MARKET'),
	('EUROPA_PANTHEON_REQ_CITY_HAS_MARKET',       'MustBeFunctioning', '1'),
	('EUROPA_PANTHEON_REQ_CITY_HAS_ART_MUSEUM',   'BuildingType',      'BUILDING_MUSEUM_ART'),
	('EUROPA_PANTHEON_REQ_CITY_HAS_ART_MUSEUM',   'MustBeFunctioning', '1'),
	('EUROPA_PANTHEON_REQ_PLOT_NEXT_TO_PRESERVE', 'PropertyName',      'EUROPA_PANTHEON_PRESERVE_TILE'),
	('EUROPA_PANTHEON_REQ_PLOT_NEXT_TO_PRESERVE', 'PropertyMinimum',   '1'),
	('EUROPA_PANTHEON_REQ_CITY_HAS_WONDER',       'PropertyName',      'EUROPA_PANTHEON_WONDER_CITY'),
	('EUROPA_PANTHEON_REQ_CITY_HAS_WONDER',       'PropertyMinimum',   '1'),
	('EUROPA_PANTHEON_REQ_HAS_MEDIEVAL_FAIRES',   'CivicType',         'CIVIC_MEDIEVAL_FAIRES');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_PANTHEON_REQSET_YOUNG_FOUNDED_CITY',     'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_PANTHEON_REQSET_CITY_HAS_MARKET',        'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_PANTHEON_REQSET_CITY_HAS_WONDER',        'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_PANTHEON_REQSET_ART_MUSEUM_AND_WONDER',  'REQUIREMENTSET_TEST_ALL'),
	('EUROPA_PANTHEON_REQSET_WILD_TILE_BY_PRESERVE',  'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_PANTHEON_REQSET_YOUNG_FOUNDED_CITY',    'EUROPA_PANTHEON_REQ_CITY_FOUNDED_BY_OWNER'),
	('EUROPA_PANTHEON_REQSET_YOUNG_FOUNDED_CITY',    'EUROPA_PANTHEON_REQ_CITY_POP_UNDER_4'),
	('EUROPA_PANTHEON_REQSET_CITY_HAS_MARKET',       'EUROPA_PANTHEON_REQ_CITY_HAS_MARKET'),
	('EUROPA_PANTHEON_REQSET_CITY_HAS_WONDER',       'EUROPA_PANTHEON_REQ_CITY_HAS_WONDER'),
	('EUROPA_PANTHEON_REQSET_ART_MUSEUM_AND_WONDER', 'EUROPA_PANTHEON_REQ_CITY_HAS_ART_MUSEUM'),
	('EUROPA_PANTHEON_REQSET_ART_MUSEUM_AND_WONDER', 'EUROPA_PANTHEON_REQ_CITY_HAS_WONDER'),
	-- REQUIRES_PLOT_BREATHTAKING_APPEAL is the stock requirement (Appeal 4 or more), reused
	-- so "Breathtaking" here always means what the loaded ruleset says it means.
	('EUROPA_PANTHEON_REQSET_WILD_TILE_BY_PRESERVE', 'REQUIRES_PLOT_BREATHTAKING_APPEAL'),
	('EUROPA_PANTHEON_REQSET_WILD_TILE_BY_PRESERVE', 'EUROPA_PANTHEON_REQ_PLOT_NO_IMPROVEMENT'),
	('EUROPA_PANTHEON_REQSET_WILD_TILE_BY_PRESERVE', 'EUROPA_PANTHEON_REQ_PLOT_NO_DISTRICT'),
	('EUROPA_PANTHEON_REQSET_WILD_TILE_BY_PRESERVE', 'EUROPA_PANTHEON_REQ_PLOT_NEXT_TO_PRESERVE'),
	('EUROPA_PANTHEON_REQSET_WILD_TILE_BY_PRESERVE', 'EUROPA_PANTHEON_REQ_HAS_MEDIEVAL_FAIRES');

-- ---------------------------------------------------------------------------
-- Modifiers
-- ---------------------------------------------------------------------------

-- Belief level: hand the effect to whoever holds the pantheon.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_PANTHEON_FIRST_SETTLERS_FOOD',        'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS'),
	('EUROPA_PANTHEON_FIRST_SETTLERS_PRODUCTION',  'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS'),
	('EUROPA_PANTHEON_NEW_REALM_GUILDS',           'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS'),
	('EUROPA_PANTHEON_SACRED_WILDERNESS',          'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS'),
	('EUROPA_PANTHEON_ARTISTIC_INSPIRATION',       'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS'),
	('EUROPA_PANTHEON_PILLARS_OF_CREATION',        'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS');

-- Player level.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	-- 1. Hearths of the First Settlers: city yield (not a tile yield) while a founded city has 1-3 Population.
	('EUROPA_PANTHEON_FIRST_SETTLERS_FOOD_MODIFIER',       'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE',   'EUROPA_PANTHEON_REQSET_YOUNG_FOUNDED_CITY'),
	('EUROPA_PANTHEON_FIRST_SETTLERS_PRODUCTION_MODIFIER', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE',   'EUROPA_PANTHEON_REQSET_YOUNG_FOUNDED_CITY'),
	-- 3. Guilds of the New Realm: each city with a working Market gets the Builder-charge modifier below.
	('EUROPA_PANTHEON_NEW_REALM_GUILDS_CITY',              'MODIFIER_PLAYER_CITIES_ATTACH_MODIFIER',            'EUROPA_PANTHEON_REQSET_CITY_HAS_MARKET'),
	-- 4. Sacred Wilderness: a tile yield, so a tile can only ever get it once however many Preserves touch it.
	('EUROPA_PANTHEON_SACRED_WILDERNESS_MODIFIER',         'MODIFIER_PLAYER_ADJUST_PLOT_YIELD',                 'EUROPA_PANTHEON_REQSET_WILD_TILE_BY_PRESERVE'),
	-- 5. Divine Inspiration: +1 Great Artist point per city with a working Art Museum and a Wonder.
	--    Same modifier type as Stockholm's per-building Great Person points.
	('EUROPA_PANTHEON_ARTISTIC_INSPIRATION_MODIFIER',      'MODIFIER_PLAYER_CITIES_ADJUST_GREAT_PERSON_POINT',  'EUROPA_PANTHEON_REQSET_ART_MUSEUM_AND_WONDER'),
	-- 6. Pillars of Creation: each city with a Wonder gets the Builder-charge modifier below.
	('EUROPA_PANTHEON_PILLARS_OF_CREATION_CITY',           'MODIFIER_PLAYER_CITIES_ATTACH_MODIFIER',            'EUROPA_PANTHEON_REQSET_CITY_HAS_WONDER');

-- City level: +1 charge for Builders this city trains or buys. This is exactly how Liang's
-- Guildmaster promotion is built (MODIFIER_SINGLE_CITY_BUILDER_CHARGES, Permanent), so the
-- charge is granted once when the unit is made, stays with the unit afterwards, and adds to
-- Liang, Serfdom, the Pyramids and the rest.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId, Permanent) VALUES
	('EUROPA_PANTHEON_NEW_REALM_GUILDS_BUILDER_CHARGE',    'MODIFIER_SINGLE_CITY_BUILDER_CHARGES', 'UNIT_IS_BUILDER', 1),
	('EUROPA_PANTHEON_PILLARS_OF_CREATION_BUILDER_CHARGE', 'MODIFIER_SINGLE_CITY_BUILDER_CHARGES', 'UNIT_IS_BUILDER', 1);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_PANTHEON_FIRST_SETTLERS_FOOD',                 'ModifierId', 'EUROPA_PANTHEON_FIRST_SETTLERS_FOOD_MODIFIER'),
	('EUROPA_PANTHEON_FIRST_SETTLERS_PRODUCTION',           'ModifierId', 'EUROPA_PANTHEON_FIRST_SETTLERS_PRODUCTION_MODIFIER'),
	('EUROPA_PANTHEON_NEW_REALM_GUILDS',                    'ModifierId', 'EUROPA_PANTHEON_NEW_REALM_GUILDS_CITY'),
	('EUROPA_PANTHEON_SACRED_WILDERNESS',                   'ModifierId', 'EUROPA_PANTHEON_SACRED_WILDERNESS_MODIFIER'),
	('EUROPA_PANTHEON_ARTISTIC_INSPIRATION',                'ModifierId', 'EUROPA_PANTHEON_ARTISTIC_INSPIRATION_MODIFIER'),
	('EUROPA_PANTHEON_PILLARS_OF_CREATION',                 'ModifierId', 'EUROPA_PANTHEON_PILLARS_OF_CREATION_CITY'),

	('EUROPA_PANTHEON_FIRST_SETTLERS_FOOD_MODIFIER',        'YieldType',  'YIELD_FOOD'),
	('EUROPA_PANTHEON_FIRST_SETTLERS_FOOD_MODIFIER',        'Amount',     '1'),
	('EUROPA_PANTHEON_FIRST_SETTLERS_PRODUCTION_MODIFIER',  'YieldType',  'YIELD_PRODUCTION'),
	('EUROPA_PANTHEON_FIRST_SETTLERS_PRODUCTION_MODIFIER',  'Amount',     '1'),

	('EUROPA_PANTHEON_NEW_REALM_GUILDS_CITY',               'ModifierId', 'EUROPA_PANTHEON_NEW_REALM_GUILDS_BUILDER_CHARGE'),
	('EUROPA_PANTHEON_NEW_REALM_GUILDS_BUILDER_CHARGE',     'Amount',     '1'),

	('EUROPA_PANTHEON_SACRED_WILDERNESS_MODIFIER',          'YieldType',  'YIELD_PRODUCTION'),
	('EUROPA_PANTHEON_SACRED_WILDERNESS_MODIFIER',          'Amount',     '1'),

	('EUROPA_PANTHEON_ARTISTIC_INSPIRATION_MODIFIER',       'GreatPersonClassType', 'GREAT_PERSON_CLASS_ARTIST'),
	('EUROPA_PANTHEON_ARTISTIC_INSPIRATION_MODIFIER',       'Amount',     '1'),

	('EUROPA_PANTHEON_PILLARS_OF_CREATION_CITY',            'ModifierId', 'EUROPA_PANTHEON_PILLARS_OF_CREATION_BUILDER_CHARGE'),
	('EUROPA_PANTHEON_PILLARS_OF_CREATION_BUILDER_CHARGE',  'Amount',     '1');

INSERT INTO BeliefModifiers (BeliefType, ModifierID) VALUES
	('BELIEF_CUSTOM_FIRST_SETTLERS',       'EUROPA_PANTHEON_FIRST_SETTLERS_FOOD'),
	('BELIEF_CUSTOM_FIRST_SETTLERS',       'EUROPA_PANTHEON_FIRST_SETTLERS_PRODUCTION'),
	('BELIEF_CUSTOM_NEW_REALM_GUILDS',     'EUROPA_PANTHEON_NEW_REALM_GUILDS'),
	('BELIEF_CUSTOM_SACRED_WILDERNESS',    'EUROPA_PANTHEON_SACRED_WILDERNESS'),
	('BELIEF_CUSTOM_ARTISTIC_INSPIRATION', 'EUROPA_PANTHEON_ARTISTIC_INSPIRATION'),
	('BELIEF_CUSTOM_PILLARS_OF_CREATION',  'EUROPA_PANTHEON_PILLARS_OF_CREATION');
