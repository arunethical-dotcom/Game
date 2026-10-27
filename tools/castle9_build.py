"""The Royal Castle built from the blueprint (source_art/castle8/blueprint.json), which
was traced from the reference picture. West half described; everything mirrored about
x = 768 as whole finished pieces, so both sides are exactly symmetric.

Construction rules (why it does not look glued together):
  - a wall runs from tower to tower; its ends tuck into the towers, which stand in front
    and hide the joins
  - a wall is ONE strip at its exact length, tiled from the section's front face cut to a
    whole number of battlement periods, so the pattern never restarts; diagonal walls are
    sheared columnwise to the blueprint slope (verticals stay vertical)
  - towers are built to their blueprint height: one body segment stretched by repeating
    its own middle masonry, plus the roof; widths and heights come from the blueprint
  - water, paving and land are drawn from explicit shapes (walk polygons, the castle's
    footprint) instead of guessed from colours, so no slivers or stray triangles
Walking: only the blueprint's walk polygons (courtyard + causeway). Collision comes only
from them.

Run:  cd tools && python3 castle9_build.py   ->  art/castle8/out/
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

import castle8_build as B
from castle8_build import cut, shrink, straighten, stack, K, W, HP, KIND_UP, KIND_FLAT, KIND_WATER

BP = json.load(open(B.SRC + 'blueprint.json'))
MIDX = 768


def mx(x):
    return 2 * MIDX - x


# ---------------------------------------------------------------- pieces
_c = {}


def memo(key, fn):
    if key not in _c:
        _c[key] = fn()
    return _c[key]


def body_src(banner):
    return memo(('body', banner), lambda: cut('body', (990, 0, 1983, 793) if banner else (0, 0, 990, 793)))


def fit_height(img, target_h, band=(0.46, 0.58)):
    """Make a body exactly target_h tall by repeating (or dropping) its middle rows."""
    h = img.shape[0]
    if target_h <= 8:
        return img
    r0, r1 = int(h * band[0]), int(h * band[1])
    if target_h >= h:
        n = target_h - h
        bandimg = img[r0:r1]
        reps = np.concatenate([bandimg] * (n // max(1, bandimg.shape[0]) + 1), 0)[:n]
        return np.concatenate([img[:r1], reps, img[r1:]], 0)
    drop = h - target_h
    keep_top = max(1, r0)
    return np.concatenate([img[:keep_top], img[keep_top + drop:]], 0)


def flag(img):
    """A pole with a small red pennant on the roof tip."""
    h, w = img.shape[:2]
    a = img[..., 3] > 0.5
    ys, xs = np.nonzero(a)
    tip_x = int(np.median(xs[ys == ys.min()]))
    ph = int(w * 0.32)
    out = np.zeros((h + ph, w, 4))
    out[ph:] = img
    pole = (70, 60, 55)
    out[1:ph + 4, tip_x - 1:tip_x + 1, :3] = pole
    out[1:ph + 4, tip_x - 1:tip_x + 1, 3] = 1
    fw, fh = int(w * 0.34), int(w * 0.16)
    for yy in range(fh):
        ln = int(fw * (1 - abs(yy - fh / 2) / (fh / 2) * 0.35))
        out[3 + yy, tip_x + 1:tip_x + 1 + ln, :3] = (190, 38, 40) if yy % 6 else (150, 25, 30)
        out[3 + yy, tip_x + 1:tip_x + 1 + ln, 3] = 1
    return out


def tower(t):
    """A tower exactly as the blueprint gives it: width w, from top to base."""
    def make():
        w = t['w'] * K
        total = int((t['base'] - t['top']) * K)
        kind = t['kind']
        banner = 'banner' in kind or kind == 'roof_flag'
        b = shrink(body_src(banner), f=w / body_src(banner).shape[1])
        if kind.startswith('turret'):
            return fit_height(b, total)
        r = shrink(cut('roof'), tw=w * 1.12)
        overlap = int(w * 0.16)
        body_h = total - r.shape[0] + overlap
        if kind == 'roof_flag':
            body_h -= int(w * 0.32)
        b = fit_height(b, max(int(w * 0.6), body_h))
        out = stack(r, b, overlap=overlap)
        return flag(out) if kind == 'roof_flag' else out
    return memo(('tower', t['id']), make)


def merlon_period(face):
    """The battlement period (px) of a wall face: autocorrelation of its top edge."""
    a = face[..., 3] > 0.5
    top = np.where(a.any(0), np.argmax(a, 0), face.shape[0]).astype(float)
    top -= top.mean()
    ac = np.correlate(top, top, 'full')[len(top) - 1:]
    lo = 6
    p = lo + int(np.argmax(ac[lo:len(top) // 3]))
    return max(lo, p)


def wall_face(diag):
    """Front face of a wall section, straightened (level), cut to whole battlement periods."""
    def make():
        if diag:
            src = straighten(cut('wall_diag'), 0.5, 0.5)[:, 25:1010]
            # undo the 0.5 slope: shift each column up so the face is level
            h, w = src.shape[:2]
            lift = (np.arange(w) * 0.5).astype(int)
            out = np.zeros((h + 2, w, 4))
            for x in range(w):
                col = src[:, x]
                out[:h - lift[x], x] = col[lift[x]:]
            ys = np.nonzero(out[..., 3].any(1) > 0)[0]
            face = out[ys.min():ys.max() + 1]
        else:
            face = straighten(cut('wall_straight'), 0.0, 0.0)[:, 46:860]
        p = merlon_period(face)
        n = face.shape[1] // p
        return face[:, :n * p], p
    return memo(('face', diag), make)


def wall(wd):
    """One wall strip from wd['from'] to wd['to'] (foot line) with tops wd['top']."""
    (ax, ay), (bx, by) = wd['from'], wd['to']
    tuck = 8
    ax, bx = ax - tuck, bx + tuck
    slope = (by - ay) / max(1e-6, bx - ax)
    h_ref = ((ay - wd['top'][0]) + (by - wd['top'][1])) / 2
    diag = abs(slope) >= 0.3
    face, _ = wall_face(diag)
    scaled = shrink(face, f=h_ref * K / face.shape[0])
    L = int(round((bx - ax) * K))
    reps = L // scaled.shape[1] + 1
    strip = np.concatenate([scaled] * reps, 1)[:, :L]
    h = strip.shape[0]
    lo = min(0.0, slope * (L - 1))
    drop = int(np.ceil(abs(slope) * L)) + 2
    out = np.zeros((h + drop, L, 4))
    for x in range(L):
        dy = int(round(slope * x - lo))
        out[dy:dy + h, x] = strip[:, x]
    X = int(round(ax * K))
    # the strip's left foot (row h + dy(0)) lands on the left foot point
    Y = int(round(ay * K)) - h - int(round(-lo))
    return out, X, Y


def bridge(br):
    """A level stone bridge across the span: the wall face at the bridge's height."""
    face, _ = wall_face(False)
    h = (br['arch_bottom'] - br['deck']) * K
    img = shrink(face, f=h / face.shape[0])
    L = int(round((abs(br['to'][0] - br['from'][0]) + 16) * K))
    img = np.concatenate([img] * (L // img.shape[1] + 1), 1)[:, :L]
    x0 = (min(br['from'][0], br['to'][0]) - 8) * K
    return img, int(round(x0)), int(round(br['deck'] * K))


def prop(kind):
    boxes = {'torch': ('lanterns', (840, 520, 990, 840), 18),
             'lantern_pillar': ('lanterns', (840, 520, 990, 840), 30),
             'knight': ('armory', (150, 185, 265, 385), 24)}
    name, box, wref = boxes[kind]
    def make():
        img = shrink(cut(name, box), tw=wref * K)
        if kind == 'knight':
            # a statue: grey stone, no armour colours
            g = img[..., :3].mean(2, keepdims=True)
            img[..., :3] = np.clip(g * np.array([0.82, 0.8, 0.86]) + 18, 0, 255)
        return img
    return memo(('prop', kind), make)


def palace():
    def make():
        f = cut('facade')
        p = BP['palace']
        main = shrink(f, tw=p['w'] * K)
        wing = shrink(f[:, :f.shape[1] // 2 + 40], tw=p['wings'][0]['w'] * K)
        return main, wing
    return memo('palace', make)


# ---------------------------------------------------------------- ground
def poly_mask(pts, dil=0):
    im = Image.new('L', (W, HP), 0)
    ImageDraw.Draw(im).polygon([(x * K, y * K) for x, y in pts], fill=255)
    m = np.array(im) > 0
    return ndimage.binary_dilation(m, iterations=dil) if dil else m


def sym(pts):
    return pts + [(mx(x), y) for x, y in reversed(pts)]


def footprint():
    """The castle's outline (ref px): inside it there is only water, paving and castle."""
    west = [(130, 1024), (120, 870), (20, 700), (10, 560), (30, 390), (80, 250), (190, 170),
            (330, 100), (520, 80), (560, 0), (768, 0)]
    return sym(west)


def walk_mask():
    c = BP['walk']['courtyard']
    m = poly_mask(sym([tuple(p) for p in c]))
    cw = BP['walk']['causeway']
    m |= poly_mask([tuple(p) for p in cw])
    return m


def ground():
    tex = lambda name, box, f: B.texture(name, box, f)
    wt = tex('water', None, 0.25).astype(float)
    wat = B.tile((wt.mean((0, 1)) + (wt - wt.mean((0, 1))) * 0.45).astype(np.uint8), HP, W)
    grs = B.tile(tex('grass', None, 0.25), HP, W)
    rck = B.tile(tex('cliff', (35, 90, 685, 640), 0.33), HP, W)
    pav = B.tile(tex('flag', (60, 60, 1194, 1194), 0.25), HP, W)
    inside = poly_mask(footprint())
    # land: everything outside the castle outline, as grass; a band of cliff along the shore
    land = ~inside
    cliff = land & ndimage.binary_dilation(inside[::4, ::4], iterations=10).repeat(4, 0).repeat(4, 1)[:HP, :W]
    col = np.where(land[..., None], grs, wat)
    col = np.where(cliff[..., None], rck, col)
    walk = walk_mask()
    # the courtyard paving runs under the walls that bound it
    paved = walk | (ndimage.binary_dilation(walk[::4, ::4], iterations=10).repeat(4, 0).repeat(4, 1)[:HP, :W]
                    & inside & (np.arange(HP)[:, None] < 640 * K))
    col = np.where(paved[..., None], pav, col)
    for ww in BP['walkways']:
        for f in (lambda x: x, mx):
            m = poly_mask([(f(x), y) for x, y in ww['poly']])
            col = np.where(m[..., None], pav, col)
            edge = m & ~ndimage.binary_erosion(m, iterations=4)
            col[edge] = (96, 88, 92)
            paved |= m
    water = inside & ~paved
    # foam where water meets land or paving
    edge1 = water & ndimage.binary_dilation(~water, iterations=2)
    col[edge1] = (226, 242, 250)
    edge2 = water & ndimage.binary_dilation(~water, iterations=6) & ~edge1
    col[edge2] = (col[edge2] * 0.55 + np.array([150, 205, 238]) * 0.45).astype(np.uint8)
    return col, water, paved, walk, ~inside


# ---------------------------------------------------------------- build
def build():
    cv = B.Canvas()
    items = []
    col, water, paved, walk, land = ground()
    cv.col[:] = col
    cv.kind[water] = KIND_WATER
    cv.kind[walk] = KIND_FLAT

    def add(img, X, Y, flat=None, mirror=True):
        items.append((Y + img.shape[0], img, X, Y, flat))
        if mirror:
            items.append((Y + img.shape[0], img[:, ::-1], W - X - img.shape[1], Y,
                          None if flat is None else flat[:, ::-1]))

    def stand(img, x_ref, base_ref, flat=None, mirror=True):
        X = int(round(x_ref * K - img.shape[1] / 2))
        Y = int(round(base_ref * K - img.shape[0]))
        add(img, X, Y, flat, mirror)

    for t in BP['towers']:
        stand(tower(t), t['cx'], t['base'])
    for wd in BP['walls']:
        img, X, Y = wall(wd)
        add(img, X, Y)
    for br in BP['bridges']:
        if br['deck']:
            img, X, Y = bridge(br)
            add(img, X, Y)
    for nw in BP.get('ns_walks', []):
        tex = B.walkway(nw['w'])
        th, tw_ = tex.shape[:2]
        y = nw['y0'] * K
        while y < nw['y1'] * K - 1:
            hh = int(min(th, nw['y1'] * K - y))
            base = np.arange(hh)[:, None] + np.zeros((1, tw_), int) + 18
            X = int(round(nw['x'] * K - tw_ / 2))
            items.append((int(y) + hh, tex[:hh], X, int(y), None, base))
            items.append((int(y) + hh, tex[:hh][:, ::-1], W - X - tw_, int(y), None, base))
            y += th
    # palace
    main, wing = palace()
    p = BP['palace']
    stand(main, p['cx'], p['base'], mirror=False)
    for wg in p['wings']:
        stand(wing, wg['cx'], wg['base'])
    # inner gate
    g = BP['gates'][0]
    gi = B.gate(g['w'])
    stand(gi, g['cx'], g['base'], flat=B.gate_flat(gi), mirror=False)
    # causeway: road with parapets from the gate to the south edge
    cw = BP['causeway']
    B.ns_walk(type('C', (), {'items': []}), 0, 0, 0, 1) if False else None
    tex = B.walkway((cw['x1'] - cw['x0']) + 16)
    th, tw_ = tex.shape[:2]
    flat = np.zeros(tex.shape[:2], bool)
    flat[:, int(tw_ * 0.18):int(tw_ * 0.82)] = True
    y = cw['y0'] * K
    while y < 1024 * K:
        hh = int(min(th, 1024 * K - y))
        base = np.arange(hh)[:, None] + np.zeros((1, tw_), int) + 18
        items.append((int(y) + hh, tex[:hh], int(round(MIDX * K - tw_ / 2)), int(y), flat[:hh], base))
        y += th
    cp = BP['causeway_props']
    for x, yb in cp['torch_posts']:
        stand(prop('torch'), x, yb)
    for x, yb in cp['knights']:
        stand(prop('knight'), x, yb)
    for x, yb in cp['lantern_pillars']:
        stand(prop('lantern_pillar'), x, yb)
    # land: waterfalls, islets, trees
    fall, splash = B.waterfall()
    for x, yb in BP['land']['waterfalls']:
        stand(fall, x, yb + 20)
        stand(splash, x, yb + 40)
    for x, yb, w in BP['land']['islets']:
        stand(B.islet(0, w), x, yb)
    rng = np.random.default_rng(7)
    trees = []
    for _ in range(900):
        x = rng.uniform(0, 1536)
        yb = rng.uniform(40, 1024)
        wx, wy = int(x * K), int(yb * K)
        if not (0 <= wy < HP and 0 <= wx < W) or not land[wy, wx]:
            continue
        # not on the cliff band right at the shore
        if not land[max(0, wy - 60):wy + 60:20, max(0, wx - 60):wx + 60:20].all():
            continue
        if any((x - a) ** 2 + (yb - b) ** 2 < 26 ** 2 for a, b in trees):
            continue
        trees.append((x, yb))
        img = B.tree(int(rng.integers(0, 6)))
        X = int(round(x * K - img.shape[1] / 2))
        Y = int(round(yb * K - img.shape[0]))
        items.append((Y + img.shape[0], img, X, Y, None))

    items.sort(key=lambda t: t[0])
    for it in items:
        img, X, Y, flat = it[1], it[2], it[3], it[4]
        base = it[5] if len(it) > 5 else None
        cv.paint(img, X, Y, flat, base)
    return cv, walk


if __name__ == '__main__':
    os.makedirs(B.OUT, exist_ok=True)
    for f in os.listdir(B.OUT):
        os.remove(B.OUT + f)
    cv, walk = build()
    B.save(cv, walk)
    print('done')
