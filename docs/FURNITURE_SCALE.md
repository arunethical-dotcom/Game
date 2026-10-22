# Furniture scale audit (stage 11)

Every prop was measured in game pixels against **Kael (64 px tall, about 1.75 m)** and the
**32 px tile**. Target heights:

- Chairs and stools: 26–45 px.
- Tables and desks: 28–45 px.
- Beds: 40–60 px deep.
- Wardrobes and shelves: 45–90 px.
- Doors: about 72 px.

| Group | Scale on import | Why |
|-------|-----------------|-----|
| Walls, towers, gates, roofs, stairs, banners, lighting, vegetation, royal props | 1 (native) | Already drawn to match Kael |
| Furniture, library props, treasury and bath props | 1 (native) | Sofa 49 px, armchair 49, wardrobe 73, bookshelf 47, single bed 61: all correct next to Kael |
| Kitchen props (barrels, pots, sacks) | 2/3 | Drawn oversized on the sheet; a barrel becomes 43 px, chest-high to Kael |
| `bed_canopy`, `chair_blue_high`, `chair_blue_tall`, `globe_large` | 2/3 (individually) | These four were drawn much larger than the rest |

These scales are set in `SCALE2` and `SCALE2_ITEMS` in `tools/import_castle.py`.
Furniture had been scaled down by 2/3 before this stage, which is why it looked like toys.
