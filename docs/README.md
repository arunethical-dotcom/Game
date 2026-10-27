# Development log

See also: [the world map](MAP.md). (CITADEL_DIMENSIONS.md describes the previous citadel, replaced in stage 13.)

This folder records how the game was built, one page per stage, so that anyone who joins
the team can see what was decided, why, and where it lives in the code.

| # | Stage | Commit | What it delivered |
|---|-------|--------|-------------------|
| 1 | [Concept and story](stages/01-concept-and-story.md) | – | Game idea, story of Kael, design rules (offline, 2D, open world) |
| 2 | [Mark I prototype](stages/02-mark-1-prototype.md) | `dc2fead` | Playable Godot game: city, open world, combat, Mission 1, Android build |
| 3 | [World clarity and interface](stages/03-world-clarity-and-interface.md) | `8321333` | Finer, more colourful art, colour grade, framed HUD |
| 4 | [Kael's animations and sunlight](stages/04-kael-and-sunlight.md) | `75e5e53` | Kael's new sprite sheets, sun shafts |
| 5 | [Stable display](stages/05-stable-display.md) | `62c6d0b` | Whole-pixel scaling and camera, no shimmer, Esc to quit |
| 6 | [Royal Citadel, main floor](stages/06-royal-citadel.md) | `c6f7849` | The castle at the centre of Akropolis Aigidos |
| 7 | [Citadel visual upgrade](stages/07-citadel-visual-upgrade.md) | `9f75ca1` | Imported castle art, working stairs, 3 floors, open interiors |
| 8 | [Colour correction](stages/08-colour-correction.md) | `f8f4452` | Diagnosed and fixed colours: importer, grade, lighting |
| 9 | [CrossCode-style camera](stages/09-camera-zones.md) | `5281976` | Camera zones, look-ahead, framed rooms, conversation framing |
| 10 | [Royal Citadel v2, main floor](stages/10-citadel-v2-main-floor.md) | `c95b8f4` | 100×90-tile citadel from the approved plan, atlas 2 imported, city grown 1.45× |
| 11 | [Main-floor visual polish](stages/11-main-floor-polish.md) | `4b6061a` | Grand throne hall, furniture scale audit, zoned royal wings, unique gardens, local lighting, S4 sealed, interior camera |
| 12 | [Living colour grading](stages/12-colour-grading.md) | `5868244` | Per-room grading profiles, local flame lighting on every floor, time of day (day/afternoon/sunset/night) |
| 13 | [Royal Castle from scratch: outer layer](stages/13-royal-castle-outer.md) | `571e9f3` | Castle on its own lake south of the city at real scale, walls, towers, barbican, bridges, waterfalls; city centre becomes a town square |
| 14 | [The castle's whole outer shell, traced](stages/14-castle-shell-traced.md) | `747ed4b` | Castle traced from the reference at the kit's own scale: real outline with diagonal walls, every building, garden and tower in place; castle-only view |
| 15 | [The castle matches the reference exactly](stages/15-castle-from-painting.md) | `3aee3a9` | Castle drawn from the reference painting; walkable areas, water, depth and collision generated from it; Kael walks behind towers and trees |
| 16 | [Crisper castle from the high-quality kit](stages/16-castle-crisp-kit.md) | `efdfafc` | New 1728 px castle map cleaned into crisp pixel art; palace, cathedral, domed hall, manor, towers and statues replaced by crisp kit sprites placed by template matching |
| 17 | [Castle built from the castle6 sheets](stages/17-castle-from-kit6.md) | `71ab6ed` | Whole castle composited from the castle6 sheets into one seamless image at native pixels; depth-sorted pieces, wall runs, generated ground, footprint collision |
| 18 | [Castle rebuilt from scratch: outer layer](stages/18-castle-rebuilt-outer.md) | `fef056f` | Old castle data deleted; outer castle built from the new reference and the coworkers' assets; tilted walls straightened; walking defined explicitly (no invisible walls) |
| 19 | [Outer castle from a traced blueprint](stages/19-castle-from-blueprint.md) | (this commit) | Reference traced into an exact blueprint (towers, walls, bridges, walkways, palace, causeway); walls run tower to tower as single strips; exact mirror; land trimmed to the castle |

**Adding a stage:** copy [stages/TEMPLATE.md](stages/TEMPLATE.md) to the next number, fill
it in, and add a row to the table above in the same commit as the work.
