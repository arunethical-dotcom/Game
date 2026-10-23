"""Royal Castle v4: clean the new castle map into crisp pixel art and build its walk /
depth / collision data.

  source_art/castle4/castle_map.png (1728 x 1728, soft AI pixel art)
    -> art/castle4/castle_map.png   864 x 864, re-pixelised: downscaled 2x on the art's
                                     own pixel grid, sharpened, reduced to 128 colours with
                                     no dithering, so every pixel is a hard-edged block
    -> art/castle4/ref_depth.png    per pixel: ground / water / upright + base y
    -> art/castle4/ref_collision.json
    -> art/castle4/ref_walk_debug.png
The game shows the map at 5x (4320 x 4320 world px). Walkable ground is traced as polygons
on the 864 px map (west half, mirrored for the east: the castle is symmetric).
"""
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

SRC = '../source_art/castle4/castle_map.png'
OUT = '../art/castle4/'
N = 864
MID = 432


def repixelise():
    src = Image.open(SRC).convert('RGB')
    small = src.resize((N, N), Image.Resampling.LANCZOS).filter(ImageFilter.UnsharpMask(1, 80, 1))
    q = small.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB')
    q.save(OUT + 'castle_map.png')
    return np.array(q).astype(int)


def mirror(poly):
    return [(2 * MID - x, y) for (x, y) in poly][::-1]


WALK_WEST = [
    [(420, 600), (432, 600), (432, 864), (420, 864)],          # causeway
    [(421, 496), (432, 496), (432, 600), (421, 600)],          # gatehouses
    [(416, 228), (432, 228), (432, 320), (416, 320)],          # grand stairs
    [(398, 204), (432, 204), (432, 228), (398, 228)],          # palace door
    [(321, 318), (432, 318), (432, 498), (321, 498)],          # fountain plaza, garden beds, lower plaza
    [(247, 452), (321, 452), (321, 492), (337, 492), (337, 514), (247, 514)],   # west courtyard and lawn
    [(298, 444), (321, 444), (321, 452), (298, 452)],
    [(204, 436), (247, 436), (247, 462), (204, 462)],          # terrace path to the market
    [(150, 462), (210, 462), (206, 522), (150, 522)],          # market yard
]
SOLID_WEST = [
    [(398, 346), (410, 346), (410, 362), (398, 362)],          # knight statue's plinth
    [(418, 366), (432, 366), (432, 400), (418, 400)],          # fountain
    [(382, 420), (394, 420), (394, 446), (382, 446)],          # angel brazier
    [(270, 454), (300, 454), (300, 476), (270, 476)],          # garden pool
]


def raster(ps):
    im = Image.new('L', (N, N), 0)
    d = ImageDraw.Draw(im)
    for p in ps:
        d.polygon(p, fill=255)
    return np.array(im) > 0


def build():
    ref = repixelise()
    r, g, b = ref[..., 0], ref[..., 1], ref[..., 2]
    walk_p = []
    for p in WALK_WEST:
        walk_p += [p, mirror(p)]
    solid_p = []
    for p in SOLID_WEST:
        solid_p += [p, mirror(p)]
    walk = raster(walk_p) & ~raster(solid_p)
    water = (b > r + 50) & (b > 120) & (g > r)
    water = ndimage.binary_opening(water, iterations=1) & ~walk
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    tree = walk & (g > r + 6) & (g > b - 14) & (lum < 128)
    tree = ndimage.binary_opening(tree, iterations=1)
    tree = ndimage.binary_closing(tree, iterations=2)
    tree = ndimage.binary_fill_holes(tree)
    # grow into the tree's bright, sunlit side (still green, brighter than the lawn's shade)
    bright = (g > r + 6) & (g > b - 20) & (lum < 175)
    for _ in range(3):
        tree = tree | (ndimage.binary_dilation(tree) & bright)
    tree &= walk
    lab, n = ndimage.label(tree)
    sizes = ndimage.sum(tree, lab, range(1, n + 1))
    tree = np.isin(lab, np.where(sizes >= 25)[0] + 1)
    ground = walk & ~tree
    up = ~ground & ~water
    base = np.zeros((N, N), np.int32)
    for x in range(N):
        col = up[:, x]
        nxt = N - 1
        for y in range(N - 1, -1, -1):
            if not col[y]:
                nxt = y
            base[y, x] = nxt
    solid = ~walk
    tl, _ = ndimage.label(tree)
    for sl in ndimage.find_objects(tl):
        ys, xs = sl
        cx = (xs.start + xs.stop) // 2
        solid[max(0, ys.stop - 3):ys.stop, max(0, cx - 2):cx + 2] = True
    depth = np.zeros((N, N, 4), np.uint8)
    depth[..., 0] = (base >> 8) & 255
    depth[..., 1] = base & 255
    kind = np.where(up, 255, np.where(water, 128, 0))
    # pixels covered by a crisp castle5 sprite: the sprite (y-sorted) handles drawing over Kael
    try:
        cover = np.array(Image.open('../art/castle5/cover.png')) > 0
        kind = np.where(cover & up, 64, kind)
    except FileNotFoundError:
        pass
    depth[..., 2] = kind
    depth[..., 3] = 255
    Image.fromarray(depth, 'RGBA').save(OUT + 'ref_depth.png')
    boxes = []
    for j in range(N):
        row = solid[j]
        i = 0
        while i < N:
            if row[i]:
                k = i
                while k < N and row[k]:
                    k += 1
                boxes.append([i, j, k - i, 1])
                i = k
            else:
                i += 1
    merged = {}
    out = []
    for bx in boxes:
        key = (bx[0], bx[2])
        if key in merged and merged[key][1] + merged[key][3] == bx[1]:
            merged[key][3] += 1
        else:
            nb = list(bx)
            merged[key] = nb
            out.append(nb)
    json.dump(out, open(OUT + 'ref_collision.json', 'w'))
    dbg = ref.astype(float) * 0.5
    dbg[ground] = dbg[ground] * 0.5 + np.array([0, 255, 0]) * 0.5
    dbg[water] = dbg[water] * 0.5 + np.array([0, 80, 255]) * 0.5
    dbg[tree] = dbg[tree] * 0.5 + np.array([255, 255, 0]) * 0.5
    Image.fromarray(dbg.astype(np.uint8)).save(OUT + 'ref_walk_debug.png')
    print(len(out), 'collision boxes')


if __name__ == '__main__':
    import os
    os.makedirs(OUT, exist_ok=True)
    build()
