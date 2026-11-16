-- Project Europa: the "Sacred Companions" pantheon.
-- Every Camp: +1 Production, +1 Faith.
--
-- Any Camp counts, whatever it is built over: the stock Camp resources (Deer, Furs,
-- Ivory, Truffles, Honey), our own animal luxuries, and anything another mod adds.
-- The only test is the improvement on the tile, so there is no resource list to keep
-- in step. Topaz (Mine) and Discus Fish (Fishing Boats) are not Camps and get nothing.
--
-- Same test as the stock Goddess of the Hunt, but attached to the pantheon's owner
-- instead of to cities following it, like the other Europa pantheons.

INSERT INTO Types (Type, Kind) VALUES
	('BELIEF_CUSTOM_SACRED_COMPANIONS', 'KIND_BELIEF');

INSERT INTO Beliefs (BeliefType, Name, Description, BeliefClassType) VALUES
	('BELIEF_CUSTOM_SACRED_COMPANIONS', 'LOC_BELIEF_CUSTOM_SACRED_COMPANIONS_NAME', 'LOC_BELIEF_CUSTOM_SACRED_COMPANIONS_DESCRIPTION', 'BELIEF_CLASS_PANTHEON');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('EUROPA_PANTHEON_REQ_PLOT_HAS_CAMP', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('EUROPA_PANTHEON_REQ_PLOT_HAS_CAMP', 'ImprovementType', 'IMPROVEMENT_CAMP');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('EUROPA_PANTHEON_REQSET_CAMP', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('EUROPA_PANTHEON_REQSET_CAMP', 'EUROPA_PANTHEON_REQ_PLOT_HAS_CAMP');

-- belief -> the player who holds the pantheon -> a yield on each of that player's matching tiles.
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('EUROPA_PANTHEON_SACRED_COMPANIONS_PRODUCTION',          'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_FAITH',               'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_PANTHEON_REQUIREMENTS'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_PRODUCTION_MODIFIER', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD',    'EUROPA_PANTHEON_REQSET_CAMP'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_FAITH_MODIFIER',      'MODIFIER_PLAYER_ADJUST_PLOT_YIELD',    'EUROPA_PANTHEON_REQSET_CAMP');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('EUROPA_PANTHEON_SACRED_COMPANIONS_PRODUCTION',          'ModifierId', 'EUROPA_PANTHEON_SACRED_COMPANIONS_PRODUCTION_MODIFIER'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_FAITH',               'ModifierId', 'EUROPA_PANTHEON_SACRED_COMPANIONS_FAITH_MODIFIER'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_PRODUCTION_MODIFIER', 'YieldType',  'YIELD_PRODUCTION'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_PRODUCTION_MODIFIER', 'Amount',     '1'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_FAITH_MODIFIER',      'YieldType',  'YIELD_FAITH'),
	('EUROPA_PANTHEON_SACRED_COMPANIONS_FAITH_MODIFIER',      'Amount',     '1');

INSERT INTO BeliefModifiers (BeliefType, ModifierID) VALUES
	('BELIEF_CUSTOM_SACRED_COMPANIONS', 'EUROPA_PANTHEON_SACRED_COMPANIONS_PRODUCTION'),
	('BELIEF_CUSTOM_SACRED_COMPANIONS', 'EUROPA_PANTHEON_SACRED_COMPANIONS_FAITH');
