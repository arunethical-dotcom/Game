# Stage 3: World clarity and interface

**Commit:** `8321333` · **Date:** 2026-10-21

## Goal
The first version's pixels were too large and its colours too dull. Match the colour-graded
reference image and make the world clearer.

## What changed
- Finer pixel art throughout: ground tiles, trees, houses and characters were redrawn at a
  smaller pixel size.
- More colourful palettes for grass, roofs, flowers and roads.
- A full-screen colour grade (`grade.gd`, `grade.gdshader`) that adds warm highlights and a light vignette.
- The interface was framed in wood and gold, with a custom health bar (`hp_bar.gd`).
- Git workflow: Claude pushes to `arunethical-dotcom/Game` and the team runs `git pull`.

## Where it lives
`tools/make_tiles.py`, `make_flora.py`, `make_props.py`, `make_ui.py`, `scripts/grade.gd`, `scripts/hud.gd`.
