"""Stage 17: build the Royal Castle as ONE seamless image at Kael's pixel size (1 world px)
from the castle6 sheets (art/castle7/, imported at native size by import_castle7.py),
laid out on the castle map (source_art/castle4/castle_map.png, 1728 px).

  - every piece is drawn at a whole-number scale (sheet px -> 2 or 3 world px; trees and
    props 1), never resampled
  - pieces are painted with a z-buffer: each column of a piece stands at its own base line
    (the bottom of the piece in that column), and a pixel only covers another if it stands
    further south. So walls, towers, buildings and trees overlap as they do in the world,
    and joins between pieces hide behind whatever stands in front of them.
  - walls along a line are built as one strip from copies of a wall section, then placed
  - the result is one colour image + one depth image (base y per pixel, and the kind of
    pixel), cut into chunks for the game (castle_outer.gd)

Coordinates: layout positions are castle-map px (1728 map). One map px = K world px.

Run:  cd tools && python3 castle7_build.py      (writes art/castle7/out/)
"""
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

import castle7_layout as L
import castle7_ground as ground

ART = '../art/castle7/'
OUT = ART + 'out/'
MAP = '../source_art/castle4/castle_map.png'
SHEET_TO_MAP = 0.756                 # one sheet px of the 2x groups is 0.756 map px
K = 2.0 / SHEET_TO_MAP               # world px per map px (2.6455)
N = 4572                             # canvas size in world px (= 1728 * K)
CHUNK = 762                          # 6 x 6 chunks

KIND_GROUND, KIND_FLAT, KIND_WATER, KIND_UP = 0, 32, 128, 255

_cache = {}


def sprite(src):
    if src not in _cache:
        _cache[src] = np.array(Image.open(ART + src + '.png').convert('RGBA'))
    return _cache[src]


class Piece:
    """A crop of a sprite at world scale: rgba, feet anchor, per-pixel base offsets."""

    def __init__(self, rgba, ax, ay, flat=None, rise=None):
        self.rgba = rgba
        self.ax, self.ay = ax, ay
        h, w = rgba.shape[:2]
        self.flat = flat if flat is not None else np.zeros((h, w), bool)
        self.rise = rise            # optional per-pixel base (image rows) overriding column bottoms

    def mirrored(self):
        return Piece(self.rgba[:, ::-1], self.rgba.shape[1] - self.ax, self.ay, self.flat[:, ::-1],
                     None if self.rise is None else self.rise[:, ::-1])


def load_piece(name, squash=None):
    p = L.PIECES[name]
    img = sprite(p['src'])
    x0, y0, x1, y1 = p.get('box', (0, 0, img.shape[1], img.shape[0]))
    sub = img[y0:y1, x0:x1].copy()
    if 'keep' in p:
        m = Image.new('L', (sub.shape[1], sub.shape[0]), 0)
        ImageDraw.Draw(m).polygon([(x - x0, y - y0) for x, y in p['keep']], fill=255)
        sub[np.array(m) == 0, 3] = 0
    if p.get('nowater'):
        # flat water drawn in the sheet (diamond pools, rings round rocks) is left out: the
        # castle's own water shows through. Bright foam and falling water are kept.
        r, g, b = (sub[..., i].astype(int) for i in range(3))
        lum = 0.3 * r + 0.59 * g + 0.11 * b
        wat = (b > r + 40) & (b > g + 5) & (lum < p.get('nowater_lum', 150))
        sub[wat, 3] = 0
        # drop specks left behind
        lab, n = ndimage.label(sub[..., 3] > 0)
        if n > 1:
            sz = ndimage.sum(np.ones_like(lab), lab, index=np.arange(1, n + 1))
            sub[np.isin(lab, np.nonzero(sz < 30)[0] + 1), 3] = 0
    h0 = sub.shape[0]
    if squash and squash < h0:
        top = p.get('top', 40)
        sub = np.concatenate([sub[:top], sub[h0 - (squash - top):]], 0)
    a = sub[..., 3] > 0
    ys, xs = np.nonzero(a)
    if len(xs) == 0:
        raise SystemExit('empty piece ' + name)
    if 'anchor' in p:
        ax, ay = p['anchor'][0] - x0, p['anchor'][1] - y0 - (h0 - sub.shape[0])
    else:
        ax, ay = (xs.min() + xs.max() + 1) / 2.0, ys.max() + 1
    s = p['scale']
    big = np.repeat(np.repeat(sub, s, 0), s, 1)
    H, W = big.shape[:2]
    flat = np.zeros((H, W), bool)
    rise = None
    for kind, (rx0, ry0, rx1, ry1), *arg in p.get('regions', []):
        sl = (slice(max(0, (ry0 - y0) * s), max(0, (ry1 - y0) * s)), slice(max(0, (rx0 - x0) * s), max(0, (rx1 - x0) * s)))
        if kind == 'flat':
            flat[sl] = True
        elif kind == 'open':
            # an open gateway: the doors are swung away, the passage is in shadow
            # keep the door's own art (arch, planks, studs) but deep in shadow, darker inside
            reg = big[sl]
            m = reg[..., 3] > 0
            hh = reg.shape[0]
            k = np.linspace(0.22, 0.42, hh)[:, None, None]
            tint = np.array([0.9, 0.95, 1.15])[None, None, :]
            reg[..., :3] = np.where(m[..., None], np.clip(reg[..., :3] * k * tint, 0, 255), reg[..., :3]).astype(np.uint8)
        elif kind in ('stand', 'rise'):
            if rise is None:
                aa = big[..., 3] > 0
                bottom = np.where(aa.any(0), H - 1 - np.argmax(aa[::-1], 0), 0)
                rise = np.broadcast_to(bottom[None, :], (H, W)).astype(np.int32).copy()
            if kind == 'rise':
                yy = np.arange(H)[:, None] + np.zeros((1, W), int)
                rise[sl] = yy[sl] + int(arg[0] * s)
            else:
                aa = big[..., 3] > 0
                lab, n = ndimage.label(aa[sl])
                for i, ss in enumerate(ndimage.find_objects(lab)):
                    m = lab[ss] == i + 1
                    reg = rise[sl][ss]
                    reg[m] = sl[0].start + ss[0].stop
    return Piece(big, ax * s, ay * s, flat, rise)


def wall_strip(e):
    """A wall along a polyline (map px), built from copies of a wall section placed side by
    side, each copy's foot on the line. Returns (Piece, map x, map y of its top-left)."""
    pts = e['pts']
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    pad = 200
    X0 = min(xs) * K - pad
    Y0 = min(ys) * K - 900
    W = int((max(xs) - min(xs)) * K + 2 * pad)
    H = int((max(ys) - min(ys)) * K + 900 + 900)
    canvas = np.zeros((H, W, 4), np.uint8)
    base = np.full((H, W), -1, np.int32)
    flat = np.zeros((H, W), bool)
    if L.PIECES.get(e['run'], {}).get('ns'):
        return ns_strip(e)
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        if bx < ax:
            ax, ay, bx, by = bx, by, ax, ay
        dx, dy = bx - ax, by - ay
        if dx < 1:
            continue
        slope = dy / dx
        kind = e['run']
        if kind == 'wall':
            name = 'wall_h' if abs(slope) < 0.22 else 'wall_d'
        else:
            name = kind
        p = L.PIECES[name]
        pc = load_piece(name, e.get('h'))
        mirror = name == 'wall_d' and slope < 0
        if mirror:
            pc = pc.mirrored()
        img = pc.rgba
        h, w = img.shape[:2]
        alpha = img[..., 3] > 0
        bottom = np.where(alpha.any(0), h - 1 - np.argmax(alpha[::-1], 0), 0)
        # foot line of the section: its left and right foot (image px), from the piece spec
        lf, rf = p.get('feet', (h, h))
        if mirror:
            lf, rf = rf, lf
        lf, rf = lf * p['scale'], rf * p['scale']
        if e.get('h') and e['h'] < (p['box'][3] - p['box'][1]):
            d = (p['box'][3] - p['box'][1] - e['h']) * p['scale']
            lf, rf = lf - d, rf - d
        x_world = ax * K
        x_end = bx * K
        while x_world < x_end - 1:
            ww = int(min(w, x_end - x_world))
            px = int(round(x_world - X0))
            foot_y = (ay + (x_world / K - ax) * slope) * K
            py = int(round(foot_y - lf - Y0))
            sub = img[:, :ww]
            am = alpha[:, :ww]
            ph, pw = sub.shape[:2]
            reg = (slice(py, py + ph), slice(px, px + pw))
            colb = np.broadcast_to(bottom[None, :ww] + py, (ph, pw))
            cur = base[reg]
            put = am & (colb >= cur)
            canvas[reg][put] = sub[put]
            base[reg][put] = colb[put]
            flat[reg][put] = pc.flat[:, :ww][put]
            x_world += w
    a = canvas[..., 3] > 0
    ys_, xs_ = np.nonzero(a)
    y0, y1, x0, x1 = ys_.min(), ys_.max() + 1, xs_.min(), xs_.max() + 1
    rise = base[y0:y1, x0:x1] - y0
    piece = Piece(canvas[y0:y1, x0:x1], 0, 0, flat[y0:y1, x0:x1], rise)
    return piece, (X0 + x0) / K, (Y0 + y0) / K


def ns_strip(e):
    """A north-south run (causeway, wall seen end-on): copies stacked top to bottom along
    the polyline. Every pixel stands a little below itself (it is part of a long low run),
    floors are flat."""
    name = e['run']
    pc = load_piece(name)
    img = pc.rgba
    h, w = img.shape[:2]
    pts = e['pts']
    (ax, ay), (bx, by) = pts[0], pts[-1]
    n = max(1, int(round((by - ay) * K / h)))
    total = n * h
    out = np.zeros((total, w + int(abs(bx - ax) * K) + 2, 4), np.uint8)
    flat = np.zeros(out.shape[:2], bool)
    rise = np.zeros(out.shape[:2], np.int32)
    lift = int(L.PIECES[name].get('stand', 24) * L.PIECES[name]['scale'])
    x0 = min(ax, bx) * K
    for i in range(n):
        cx = (ax + (bx - ax) * (i + 0.5) / n) * K - x0
        px = int(round(cx - w / 2 + (w / 2 if bx < ax else 0)))
        px = max(0, min(out.shape[1] - w, int(round(cx))))
        reg = (slice(i * h, (i + 1) * h), slice(px, px + w))
        m = img[..., 3] > 0
        out[reg][m] = img[m]
        flat[reg][m] = pc.flat[m]
        yy = np.arange(i * h, (i + 1) * h)[:, None] + np.zeros((1, w), int)
        rise[reg][m] = (yy + lift)[m]
    piece = Piece(out, 0, 0, flat, rise)
    return piece, x0 / K, ay


class Canvas:
    def __init__(self):
        self.col = np.zeros((N, N, 3), np.uint8)
        self.base = np.full((N, N), -1, np.int32)       # -1 = ground
        self.kind = np.zeros((N, N), np.uint8)
        self.foot = np.zeros((N, N), bool)     # ground an upright thing stands on (blocks walking)

    def paint(self, pc, X, Y, z=0, depth=None, centre=1.0):
        """depth: how far (px) north of its base line a pixel still stands on the ground the
        thing occupies; centre: only the middle fraction of its columns has a footprint (trees)."""
        """Paint a Piece with its top-left at world px (X, Y)."""
        big = pc.rgba
        h, w = big.shape[:2]
        a = big[..., 3] > 0
        if pc.rise is not None:
            base = pc.rise.astype(np.int32) + Y
        else:
            bottom = np.where(a.any(0), h - 1 - np.argmax(a[::-1], 0), 0)
            base = np.broadcast_to(bottom[None, :] + Y, (h, w)).astype(np.int32)
        base = base + z
        cx0, cy0 = max(0, X), max(0, Y)
        cx1, cy1 = min(N, X + w), min(N, Y + h)
        if cx0 >= cx1 or cy0 >= cy1:
            return
        sx0, sy0 = cx0 - X, cy0 - Y
        sl_c = (slice(cy0, cy1), slice(cx0, cx1))
        sl_s = (slice(sy0, sy0 + cy1 - cy0), slice(sx0, sx0 + cx1 - cx0))
        A = a[sl_s]
        F = pc.flat[sl_s] & A
        U = A & ~pc.flat[sl_s]
        B = base[sl_s]
        kind = self.kind[sl_c]
        wf = F & (kind != KIND_UP)
        wu = U & ((B >= self.base[sl_c]) | (kind != KIND_UP))
        col = big[sl_s][..., :3]
        c = self.col[sl_c]
        c[wf] = col[wf]
        c[wu] = col[wu]
        kind[wf] = KIND_FLAT
        kind[wu] = KIND_UP
        bb = self.base[sl_c]
        bb[wu] = B[wu]
        bb[wf] = -1
        if depth is None:
            depth = 0.5 * w
        yy = np.arange(cy0, cy1)[:, None]
        fp = U & (B - yy < depth) & (B - yy >= 0)
        if centre < 1.0:
            cols = np.arange(cx0, cx1) - X
            fp &= (np.abs(cols - w / 2) < w * centre / 2)[None, :]
        self.foot[sl_c] |= fp


def expand(layout):
    out = []
    for e in layout:
        out.append(dict(e))
        if e.get('sym'):
            m = dict(e)
            if 'pts' in e:
                m['pts'] = [(1728 - x, y) for x, y in e['pts']]
            else:
                m['x'] = 1728 - e['x']
                m['mirror'] = not e.get('mirror', False)
            out.append(m)
    return out


def build():
    os.makedirs(OUT, exist_ok=True)
    refmap = np.array(Image.open(MAP).convert('RGB')).astype(np.float32)
    cv = Canvas()
    g = ground.make(N, K)
    cv.col[:] = g['col']
    cv.kind[g['water']] = KIND_WATER
    items = []
    for e in expand(L.LAYOUT):
        if 'pts' in e:
            pc, mx, my = wall_strip(e)
            X, Y = int(round(mx * K)), int(round(my * K))
            ns = L.PIECES.get(e['run'], {}).get('ns')
            d = (L.PIECES[e['run']].get('stand', 24) * 2 + 10) if ns else 40
            items.append((Y + pc.rgba.shape[0], pc, X, Y, e.get('z', 0), d, 1.0))
        else:
            pc = load_piece(e['p'], e.get('h'))
            if e.get('mirror'):
                pc = pc.mirrored()
            X = int(round(e['x'] * K - pc.ax))
            Y = int(round(e['y'] * K - pc.ay))
            items.append((Y + pc.rgba.shape[0], pc, X, Y, e.get('z', 0), L.PIECES[e['p']].get('depth'), 1.0))
    for name, tx, ty, mir in ground.cliffs(g['cls'], K) + [(c['p'], c['x'], c['y'], c.get('mirror', False)) for c in L.NATURE]:
        pc = load_piece(name)
        if mir:
            pc = pc.mirrored()
        X = int(round(tx * K - pc.ax))
        Y = int(round(ty * K - pc.ay))
        items.append((Y + pc.rgba.shape[0], pc, X, Y, 0, None, 1.0))
    trees = ground.trees(refmap, K, L.TREES_OFF) + [(t['p'], t['x'], t['y'], t.get('mirror', False)) for t in L.TREES]
    # a tree only grows on grass, clear of the castle's pieces (no trunks in water or walls)
    cls = g['cls']
    grassy = (cls == ground.CLASSES.index('grass')) | (cls == ground.CLASSES.index('forest'))
    occupied = np.zeros((N // 2, N // 2), bool)
    for _, pc, X, Y, *_r in items:
        a = pc.rgba[::2, ::2, 3] > 0
        y0, x0 = Y // 2, X // 2
        ys, xs = slice(max(0, y0), min(N // 2, y0 + a.shape[0])), slice(max(0, x0), min(N // 2, x0 + a.shape[1]))
        occupied[ys, xs] |= a[ys.start - y0:ys.stop - y0, xs.start - x0:xs.stop - x0]
    occupied = ndimage.binary_dilation(occupied, iterations=2)
    keep = []
    for t in trees:
        hx, hy = int(t[1] * K / 2), int(t[2] * K / 2)
        if 0 <= hx < N // 2 and 0 <= hy < N // 2 and grassy[hy, hx] and not occupied[hy, hx]:
            keep.append(t)
    trees = keep
    for name, tx, ty, mir in trees:
        pc = load_piece(name)
        if mir:
            pc = pc.mirrored()
        X = int(round(tx * K - pc.ax))
        Y = int(round(ty * K - pc.ay))
        items.append((Y + pc.rgba.shape[0], pc, X, Y, 0, 14, 0.3))
    items.sort(key=lambda t: t[0])
    for _, pc, X, Y, z, d, cen in items:
        cv.paint(pc, X, Y, z, d, cen)
    cv.cls = g['cls']
    return cv, len(items), len(trees)


def walkable(cv, cls):
    """Where Kael can walk: visible paving, lawn, sand and flat floors (causeway, stairs)
    inside the castle, joined to the causeway. -> bool mask at world px."""
    h = N // 2
    ok = np.isin(cls, [ground.CLASSES.index(c) for c in ('pave', 'grass', 'sand')])
    okf = np.repeat(np.repeat(ok, 2, 0), 2, 1)
    inside = np.zeros((N, N), bool)
    inside[int(330 * K):int(1205 * K), int(200 * K):int(1528 * K)] = True
    walk = (okf & inside & ~cv.foot & (cv.kind != KIND_WATER)) | (cv.kind == KIND_FLAT)
    walk = ndimage.binary_opening(walk, iterations=3)
    for x0, y0, x1, y1 in L.PASSAGES:
        walk[int(y0 * K):int(y1 * K), int(x0 * K):int(x1 * K)] = True
    lab, n = ndimage.label(walk)
    seed = lab[int(1660 * K), int(864 * K)]
    if seed == 0:
        raise SystemExit('the causeway start is not walkable')
    return lab == seed


def collision(walk, cell=8):
    """Solid boxes (canvas px) covering everything that is not walkable, at `cell` px."""
    n = N // cell
    w = walk[:n * cell, :n * cell].reshape(n, cell, n, cell).mean((1, 3)) > 0.5
    solid = ~w
    # only solid cells next to walkable ones matter
    solid &= ndimage.binary_dilation(w, iterations=2)
    boxes = []
    open_runs = {}
    for j in range(n):
        row = solid[j]
        runs = []
        i = 0
        while i < n:
            if row[i]:
                k = i
                while k < n and row[k]:
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


def lights(cv):
    """Torches, braziers and lit windows' flames: bright orange blobs in the image."""
    c = cv.col.astype(int)
    flame = (c[..., 0] > 235) & (c[..., 1] > 150) & (c[..., 2] < 120) & (cv.kind == KIND_UP)
    core = (c[..., 0] > 248) & (c[..., 1] > 225) & (c[..., 2] > 110)
    lab, n = ndimage.label(ndimage.binary_dilation(flame, iterations=2))
    out = []
    for i, s in enumerate(ndimage.find_objects(lab)):
        m = lab[s] == i + 1
        sz = m.sum()
        if sz < 60 or (core[s] & m).sum() < 6:
            continue
        cy = (s[0].start + s[0].stop) / 2
        cx = (s[1].start + s[1].stop) / 2
        out.append([round(cx), round(cy), 'torch' if sz < 900 else 'brazier'])
    return out


def save(cv):
    depth = np.zeros((N, N, 3), np.uint8)
    b = np.clip(cv.base, 0, 65535)
    depth[..., 0] = (b >> 8) & 255
    depth[..., 1] = b & 255
    depth[..., 2] = cv.kind
    n = N // CHUNK
    for r in range(n):
        for c in range(n):
            sl = (slice(r * CHUNK, (r + 1) * CHUNK), slice(c * CHUNK, (c + 1) * CHUNK))
            Image.fromarray(cv.col[sl]).save(OUT + 'col_%d_%d.png' % (r, c))
            Image.fromarray(depth[sl]).save(OUT + 'dep_%d_%d.png' % (r, c))
    Image.fromarray(cv.col).resize((N // 4, N // 4), Image.Resampling.BOX).save(OUT + 'preview.png')


if __name__ == '__main__':
    cv, n, nt = build()
    np.save('/tmp/c7_kind.npy', cv.kind)
    np.save('/tmp/c7_base.npy', cv.base)
    np.save('/tmp/c7_col.npy', cv.col)
    if 'nosave' not in sys.argv:
        save(cv)
        walk = walkable(cv, cv.cls)
        Image.fromarray((walk[::4, ::4] * 255).astype(np.uint8)).save(OUT + 'walk_debug.png')
        boxes = collision(walk)
        json.dump(boxes, open(OUT + 'collision.json', 'w'))
        lt = lights(cv)
        json.dump(lt, open(OUT + 'lights.json', 'w'))
        print('collision boxes', len(boxes), 'lights', len(lt))
    else:
        Image.fromarray(cv.col).resize((N // 4, N // 4), Image.Resampling.BOX).save(OUT + 'preview.png')
    print('items', n, 'trees', nt)
