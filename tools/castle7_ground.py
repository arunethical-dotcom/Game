"""Ground for the stage-17 castle: water, grass, paving, sand, rock and paths, drawn as
pixel art at 2 world px per pixel (the same pixel size as the 2x castle pieces), in colours
taken from the castle6 sheets. Seamless by construction (procedural), so no tile joins.

Where each kind of ground goes comes from the castle map: a blurred copy is classified by
colour outside the walls; inside, the walkable areas (castle_mask4.py's traced polygons)
decide paving / lawn / sand.

trees(): places pines/cypresses where the map has tree crowns.
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

import castle_mask4 as cm

MAPN = 1728


def hexc(s):
    s = s.lstrip('#')
    return [int(s[i:i + 2], 16) for i in (0, 2, 4)]


PAL = {
    # sampled from the castle6 sheets (water tiles, grass tiles, paving plates, market sand)
    'water': [hexc(c) for c in ('0f3f8c', '1553ab', '1f68c4', '2f80d8', '5aa6ea', 'bfe8fb')],
    'grass': [hexc(c) for c in ('2c5a26', '3a7228', '4b8a2c', '62a335', '7fbb45')],
    'forest': [hexc(c) for c in ('1f4a24', '2b5e28', '386f2b', '4a8430', '5f9a38')],
    'pave': [hexc(c) for c in ('6f6662', '8e847b', 'a89d90', 'c2b6a6', 'd8cdbb')],
    'sand': [hexc(c) for c in ('8a5a32', 'a9733f', 'c08d52', 'd4a668', 'e3bd82')],
    'rock': [hexc(c) for c in ('2e3142', '444a5e', '5d647a', '7b8296', '9ea4b3')],
    'path': [hexc(c) for c in ('7a5532', '946a3f', 'ad8250', 'c39b66', 'd6b27c')],
}
CLASSES = ['water', 'grass', 'forest', 'pave', 'sand', 'rock', 'path']


def walk_mask():
    """The traced walkable areas (864 map) at 1728 map resolution."""
    ps = []
    for p in cm.WALK_WEST:
        ps += [p, cm.mirror(p)]
    im = Image.new('L', (MAPN, MAPN), 0)
    d = ImageDraw.Draw(im)
    for p in ps:
        d.polygon([(x * 2, y * 2) for x, y in p], fill=255)
    return np.array(im) > 0


def classify(refmap):
    m = np.array(Image.fromarray(refmap.astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))).astype(int)
    r, g, b = m[..., 0], m[..., 1], m[..., 2]
    mx, mn = m.max(2), m.min(2)
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    sat = mx - mn
    cls = np.full((MAPN, MAPN), CLASSES.index('grass'))
    water = (b > r + 70) & (b > g + 25) & (g > r + 20)
    rock = (sat < 55) & (lum < 150) & ~water & (lum > 50)
    pave = (sat < 60) & (lum >= 150)
    sand = (r > g + 25) & (g > b + 15) & (r > 120)
    forest = (g > r + 15) & (lum < 105)
    cls[forest] = CLASSES.index('forest')
    cls[rock] = CLASSES.index('rock')
    cls[pave] = CLASSES.index('pave')
    cls[sand] = CLASSES.index('path')
    cls[water] = CLASSES.index('water')
    # inside the castle: the walkable areas are paving, lawn or sand; the rest is paving
    # under the buildings, except open water (moats, channels)
    walk = walk_mask()
    inner = np.zeros((MAPN, MAPN), bool)
    inner[330:1185, 200:1528] = True
    green = (g > r + 4) & (g > b - 6)
    # lawns only where the map has a real garden (big green areas), sand only in the yards
    green = ndimage.binary_opening(green, iterations=5)
    green = ndimage.binary_closing(green, iterations=4)
    ins = np.where(green, CLASSES.index('grass'), CLASSES.index('pave'))
    yards = np.zeros_like(green)
    for x0, y0, x1, y1 in ((200, 900, 430, 1080), (1298, 900, 1528, 1080)):
        yards[y0:y1, x0:x1] = True

    cls = np.where(inner | walk, ins, cls)
    # majority filter: drop specks
    oh = np.stack([(cls == i).astype(np.float32) for i in range(len(CLASSES))])
    oh = np.stack([ndimage.uniform_filter(o, 13) for o in oh])
    return oh, walk


def noise(h, w, cell, seed):
    rng = np.random.default_rng(seed)
    gh, gw = h // cell + 2, w // cell + 2
    gr = rng.random((gh, gw)).astype(np.float32)
    yy = (np.arange(h) / cell)[:, None]
    xx = (np.arange(w) / cell)[None, :]
    y0, x0 = yy.astype(int), xx.astype(int)
    fy, fx = yy - y0, xx - x0
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = gr[y0, x0] * (1 - fx) + gr[y0, x0 + 1] * fx
    b = gr[y0 + 1, x0] * (1 - fx) + gr[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


def tex_tones(h, w, seed, cells=(40, 11), bias=0.0, n=5):
    v = noise(h, w, cells[0], seed) * 0.6 + noise(h, w, cells[1], seed + 1) * 0.4 + bias
    return np.clip(((v - 0.2) / 0.6 * (n - 1)).round(), 0, n - 2).astype(int) + 1 * 0


def cobbles(h, w, seed):
    """Voronoi cobbles: tone index per pixel (0 = mortar)."""
    rng = np.random.default_rng(seed)
    cs = 7
    gh, gw = h // cs + 3, w // cs + 3
    jx = rng.integers(1, cs - 1, (gh, gw))
    jy = rng.integers(1, cs - 1, (gh, gw))
    tone = rng.integers(2, 4, (gh, gw))
    yy, xx = np.mgrid[0:h, 0:w]
    gy, gx = yy // cs, xx // cs
    d1 = np.full((h, w), 1e9, np.float32)
    d2 = np.full((h, w), 1e9, np.float32)
    t = np.zeros((h, w), int)
    cx = np.zeros((h, w), np.float32)
    cy = np.zeros((h, w), np.float32)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            ny = np.clip(gy + oy, 0, gh - 1)
            nx = np.clip(gx + ox, 0, gw - 1)
            px = nx * cs + jx[ny, nx]
            py = ny * cs + jy[ny, nx]
            d = ((xx - px) * 0.85) ** 2 + (yy - py) ** 2
            m = d < d1
            d2 = np.where(m, d1, np.minimum(d2, d))
            t = np.where(m, tone[ny, nx], t)
            cx = np.where(m, px, cx)
            cy = np.where(m, py, cy)
            d1 = np.where(m, d, d1)
    edge = np.sqrt(d2) - np.sqrt(d1)
    lit = (xx - cx) * 0.7 + (yy - cy)
    out = t.copy()
    out = np.where(lit < -2.2, np.minimum(t + 1, 4), out)
    out = np.where(lit > 2.2, np.maximum(t - 1, 1), out)
    out = np.where(edge < 1.0, 0, out)
    return out


def make(N, K):
    refmap = np.array(Image.open(cm.SRC).convert('RGB')).astype(np.float32)
    oh, walk = classify(refmap)
    h = N // 2
    # class probabilities up to half canvas res (2 world px per pixel), smooth edges
    up = np.stack([np.array(Image.fromarray(o).resize((h, h), Image.Resampling.BILINEAR)) for o in oh])
    cls = up.argmax(0)
    col = np.zeros((h, h, 3), np.uint8)
    for i, name in enumerate(CLASSES):
        m = cls == i
        if not m.any():
            continue
        pal = np.array(PAL[name], np.uint8)
        if name == 'pave':
            t = cobbles(h, h, 11)
        elif name == 'water':
            v = noise(h, h, 34, 21) * 0.55 + noise(h, h, 9, 22) * 0.45
            t = np.clip(((v - 0.25) / 0.5 * 2.4).round(), 0, 2).astype(int) + 1
            yy, xx = np.mgrid[0:h, 0:h]
            s = np.sin(xx * 0.31 + np.sin(yy * 0.17) * 2.2 + yy * 0.9)
            t = np.where((s > 0.985) & (v > 0.45), 4, t)
        elif name in ('grass', 'forest'):
            v = noise(h, h, 30, 31 + i) * 0.6 + noise(h, h, 6, 33 + i) * 0.4
            t = np.clip(((v - 0.2) / 0.6 * 3).round(), 0, 3).astype(int) + 1
            rng = np.random.default_rng(5 + i)
            tuft = rng.random((h, h)) < 0.025
            t = np.where(tuft, 4, t)
            t = np.where(np.roll(tuft, 1, 0), np.maximum(t - 1, 0), t)
        elif name == 'rock':
            # cliff faces: vertical rock columns with lit left edges and dark cracks
            v = noise(h, h, 18, 41)
            colx = (np.arange(h)[None, :] + (noise(h, h, 24, 42) * 14).astype(int)) % 9
            t = np.clip((v * 3).astype(int) + 1, 1, 3)
            t = np.where(colx == 0, 0, np.where(colx == 1, 4, t))
        else:
            v = noise(h, h, 26, 51 + i) * 0.6 + noise(h, h, 5, 52 + i) * 0.4
            t = np.clip(((v - 0.2) / 0.6 * 3).round(), 0, 3).astype(int) + 1
            rng = np.random.default_rng(7 + i)
            t = np.where(rng.random((h, h)) < 0.01, 0, t)
        col[m] = pal[t[m]]
    # edges: a dark curb where paving meets lawn, foam where water meets land
    water = cls == CLASSES.index('water')
    land_next = water & ~ndimage.binary_erosion(water, iterations=1)
    col[land_next] = PAL['water'][5]
    foam2 = water & ~ndimage.binary_erosion(water, iterations=3) & ~land_next
    col[foam2 & ((np.add.outer(np.arange(h), np.arange(h)) % 5) < 2)] = PAL['water'][4]
    pave = cls == CLASSES.index('pave')
    green = (cls == CLASSES.index('grass')) | (cls == CLASSES.index('forest'))
    curb = pave & ndimage.binary_dilation(green, iterations=1)
    col[curb] = PAL['pave'][0]
    full = np.repeat(np.repeat(col, 2, 0), 2, 1)[:N, :N]
    wfull = np.repeat(np.repeat(water, 2, 0), 2, 1)[:N, :N]
    return {'col': full, 'water': wfull, 'cls': cls}


def trees(refmap, K, off):
    """Tree positions from the map's crowns -> [(piece, map x, map base y, mirror)]."""
    m = refmap
    r, g, b = m[..., 0], m[..., 1], m[..., 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    treeish = (g > r + 12) & (g > b - 10) & (lum < 140)
    walk = walk_mask()
    sm = ndimage.gaussian_filter(treeish.astype(np.float32), 5)
    # crowns: local maxima of tree density, spaced like the map's trees
    peaks = (sm == ndimage.maximum_filter(sm, size=22)) & (sm > 0.55)
    ys, xs = np.nonzero(peaks)
    out = []
    rng = np.random.default_rng(9)
    for x, y in zip(xs, ys):
        if any(x0 <= x < x1 and y0 <= y < y1 for x0, y0, x1, y1 in off):
            continue
        inside = 330 < y < 1225 and 200 < x < 1528
        if inside and rng.random() < 0.5:
            name = 'cypress%d' % rng.integers(0, 3)
        else:
            name = 'pine%d' % rng.integers(0, 6)
        out.append((name, float(x), float(y + 14), bool(rng.integers(0, 2))))
    return out


def cliffs(cls, K):
    """Cliff pieces over the map's rock (cliff) areas -> [(piece, map x, map base y, mirror)]."""
    h = cls.shape[0]
    rock = cls == CLASSES.index('rock')
    f = h / MAPN
    out = []
    rng = np.random.default_rng(17)
    names = ['cliff_w07', 'cliff_w08', 'cliff_w09', 'cliff_w36', 'cliff_w37', 'cliff_w39', 'cliff_w40',
             'cliff_t76', 'cliff_t78', 'cliff_t82', 'cliff_t86', 'cliff_t87', 'cliff_t88', 'cliff_t92', 'cliff_t93']
    step = 46
    for my in range(20, MAPN, step):
        for mx in range(20, MAPN, step):
            jx = mx + rng.integers(-14, 15)
            jy = my + rng.integers(-10, 11)
            x0, y0 = int((jx - 20) * f), int((jy - 30) * f)
            x1, y1 = int((jx + 20) * f), int((jy + 5) * f)
            if x0 < 0 or y0 < 0 or x1 >= h or y1 >= h:
                continue
            if 330 < jy < 1225 and 200 < jx < 1528:
                continue
            if 760 < jx < 968 and jy > 1225:
                continue
            if rock[y0:y1, x0:x1].mean() > 0.6:
                out.append((names[rng.integers(0, len(names))], float(jx), float(jy), bool(rng.integers(0, 2))))
    return out
