-- Project Europa: city-states, shared rows.
-- Loaded before the per-city-state files (it is listed first in the modinfo action).
--
-- Each city-state lives in its own file: Civ 6 rolls back a whole file on the
-- first bad row, so one mistake then only drops one city-state.
--
-- How a Suzerain bonus is wired (the same way the stock city-states do it):
--   trait modifier   MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER, subjects = PLAYER_IS_SUZERAIN
--     -> attaches    an ordinary player modifier to whoever is Suzerain
-- The engine adds and removes the attached modifier as suzerainty changes.
--
-- Where a bonus needs counting (tiles round a district, Trade Routes from a city)
-- Scripts/Europa_CityStates.lua writes the number onto the district's plot or the
-- city-centre plot and a requirement here reads it back, one modifier per point.

-- 1..6: a hex has six neighbours, so no neighbour count can exceed 6.
CREATE TABLE IF NOT EXISTS Europa_Tiers (n INTEGER PRIMARY KEY);
INSERT OR IGNORE INTO Europa_Tiers (n) VALUES (1), (2), (3), (4), (5), (6);

-- Plot properties written by the script. One requirement per value that is tested.
--   on a district's own plot:
--     EUROPA_CS_WATERWORKS   Campus: adjacent completed Aqueducts and Dams           (Syracuse)
--     EUROPA_CS_WILD_TILES   Theater Square: adjacent unimproved Woods/Rainforest, max 2 (Ubud)
--     EUROPA_CS_STEELWORKS   Industrial Zone: 1 with three adjacent Mines/Quarries   (Sheffield)
--     EUROPA_CS_MONASTERY    Holy Site: 1 with two adjacent Mountains                (Lhasa)
--     EUROPA_CS_HUB_THEATERS Commercial Hub: adjacent completed Theater Squares      (Bruges)
--     EUROPA_CS_THEATER_HUBS Theater Square: adjacent completed Commercial Hubs      (Bruges)
--   on a Mine or Quarry plot:
--     EUROPA_CS_STEEL_TILE   1 while it touches one of its owner's Industrial Zones  (Sheffield)
--   on the city-centre plot:
--     EUROPA_CS_MONASTERY_CITY 1 while the city's Holy Site has EUROPA_CS_MONASTERY  (Lhasa)
--     EUROPA_CS_ARSENAL      1 while a city with a Harbor and an Encampment is
--                            constructing a building of either district             (Ravenna)
--     EUROPA_CS_TRADE_CULTURE Trade Routes sent by a city with a Commercial Hub and
--                            a Theater Square, max 2                                 (Bruges)
INSERT OR IGNORE INTO Requirements (RequirementId, RequirementType)
	SELECT 'EUROPA_REQ_CS_' || p.Name || '_' || t.n, 'REQUIREMENT_PLOT_PROPERTY_MATCHES'
	FROM Europa_Tiers t,
		(SELECT 'WATERWORKS' AS Name, 6 AS Top UNION ALL SELECT 'WILD_TILES', 2 UNION ALL SELECT 'STEELWORKS', 1
		 UNION ALL SELECT 'MONASTERY', 1 UNION ALL SELECT 'HUB_THEATERS', 6 UNION ALL SELECT 'THEATER_HUBS', 6
		 UNION ALL SELECT 'STEEL_TILE', 1 UNION ALL SELECT 'MONASTERY_CITY', 1 UNION ALL SELECT 'ARSENAL', 1
		 UNION ALL SELECT 'TRADE_CULTURE', 2) p
	WHERE t.n <= p.Top;

INSERT OR IGNORE INTO RequirementArguments (RequirementId, Name, Value)
	SELECT RequirementId, 'PropertyName', 'EUROPA_CS_' || substr(RequirementId, 15, length(RequirementId) - 16)
	FROM Requirements WHERE RequirementId LIKE 'EUROPA_REQ_CS_%';
INSERT OR IGNORE INTO RequirementArguments (RequirementId, Name, Value)
	SELECT RequirementId, 'PropertyMinimum', substr(RequirementId, -1)
	FROM Requirements WHERE RequirementId LIKE 'EUROPA_REQ_CS_%';

-- One single-requirement set per requirement, same name with REQSET in place of REQ.
-- (Not for STEELWORKS: Sheffield only ever tests it together with "has a Workshop",
-- in a set of its own.)
INSERT OR IGNORE INTO RequirementSets (RequirementSetId, RequirementSetType)
	SELECT replace(RequirementId, 'EUROPA_REQ_CS_', 'EUROPA_REQSET_CS_'), 'REQUIREMENTSET_TEST_ALL'
	FROM Requirements WHERE RequirementId LIKE 'EUROPA_REQ_CS_%' AND RequirementId <> 'EUROPA_REQ_CS_STEELWORKS_1';
INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
	SELECT replace(RequirementId, 'EUROPA_REQ_CS_', 'EUROPA_REQSET_CS_'), RequirementId
	FROM Requirements WHERE RequirementId LIKE 'EUROPA_REQ_CS_%' AND RequirementId <> 'EUROPA_REQ_CS_STEELWORKS_1';
