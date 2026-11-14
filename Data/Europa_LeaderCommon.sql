-- Project Europa: custom leaders, shared rows.
-- Loaded before the per-leader files (it is listed first in the modinfo action).
--
-- Each leader lives in its own file so that a missing DLC civilization only
-- drops that one leader: Civ 6 rolls back a whole file on the first bad row.
--
-- Everything here uses our own ids (EUROPA_*) and base-game requirement and
-- effect types, so the leaders load with or without Better Balanced Game.

-- Modifier types that only exist in DLC packs or are not instanced by the base
-- game, redefined under our own names so we do not depend on those packs.
INSERT OR IGNORE INTO Types (Type, Kind) VALUES
	('EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_UNIT_PRODUCTION', 'KIND_MODIFIER'),
	('EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_FOR_DOMESTIC', 'KIND_MODIFIER');

INSERT OR IGNORE INTO DynamicModifiers (ModifierType, CollectionType, EffectType) VALUES
	('EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_UNIT_PRODUCTION', 'COLLECTION_PLAYER_CITIES', 'EFFECT_ADJUST_UNIT_PRODUCTION'),
	('EUROPA_MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_FOR_DOMESTIC', 'COLLECTION_PLAYER_CITIES', 'EFFECT_ADJUST_CITY_TRADE_ROUTE_YIELD_FOR_DOMESTIC');

-- Requirements used by more than one leader.
INSERT OR IGNORE INTO Requirements (RequirementId, RequirementType, Inverse) VALUES
	('EUROPA_REQ_CITY_HAS_ANY_WONDER',      'REQUIREMENT_CITY_HAS_ANY_WONDER',       0),
	('EUROPA_REQ_PLOT_HAS_NO_IMPROVEMENT',  'REQUIREMENT_PLOT_HAS_ANY_IMPROVEMENT',  1);

INSERT OR IGNORE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_REQSET_CITY_HAS_ANY_WONDER', 'REQUIREMENTSET_TEST_ALL');

INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_REQSET_CITY_HAS_ANY_WONDER', 'EUROPA_REQ_CITY_HAS_ANY_WONDER');
