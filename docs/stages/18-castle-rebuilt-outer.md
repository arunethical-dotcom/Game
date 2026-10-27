# Stage 18: Royal Castle rebuilt from scratch, outer layer

**Commit:** see docs/README.md

## Why
- **Invisible walls:** the stage-17 castle worked out where you could walk from the picture itself, which left invisible walls in places.
- **New reference:** the castle also had a new reference picture (`source_art/castle8/castle_ref.png`) and a full set of coworker assets (S-001 to S-079).
- **Clean slate:** all old castle data (`art/castle4` to `art/castle7`) was deleted and the castle was started again.

## What was built (outer layer)
- **Water and land:** the lake and moat, land with trees, and rocky cliffs around the castle.
- **Outer barbican wall:**
  - roofless turrets and two flag towers;
  - two waterfalls under the wall;
  - rocky islets in the moat.
- **Approach:** the causeway with torches and two gatehouses, outer and inner.
- **Main wall:** towers standing in the water, including the two big water towers.
- **Perimeter:** the west and east towers, bridges, wall-walks and the back wall.
- **Inside:** plain paving for now. Interior buildings come in later stages.

![overview](18-overview.png)
![outer gate](18-outer-gate.png)

## How
- **Coordinates:** `tools/castle8_build.py` places everything in reference pixels; 1 ref px = 3.5 world px.
- **Assets:**
  - Each one is cut from its magenta sheet and shrunk by area averaging, with hard alpha.
  - **Tilt fix:** the generator tilted the "straight" wall (its foot dropped 0.40 per px) and the diagonal one (0.58 instead of 0.5). Each column is remapped so the front face becomes an exact rectangle at the right slope. Verticals stay vertical; nothing is rotated.
- **Towers:** a body segment (with or without a banner), stacked taller with plain masonry where needed, plus the conical roof.
- **Walking is explicit:**
  - Kael can walk only on the causeway strip (through both gate arches) and the inner enclosure polygon.
  - Collision boxes are made only from those shapes, never from the picture.
  - So there are no invisible walls inside them, and the moat and walls always block.
- **Game side:** `scripts/castle_outer.gd` loads the chunks using `meta.json`. In `scripts/geo.gd`, `Geo.rp(x, y)` now takes reference px.

## Tests
- **Walk test** (`castlewalk8.gd`):
  - up the causeway, through both gates, and over the bridge;
  - round all four sides and both diagonals of the courtyard;
  - **blocked as expected:** the moat and the front wall stop Kael.
- **Mission 1** completes in the full game.

## Next
- **Inner layer:** the palace, cathedral, domed hall, manor, market, training yard, gardens, fountain and terraces, each with its own walkable area.
