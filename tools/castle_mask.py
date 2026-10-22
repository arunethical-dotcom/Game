"""Build the Royal Castle's walk / depth data from the reference painting.

The castle is drawn from source_art/castle3/reference_map.png itself (3x, nearest), so it
matches the reference exactly: every tower, wall, building and tree. This script works out,
for every pixel of the painting:
  - walkable ground (authored polygons below, minus water, trees, statues)
  - water (by colour)
  - upright things (everything else: walls, towers, roofs, trees, statues) and the y of
    their base, found by scanning down each column to the ground. The game redraws upright
    pixels over Kael when their base is south of his feet, so he walks behind towers,
    trees and statues.
Outputs (art/castle3/):
  ref_depth.png        R,G = base y (16 bit, painting px), B = 0 ground / 128 water / 255 upright
  ref_collision.json   solid boxes in painting px [x, y, w, h]
  ref_walk_debug.png   preview: walkable green, water blue, upright red
Run: python3 castle_mask.py
"""
import json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

REF = "../source_art/castle3/reference_map.png"
OUT = '../art/castle3/'
W, H = 1536, 1024
MID = 768


def mirror(poly):
    return [(2 * MID - x, y) for (x, y) in poly][::-1]


# Walkable ground, west half (mirrored for the east), in painting px.
WALK_WEST = [
    [(742, 440), (768, 440), (768, 1024), (742, 1024)],                                     # avenue, gates, causeway
    [(436, 498), (768, 498), (768, 552), (680, 552), (672, 562), (600, 564), (592, 574),
     (482, 576), (436, 546)],                                                              # courtyard and its lawns
    [(604, 330), (768, 330), (768, 498), (640, 498), (640, 396), (604, 396)],              # fountain plaza, garden lawns
    [(738, 208), (768, 208), (768, 345), (738, 345)],                                      # grand stairs and palace door
    [(376, 556), (440, 556), (482, 576), (470, 606), (376, 606)],                          # path past the chapel to the side yard
    [(430, 536), (492, 536), (492, 584), (430, 584)],                                      # lawn joining the courtyard and the path
]
WALK_EXTRA = [
    [(272, 523), (394, 523), (394, 560), (335, 558), (330, 536), (280, 536)],              # west market yard
    [(1140, 512), (1278, 512), (1278, 570), (1240, 572), (1240, 600), (1140, 600)],        # east training ground
]
# solid things inside walkable areas (statues, lamps, fountain rim), mirrored too
SOLID_WEST = [
    [(712, 328), (732, 328), (732, 402), (712, 402)],    # knight statue on its plinth
    [(743, 384), (768, 384), (768, 442), (743, 442)],    # fountain
    [(718, 248), (730, 248), (730, 290), (718, 290)],    # statue on the stair landing
    [(696, 444), (708, 444), (708, 486), (696, 486)],    # angel lamp in the garden
]


def polys():
    walk = []
    for p in WALK_WEST:
        walk += [p, mirror(p)]
    walk += WALK_EXTRA
    solid = []
    for p in SOLID_WEST:
        solid += [p, mirror(p)]
    return walk, solid


def raster(ps):
    im = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(im)
    for p in ps:
        d.polygon(p, fill=255)
    return np.array(im) > 0


def build():
    ref = np.array(Image.open(REF).convert('RGB')).astype(int)
    r, g, b = ref[..., 0], ref[..., 1], ref[..., 2]
    walk_p, solid_p = polys()
    walk = raster(walk_p) & ~raster(solid_p)
    water = (b > r + 60) & (g > r + 25) & (b > 100) & (g > 55)
    water = ndimage.binary_opening(water, iterations=1)
    water &= ~raster(solid_p)
    # inside the castle grounds only the garden pools are water (blue roofs and shadows are not)
    pools = raster([[(512, 478), (592, 478), (592, 508), (512, 508)], [(944, 478), (1024, 478), (1024, 508), (944, 508)]])
    water &= ~walk | pools
    # trees: dark conifers inside walkable areas
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    tree = walk & (g > r + 18) & (lum < 105) & ~water
    tree = ndimage.binary_opening(tree, iterations=1)
    tree = ndimage.binary_closing(tree, iterations=2) & walk
    lab, n = ndimage.label(tree)
    sizes = ndimage.sum(tree, lab, range(1, n + 1))
    tree = np.isin(lab, np.where(sizes >= 40)[0] + 1)
    ground = walk & ~water & ~tree
    up = ~ground & ~water
    # base of every upright pixel: scan down its column to the first ground or water pixel
    base = np.zeros((H, W), np.int32)
    for x in range(W):
        col = up[:, x]
        nxt = H - 1
        for y in range(H - 1, -1, -1):
            if not col[y]:
                nxt = y
            base[y, x] = nxt
    # collision: everything not walkable, except tree canopies (only the trunk band is solid)
    solid = ~walk | water
    if True:
        tl, tn = ndimage.label(tree)
        for i, sl in enumerate(ndimage.find_objects(tl)):
            ys, xs = sl
            m = tl[sl] == i + 1
            bottom = ys.stop
            cx = (xs.start + xs.stop) // 2
            solid[max(0, bottom - 4):bottom, max(0, cx - 3):cx + 3] = True
    depth = np.zeros((H, W, 4), np.uint8)
    depth[..., 0] = (base >> 8) & 255
    depth[..., 1] = base & 255
    depth[..., 2] = np.where(up, 255, np.where(water, 128, 0))
    depth[..., 3] = 255
    Image.fromarray(depth, 'RGBA').save(OUT + 'ref_depth.png')
    # merge solid cells (2 px) into row runs
    C = 2
    gs = solid[:H // C * C, :W // C * C].reshape(H // C, C, W // C, C).any(axis=(1, 3))
    boxes = []
    for j in range(gs.shape[0]):
        row = gs[j]
        i = 0
        while i < len(row):
            if row[i]:
                k = i
                while k < len(row) and row[k]:
                    k += 1
                boxes.append([i * C, j * C, (k - i) * C, C])
                i = k
            else:
                i += 1
    # merge vertically identical runs
    merged = {}
    out = []
    for bx in boxes:
        key = (bx[0], bx[2])
        if key in merged and merged[key][1] + merged[key][3] == bx[1]:
            merged[key][3] += C
        else:
            nb = list(bx)
            merged[key] = nb
            out.append(nb)
    json.dump(out, open(OUT + 'ref_collision.json', 'w'))
    dbg = ref.copy().astype(float) * 0.5
    dbg[ground] = dbg[ground] * 0.5 + np.array([0, 255, 0]) * 0.5
    dbg[water] = dbg[water] * 0.5 + np.array([0, 80, 255]) * 0.5
    dbg[tree] = dbg[tree] * 0.5 + np.array([255, 255, 0]) * 0.5
    Image.fromarray(dbg.astype(np.uint8)).save(OUT + 'ref_walk_debug.png')
    print(len(out), 'collision boxes; walkable', ground.mean(), 'trees', ndimage.label(tree)[1])


if __name__ == '__main__':
    build()
