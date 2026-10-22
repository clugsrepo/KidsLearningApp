# Skate It: Roblox game handover

A Roblox skateboarding game designed by **Ollie Easton (age 9)**, built with Claude. Ollie is the game designer and makes the decisions. Claude writes the code and the steps.

## Working with Ollie
- He's 9. Keep replies short, fun and encouraging, with simple words and a few emojis.
- Ask one question at a time. Offer 3 to 5 choices plus "your own idea".
- Keep everything child-safe. No chat features, no links out of the game, no real-money purchases.
- When a grown-up needs to do a step (installing things, settings), say so.
- Let Ollie name things and choose colours. Explain changes as "what you'll see in the game".

## The game design (Ollie's decisions)
- **Name:** Skate It
- **Style:** a city skatepark like the console game *Skate*, with tricks and races
- **City:** buildings, graffiti walls, kicker ramps, grind rails, funbox, ledges, stairs with a handrail, a half-pipe
- **Mega ramp:** a tall tower with a huge roll-in, a jump over a gap, and a landing. A green pad teleports you to the top
- **Rocket:** walk into the glowing door to teleport to **space**: floating platforms, low gravity (25%), a planet and stars. An orange pad takes you back to the city
- **Skateboard:** every player rides one
- **Tricks:** Dark Flip (press F, or the on-screen button on a tablet), worth 100 points
- **Skate shop:** spend points on better gear
  - Decks give a trick points bonus (Classic x1, Flame x1.5 for 500, Galaxy x2 for 2000, Gold x3 for 5000)
  - Trucks give jump height (Basic, Pro 400, Rocket 1500)
  - Wheels give speed (Basic, Speedy 300, Turbo 1200, Lightning 3000)

## The scripts (all in this folder)
| File | Type in Roblox Studio | Where it goes |
|---|---|---|
| `1_BuildSkatepark.server.lua` | Script | ServerScriptService |
| `2_Skateboard.server.lua` | Script | ServerScriptService |
| `3_Tricks.client.lua` | LocalScript | StarterPlayer > StarterPlayerScripts |
| `4_Shop.client.lua` | LocalScript | StarterPlayer > StarterPlayerScripts |

Start from a new **Baseplate** place. Script 1 builds the whole map from code when the game starts (in a model called `SkateItMap`). The shop items, prices and colours live in the `SHOP` table at the top of script 2.

How they talk to each other:
- Script 2 creates `ReplicatedStorage.TrickDone` (RemoteEvent), `ReplicatedStorage.ShopRequest` (RemoteFunction) and `ReplicatedStorage.ShopItems` (the shop list, as Configuration objects with attributes).
- The board is built from parts named `Skateboard*` welded under the character. The deck's weld is `SkateboardWeld`, which the tricks script animates.
- Equipped gear is stored as player attributes (`Deck`, `Trucks`, `Wheels`) and owned gear as `Owns_<Category>_<Id>`.
- Points are `leaderstats.Points`.

## Status
- Written in a cloud session and checked for syntax only. **Not yet play-tested in Roblox Studio.** Test first and fix anything broken.
- Points reset when you stop the game. No saving yet.

## Ideas for next steps
1. Play-test everything and fix bugs (board lining up with the feet, the wedge ramps facing the right way, the teleport pads)
2. More tricks (kickflip, heelflip, 360, grinds on the rails), with combos
3. Races: start line, checkpoints, finish line and a timer, with prizes in points
4. Save points and gear between games (DataStore; the place needs to be published with Studio API access turned on)
5. A skate shop building in the city
6. A skating pose instead of the walking animation
