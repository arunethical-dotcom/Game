# Task: rebuild the Royal Castle from the castle6 asset sheets

## Goal
Build the castle entirely from the new, sharper assets in `source_art/castle6/`, so the castle is
crisp everywhere: walls, towers, trees, water and buildings, not only the buildings. Follow
the layout of the current castle map (`source_art/castle4/castle_map.png`, the approved design)
and keep the castle in the same place (`Geo.CASTLE_O`, 4320×4320 world px).

## The new sheets (`source_art/castle6/`)
| File | Contents |
|------|----------|
| `palace_with_wings.png` | The palace with its wing walls and towers. **Black/transparent background (RGBA), not magenta** |
| `gatehouse_causeway.png` | The main gatehouse, its side walls and the torch-lit causeway |
| `wall_curve_south.png` | The front (south) curtain wall, a curved run of walls and towers |
| `wall_diagonal_west.png` | A diagonal wall run with towers standing in water (the west side; mirror it for the east) |
| `wall_east_bridges.png` | The east wall run with arched bridges, the aqueduct, and the north-east corner |
| `wall_kit.png` | Modular wall pieces, corners, gates, towers, roofs, stairs, bridges and small props |
| `buildings_gardens.png` | Cathedral, manor, domed hall, chapels, market, training yard, angel statues, fountain, pools, raised garden beds, stairs, paving |
| `trees_cliffs.png` | Pines, cypresses, bushes, hedges, grass tiles, cliffs and rocks |
| `water_cliffs_waterfalls.png` | Water tiles, shoreline cliffs, waterfalls and rocks in water |
| `props_banners_statues.png` | Banners, flags, statues, torches, lamps, fountains, benches, fences, market stalls, crates, carts |

## Steps (do them in order, and check screenshots after each)
1. **Import.** Write `tools/import_castle6.py`, based on `tools/import_castle.py` / `import_castle3.py`.
   - **Cutting:** remove the magenta and fringe, and cut every object with connected components.
     The palace sheet's background is black/transparent instead of magenta.
   - **Clean pixels:** hard alpha, a quantized palette, no dithering.
   - **Output:** one PNG per object in `art/castle6/<group>/`, a `manifest.json` with size and
     pivot, and a labelled contact sheet so a human can check the cuts.
   - **Scale:** pick one global scale so the pieces match the castle map (towers about 80–90 px
     wide at map-1728 scale), and draw them at a whole-number scale in game.
2. **Lay out the castle.** Write a placements file in the castle-map coordinates of `castle_map.png`.
   - **Big runs:** place `palace_with_wings`, `gatehouse_causeway`, `wall_curve_south` and the
     diagonal and east wall runs where the map has them. Mirror the west run for the east, since
     the castle is symmetric about x = 864 on the 1728 map.
   - **Buildings:** place the cathedral, domed hall, manor and chapels where the map has them.
   - **Gardens and terraces:** the garden beds, fountain, statues and stairs from `buildings_gardens.png`.
   - **Trees:** match the map's trees by position and count, using the pines and cypresses from `trees_cliffs.png`.
   - **Water and shores:** the water tiles, shore cliffs and the three waterfalls (north-west,
     south-west, south-east).
   - **Ground:** paving and lawns drawn from tiles, not from the old map.
3. **Make it playable.** Update `tools/castle_mask4.py` (or write a new one) so the walk, water and
   collision data still match. Keep the existing walkable routes: the causeway, both gates, the
   avenue, the fountain plaza, the grand stairs to the palace door, both courtyards, the market
   and the training ground. Upright sprites are y-sorted by their base, so Kael walks behind
   them correctly.
4. **Verify.**
   - Re-run the walk test (see `CLAUDE.md`).
   - Run Mission 1 with `CASTLE_ONLY := false`.
   - Take screenshots at 2392×1080: the whole castle, the gate, the fountain plaza, the palace
     stairs, the market and the training ground. Compare them side by side with `castle_map.png`.
5. **Document and push.** Write `docs/stages/17-castle-from-kit6.md`, add the row in
   `docs/README.md`, commit and push.

## Don't
- Don't stretch sprites to fit.
- Don't use the soft old map as visible ground.
- Don't change Kael, combat or the quest.
