"""Stage 18: the Royal Castle rebuilt from scratch on the new reference
(source_art/castle8/castle_ref.png, 1536 x 1024), outer layer first, from the coworkers'
assets (source_art/castle8/*.png).

Everything is placed in reference px; K world px per reference px. Each asset is cut from
its magenta sheet, straightened where the generator tilted it (column-wise, so verticals
stay vertical), shrunk to its size by area averaging and given hard alpha.

Walking is NOT derived from the picture: Kael may walk exactly where WALK polygons say
(the causeway, the two gate passages and the castle's inner ground), and nowhere else.
So there are no invisible walls inside those areas and no gaps outside them.

Run:  cd tools && python3 castle8_build.py   ->  art/castle8/out/
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

import import_castle as ic

SRC = '../source_art/castle8/'
OUT = '../art/castle8/out/'
REF_W, REF_H = 1536, 1024
K = 3.5
W, H = int(REF_W * K), int(REF_H * K)          # 5376 x 3584
CHUNK = 768
COLS, ROWS = W // CHUNK, -(-H // CHUNK)        # 7 x 5
HP = ROWS * CHUNK                              # padded canvas height
KIND_GROUND, KIND_FLAT, KIND_WATER, KIND_UP = 0, 32, 128, 255
MID = REF_W / 2.0


def mx(x):
    return REF_W - x


# ------------------------------------------------------------------ assets
_sheets = {}


def sheet(name):
    """(colours int array, foreground mask) of a magenta sheet."""
    if name not in _sheets:
        rgb = np.array(Image.open(SRC + name + '.png').convert('RGB')).astype(int)
        bg = ic.background(rgb)
        rgb, bg = ic.despill(rgb, bg)
        fg = ndimage.binary_opening(~bg, iterations=1)
        _sheets[name] = (rgb, fg)
    return _sheets[name]


def cut(name, box=None):
    """RGBA float crop of a sheet (alpha 0/1), trimmed to its content."""
    rgb, fg = sheet(name)
    if box is None:
        box = (0, 0, rgb.shape[1], rgb.shape[0])
    x0, y0, x1, y1 = box
    c, a = rgb[y0:y1, x0:x1].astype(float), fg[y0:y1, x0:x1].astype(float)
    ys, xs = np.nonzero(a)
    c, a = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1], a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return np.dstack([c, a])


def straighten(img, top_target=0.0, bot_target=0.0):
    """Remove a generator's tilt: per column, map the object's fitted top and bottom lines
    onto lines of the target slopes (verticals stay vertical, nothing rotates)."""
    a = img[..., 3] > 0.5
    h, w = a.shape
    cols = np.arange(w)
    has = a.any(0)
    top = np.where(has, np.argmax(a, 0), 0)
    bot = np.where(has, h - 1 - np.argmax(a[::-1], 0), 0)
    sel = has.copy()
    sel[:int(w * 0.04)] = False
    sel[int(w * 0.96):] = False
    kt = np.polyfit(cols[sel], top[sel], 1)
    kb = np.polyfit(cols[sel], bot[sel], 1)
    t0 = np.polyval(kt, cols)
    b0 = np.polyval(kb, cols)
    hh = float(np.median(b0 - t0))
    span = abs(top_target) * w + abs(bot_target) * w
    pad = int(span + 4)
    nh = int(hh + pad * 2 + 8)
    out = np.zeros((nh, w, 4))
    base_t = pad + 2 - min(0, top_target * w)
    for x in range(w):
        tt = base_t + top_target * x
        bb = tt + hh + (bot_target - top_target) * x
        ys = np.arange(int(np.floor(tt)), int(np.ceil(bb)) + 1)
        ys = ys[(ys >= 0) & (ys < nh)]
        f = (ys - tt) / max(1e-6, bb - tt)
        src = t0[x] + f * (b0[x] - t0[x])
        si = np.clip(np.round(src).astype(int), 0, h - 1)
        # keep pixels above/below the fitted lines (merlons, plinth) by extending the map
        out[ys, x] = img[si, x]
    # the parts outside the fitted lines (merlons above, plinth steps below)
    for x in range(w):
        tt = base_t + top_target * x
        above = np.arange(0, int(t0[x]))
        dst = np.round(tt - (t0[x] - above)).astype(int)
        ok = (dst >= 0) & (dst < nh)
        out[dst[ok], x] = img[above[ok], x]
        bb = tt + hh + (bot_target - top_target) * x
        below = np.arange(int(b0[x]) + 1, h)
        dst = np.round(bb + (below - b0[x])).astype(int)
        ok = (dst >= 0) & (dst < nh)
        out[dst[ok], x] = img[below[ok], x]
    ys, xs = np.nonzero(out[..., 3] > 0.5)
    return out[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def shrink(img, tw=None, th=None, f=None):
    """Area-average shrink to a target size; colours bleed only from the object; hard alpha."""
    h, w = img.shape[:2]
    if f is None:
        f = (tw / w) if tw else (th / h)
    nw, nh = max(1, round(w * f)), max(1, round(h * f))
    a = img[..., 3]
    c = img[..., :3]
    idx = ndimage.distance_transform_edt(a < 0.5, return_distances=False, return_indices=True)
    c = c[idx[0], idx[1]]
    ci = Image.fromarray(np.clip(c, 0, 255).astype(np.uint8)).resize((nw, nh), Image.Resampling.BOX)
    ci = ci.filter(ImageFilter.UnsharpMask(1, 50, 2))
    ai = np.array(Image.fromarray((a * 255).astype(np.uint8)).resize((nw, nh), Image.Resampling.BOX)) >= 128
    return np.dstack([np.array(ci).astype(float), ai.astype(float)])


def stack(top, bottom, overlap=0):
    """Put `top` on `bottom` (centred), overlapping `overlap` px."""
    w = max(top.shape[1], bottom.shape[1])
    h = top.shape[0] + bottom.shape[0] - overlap
    out = np.zeros((h, w, 4))
    bx = (w - bottom.shape[1]) // 2
    y0 = top.shape[0] - overlap
    out[y0:y0 + bottom.shape[0], bx:bx + bottom.shape[1]] = bottom
    tx = (w - top.shape[1]) // 2
    m = top[..., 3] > 0.5
    reg = out[0:top.shape[0], tx:tx + top.shape[1]]
    reg[m] = top[m]
    return out


# ---------------------------------------------------------------- pieces
_pc = {}


def P(key, fn):
    if key not in _pc:
        _pc[key] = fn()
    return _pc[key]


def tower(width_ref, roof=True, banner=True, segs=1.0, flag=False):
    """A round tower `width_ref` reference px wide: body segment(s), optional roof."""
    def make():
        wpx = width_ref * K
        seg = cut('body', (990, 0, 1983, 793) if banner else (0, 0, 990, 793))
        mid = cut('body', (0, 230, 990, 560))           # plain masonry band for taller towers
        f = wpx / seg.shape[1]
        body = shrink(seg, f=f)
        if segs > 1.0:
            extra = shrink(mid, tw=body.shape[1])
            extra = extra[:, :body.shape[1]]
            n = int(round((segs - 1.0) * body.shape[0]))
            reps = []
            while sum(r.shape[0] for r in reps) < n:
                reps.append(extra)
            filler = np.concatenate(reps, 0)[:n] if reps else None
            if filler is not None and filler.shape[0] > 0:
                # insert the filler under the crenellated top third of the segment
                cutp = int(body.shape[0] * 0.42)
                body = np.concatenate([body[:cutp], filler, body[cutp:]], 0)
        if not roof:
            return body
        r = shrink(cut('roof'), tw=wpx * 1.12)
        # the roof's eave ring sits on the body's crenellated ring
        return stack(r, body, overlap=int(body.shape[0] * 0.16 if segs <= 1 else body.shape[0] * 0.1))
    return P(('tower', width_ref, roof, banner, segs), make)


def wall_tex(height_ref, slope):
    """A wall section `height_ref` ref px tall whose foot runs at `slope` (straightened)."""
    def make():
        if abs(slope) < 0.2:
            src = straighten(cut('wall_straight'), 0.0, 0.0)
        else:
            src = straighten(cut('wall_diag'), 0.5, 0.5)
        hh = src.shape[0] - abs(0.5 if abs(slope) >= 0.2 else 0) * src.shape[1]
        return shrink(src, f=height_ref * K / hh)
    return P(('wall', height_ref, abs(slope) >= 0.2), make)


def walkway(width_ref):
    def make():
        src = cut('bridge', (170, 0, 835, 915))
        return shrink(src, tw=width_ref * K)
    return P(('walkway', width_ref), make)


def gate(width_ref):
    """The gatehouse, made exactly front-facing: the generator drew it turned (its right
    side wall shows), so the straight left half is mirrored about the arch's centre."""
    def make():
        g = straighten(cut('gate'), 0.0, 0.0)
        a = g[..., 3] > 0.5
        c = g[..., :3].mean(2)
        h = g.shape[0]
        # the arch centre: the middle of the dark opening's widest rows
        dark = (c < 70) & a
        rows = dark[int(h * 0.6):int(h * 0.85)]
        xs = np.nonzero(rows.sum(0) > rows.shape[0] * 0.5)[0]
        cx = int(round((xs.min() + xs.max()) / 2))
        # refine: the line about which the arch, shield and portcullis are most symmetric
        band = g[int(h * 0.38):int(h * 0.9), :, :3].mean(2)
        best = None
        for cand in range(cx - 60, cx + 61):
            r = min(cand, band.shape[1] - cand, 260)
            d = np.abs(band[:, cand - r:cand] - band[:, cand:cand + r][:, ::-1]).mean()
            if best is None or d < best[0]:
                best = (d, cand)
        cx = best[1]
        left = g[:, :cx]
        sym = np.concatenate([left, left[:, ::-1]], 1)
        ys, xs2 = np.nonzero(sym[..., 3] > 0.5)
        sym = sym[ys.min():ys.max() + 1, xs2.min():xs2.max() + 1]
        return shrink(sym, tw=width_ref * K)
    return P(('gate', width_ref), make)


def waterfall():
    def make():
        fall = shrink(cut('waterfall', (50, 30, 330, 495)), tw=60 * K)
        splash = shrink(cut('waterfall', (25, 630, 345, 840)), tw=80 * K)
        return fall, splash
    return P('fall', make)


def islet(i, width_ref):
    boxes = [(10, 0, 690, 724), (735, 0, 1410, 724), (1460, 0, 2165, 724)]
    return P(('islet', i, width_ref), lambda: shrink(cut('islets', boxes[i]), tw=width_ref * K))


TREE_BOX = [(20, 20, 300, 470), (300, 20, 560, 470), (560, 20, 840, 470), (840, 20, 1130, 470),
            (1130, 20, 1410, 470), (1410, 20, 1774, 470)]
BUSH_BOX = [(800, 560, 1000, 870), (1000, 560, 1200, 870), (1200, 560, 1400, 870), (1400, 560, 1650, 870)]


def tree(i):
    return P(('tree', i), lambda: shrink(cut('trees', TREE_BOX[i]), th=118))


# ---------------------------------------------------------------- canvas
class Canvas:
    def __init__(self):
        self.col = np.zeros((HP, W, 3), np.uint8)
        self.base = np.full((HP, W), -1, np.int32)
        self.kind = np.zeros((HP, W), np.uint8)

    def paint(self, img, X, Y, flat=None, base=None):
        """Paint RGBA `img` with its top-left at (X, Y). Each column stands on its lowest
        opaque pixel unless `base` (per-pixel, image rows) is given; `flat` pixels lie on
        the ground."""
        h, w = img.shape[:2]
        a = img[..., 3] > 0.5
        if base is None:
            bottom = np.where(a.any(0), h - 1 - np.argmax(a[::-1], 0), 0)
            base = np.broadcast_to(bottom[None, :], (h, w))
        base = base.astype(np.int32) + Y
        if flat is None:
            flat = np.zeros((h, w), bool)
        cx0, cy0, cx1, cy1 = max(0, X), max(0, Y), min(W, X + w), min(HP, Y + h)
        if cx0 >= cx1 or cy0 >= cy1:
            return
        ss = (slice(cy0 - Y, cy1 - Y), slice(cx0 - X, cx1 - X))
        sc = (slice(cy0, cy1), slice(cx0, cx1))
        A, F, B = a[ss], flat[ss] & a[ss], base[ss]
        U = A & ~flat[ss]
        kind = self.kind[sc]
        wf = F & (kind != KIND_UP)
        wu = U & ((B >= self.base[sc]) | (kind != KIND_UP))
        col = img[ss][..., :3].astype(np.uint8)
        c = self.col[sc]
        c[wf] = col[wf]
        c[wu] = col[wu]
        kind[wf] = KIND_FLAT
        kind[wu] = KIND_UP
        bb = self.base[sc]
        bb[wu] = B[wu]


def place(cv, img, x_ref, base_ref, mirror=False, flat=None):
    """Stand `img` with its bottom centre at (x_ref, base_ref)."""
    if mirror:
        img = img[:, ::-1]
        flat = None if flat is None else flat[:, ::-1]
    h, w = img.shape[:2]
    X = int(round(x_ref * K - w / 2))
    Y = int(round(base_ref * K - h))
    cv.items.append((Y + h, img, X, Y, flat, None))


def wall_run(cv, pts, height_ref):
    """A wall along a polyline of foot points (ref px), copies of a straightened section
    side by side with their feet on the line, joined into one strip."""
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        if bx < ax:
            ax, ay, bx, by = bx, by, ax, ay
        slope = (by - ay) / max(1e-6, bx - ax)
        tex = wall_tex(height_ref, slope)
        if abs(slope) >= 0.2 and slope < 0:
            tex = tex[:, ::-1]
        sec_w = tex.shape[1]
        a = tex[..., 3] > 0.5
        foot = np.where(a.any(0), tex.shape[0] - 1 - np.argmax(a[::-1], 0), 0)
        x = ax * K
        while x < bx * K - 2:
            w = int(min(sec_w, bx * K - x))
            if w < 8:
                break
            fy = (ay + (x / K - ax) * slope) * K
            X = int(round(x))
            Y = int(round(fy - foot[0]))
            piece = tex[:, :w]
            cv.items.append((Y + tex.shape[0], piece, X, Y, None, None))
            x += sec_w


def ns_walk(cv, x_ref, y0, y1, width_ref, flat_floor=True):
    """A north-south wall-walk or causeway from y0 to y1 (ref px)."""
    tex = walkway(width_ref)
    h, w = tex.shape[:2]
    a = tex[..., 3] > 0.5
    flat = np.zeros(a.shape, bool)
    if flat_floor:
        flat[:, int(w * 0.24):int(w * 0.76)] = True
    y = y0 * K
    while y < y1 * K - 1:
        hh = int(min(h, y1 * K - y))
        X = int(round(x_ref * K - w / 2))
        Y = int(round(y))
        rows = np.arange(hh)[:, None] + np.zeros((1, w), int)
        base = rows + 18           # a long low run: each pixel stands just below itself
        cv.items.append((Y + hh, tex[:hh], X, Y, flat[:hh], base))
        y += h


# ---------------------------------------------------------------- layout
# towers: (x, base y, width, roof, banner, segments)
TOWERS_W = [
    # outer (barbican) wall: roofless turrets, the two flag towers at the gate
    (164, 852, 48, False, False, 1.6), (283, 876, 38, False, False, 1.5),
    (396, 934, 46, False, False, 1.6), (505, 940, 44, False, False, 1.5),
    (640, 948, 60, True, True, 1.7),
    # main (front) wall
    (691, 728, 42, True, True, 1.6), (604, 722, 38, True, True, 1.4),
    (440, 798, 70, True, True, 2.0), (272, 694, 36, True, True, 1.4),
    # west perimeter
    (58, 628, 62, True, True, 1.6), (198, 518, 36, True, True, 1.3),
    (80, 402, 56, True, True, 1.6), (125, 262, 50, True, True, 1.5),
    (236, 202, 58, True, True, 1.5),
    # back wall
    (352, 142, 42, True, True, 1.3), (560, 118, 52, True, True, 1.6),
]
WALLS_W = [
    ([(188, 846), (265, 852)], 46),
    ([(300, 862), (372, 918)], 46),
    ([(420, 928), (482, 936)], 46),
    ([(528, 937), (610, 942)], 46),
    ([(290, 706), (585, 706)], 66),
    ([(622, 708), (670, 708)], 66),
    ([(165, 562), (255, 690)], 60),
    ([(90, 560), (165, 560)], 34),        # bridge to the far west tower
    ([(150, 252), (207, 252)], 34),        # bridge between the north-west towers
    ([(265, 200), (352, 142)], 56),
    ([(352, 142), (768, 142)], 56),
]
WALKS_W = [(206, 236, 500, 30)]           # west wall-walk (x, y0, y1, width)

# Kael may walk only here (ref px). West half; mirrored for the east.
ENCLOSURE_W = [(768, 636), (300, 636), (256, 628), (176, 506), (226, 500), (228, 244),
               (272, 214), (356, 156), (768, 156)]
CAUSEWAY = (749, 787, 636, 1024)          # x0, x1, y0, y1: road, through both gates


def walk_mask():
    im = Image.new('L', (W, HP), 0)
    d = ImageDraw.Draw(im)
    poly = ENCLOSURE_W + [(mx(x), y) for x, y in reversed(ENCLOSURE_W)]
    d.polygon([(x * K, y * K) for x, y in poly], fill=255)
    x0, x1, y0, y1 = CAUSEWAY
    d.rectangle([x0 * K, y0 * K, x1 * K, y1 * K], fill=255)
    return np.array(im) > 0


# ---------------------------------------------------------------- ground
def texture(name, box, f):
    t = cut(name, box)
    t = shrink(t, f=f)
    return t[..., :3].astype(np.uint8)


def tile(tex, h, w):
    th, tw = tex.shape[:2]
    return np.tile(tex, (h // th + 1, w // tw + 1, 1))[:h, :w]


def ground():
    ref = np.array(Image.open(SRC + 'castle_ref.png').convert('RGB').filter(ImageFilter.GaussianBlur(2))).astype(int)
    r, g, b = ref[..., 0], ref[..., 1], ref[..., 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    water = (b > r + 45) & (b > g + 5)
    green = (g > r + 10) & (g >= b - 8) & ~water
    # the castle's own footprint (walls, towers) is water underneath, never land or rock
    hull = Image.new('L', (REF_W, REF_H), 0)
    hd = ImageDraw.Draw(hull)
    hp = [(150, 1024), (130, 860), (40, 690), (20, 560), (40, 380), (95, 230), (230, 160), (360, 100),
          (560, 70)]
    hd.polygon(hp + [(mx(x), y) for x, y in reversed(hp)], fill=255)
    hull = np.array(hull) > 0
    land = green & ~hull
    rock = ~water & ~green & ~hull & (lum < 170)
    land = ndimage.binary_opening(land, iterations=2)
    rock = ndimage.binary_opening(rock, iterations=2) & ~land
    cls = np.zeros((REF_H, REF_W), np.uint8)       # 0 water, 1 grass, 2 rock
    cls[land] = 1
    cls[rock] = 2
    cls = ndimage.median_filter(cls, 5)
    up = np.array(Image.fromarray(cls).resize((W, HP), Image.Resampling.NEAREST))
    up = ndimage.median_filter(up[::2, ::2], 5).repeat(2, 0).repeat(2, 1)[:HP, :W]
    wt = texture('water', None, 0.25).astype(float)
    wat = tile((wt.mean((0, 1)) + (wt - wt.mean((0, 1))) * 0.45).astype(np.uint8), HP, W)
    grs = tile(texture('grass', None, 0.25), HP, W)
    rck = tile(texture('cliff', (35, 90, 685, 640), 0.33), HP, W)
    pav = tile(texture('flag', (60, 60, 1194, 1194), 0.25), HP, W)
    col = np.where((up == 1)[..., None], grs, np.where((up == 2)[..., None], rck, wat))
    walk = walk_mask()
    col = np.where(walk[..., None], pav, col)
    waterm = (up == 0) & ~walk
    # no slivers of land or rock: anything thinner than ~40 px becomes water
    solid = ndimage.binary_opening(~waterm & ~walk, iterations=20) | walk
    col = np.where((~solid & ~waterm)[..., None], wat, col)
    waterm = ~solid
    # foam where water meets land or rock
    edge = waterm & ndimage.binary_dilation(~waterm, iterations=3)
    col[edge] = (np.array([168, 216, 245]) * 0.6 + col[edge] * 0.4).astype(np.uint8)
    edge1 = waterm & ndimage.binary_dilation(~waterm, iterations=1)
    col[edge1] = (230, 246, 252)
    return col, waterm, up


def trees_from_ref(up, rng):
    ref = np.array(Image.open(SRC + 'castle_ref.png').convert('RGB')).astype(int)
    r, g, b = ref[..., 0], ref[..., 1], ref[..., 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    dark = (g > r + 15) & (lum < 110)
    sm = ndimage.gaussian_filter(dark.astype(float), 3)
    peaks = (sm == ndimage.maximum_filter(sm, 14)) & (sm > 0.45)
    out = []
    for y, x in zip(*np.nonzero(peaks)):
        wy, wx = int((y + 8) * K), int(x * K)
        if 0 <= wy < HP and 0 <= wx < W and up[wy, wx] == 1:
            out.append((x, y + 8, int(rng.integers(0, 6)), bool(rng.integers(0, 2))))
    return out


# ---------------------------------------------------------------- build
def build():
    os.makedirs(OUT, exist_ok=True)
    cv = Canvas()
    cv.items = []
    col, waterm, up = ground()
    cv.col[:] = col
    cv.kind[waterm] = KIND_WATER
    walk = walk_mask()
    cv.kind[walk] = KIND_FLAT

    for x, by, w, roof, ban, segs in TOWERS_W:
        img = tower(w, roof, ban, segs)
        place(cv, img, x, by)
        if (mx(x), by) != (x, by):
            place(cv, img, mx(x), by, mirror=True)
    for pts, hgt in WALLS_W:
        wall_run(cv, pts, hgt)
        wall_run(cv, [(mx(x), y) for x, y in pts], hgt)
    for x, y0, y1, w in WALKS_W:
        ns_walk(cv, x, y0, y1, w, False)
        ns_walk(cv, mx(x), y0, y1, w, False)
    # causeway (flat road with parapets) and the two gatehouses
    ns_walk(cv, MID, 712, 1024, 96)
    g_in = gate(150)
    place(cv, g_in, MID, 714)
    g_out = gate(190)
    place(cv, g_out, MID, 1004)
    # waterfalls under the outer wall
    fall, splash = waterfall()
    for x in (226, mx(226)):
        place(cv, fall, x, 940)
        place(cv, splash, x, 958)
    # islets in the moat
    for i, (x, y, w) in enumerate([(385, 1000, 120), (1150, 1000, 120), (690, 1030, 70)]):
        place(cv, islet(i % 3, w), x, y)
    rng = np.random.default_rng(4)
    for x, y, t, mir in trees_from_ref(up, rng):
        place(cv, tree(t), x, y, mirror=mir)

    cv.items.sort(key=lambda t: t[0])
    for _, img, X, Y, flat, base in cv.items:
        cv.paint(img, X, Y, flat, base)
    # the walkable areas stay walkable whatever was drawn: anything upright drawn over them
    # (a roof, a tree top) is drawn over Kael by the occluder, but never blocks him
    return cv, walk


def collision(walk, cell=8):
    n_r, n_c = HP // cell, W // cell
    w = walk[:n_r * cell, :n_c * cell].reshape(n_r, cell, n_c, cell).mean((1, 3)) > 0.5
    solid = ~w & ndimage.binary_dilation(w, iterations=2)
    boxes, open_runs = [], {}
    for j in range(n_r):
        row, runs, i = solid[j], [], 0
        while i < n_c:
            if row[i]:
                k = i
                while k < n_c and row[k]:
                    k += 1
                runs.append((i, k))
                i = k
            else:
                i += 1
        new = {}
        for r in runs:
            if r in open_runs:
                b = open_runs[r]
                b[3] += 1
            else:
                b = [r[0], j, r[1] - r[0], 1]
                boxes.append(b)
            new[r] = b
        open_runs = new
    return [[b[0] * cell, b[1] * cell, b[2] * cell, b[3] * cell] for b in boxes]


def lights():
    out = []
    for y in range(745, 1000, 52):
        for x in (741, 795):
            out.append([round(x * K), round(y * K), 'torch'])
    for x in (750, 786):
        out.append([round(x * K), round(690 * K), 'torch'])
        out.append([round(x * K), round(980 * K), 'torch'])
    return out


def save(cv, walk):
    depth = np.zeros((HP, W, 3), np.uint8)
    b = np.clip(cv.base, 0, 65535)
    depth[..., 0] = (b >> 8) & 255
    depth[..., 1] = b & 255
    depth[..., 2] = cv.kind
    for r in range(ROWS):
        for c in range(COLS):
            sl = (slice(r * CHUNK, (r + 1) * CHUNK), slice(c * CHUNK, (c + 1) * CHUNK))
            Image.fromarray(cv.col[sl]).save(OUT + 'col_%d_%d.png' % (r, c))
            Image.fromarray(depth[sl]).save(OUT + 'dep_%d_%d.png' % (r, c))
    json.dump({'w': W, 'h': H, 'chunk': CHUNK, 'cols': COLS, 'rows': ROWS, 'k': K}, open(OUT + 'meta.json', 'w'))
    json.dump(collision(walk), open(OUT + 'collision.json', 'w'))
    json.dump(lights(), open(OUT + 'lights.json', 'w'))
    Image.fromarray(cv.col[:H]).resize((W // 4, H // 4), Image.Resampling.BOX).save(OUT + 'preview.png')
    dbg = cv.col[:H:4, ::4].astype(float)
    wm = walk[:H:4, ::4]
    dbg[wm] = dbg[wm] * 0.5 + np.array([0, 255, 0]) * 0.5
    Image.fromarray(dbg.astype(np.uint8)).save(OUT + 'walk_debug.png')


if __name__ == '__main__':
    cv, walk = build()
    save(cv, walk)
    print('items', len(cv.items))
