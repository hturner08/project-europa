-- Project Europa: custom leaders, front-end (game setup) rows.
-- Runs against the Configuration database, not the gameplay one.
--
-- Each leader copies its civilization columns and unique-item list from the
-- stock leader it stands beside, so whatever names and descriptions the loaded
-- ruleset (stock or BBG) shows for the civilization are shown here too. If that
-- stock leader is absent (DLC not owned) the SELECT matches nothing and the
-- leader simply is not offered.
--
-- Gathering Storm ruleset only: Preserves, Mali and the trade-route rules the
-- abilities lean on all need it.

-- Mali: Golden Expansion (beside Mansa Musa)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_GOLDEN_EXPANSION', 'LOC_LEADER_EUROPA_GOLDEN_EXPANSION_NAME', 'ICON_LEADER_EUROPA_GOLDEN_EXPANSION',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION_NAME', 'LOC_TRAIT_LEADER_EUROPA_GOLDEN_EXPANSION_DESCRIPTION', 'ICON_LEADER_EUROPA_GOLDEN_EXPANSION',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_MANSA_MUSA_NEUTRAL', 'LEADER_MANSA_MUSA_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_MANSA_MUSA' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_GOLDEN_EXPANSION', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_MANSA_MUSA' AND Domain = 'Players:Expansion2_Players';

-- China: Imperial Gardens (beside Qin)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_IMPERIAL_GARDENS', 'LOC_LEADER_EUROPA_IMPERIAL_GARDENS_NAME', 'ICON_LEADER_EUROPA_IMPERIAL_GARDENS',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_IMPERIAL_GARDENS_NAME', 'LOC_TRAIT_LEADER_EUROPA_IMPERIAL_GARDENS_DESCRIPTION', 'ICON_LEADER_EUROPA_IMPERIAL_GARDENS',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_QIN_NEUTRAL', 'LEADER_QIN_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_QIN' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_IMPERIAL_GARDENS', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_QIN' AND Domain = 'Players:Expansion2_Players';

-- Ethiopia: Highland Empire (beside Menelik)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_HIGHLAND_EMPIRE', 'LOC_LEADER_EUROPA_HIGHLAND_EMPIRE_NAME', 'ICON_LEADER_EUROPA_HIGHLAND_EMPIRE',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE_NAME', 'LOC_TRAIT_LEADER_EUROPA_HIGHLAND_EMPIRE_DESCRIPTION', 'ICON_LEADER_EUROPA_HIGHLAND_EMPIRE',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_MENELIK_NEUTRAL', 'LEADER_MENELIK_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_MENELIK' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_HIGHLAND_EMPIRE', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_MENELIK' AND Domain = 'Players:Expansion2_Players';

-- Brazil: Living Paradise (beside Pedro)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_LIVING_PARADISE', 'LOC_LEADER_EUROPA_LIVING_PARADISE_NAME', 'ICON_LEADER_EUROPA_LIVING_PARADISE',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_LIVING_PARADISE_NAME', 'LOC_TRAIT_LEADER_EUROPA_LIVING_PARADISE_DESCRIPTION', 'ICON_LEADER_EUROPA_LIVING_PARADISE',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_PEDRO_NEUTRAL', 'LEADER_PEDRO_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_PEDRO' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_LIVING_PARADISE', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_PEDRO' AND Domain = 'Players:Expansion2_Players';

-- Cree: The Borderless Empire (beside Poundmaker)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_BORDERLESS_EMPIRE', 'LOC_LEADER_EUROPA_BORDERLESS_EMPIRE_NAME', 'ICON_LEADER_EUROPA_BORDERLESS_EMPIRE',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE_NAME', 'LOC_TRAIT_LEADER_EUROPA_BORDERLESS_EMPIRE_DESCRIPTION', 'ICON_LEADER_EUROPA_BORDERLESS_EMPIRE',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_POUNDMAKER_NEUTRAL', 'LEADER_POUNDMAKER_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_POUNDMAKER' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_BORDERLESS_EMPIRE', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_POUNDMAKER' AND Domain = 'Players:Expansion2_Players';

-- Russia: The Endless Continent (beside Peter)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_ENDLESS_CONTINENT', 'LOC_LEADER_EUROPA_ENDLESS_CONTINENT_NAME', 'ICON_LEADER_EUROPA_ENDLESS_CONTINENT',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_ENDLESS_CONTINENT_NAME', 'LOC_TRAIT_LEADER_EUROPA_ENDLESS_CONTINENT_DESCRIPTION', 'ICON_LEADER_EUROPA_ENDLESS_CONTINENT',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_PETER_GREAT_NEUTRAL', 'LEADER_PETER_GREAT_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_PETER_GREAT' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_ENDLESS_CONTINENT', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_PETER_GREAT' AND Domain = 'Players:Expansion2_Players';

-- America: The Scenic Genius (beside Teddy Roosevelt)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_SCENIC_GENIUS', 'LOC_LEADER_EUROPA_SCENIC_GENIUS_NAME', 'ICON_LEADER_EUROPA_SCENIC_GENIUS',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_SCENIC_GENIUS_NAME', 'LOC_TRAIT_LEADER_EUROPA_SCENIC_GENIUS_DESCRIPTION', 'ICON_LEADER_EUROPA_SCENIC_GENIUS',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_T_ROOSEVELT_NEUTRAL', 'LEADER_T_ROOSEVELT_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_T_ROOSEVELT' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_SCENIC_GENIUS', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_T_ROOSEVELT' AND Domain = 'Players:Expansion2_Players';

-- France: The Palace Designer (beside Catherine de Medici)
INSERT OR REPLACE INTO Players
	(Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
	 CivilizationName, CivilizationIcon,
	 LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 Portrait, PortraitBackground)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_PALACE_DESIGNER', 'LOC_LEADER_EUROPA_PALACE_DESIGNER_NAME', 'ICON_LEADER_EUROPA_PALACE_DESIGNER',
	 CivilizationName, CivilizationIcon,
	 'LOC_TRAIT_LEADER_EUROPA_PALACE_DESIGNER_NAME', 'LOC_TRAIT_LEADER_EUROPA_PALACE_DESIGNER_DESCRIPTION', 'ICON_LEADER_EUROPA_PALACE_DESIGNER',
	 CivilizationAbilityName, CivilizationAbilityDescription, CivilizationAbilityIcon,
	 'LEADER_CATHERINE_DE_MEDICI_NEUTRAL', 'LEADER_CATHERINE_DE_MEDICI_BACKGROUND'
FROM Players WHERE LeaderType = 'LEADER_CATHERINE_DE_MEDICI' AND Domain = 'Players:Expansion2_Players';

INSERT OR REPLACE INTO PlayerItems (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_EUROPA_PALACE_DESIGNER', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_CATHERINE_DE_MEDICI' AND Domain = 'Players:Expansion2_Players';
