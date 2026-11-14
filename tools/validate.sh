#!/bin/bash
# Offline checks for the mod. Applies the gameplay SQL to a copy of the game's own
# cached database (written each time a game is started) with foreign keys on, so
# typos in type names fail here rather than silently disabling the mod in-game.
set -euo pipefail
cd "$(dirname "$0")/.."

CACHE="${CIV6_CACHE:-$HOME/Library/Application Support/Sid Meier's Civilization VI/Firaxis Games/Sid Meier's Civilization VI/Cache}"
# Two steps: bash 3.2 (macOS) mis-parses an odd number of apostrophes inside "${VAR:-...}".
GAME_ASSETS_DEFAULT="$HOME/Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization VI/Civ6.app/Contents/Assets"
GAME_ASSETS="${CIV6_ASSETS:-$GAME_ASSETS_DEFAULT}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0

echo "== XML well-formedness"
xmllint --noout ProjectEuropa.modinfo ProjectEuropa.dep ArtDefs/*.artdef Data/*.xml Text/*.xml

echo "== modinfo file references"
for f in $(grep -o '<File[^>]*>[^<]*</File>' ProjectEuropa.modinfo | sed 's/<[^>]*>//g' | sort -u); do
	[ -f "$f" ] || { echo "MISSING: $f"; fail=1; }
done
for f in Config/* Data/* Text/* Scripts/* Textures/* ArtDefs/* Maps/*.lua Maps/Utility/*.lua ProjectEuropa.dep; do
	grep -q ">$f<" ProjectEuropa.modinfo || { echo "NOT IN MODINFO: $f"; fail=1; }
done

echo "== icon atlases referenced by the icon database exist"
for f in $(grep -ho 'Filename="[^"]*"' Data/Europa_Icons.xml Data/Europa_CityStates_Icons.xml | cut -d'"' -f2 | sort -u); do
	[ -f "Textures/$f" ] || { echo "MISSING TEXTURE: $f"; fail=1; }
done

echo "== gameplay SQL against the game's cached database"
if [ ! -f "$CACHE/DebugGameplay.sqlite" ]; then
	echo "SKIPPED: no DebugGameplay.sqlite in $CACHE (start any game once to create it)"
else
	cp "$CACHE/DebugGameplay.sqlite" "$TMP/gp.sqlite"
	# Python rather than the sqlite3 CLI: the Types table has a trigger that calls
	# Make_Hash(), a function the game registers at runtime, so we must stub it.
	python3 - "$TMP/gp.sqlite" Data/*.sql <<'PY' || fail=1
import sqlite3, sys, zlib
db = sqlite3.connect(sys.argv[1])
db.create_function("Make_Hash", 1, lambda s: zlib.crc32(s.encode()))  # stand-in, not the game's hash
db.execute("PRAGMA foreign_keys=ON")
# Drop rows from a previous run of this mod so the check is repeatable.
db.execute("DELETE FROM Types WHERE Type LIKE 'RESOURCE_EUROPA_%' OR Type LIKE 'IMPROVEMENT_EUROPA_%'"
           " OR Type LIKE 'LEADER_EUROPA_%' OR Type LIKE 'TRAIT_LEADER_EUROPA_%' OR Type LIKE 'EUROPA_MODIFIER_%'"
           " OR Type LIKE 'CIVILIZATION_EUROPA_%' OR Type LIKE 'LEADER_MINOR_CIV_EUROPA_%' OR Type LIKE 'MINOR_CIV_EUROPA_%'")
db.execute("DELETE FROM LoadingInfo WHERE LeaderType LIKE 'LEADER_EUROPA_%'")
for t, c in (("TraitModifiers", "ModifierId"), ("ModifierArguments", "ModifierId"), ("Modifiers", "ModifierId"),
             ("RequirementSetRequirements", "RequirementSetId"), ("RequirementSets", "RequirementSetId"),
             ("RequirementArguments", "RequirementId"), ("Requirements", "RequirementId")):
    db.execute(f"DELETE FROM {t} WHERE {c} LIKE 'EUROPA_%' OR {c} LIKE '%LEADER_MINOR_CIV_EUROPA_%'")
ok = True
# The game rewrites this cache at every launch, from the base rules until a game is started.
# The leaders need Gathering Storm rows, so they can only be checked against a cache left
# by a Gathering Storm game.
paths = sys.argv[2:]
if not db.execute("SELECT 1 FROM Civilizations WHERE CivilizationType='CIVILIZATION_MALI'").fetchone():
    print("SKIPPED leader SQL: the cached database is base rules only (the game was launched but no")
    print("  Gathering Storm game started since). Start one, quit, and re-run to check the leaders.")
    print("SKIPPED city-state SQL for the same reason.")
    paths = [p for p in paths if "Leader" not in p and "CityState" not in p]
for path in paths:
    try:
        db.executescript(open(path).read())
    except sqlite3.Error as e:
        print(f"SQL FAILED: {path}: {e}"); ok = False
bad = db.execute("PRAGMA foreign_key_check").fetchall()
if bad:
    print("FOREIGN KEY VIOLATIONS:", *bad, sep="\n  "); ok = False
q = """SELECT replace(r.ResourceType,'RESOURCE_EUROPA_',''),
  (SELECT group_concat(replace(TerrainType,'TERRAIN_',''), ' ') FROM Resource_ValidTerrains t WHERE t.ResourceType = r.ResourceType),
  (SELECT group_concat(replace(FeatureType,'FEATURE_',''), ' ') FROM Resource_ValidFeatures f WHERE f.ResourceType = r.ResourceType),
  (SELECT replace(ImprovementType,'IMPROVEMENT_','') FROM Improvement_ValidResources i WHERE i.ResourceType = r.ResourceType),
  (SELECT group_concat(replace(YieldType,'YIELD_','') || '+' || YieldChange, ' ') FROM Resource_YieldChanges y WHERE y.ResourceType = r.ResourceType),
  (SELECT group_concat(replace(Tag,'CLASS_',''), ' ') FROM TypeTags g WHERE g.Type = r.ResourceType)
FROM Resources r WHERE r.ResourceType LIKE 'RESOURCE_EUROPA_%'"""
for row in db.execute(q):
    print("  " + " | ".join(str(c or "-") for c in row))
for t in ("Improvements", "Improvement_ValidBuildUnits", "Improvement_YieldChanges", "Improvement_BonusYieldChanges", "Improvement_Tourism"):
    cur = db.execute(f"SELECT * FROM {t} WHERE ImprovementType LIKE 'IMPROVEMENT_EUROPA_%'")
    cols = [c[0] for c in cur.description]
    for row in cur:
        print(f"  {t}: " + ", ".join(f"{c}={v}" for c, v in zip(cols, row) if v not in (None, 0, "") and c != "ImprovementType"))

# ---- custom leaders -------------------------------------------------------
def reqset(rs):
    kind = db.execute("SELECT RequirementSetType FROM RequirementSets WHERE RequirementSetId=?", (rs,)).fetchone()
    parts = []
    for (rid,) in db.execute("SELECT RequirementId FROM RequirementSetRequirements WHERE RequirementSetId=?", (rs,)):
        rtype, inv = db.execute("SELECT RequirementType, Inverse FROM Requirements WHERE RequirementId=?", (rid,)).fetchone()
        args = ",".join(f"{n}={v}" for n, v in db.execute("SELECT Name, Value FROM RequirementArguments WHERE RequirementId=?", (rid,)))
        parts.append(("NOT " if inv else "") + rtype.replace("REQUIREMENT_", "") + (f"({args})" if args else ""))
    return ("ANY" if kind and kind[0].endswith("ANY") else "ALL") + "[" + "; ".join(parts) + "]"

leaders = db.execute("SELECT LeaderType FROM Leaders WHERE LeaderType LIKE 'LEADER_EUROPA_%' ORDER BY 1").fetchall()
for (leader,) in leaders:
    civ = db.execute("SELECT CivilizationType, CapitalName FROM CivilizationLeaders WHERE LeaderType=?", (leader,)).fetchone()
    agenda = db.execute("SELECT AgendaType FROM HistoricalAgendas WHERE LeaderType=?", (leader,)).fetchone()
    print(f"  {leader}: {civ[0] if civ else 'NO CIVILIZATION'}, agenda {agenda[0] if agenda else 'NONE'}")
    if not civ or not agenda:
        print(f"LEADER INCOMPLETE: {leader}"); ok = False
    traits = db.execute("SELECT TraitType FROM LeaderTraits WHERE LeaderType=?", (leader,)).fetchall()
    for (trait,) in traits:
        for (mid,) in db.execute("SELECT ModifierId FROM TraitModifiers WHERE TraitType=?", (trait,)):
            row = db.execute("SELECT ModifierType, SubjectRequirementSetId FROM Modifiers WHERE ModifierId=?", (mid,)).fetchone()
            args = ", ".join(f"{n}={v}" for n, v in db.execute("SELECT Name, Value FROM ModifierArguments WHERE ModifierId=?", (mid,)))
            print(f"    {mid.replace('EUROPA_', '')}: {row[0].replace('MODIFIER_', '')} {{{args}}}" + (f" if {reqset(row[1])}" if row[1] else ""))
            if not db.execute("SELECT 1 FROM DynamicModifiers WHERE ModifierType=?", (row[0],)).fetchone():
                print(f"UNKNOWN MODIFIER TYPE: {row[0]}"); ok = False
# Every EUROPA_ modifier must be attached to something, and every requirement set used.
for (mid,) in db.execute("SELECT ModifierId FROM Modifiers WHERE ModifierId LIKE 'EUROPA_%' AND ModifierId NOT IN (SELECT ModifierId FROM TraitModifiers)"
                         " AND ModifierId NOT IN (SELECT Value FROM ModifierArguments WHERE Name='ModifierId')"):
    print(f"UNATTACHED MODIFIER: {mid}"); ok = False
for (rs,) in db.execute("SELECT RequirementSetId FROM RequirementSets WHERE RequirementSetId LIKE 'EUROPA_%' AND RequirementSetId NOT IN (SELECT SubjectRequirementSetId FROM Modifiers WHERE SubjectRequirementSetId IS NOT NULL) AND RequirementSetId NOT IN (SELECT OwnerRequirementSetId FROM Modifiers WHERE OwnerRequirementSetId IS NOT NULL) AND RequirementSetId NOT IN (SELECT Value FROM RequirementArguments WHERE Name='RequirementSetId')"):
    print(f"UNUSED REQUIREMENT SET: {rs}"); ok = False
for (rs,) in db.execute("SELECT RequirementSetId FROM RequirementSets WHERE RequirementSetId LIKE 'EUROPA_%' AND RequirementSetId NOT IN (SELECT RequirementSetId FROM RequirementSetRequirements)"):
    print(f"EMPTY REQUIREMENT SET: {rs}"); ok = False
# ---- city-states ------------------------------------------------------------
# Each Suzerain bonus is a trait modifier that attaches a second modifier to the Suzerain;
# print the attached one, with what it needs, to read against the design.
states = db.execute("SELECT c.CivilizationType, cl.LeaderType FROM Civilizations c JOIN CivilizationLeaders cl USING (CivilizationType)"
                    " WHERE c.CivilizationType LIKE 'CIVILIZATION_EUROPA_%' ORDER BY 1").fetchall()
lua = open("Scripts/Europa_CityStates.lua").read()
for civ, leader in states:
    cat = db.execute("SELECT Value FROM TypeProperties WHERE Type=? AND Name='CityStateCategory'", (civ,)).fetchone()
    inherit, = db.execute("SELECT InheritFrom FROM Leaders WHERE LeaderType=?", (leader,)).fetchone()
    bonus = db.execute("SELECT MinorCivBonusType FROM Leaders_XP2 WHERE LeaderType=?", (leader,)).fetchone()
    level, = db.execute("SELECT StartingCivilizationLevelType FROM Civilizations WHERE CivilizationType=?", (civ,)).fetchone()
    print(f"  {civ}: {cat[0] if cat else 'NO CATEGORY'}, inherits {inherit}, envoy bonuses {bonus[0] if bonus else 'NONE'}")
    if not cat or not bonus or level != "CIVILIZATION_LEVEL_CITY_STATE" or inherit != f"LEADER_MINOR_CIV_{cat[0]}" or bonus[0] != f"MINOR_CIV_BONUS_{cat[0]}":
        print(f"CITY-STATE INCOMPLETE OR INCONSISTENT: {civ}"); ok = False
    mods = db.execute("SELECT tm.ModifierId FROM TraitModifiers tm JOIN LeaderTraits lt USING (TraitType) WHERE lt.LeaderType=? AND tm.ModifierId LIKE 'EUROPA_%' ORDER BY 1", (leader,)).fetchall()
    if not mods:
        print(f"CITY-STATE HAS NO SUZERAIN BONUS: {civ}"); ok = False
    for (outer,) in mods:
        otype, oreq = db.execute("SELECT ModifierType, SubjectRequirementSetId FROM Modifiers WHERE ModifierId=?", (outer,)).fetchone()
        inner = db.execute("SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='ModifierId'", (outer,)).fetchone()
        if otype != "MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER" or oreq != "PLAYER_IS_SUZERAIN" or not inner:
            print(f"NOT A SUZERAIN ATTACH MODIFIER: {outer}"); ok = False; continue
        row = db.execute("SELECT ModifierType, SubjectRequirementSetId, OwnerRequirementSetId, Permanent FROM Modifiers WHERE ModifierId=?", (inner[0],)).fetchone()
        if not row:
            print(f"ATTACHED MODIFIER MISSING: {inner[0]}"); ok = False; continue
        if not db.execute("SELECT 1 FROM DynamicModifiers WHERE ModifierType=?", (row[0],)).fetchone():
            print(f"UNKNOWN MODIFIER TYPE: {row[0]}"); ok = False
        args = ", ".join(f"{n}={v}" for n, v in db.execute("SELECT Name, Value FROM ModifierArguments WHERE ModifierId=?", (inner[0],)))
        print(f"    {inner[0].replace('EUROPA_', '')}: {row[0].replace('MODIFIER_', '')} {{{args}}}" + (" permanent" if row[3] else "")
              + (f" if {reqset(row[1])}" if row[1] else "") + (f" when owner {reqset(row[2])}" if row[2] else ""))
    copied = db.execute("SELECT count(*) FROM Modifiers WHERE ModifierId LIKE ?", (f"BBG%{leader}",)).fetchone()[0]
    fez = db.execute("SELECT count(*) FROM Modifiers WHERE ModifierId LIKE 'BBG%LEADER_MINOR_CIV_FEZ'").fetchone()[0]
    print(f"    BBG per-city-state modifiers: {copied} (Fez has {fez})")
    if copied != fez:
        print(f"BBG ROWS NOT COPIED FOR {leader}"); ok = False
if len(states) != 6 and db.execute("SELECT 1 FROM Civilizations WHERE CivilizationType='CIVILIZATION_FEZ'").fetchone():
    print(f"EXPECTED 6 CITY-STATES, GOT {len(states)}"); ok = False
for (prop,) in db.execute("SELECT DISTINCT Value FROM RequirementArguments WHERE Name='PropertyName' AND Value LIKE 'EUROPA_CS_%'"):
    if f'"{prop}"' not in lua:
        print(f"PLOT PROPERTY NEVER WRITTEN BY LUA: {prop}"); ok = False
for (rid,) in db.execute("SELECT RequirementId FROM Requirements WHERE RequirementId LIKE 'EUROPA_REQ_CS_%' AND RequirementId NOT IN"
                         " (SELECT RequirementId FROM RequirementArguments WHERE Name='PropertyName' AND Value LIKE 'EUROPA_CS_%')"):
    print(f"PROPERTY REQUIREMENT WITHOUT A PROPERTY NAME: {rid}"); ok = False
# BBG switches leader-specific district adjacencies off by trait, so a new leader inherits every
# sibling's unless it opts out. KEEP lists the ones a leader is meant to have; anything else
# left over is a mistake.
# BBG_AOS_ADJENCY_IZ_RND is not a sibling's bonus: it is England's Industrial Zone
# adjacency, which BBG excludes for every non-English trait including Eleanor's.
KEEP = {"LEADER_EUROPA_GOLDEN_EXPANSION": {"BBG_SUGUBA_HOLY_SITE_MANSA"},
        "LEADER_EUROPA_PALACE_DESIGNER": {"BBG_AOS_ADJENCY_IZ_RND"}}
for (leader,) in leaders:
    civ = db.execute("SELECT CivilizationType FROM CivilizationLeaders WHERE LeaderType=?", (leader,)).fetchone()
    if not civ: continue
    theirs = {r[0] for r in db.execute("""SELECT DISTINCT YieldChangeId FROM ExcludedAdjacencies WHERE TraitType IN
        (SELECT TraitType FROM LeaderTraits WHERE LeaderType IN (SELECT LeaderType FROM CivilizationLeaders
         WHERE CivilizationType=? AND LeaderType NOT LIKE 'LEADER_EUROPA_%'))""", (civ[0],))}
    ours = {r[0] for r in db.execute("SELECT YieldChangeId FROM ExcludedAdjacencies WHERE TraitType IN (SELECT TraitType FROM LeaderTraits WHERE LeaderType=?)", (leader,))}
    kept, want = theirs - ours, KEEP.get(leader, set())
    if kept - want:
        print(f"LEADER-SPECIFIC ADJACENCY NOT EXCLUDED for {leader}: {sorted(kept - want)}"); ok = False
    if theirs and want - kept:
        print(f"ADJACENCY MEANT TO BE KEPT IS MISSING OR EXCLUDED for {leader}: {sorted(want - kept)}"); ok = False
    if theirs:
        print(f"  {leader} keeps: {', '.join(sorted(kept)) or 'none'}; opts out of: {', '.join(sorted(theirs & ours)) or 'none'}")
sys.exit(0 if ok else 1)
PY
fi

echo "== setup-screen SQL against the game's cached configuration database"
if [ ! -f "$CACHE/DebugConfiguration.sqlite" ]; then
	echo "SKIPPED: no DebugConfiguration.sqlite in $CACHE"
else
	cp "$CACHE/DebugConfiguration.sqlite" "$TMP/cfg.sqlite"
	python3 - "$TMP/cfg.sqlite" Config/*.sql <<'PY' || fail=1
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
db.execute("DELETE FROM Players WHERE LeaderType LIKE 'LEADER_EUROPA_%'")
db.execute("DELETE FROM PlayerItems WHERE LeaderType LIKE 'LEADER_EUROPA_%'")
db.execute("DELETE FROM CityStates WHERE CivilizationType LIKE 'CIVILIZATION_EUROPA_%'")
ok = True
for path in sys.argv[2:]:
    try:
        db.executescript(open(path).read())
    except sqlite3.Error as e:
        print(f"SQL FAILED: {path}: {e}"); ok = False
rows = db.execute("SELECT LeaderType, Domain, CivilizationType, Portrait, CivilizationAbilityName FROM Players WHERE LeaderType LIKE 'LEADER_EUROPA_%' ORDER BY 1").fetchall()
for leader, domain, civ, portrait, civ_ability in rows:
    items = [r[0] for r in db.execute("SELECT Type FROM PlayerItems WHERE LeaderType=? AND Domain=? ORDER BY SortIndex", (leader, domain))]
    print(f"  {leader}: {civ} in {domain}, portrait {portrait}, items {', '.join(items) or 'NONE'}")
    if not items or not portrait or not civ_ability:
        print(f"SETUP ROW INCOMPLETE: {leader}"); ok = False
states = db.execute("SELECT CivilizationType, Domain, CityStateCategory, Name, Icon, Bonus FROM CityStates WHERE CivilizationType LIKE 'CIVILIZATION_EUROPA_%' ORDER BY 1").fetchall()
for civ, domain, category, name, icon, bonus in states:
    print(f"  {civ}: {category} in {domain}, icon {icon}")
if len(states) != 6:
    print(f"EXPECTED 6 CITY-STATES IN THE PICKER, GOT {len(states)}"); ok = False
if len(rows) != 8:
    print(f"EXPECTED 8 SELECTABLE LEADERS, GOT {len(rows)}"); ok = False
sys.exit(0 if ok else 1)
PY
fi

echo "== every leader has a name, ability text, loading text, icon, colours, art and setup row"
for l in $(grep -h "KIND_LEADER" Data/*.sql | grep -o "LEADER_EUROPA_[A-Z_]*" | sort -u); do
	grep -q "LOC_${l}_NAME\"" Text/*.xml                          || { echo "NO NAME TEXT: $l"; fail=1; }
	grep -q "LOC_TRAIT_${l}_NAME\"" Text/*.xml                    || { echo "NO ABILITY NAME TEXT: $l"; fail=1; }
	grep -q "LOC_TRAIT_${l}_DESCRIPTION\"" Text/*.xml             || { echo "NO ABILITY TEXT: $l"; fail=1; }
	grep -q "LOC_LOADING_INFO_${l}\"" Text/*.xml                  || { echo "NO LOADING TEXT: $l"; fail=1; }
	grep -q "Name=\"ICON_${l}\"" Data/Europa_Leaders_Icons.xml   || { echo "NO ICON: $l"; fail=1; }
	grep -q "<Type>${l}</Type>" Data/Europa_Leaders_Colors.xml    || { echo "NO COLOURS: $l"; fail=1; }
	grep -q "m_Name text=\"${l}\"" ArtDefs/Leaders.artdef         || { echo "NO LEADER ARTDEF: $l"; fail=1; }
	grep -q "m_Name text=\"${l}\"" ArtDefs/FallbackLeaders.artdef || { echo "NO FALLBACK ARTDEF: $l"; fail=1; }
	grep -q "'${l}'" Config/*.sql                                 || { echo "NO SETUP ROW: $l"; fail=1; }
done
for k in $(grep -ho "LOC_[A-Z0-9_]*EUROPA[A-Z0-9_]*" Data/Europa_Leader*.sql Data/Europa_CityState*.sql Config/*.sql | sort -u); do
	grep -q "Tag=\"${k}\"" Text/*.xml || { echo "TEXT KEY NOT DEFINED: $k"; fail=1; }
done
for prop in $(grep -ho "'EUROPA_[A-Z_]*'" Data/Europa_Leader*.sql | tr -d "'" | sort -u | while read v; do grep -q "'PropertyName', *'$v'" Data/Europa_Leader*.sql && echo "$v"; done); do
	grep -q "\"${prop}\"" Scripts/Europa_Leaders.lua || { echo "PLOT PROPERTY NEVER WRITTEN BY LUA: $prop"; fail=1; }
done

echo "== every city-state has a name, bonus text, pedia text, icon, colours and picker row"
for c in $(grep -h "KIND_CIVILIZATION" Data/Europa_CityState*.sql | grep -o "CIVILIZATION_EUROPA_[A-Z_]*" | sort -u); do
	k=${c#CIVILIZATION_}
	grep -q "LOC_${c}_NAME\"" Text/*.xml                              || { echo "NO NAME TEXT: $c"; fail=1; }
	grep -q "LOC_MINOR_CIV_${k}_TRAIT_DESCRIPTION\"" Text/*.xml       || { echo "NO BONUS TEXT: $c"; fail=1; }
	grep -q "LOC_PEDIA_CITYSTATES_PAGE_${c}_CHAPTER_HISTORY_PARA_1\"" Text/*.xml || { echo "NO PEDIA TEXT: $c"; fail=1; }
	grep -q "Name=\"ICON_${c}\"" Data/Europa_CityStates_Icons.xml    || { echo "NO ICON: $c"; fail=1; }
	grep -q "<Type>${c}</Type>" Data/Europa_CityStates_Colors.xml     || { echo "NO COLOURS: $c"; fail=1; }
	grep -q "'${c}'" Config/Europa_CityStates_Config.sql              || { echo "NO PICKER ROW: $c"; fail=1; }
	grep -q "\"${c}\"" Scripts/Europa_CityStates.lua                 || { echo "NOT IN THE SCRIPT'S LIST: $c"; fail=1; }
done

echo "== city-state icon atlases are up to date with the generator"
python3 tools/make_citystate_icons.py --check || fail=1

echo "== city-state script logic (needs the 'lupa' Python package; skipped without it)"
python3 tools/test_citystates.py || fail=1

echo "== leader icons use atlases the installed game defines, and load after them"
for a in $(grep -o 'Atlas="[^"]*"' Data/Europa_Leaders_Icons.xml | cut -d'"' -f2 | sort -u); do
	grep -rqs --include='*.xml' "Row Name=\"$a\"" "$GAME_ASSETS" || { echo "ICON ATLAS NOT IN GAME: $a"; fail=1; }
done
# The icon database has a foreign key on Atlas; without a late LoadOrder our rows load first and fail.
python3 - <<'PY' || fail=1
import re, sys
s = open("ProjectEuropa.modinfo").read()
blocks = re.findall(r"<UpdateIcons[^>]*>.*?</UpdateIcons>", s, re.S)
mine = [b for b in blocks if "Europa_Leaders_Icons.xml" in b]
bad = [b.split(">")[0] for b in mine if "<LoadOrder>" not in b]
if len(mine) != 2 or bad:
    print("LEADER ICONS NEED A LoadOrder IN BOTH InGame AND FrontEnd ACTIONS:", bad or f"{len(mine)} action(s) found"); sys.exit(1)
PY

echo "== leader art definitions are the installed stock entries, renamed"
python3 tools/make_leader_art.py --check || fail=1

echo "== leader script logic (needs the 'lupa' Python package; skipped without it)"
python3 tools/test_leaders.py || fail=1

echo "== every resource has a name, pedia text, icon, FOW icon, font icon and art entry"
for r in $(grep "KIND_RESOURCE" Data/Europa_Resources.sql | grep -o "RESOURCE_EUROPA_[A-Z_]*" | sort -u); do
	grep -q "LOC_${r}_NAME\"" Text/*.xml                      || { echo "NO NAME TEXT: $r"; fail=1; }
	grep -q "LOC_PEDIA_RESOURCES_PAGE_${r}_CHAPTER" Text/*.xml || { echo "NO PEDIA TEXT: $r"; fail=1; }
	grep -q "Name=\"ICON_${r}\"" Data/Europa_Icons.xml         || { echo "NO ICON: $r"; fail=1; }
	grep -q "Name=\"ICON_${r}_FOW\"" Data/Europa_Icons.xml     || { echo "NO FOW ICON: $r"; fail=1; }
	grep -q "Name=\"${r}\"" Data/Europa_Icons.xml              || { echo "NO FONT ICON: $r"; fail=1; }
	grep -q "m_Name text=\"${r}\"" ArtDefs/Resources.artdef    || { echo "NO ARTDEF: $r"; fail=1; }
done

echo "== every improvement has a name, description, icon and art entry"
for i in $(grep "KIND_IMPROVEMENT" Data/Europa_Resources.sql | grep -o "IMPROVEMENT_EUROPA_[A-Z_]*" | sort -u); do
	grep -q "LOC_${i}_NAME\"" Text/*.xml                    || { echo "NO NAME TEXT: $i"; fail=1; }
	grep -q "LOC_${i}_DESCRIPTION\"" Text/*.xml             || { echo "NO DESCRIPTION TEXT: $i"; fail=1; }
	grep -q "Name=\"ICON_${i}\"" Data/Europa_Icons.xml      || { echo "NO ICON: $i"; fail=1; }
	grep -q "m_Name text=\"${i}\"" ArtDefs/Improvements.artdef || { echo "NO ARTDEF: $i"; fail=1; }
done

echo "== terrain generator override is the installed stock file + our hook"
python3 tools/make_terrain_override.py --check || fail=1

echo "== desert growth logic (needs the 'lupa' Python package; skipped without it)"
python3 tools/test_desert_growth.py || fail=1

if command -v luac >/dev/null; then
	echo "== Lua syntax"; luac -p Scripts/*.lua || fail=1
fi

[ "$fail" = 0 ] && echo "ALL CHECKS PASSED" || { echo "CHECKS FAILED"; exit 1; }
