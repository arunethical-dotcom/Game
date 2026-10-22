# Stage 2: Mark I prototype

**Commit:** `dc2fead` · **Date:** 2026-10-21

## Goal
A complete, playable first version on a phone: walk the city, leave the walls, fight, and
finish Mission 1.

## What changed
- **Engine:** Godot 4 (GL Compatibility renderer, which suits phones), written in GDScript.
- **Akropolis Aigidos:** a walled city with a ring road, spoke streets, a market, fields,
  houses and Haldor's forge yard.
- **Open world:** ground is streamed in 16×16-tile chunks around the player (`world.gd`), so
  there is never a loading screen. Biomes: city, plateau, cliffs, forest, mountains, stream.
- **Landmarks:** an inn, an outpost, a mine, watchtowers, the Serpent's Way and the Elder path,
  a ramp down the cliffs, the quarry and the beast den.
- **Combat:**
  - Kael can attack, do a heavy slam that leaves a crater, and dodge-roll.
  - Taking damage plays a hurt reaction, and losing all health knocks him down.
  - Terrak beasts roam, chase and lunge, and a leader commands the pack.
- **Mission 1** flows through these stages: start, gather ore, forge, hunt, return, done.
  - A guide arrow points along roads and through gates to the next goal.
  - Dialogue lives in `story.gd`.
- **Touch controls:** a joystick plus buttons for Attack, Slam, Dodge and Talk. A minimap.
- **Android:** an export preset; the APK was installed on a Nothing Phone (3a) Pro.

## Where it lives
| File | Role |
|------|------|
| `scripts/main.gd` | Builds the scene layers, runs the mission, camera, talking |
| `scripts/geo.gd` | All layout constants, biomes, guide-arrow routing |
| `scripts/world.gd`, `chunk.gd` | Streaming ground chunks, trees, bushes |
| `scripts/city.gd`, `paving.gd` | City walls, houses, market, roads |
| `scripts/player.gd`, `beast.gd`, `npc.gd` | Kael, the Terrak, townsfolk |
| `scripts/hud.gd`, `joystick.gd`, `touch_button.gd`, `minimap.gd` | Interface |
| `tools/*.py` | Python scripts that draw all the pixel art |

## How it was checked
A headless auto-walk test plays the whole mission from start to finish.
