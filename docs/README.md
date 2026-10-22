# Development log

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

**Adding a stage:** copy [stages/TEMPLATE.md](stages/TEMPLATE.md) to the next number, fill
it in, and add a row to the table above in the same commit as the work.
