# Pantheons: manual test checklist

`tools/validate.sh` checks everything that can be checked without the game: the SQL
loads against the game's own database with foreign keys on, every modifier and
requirement type exists, each effect is limited to the pantheon's owner, the Builder
charges are permanent, the Sacred Companions list matches the Camp luxuries, the stock
Divine Inspiration belief is untouched, and text, icons and load order are in place.

With the `lupa` package installed it also runs `Scripts/Europa_Pantheons.lua` against
stubbed game functions (`tools/test_pantheons.py`).

It cannot run the engine. The items below need a game. Items marked **(open)** are the
ones where the engine's behaviour is not known in advance; the rest are expected to
pass and are here to confirm it.

Setup: Gathering Storm ruleset, BBG and Project Europa on, two human players (hotseat is
fine for most of it; do one pass over real multiplayer with simultaneous turns). After
the first launch, check `Database.log` and `Modding.log` for lines mentioning `Europa_Pantheon`,
and `Lua.log` for `Europa pantheons: hooks added.` Any other `Europa pantheons:` line means a
game function the script needs is missing.

## Selection

- [ ] All six appear in the pantheon chooser with name, description and icon, alongside the stock ones.
- [ ] Civilopedia has a page for each.
- [ ] Without Spare Beliefs: once one player takes a pantheon, the other is not offered it.
- [ ] With Spare Beliefs: both players can take the same one, and the copy has its icon.
- [ ] The bonus is still there after founding a religion.
- [ ] Take our Divine Inspiration, later take the stock Follower belief of the same name: both effects apply.

## Hearths of the First Settlers

- [ ] New city at 1 Population: +1 Food, +1 Production in the city's yield breakdown.
- [ ] Still there at 3; gone at 4; back if the city drops to 3.
- [ ] The Capital and cities founded before taking the pantheon get it.
- [ ] A captured 2-Population city gets nothing.
- [ ] Six qualifying cities: +6 and +6 in total.

## Sacred Companions

- [ ] Camp on Peacocks (and each of Pallas's Cats, Pygmy Rabbits, Tibetan Foxes, Capybaras): +1 Production, +1 Faith on the tile.
- [ ] Topaz Mine and Discus Fish Fishing Boats: nothing. A Camp on a stock resource (Deer, Furs): nothing.
- [ ] **(open)** Pillage the Camp: both bonuses go until it is repaired.
- [ ] With Goddess of the Hunt held by the same player (Spare Beliefs cannot do this; skip unless a way exists): both apply.

## Guilds of the New Realm / Pillars of Creation

Same mechanism, so run each line for a Market city (Guilds) and a Wonder city (Pillars).

- [ ] Builder trained in a city without the Market / Wonder: normal charges.
- [ ] Builder trained in a qualifying city: +1 charge.
- [ ] Builder bought with Gold, and with Faith (Monumentality), in a qualifying city: +1 charge.
- [ ] Finishing the Market / Wonder does not change Builders that already exist.
- [ ] With Liang (Guildmaster) in the city, Serfdom slotted and the Pyramids built: each adds on top.
- [ ] Save, quit, reload: the Builder has the same charges as before (no extra, none lost).
- [ ] Pillage the Market after the Builder exists: the Builder keeps its charge.
- [ ] **(open)** Pillage the Market, then train a Builder: no extra charge until repaired.
- [ ] Note only: whether a free Builder that appears in a qualifying city (Ancestral Hall, Endless Continent's Tundra city) gets the charge. Either result is accepted.
- [ ] Pillars only: a city whose only Wonder is still under construction gives no extra charge; the turn the Wonder is finished it does.
- [ ] Pillars only: four Wonders in the city still give only +1. A captured Wonder city qualifies.

## Sacred Wilderness

- [ ] Before Medieval Faires: nothing. After: an unimproved Breathtaking tile next to a Preserve gets +1 Production.
- [ ] A Charming tile next to the Preserve: nothing.
- [ ] Build a Mine on a qualifying tile: bonus goes. Remove it: bonus returns.
- [ ] A tile next to two Preserves: still +1.
- [ ] Lower the tile's Appeal below 4 (Mine or Industrial Zone nearby): bonus goes; raise it again: returns.
- [ ] A tile in one city next to a Preserve of another of your cities: gets it.
- [ ] Stacks with the Grove and Sanctuary tile yields.
- [ ] A Preserve still under construction does not count; the tiles get the bonus once it is finished (at the latest at the start of your next turn).
- [ ] Your tile next to the *other player's* Preserve: no bonus.
- [ ] Capture a city with a Preserve: its neighbouring tiles now count for you, and no longer for the previous owner's tiles across the border.

## Divine Inspiration

- [ ] City with an Art Museum and a Wonder: +1 Great Artist point per turn in the Great People screen breakdown.
- [ ] Three Wonders, one Art Museum: still +1. Empty museum: still +1.
- [ ] Wonder and Archaeological Museum: nothing. Art Museum, no Wonder: nothing.
- [ ] Four qualifying cities: +4.
- [ ] **(open)** Pillage the Art Museum: bonus goes until repaired.
- [ ] A Wonder still under construction does not count; the point appears once it is finished.

## Multiplayer

- [ ] One full game start to Medieval era over real multiplayer, simultaneous turns, each player on a different one of these pantheons: no desync, and both see the same yields on each other's tiles and cities.
- [ ] Save and reload the multiplayer game mid-way: yields and Builder charges unchanged.
- [ ] Suzerain of each of the six custom city-states while holding one of these pantheons: both sets of bonuses apply.
