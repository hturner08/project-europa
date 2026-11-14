# AGENTS.md

Context for any agent working on Project Europa. Read this before proposing or
balancing content. What the mod contains is in [README.md](README.md); this file
is about who it is for and what that means for design.

## Who this mod is for

Project Europa is a private mod for exactly two people: Herbie and his
girlfriend. Every game it is used in looks like this:

- **Two human players, multiplayer.**
- **No AI civilizations.** City-states are in the game; other major civs are not.

It is not balanced for the general public, for larger lobbies, or for games
against the AI. When a design choice is good for a two-player game and bad for
an eight-player one, the two-player game wins.

## How they play

- **Expansive empires.** Both players settle wide and keep settling. Content that
  rewards more cities, more land, and well-developed territory fits.
- **Mostly peaceful.** War between them happens, but very rarely.
- **Victory types they aim for:** Religious, Cultural, Scientific and Diplomatic.
  Domination is not a goal.

## Design rules

### 1. Don't build around the military

They build few units and few fortifications, and do not use things like Military
Engineers. So:

- Don't make a bonus depend on combat, kills, pillaging, conquest, or being at war.
- Don't make it depend on having a large army, Encampments, walls, Forts, or
  Military Engineer charges.
- Don't use unique units or combat strength as the main payoff of a leader,
  city-state, or other piece of content.
- A small military rider on an otherwise peaceful bonus is fine. A bonus that is
  wasted unless you fight is not.

Prefer payoffs in settling, growth, districts, Wonders, Appeal, trade, Faith,
Culture, Science, and Tourism.

### 2. Don't rely on there being many civilizations

With one other major civ in the game, anything that scales with the number of
civs is weak or does nothing. Before using a mechanic, ask "how many other civs
does this need to be worth it?" If the answer is more than one, pick something
else. Things to check:

- Bonuses per civ met, per alliance, per trade partner, or per civ with some property.
- Bonuses for international Trade Routes to *different* civs. (Routes to
  city-states still work.)
- Effects that need the AI: AI agendas, AI deals, selling to the AI, AI-declared wars.
- Effects that need a third party: joint wars, emergencies with several
  members, being a neutral party to someone else's conflict.
- Tourism or religion effects whose value comes from many targets rather than one.

Anything "per other civ" has a hard ceiling of one here. City-states are the
only third parties, so effects that count city-states, envoys, or suzerainties
do scale normally.

### 3. Be very careful with Diplomatic Victory yields

This is the most sensitive area in the mod. In a two-player game the Diplomatic
Victory race has only two competitors, so a small edge for one of them is a
large swing in the result: the scale tips easily.

Treat all of the following as high-risk, and flag them to the user rather than
adding or changing them quietly:

- Diplomatic Favor, from any source (per turn or lump sum).
- Diplomatic Victory Points.
- World Congress votes, vote costs, and resolution outcomes.
- Suzerainty and envoys, because suzerainties generate Diplomatic Favor. A
  city-state or leader bonus that makes suzerainty easier is indirectly a
  Diplomatic Victory bonus.
- Anything else that feeds Favor, such as alliances, government tier, or
  Grievances.

When a change touches any of these:

1. Say so explicitly, and state which player it is likely to favour and when.
2. Prefer effects that are symmetric (both players can get them equally) over
   ones tied to a single leader or to who gets somewhere first.
3. Prefer small numbers, and prefer a different yield entirely when one will do.

### 4. Everything is head-to-head

More generally, with two players every asymmetric bonus is a direct advantage
over one specific person. Aim for content that is fun for both, not content
that is strongest in the abstract. If one leader or city-state is clearly the
best pick, that is a problem even if it would be reasonable in a full lobby.
