-- Project Europa: city-states, Better Balanced Game compatibility. Does nothing without BBG.
--
-- BBG replaces "per city-state you are Suzerain of" bonuses (Pericles' Culture, the Huszar's
-- and the Varangian longship's Combat Strength) with one hand-written modifier per stock
-- city-state. A new city-state would not count toward any of them, so this copies every
-- such row BBG made for Fez under our city-states' names. It keys on the leader name inside
-- the ids, so it follows whatever BBG adds later; with BBG absent the SELECTs match nothing.
-- Kept in its own file so that a BBG change that breaks it cannot take a city-state with it.

INSERT OR IGNORE INTO Requirements (RequirementId, RequirementType, Inverse)
	SELECT replace(r.RequirementId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), r.RequirementType, r.Inverse
	FROM Requirements r, Leaders l
	WHERE r.RequirementId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

INSERT OR IGNORE INTO RequirementArguments (RequirementId, Name, Value)
	SELECT replace(a.RequirementId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), a.Name, replace(a.Value, 'LEADER_MINOR_CIV_FEZ', l.LeaderType)
	FROM RequirementArguments a, Leaders l
	WHERE a.RequirementId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

INSERT OR IGNORE INTO RequirementSets (RequirementSetId, RequirementSetType)
	SELECT replace(s.RequirementSetId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), s.RequirementSetType
	FROM RequirementSets s, Leaders l
	WHERE s.RequirementSetId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
	SELECT replace(s.RequirementSetId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), replace(s.RequirementId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType)
	FROM RequirementSetRequirements s, Leaders l
	WHERE s.RequirementSetId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

INSERT OR IGNORE INTO Modifiers (ModifierId, ModifierType, RunOnce, NewOnly, Permanent, Repeatable, OwnerRequirementSetId, SubjectRequirementSetId)
	SELECT replace(m.ModifierId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), m.ModifierType, m.RunOnce, m.NewOnly, m.Permanent, m.Repeatable,
		replace(m.OwnerRequirementSetId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), replace(m.SubjectRequirementSetId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType)
	FROM Modifiers m, Leaders l
	WHERE m.ModifierId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

INSERT OR IGNORE INTO ModifierArguments (ModifierId, Name, Value)
	SELECT replace(a.ModifierId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), a.Name, a.Value
	FROM ModifierArguments a, Leaders l
	WHERE a.ModifierId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

-- The preview line names the city-state: "+2 ... Fez" becomes "+2 ... Syracuse".
INSERT OR IGNORE INTO ModifierStrings (ModifierId, Context, Text)
	SELECT replace(s.ModifierId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType), s.Context,
		replace(s.Text, 'LOC_CIVILIZATION_FEZ_NAME', 'LOC_CIVILIZATION_' || substr(l.LeaderType, 18) || '_NAME')
	FROM ModifierStrings s, Leaders l
	WHERE s.ModifierId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId)
	SELECT t.TraitType, replace(t.ModifierId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType)
	FROM TraitModifiers t, Leaders l
	WHERE t.ModifierId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';

INSERT OR IGNORE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
	SELECT u.UnitAbilityType, replace(u.ModifierId, 'LEADER_MINOR_CIV_FEZ', l.LeaderType)
	FROM UnitAbilityModifiers u, Leaders l
	WHERE u.ModifierId LIKE '%LEADER\_MINOR\_CIV\_FEZ%' ESCAPE '\' AND l.LeaderType LIKE 'LEADER\_MINOR\_CIV\_EUROPA\_%' ESCAPE '\';
