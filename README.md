# The Blacksmith's Boy (prototype)

A 2D open-world action RPG prototype made in Godot 4, set in Kingdom B's fortress city,
Akropolis Aigidos. This build covers Mission 1: Kael wakes at Haldor's forge, leaves the city
to mine iron ore at the foot of the cliffs, forges his first sword, then takes a moonsteel stone
from the beast pack leader in the Forest of Elders.

## Run it on your computer

1. Download Godot 4.3 or newer (Standard version, free) from godotengine.org.
2. Open Godot, click Import, and pick the `project.godot` file in this folder.
3. Press F5 (or the play button) to run.

Controls: WASD or arrow keys to move, J or Space to attack, L for the heavy slam
(after you have the sword), K or Shift to dodge, E to talk. On a phone, an on-screen
joystick and buttons appear automatically.

## What's in the prototype

- Akropolis Aigidos, built from the concept map: a round outer wall with towers, the royal castle inside its eight-sided wall, streets running out from the castle, a ring road, districts of houses, farm fields, and Haldor's fenced yard by the north gate.
- The land outside: a grass plateau, cliffs all around, the Serpent's Way winding down to the foothills (iron ore), the Forest of Elders (beasts), and the Lowlands with a stream.
- One seamless open world. Walking from the forge, out the gate, and down the cliffs never shows a loading screen.
- People: Haldor, gate guards, royal guards at the castle, townsfolk, and Kingdom A captives in chains hauling stone. Most of them can be talked to.
- Real-time combat against Terrak, the ancient horned beasts: quick attacks, a heavy slam that cracks the ground, and a dodge roll that makes you briefly invincible. Terrak roar and glow red before lunging. The pack leader is bigger and carries the moonsteel.
- A forging mini-game where your timing decides how strong your sword is.
- Places from the city plan: the blacksmith compound (weapon rack, armour stand, woodpile, storage), the Gilded Tankard inn, watchtowers on the plateau, a scout outpost at the edge of the Forest of Elders, and the East Quarry mining settlement (headframe, mine tunnel, ore carts, bunkhouse, miners and Kingdom A captives).
- A guide arrow that leads you through the yard gate, the north gate and down the Serpent's Way, plus a minimap.
- Fully offline. No servers.

## Where things live

| File | What it does |
|------|--------------|
| `scripts/story.gd` | All dialogue. Writers can edit this without touching game code. |
| `scripts/main.gd` | Mission flow, spawning, objectives |
| `scripts/geo.gd` | The map layout: where the walls, gates, roads, cliffs and forest are |
| `scripts/city.gd` | Builds the city: walls, towers, castle, houses, yard, fields |
| `scripts/world.gd` | Ground, trees and ore rocks, streamed in chunks |
| `scripts/npc.gd` | Haldor, guards, townsfolk, captives |
| `scripts/player.gd` | Movement and combat |
| `scripts/beast.gd` | Enemy behavior |
| `scripts/forge_panel.gd` | Forging mini-game |
| `scripts/hud.gd` | Health, quest text, dialogue box, phone controls |

## Look and display

- The game renders at 960x540 and is scaled up by a whole number (2x on a 1080p phone),
  so every art pixel stays a crisp square. The desktop window opens at 1920x1080.
- Roads, the market square, fields, the castle courtyard and the cliff are drawn as smooth
  textured shapes by `scripts/paving.gd` (textures: `art/tex_*.png`).
- A warm colour grade (`scripts/grade.gdshader`) sits between the world and the interface.
- Bushes, flowers, grass tufts, ferns, mushrooms and pebbles (`art/flora.png`) are scattered by `scripts/world.gd`.
- Soft shadows under everything come from `scripts/shadow.gd`.
- Interface frames and buttons: `art/ui_*.png`.

## The Royal Citadel

Built by `scripts/citadel.gd` at the centre of the city, following the Royal Citadel blueprint.
Every door is open for now (conditions and gameplay can be added later).

**Main floor**
- curtain wall with towers, a moat and the main gatehouse with its bridge (south)
- the Royal Courtyard: flagstones in four layouts so the ground never repeats, a cobbled
  avenue with dark kerbs, the battle arena with a rope fence (open on four sides),
  irregular planting beds, statues, braziers and the red carpet up the grand steps
- the Grand Throne Hall: the roof fades away when you walk in and a low cut-down front wall
  appears (Kael walks behind it); checkered marble nave with inlaid borders, rugs, pillars,
  statues and armour in the side aisles, wall torches, window light, the throne under a
  velvet canopy, stairs up and stairs down
- the West Wing (barracks and armory) and East Wing (banquet hall), both walk-in
- the West and East Gardens and the Chapel (walk-in)

**Royal Residence (stairs up)**: a long corridor with the King and Queen's chamber, the
princes' room, the princess's room, the king's sister's rooms and the Royal Library.

**Service Floor (stairs down)**: a service hall with the kitchen, storeroom and servants' quarters.

Walking onto a staircase fades the screen out and in (about half a second, no loading
screen). The other floors are built far away in the same world (`citadel_floors.gd`,
`floor_plan.gd`), so moving between them is instant.

Layers: ground (`cit_ground.gd`, `cit_interior.gd`, `floor_plan.gd`) is drawn under
everything; buildings, furniture, people and Kael are y-sorted by their feet; collision
boxes are separate from the art, so decorations never block doors, stairs or paths.

## Imported castle art (from an AI sheet)

`tools/import_castle.py` turns `source_art/castle/sheet1.png` (objects on magenta) into
game sprites: it removes the magenta and its pink fringe, cuts each object out, scales
everything by the same factor (so pixels match Kael), and writes them in groups:

| Folder | Contents | Pivot |
|--------|----------|-------|
| `art/castle/tiles/` + `tiles.png` atlas | floor tiles, exactly 32x32 | top-left |
| `art/castle/rugs/` | rugs and runners | bottom-centre |
| `art/castle/furniture/` | beds, tables, chairs, chests, shelves | bottom-centre (feet) |
| `art/castle/decor/` | banners, statues, armour, plants, candelabras, throne | bottom-centre |
| `art/castle/walls/` | wall pieces, doors, arches, stairs | bottom-centre |
| `art/castle/kitchen/` | hearth, oven, stove, barrels, sacks | bottom-centre |

`art/castle/manifest.json` lists every sprite's size, pivot and collision footprint.
To add another sheet: put it in `source_art/castle/`, add its names to the script, run it.
Rules for new sheets: pure magenta background (#FF00FF), one group per sheet, a clear gap
between objects, the same 3/4 view and the same scale as this one.

## Kael's animations

Kael is drawn from AI-generated sheets kept in `source_art/kael/` (magenta background).
`tools/import_kael.py` turns them into the game sheets `art/kael_idle.png`, `kael_walk.png`,
`kael_attack.png`, `kael_roll.png` and `kael_hurt.png`: it removes the background, cuts the
grid, lines up the feet, shrinks every sheet to the same height (64 px) and keeps the pixel
edges crisp. Frames are 96x96 with the feet at y = 88; rows face down, up and right
(left is mirrored in game). To update Kael, replace a source sheet with the same layout and run
`cd tools && python3 import_kael.py`.

| Sheet | Layout |
|---|---|
| idle | 3 rows x 4 frames |
| walk | 3 rows x 6 frames |
| attack | 3 rows x 6: ready, wind-up, swing, impact, follow-through, recover |
| roll | 3 rows x 6 |
| hurt | 1 row x 7 (facing right): hurt x2, fall, lie x2, get up, stand |

## Sunlight

`scripts/grade.gdshader` adds sun shafts falling from the upper left (fixed to the world, so you
walk through them), a golden glow from the sun's corner and dust drifting in the beams.
Strength is set by `shaft_strength` and `glow_strength` at the top of the file.

## Art

All graphics are pixel-art PNG sprite sheets in the `art/` folder, drawn 1:1 in game
(one art pixel = one screen pixel at normal zoom). They were generated by the Python
scripts in `tools/`. To regenerate them: `cd tools && python3 make_all.py` (needs Python 3 and Pillow).

An artist can replace any PNG with hand-drawn art as long as the layout stays the same:

| File | Layout |
|------|--------|
| `tiles.png` | 32x32 ground tiles, 4 variants per row (grass, forest grass, meadow, path, cobble, plaza, dirt, field, rocky, cliff top, cliff face, water, mountain, grass edge) |
| `char_*.png` | 40x60 frames: rows are facing down, up, side (right); 4 walk frames each |
| `terrak_leader.png`, `terrak_young.png` | 7 frames in a row, facing right: 4 walk, 2 roar, 1 lunge |
| `houses.png` | 112x80 cells: columns are sizes, rows are roof colours (red, brown, blue, teal, slate) |
| `trees.png` | 64x88 each: oak, oak, pine, pine, blossom, blossom, autumn, autumn, violet, violet |
| `rocks.png` | 48x40 each, 3 ore rocks |
| `x_*.png` | one sprite each (inn, watchtower, outpost, headframe, mine entrance, carts, racks...), anchored bottom-centre |
| `castle.png`, `forge.png`, `towers.png`, `market.png`, `items.png`, `wall_stone.png` | single sprites or small strips |

Good tools for editing pixel art: Aseprite (paid, the industry favourite), LibreSprite or Piskel (free).

## Put it on an Android phone

1. In Godot: Editor > Manage Export Templates > Download and Install.
2. Install Android Studio (for the Android SDK) and OpenJDK 17.
3. In Godot: Editor > Editor Settings > Export > Android, set the SDK path and Java path.
4. Project > Export > Add > Android. Godot will create a debug keystore for testing.
5. Connect your phone with USB debugging on, then use the Android icon in the top right of the editor to run it on the phone.

For the Play Store you'll export an AAB file signed with your own release keystore.
Keep that keystore safe: you need the same one for every future update.
