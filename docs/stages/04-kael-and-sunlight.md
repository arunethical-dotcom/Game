# Stage 4: Kael's animations and sunlight

**Commit:** `75e5e53` · **Date:** 2026-10-21

## Goal
Use the hand-picked Kael sprite sheets and make sunlight feel real, falling from the sky to the ground.

## What changed
- **Kael:** the four supplied sheets (idle, walk, attack, roll, hurt) are imported by
  `tools/import_kael.py` into 96×96 frames, with his feet at y=88 and his body 64 px tall.
  `player.gd` picks the frame from his state and facing, and mirrors the sheets for left.
- **Sunlight:** diagonal sun shafts that drift slowly, a warm glow from the sun's corner,
  and dust specks in the beams. They are fixed to the world, so they don't slide with the camera.

## Where it lives
`source_art/kael/` (the original sheets), `tools/import_kael.py`, `scripts/player.gd`, `scripts/grade.gdshader`.
