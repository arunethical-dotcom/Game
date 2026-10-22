# Stage 5: Stable display

**Commit:** `62c6d0b` · **Date:** 2026-10-21

## Goal
Walls and buildings shook while Kael walked, and the game window couldn't be closed on a computer.

## What changed
- **Integer scaling:** the game renders at 960×540 and is scaled up by a whole number (2× on
  a 1080p phone), so every art pixel stays a crisp square.
- **Pixel-snapped camera:** the camera eases toward Kael, then rounds to a whole pixel, and screen
  shake is rounded too. Godot's 2D transform and vertex snapping are turned on.
- **Nearest-neighbour filtering** for every texture, so nothing gets blurred.
- **Desktop window:** opens maximised and scales smoothly; Esc quits.

## How it was checked
Consecutive frames were compared after a whole-pixel camera move, and the scenery matched 100%.
