"""Small helpers for drawing pixel art with Pillow."""
from PIL import Image, ImageDraw
import random

def hexc(s, a=255):
    s = s.lstrip('#')
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)

def new(w, h):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))

def mix(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))

def mask(w, h):
    return Image.new('L', (w, h), 0)

def outline(img, col, diagonal=False):
    """Add a 1px outline around every opaque pixel."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    o = out.load()
    nb = [(1,0),(-1,0),(0,1),(0,-1)] + ([(1,1),(-1,-1),(1,-1),(-1,1)] if diagonal else [])
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in nb:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        o[x, y] = col
                        break
    return out

def paint_mask(img, m, ramp, light=(-0.6, -0.8), rng=None, dither=0.0, bbox=None):
    """Fill mask pixels with a colour ramp (dark..light), shaded from a light direction
    using the pixel's position inside the mask's bounding box."""
    w, h = img.size
    mp = m.load()
    ip = img.load()
    bb = bbox or m.getbbox()
    if not bb:
        return
    x0, y0, x1, y1 = bb
    bw, bh = max(1, x1 - x0), max(1, y1 - y0)
    rng = rng or random.Random(1)
    n = len(ramp)
    for y in range(y0, y1):
        for x in range(x0, x1):
            if mp[x, y] > 0:
                u = (x - x0) / bw - 0.5
                v = (y - y0) / bh - 0.5
                t = 0.5 - (u * light[0] + v * light[1])  # 0 dark .. 1 light
                # edges of the shape a bit darker
                edge = 0
                for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx, ny = x+dx, y+dy
                    if not (0 <= nx < w and 0 <= ny < h) or mp[nx, ny] == 0:
                        edge += 1
                if edge and dy_edge_below(mp, x, y, w, h):
                    t -= 0.25
                if dither:
                    t += (rng.random() - 0.5) * dither
                    if (x + y) % 2 == 0:
                        t += dither * 0.15
                idx = max(0, min(n - 1, int(t * n)))
                ip[x, y] = ramp[idx]

def dy_edge_below(mp, x, y, w, h):
    return y + 1 >= h or mp[x, y + 1] == 0

def noise_fill(img, box, colors, weights, rng):
    p = img.load()
    x0, y0, x1, y1 = box
    for y in range(y0, y1):
        for x in range(x0, x1):
            p[x, y] = rng.choices(colors, weights)[0]


# ---------------------------------------------------------------- double resolution

def _scale2x(img):
    """Scale2x / EPX: doubles resolution and smooths diagonal staircases."""
    w, h = img.size
    s = img.load()
    out = Image.new('RGBA', (w * 2, h * 2), (0, 0, 0, 0))
    o = out.load()
    def g(x, y):
        if 0 <= x < w and 0 <= y < h:
            return s[x, y]
        return (0, 0, 0, 0)
    for y in range(h):
        for x in range(w):
            P = s[x, y]
            A, B, C, D = g(x, y - 1), g(x + 1, y), g(x - 1, y), g(x, y + 1)
            e0 = e1 = e2 = e3 = P
            if C == A and C != D and A != B: e0 = A
            if A == B and A != C and B != D: e1 = B
            if D == C and D != B and C != A: e2 = C
            if B == D and B != A and D != C: e3 = D
            o[2 * x, 2 * y] = e0; o[2 * x + 1, 2 * y] = e1
            o[2 * x, 2 * y + 1] = e2; o[2 * x + 1, 2 * y + 1] = e3
    return out


def _shift(c, t):
    if t > 0:
        return tuple(int(c[i] + (255 - c[i]) * t) for i in range(3)) + (c[3],)
    return tuple(int(c[i] * (1 + t)) for i in range(3)) + (c[3],)


def finish(lo, outline_col, seed=1):
    """Turn a low-res sprite into a double-resolution one with finer detail:
    smoothed edges, a thin 1px outline, bevels on every colour block, and light texture."""
    rng = random.Random(seed)
    w, h = lo.size
    L = lo.load()
    hi = _scale2x(lo)
    H = hi.load()
    W2, H2 = hi.size
    oc = tuple(outline_col)

    def lo_px(x, y):
        if 0 <= x < w and 0 <= y < h:
            return L[x, y]
        return (0, 0, 0, 0)

    # bevels: lighter top/left edge, darker bottom/right edge of each colour block
    for y in range(h):
        for x in range(w):
            c = L[x, y]
            if c[3] == 0 or c[:3] == oc[:3]:
                continue
            up, dn, lf, rt = lo_px(x, y - 1), lo_px(x, y + 1), lo_px(x - 1, y), lo_px(x + 1, y)
            def adj(px, py, t):
                if H[px, py] == c:
                    H[px, py] = _shift(c, t)
            if up != c and up[3]:
                adj(2 * x, 2 * y, 0.12); adj(2 * x + 1, 2 * y, 0.12)
            if lf != c and lf[3]:
                adj(2 * x, 2 * y, 0.06); adj(2 * x, 2 * y + 1, 0.06)
            if dn != c and dn[3] and dn[:3] != oc[:3]:
                adj(2 * x, 2 * y + 1, -0.12); adj(2 * x + 1, 2 * y + 1, -0.12)
            if rt != c and rt[3] and rt[:3] != oc[:3]:
                adj(2 * x + 1, 2 * y, -0.06); adj(2 * x + 1, 2 * y + 1, -0.06)
            # texture on flat areas
            flat = up == c and dn == c and lf == c and rt == c
            if flat:
                for dx in (0, 1):
                    for dy in (0, 1):
                        r = rng.random()
                        if r < 0.07:
                            H[2 * x + dx, 2 * y + dy] = _shift(c, -0.07)
                        elif r < 0.11:
                            H[2 * x + dx, 2 * y + dy] = _shift(c, 0.06)

    # thin the outline: keep only outline pixels that touch transparency
    out = hi.copy()
    O = out.load()
    for y in range(H2):
        for x in range(W2):
            if H[x, y][3] and H[x, y][:3] == oc[:3]:
                touches_clear = False
                inner = None
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        n = H[nx, ny] if 0 <= nx < W2 and 0 <= ny < H2 else (0, 0, 0, 0)
                        if n[3] == 0:
                            touches_clear = True
                        elif n[:3] != oc[:3] and inner is None and (dx == 0 or dy == 0):
                            inner = n
                if not touches_clear and inner is not None:
                    O[x, y] = _shift(inner, -0.3)
    return out


def rebrick(img, bw=10, bh=6, seed=2):
    """Re-texture grey stone areas of a double-res sprite with fine bricks,
    keeping the original light and shadow."""
    rng = random.Random(seed)
    p = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            c = p[x, y]
            if c[3] == 0:
                continue
            mx, mn = max(c[:3]), min(c[:3])
            if mx - mn > 34 or mx < 95 or mx > 236:
                continue
            row = y // bh
            bx = (x + (row % 2) * (bw // 2)) % bw
            by = y % bh
            t = 0.0
            if by == bh - 1 or bx == bw - 1:
                t = -0.22
            elif by == 0:
                t = 0.1
            elif rng.random() < 0.05:
                t = -0.08
            if rng.random() < 0.012 and by != bh - 1:
                p[x, y] = (106, 160, 64, 255)  # moss
                continue
            p[x, y] = _shift(c, t)
