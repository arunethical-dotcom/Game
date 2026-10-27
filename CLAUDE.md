# Akropolis Aigidos: project guide for Claude Code

Offline 2D top-down 3/4-view medieval RPG for Android, built in **Godot 4.7** (GL Compatibility
renderer) with GDScript. The hero is **Kael**, a 19-year-old from conquered Kingdom A who works
for Haldor the blacksmith in Kingdom B's capital. Part 1 has no magic.

## Ground rules
- **Strictly 2D pixel art:** nearest-neighbour filtering only, no blur, no 3D.
- **Protected systems:** don't rewrite the player controller, combat, Mission 1, the HUD,
  the camera or the colour grade unless the task asks for it.
- **Keep it tested:** after every change, run the game, look at screenshots, and run the tests below.
- **Document every stage:** each stage of work gets a page in `docs/stages/NN-name.md`
  (copy `TEMPLATE.md`) and a row in `docs/README.md`, added in the same commit.
- **Commit and push** to `main` when a stage works.

## Scale and display
- The game renders at 960×540 and is scaled up by a whole number (2× on a 1080p phone).
  The camera always lands on whole pixels.
- Kael is 64 px tall (96×96 px frames, feet at y=88). Ground tiles are 32 px. Walk speed is 210 px/s.
- Everything upright is y-sorted in `main.entity_layer` by its feet position.
- Ground drawing goes in `main.ground_layer`.

## Where things live
| Path | What |
|------|------|
| `scripts/main.gd` | Builds the scene, runs the mission, camera zones, stairs/floors. `CASTLE_ONLY := true` shows only the castle |
| `scripts/geo.gd` | Layout constants. Castle map origin `CASTLE_O`, scale `CASTLE_S`, `Geo.rp(x, y)` converts castle-map px to world px |
| `scripts/castle_outer.gd` | The Royal Castle: loads the composited chunks (`art/castle8/out/`), occluder shader, collision, lights |
| `tools/castle8_build.py` | Builds the castle from `source_art/castle8/` (reference + coworker assets) in reference px; the layout tables and the walkable polygons are at the top. Run `python3 castle8_build.py` in `tools/` |
| `tools/import_castle*.py` | Magenta-sheet importers (background removal, cutting, scaling) |
| `scripts/light_layer.gd`, `grade.gd` | Warm local lights and per-room colour grading |
| `docs/` | Development log, one page per stage |

## Asset rules
- **Source art:** AI sheets in `source_art/` on a #FF00FF magenta background.
- **Importing a sheet:**
  - Remove the magenta and its pink fringe.
  - Cut each object into its own sprite.
  - Resample to the target size, then quantize (no dithering) so pixels are hard-edged.
  - Use hard alpha (fully opaque or fully transparent).
  - Set the pivot at the bottom centre.
- **Scale:** objects are compared against Kael (64 px) and the castle map. One map-1728 px = 2.5 world px.

## How to test
- **Import:** `godot --headless --path . --import`
- **Quick run:** add a temporary `autotest.gd` child node from `main._ready()` that drives the
  player, prints results and quits. Never commit it.
- **Screenshots:** run with a display (`xvfb-run` on a server, or normally on a desktop), save
  `get_viewport().get_texture().get_image()` in `_process` after `RenderingServer.frame_post_draw`.
  Use 2392×1080 for the phone (Nothing Phone 3a Pro).

## Current state
Stage 18: the outer castle is rebuilt from `source_art/castle8/castle_ref.png`. Next: the inner layer (see `docs/stages/18-castle-rebuilt-outer.md`). Walking is defined only by the walkable polygons in `castle8_build.py`.
