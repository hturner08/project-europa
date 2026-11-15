-- Project Europa: Wonders on great lakes
--
-- These Wonders are placed on a water tile next to land, and the stock rules add
-- "but not on a lake". On a Pangaea map that leaves them to whoever holds the
-- outer coast. With great lakes (Maps/Europa_LakeGrowth.lua) there are lake
-- Harbors to put them beside, so the lake ban is lifted for these four. Every
-- other requirement (next to land, next to a Harbor, and so on) is unchanged.
--
-- Deliberately left banned:
--   Statue of Liberty   gives Diplomatic Victory Points; see AGENTS.md rule 3
--   Venetian Arsenal    naval units only
--   Golden Gate Bridge  a crossing between two land tiles
--
-- Wonders from DLC that is not loaded simply match no row.
UPDATE Buildings SET MustNotBeLake = 0
WHERE BuildingType IN ('BUILDING_COLOSSUS', 'BUILDING_GREAT_LIGHTHOUSE',
                       'BUILDING_SYDNEY_OPERA_HOUSE', 'BUILDING_TORRE_DE_BELEM');
