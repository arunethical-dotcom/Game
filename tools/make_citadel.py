"""Art for the Royal Citadel, drawn 1:1 (one art pixel = one game pixel).

Textures (seamless, repeated by the game):  art/cit_tex_<name>.png
Sprites (single objects):                    art/cit_<name>.png
Run:  python3 make_citadel.py
"""
import math
import random
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, mask, outline, paint_mask

OUT = '../art/'
OL = hexc('1e1610')
BAYER = [[0, 2], [3, 1]]


def ramp(*hs):
    return [hexc(h) for h in hs]


STONE = ramp('6b6255', '857b6c', '9e9483', 'b5ab98', 'cbc2ae', 'ddd5c2')
SLATE = ramp('172848', '213a66', '2c4c86', '3a62a6', '5582c4', '7aa2dc')
GOLD = ramp('6e4a1c', 'a0702c', 'd0a050', 'f2d080', 'fff0b8')
RED = ramp('4a0c10', '6e1418', '962026', 'b83030', 'd84848')
BLUE = ramp('16264a', '22386c', '2f4f94', '4268b8', '6a8ad6')
MARBLE = ramp('8a90a0', 'a8aebc', 'c4c8d2', 'dcdfe6', 'eef0f4')
WOOD = ramp('3d2414', '5a3820', '7a4e2c', '96663a', 'b8844e')
LEAF = ramp('1f4a22', '2a5e2a', '387634', '4a8c3e', '62a64e')
IRON = ramp('2e3036', '4a4e56', '6a6e76', '9aa0a8', 'd8dde3')


def shade(c, t):
    return mix(c, (255, 244, 220, 255), t) if t > 0 else mix(c, (24, 16, 12, 255), -t)


def save(name, img, ol=True):
    if ol:
        img = outline(img, OL)
    img.save(OUT + name + '.png')
    return img


# ============================================================ textures

def blocks(W, H, rows, cols_choice, base_ramp, mortar, seed, moss=0.0, crack=0.0, bevel=True):
    """Seamless ashlar: rows of blocks of varied width, lit from the top-left."""
    rng = random.Random(seed)
    img = new(W, H)
    p = img.load()
    for y in range(H):
        for x in range(W):
            p[x, y] = hexc(mortar)
    rh = H // rows
    for r in range(rows):
        x = rng.randrange(0, 12)
        widths = []
        total = 0
        while total < W:
            w = rng.choice(cols_choice)
            if total + w > W:
                w = W - total
            widths.append(w)
            total += w
        x0 = (r * 13) % W
        for w in widths:
            tone = rng.randrange(1, len(base_ramp) - 1)
            for yy in range(r * rh, r * rh + rh - 1):
                for xx in range(x0, x0 + w - 1):
                    t = tone
                    if bevel:
                        if yy == r * rh: t += 1
                        if xx == x0: t += 1
                        if yy == r * rh + rh - 2: t -= 1
                        if xx == x0 + w - 2: t -= 1
                    c = base_ramp[max(0, min(len(base_ramp) - 1, t))]
                    if rng.random() < 0.07:
                        c = shade(c, -0.07)
                    p[xx % W, yy] = c
            x0 += w
    for _ in range(int(W * H * moss / 40)):
        x, y = rng.randrange(W), rng.randrange(H)
        p[x, y] = rng.choice([hexc('5e8a3a'), hexc('4c7630'), hexc('6e9a44')])
    for _ in range(int(crack)):
        x, y = rng.randrange(W), rng.randrange(H)
        for i in range(rng.randrange(3, 7)):
            p[(x + i // 2) % W, (y + i) % H] = hexc(mortar)
    return img


def tex_stone():
    return blocks(64, 48, 3, [20, 24, 28, 32], STONE[1:5], '5a5246', 1, moss=0.25, crack=4)


def tex_walltop():
    return blocks(32, 32, 4, [10, 12, 16], STONE[2:6], '857b6c', 2)


def tex_battlement():
    """Crenellations seen from the front: merlons and gaps, tiles every 32 px."""
    W, H = 32, 18
    img = new(W, H)
    d = ImageDraw.Draw(img)
    for x0 in (0, 16):
        d.rectangle([x0, 0, x0 + 11, H - 1], fill=STONE[3])
        d.rectangle([x0, 0, x0 + 11, 1], fill=STONE[5])
        d.rectangle([x0, 0, x0 + 1, H - 1], fill=STONE[4])
        d.rectangle([x0 + 10, 2, x0 + 11, H - 1], fill=STONE[1])
        d.line([(x0 + 2, 9), (x0 + 9, 9)], fill=STONE[2])
    d.rectangle([0, H - 3, W - 1, H - 1], fill=STONE[2])
    d.line([(0, H - 1), (W - 1, H - 1)], fill=STONE[0])
    return img


def tex_roof():
    """Blue slate in clear overlapping rows: each slate lit on top, shadowed underneath."""
    rng = random.Random(4)
    W, H = 48, 32
    img = new(W, H)
    p = img.load()
    rh = 8
    for y in range(H):
        r = y // rh
        ry = y % rh
        for x in range(W):
            off = (r % 2) * 6
            bx = (x + off) % 12
            tone = 3 + ((x + off) // 12 * 7 + r * 3) % 3 - 1
            t = tone
            if ry == 0: t = 5
            elif ry == 1: t = tone + 1
            elif ry >= rh - 2: t = 1 if ry == rh - 2 else 0
            if bx == 11 and ry < rh - 2: t = min(t, 1)
            if bx == 0 and ry < rh - 2: t += 1
            c = SLATE[max(0, min(5, t))]
            if rng.random() < 0.04:
                c = shade(c, -0.1)
            p[x, y] = c
    return img


def tex_marble():
    rng = random.Random(5)
    S = 32
    img = new(S, S)
    p = img.load()
    for y in range(S):
        for x in range(S):
            light = ((x // 16) + (y // 16)) % 2 == 0
            base = [hexc('dcd6cc'), hexc('e4dfd6')] if light else [hexc('aeb6c4'), hexc('b8bfcc')]
            c = base[1] if (x + y) % 5 else base[0]
            if x % 16 == 0 or y % 16 == 0:
                c = shade(c, 0.1)
            if x % 16 == 15 or y % 16 == 15:
                c = shade(c, -0.15)
            p[x, y] = c
    for _ in range(6):  # veins
        x, y = rng.randrange(S), rng.randrange(S)
        for i in range(rng.randrange(4, 9)):
            xx, yy = (x + i) % S, (y + (i // 2)) % S
            p[xx, yy] = shade(p[xx, yy], -0.12)
    return img


def tex_flag():
    return blocks(64, 64, 4, [14, 16, 20, 24], ramp('a99c84', 'b8ab92', 'c6baa0', 'd2c7ae', 'ddd3bc'), '8e816a', 6, moss=0.15, crack=3)


def tex_carpet():
    S = 32
    img = new(S, S)
    p = img.load()
    for y in range(S):
        for x in range(S):
            c = RED[2]
            if (x + y) % 8 == 0 or (x - y) % 8 == 0:
                c = RED[1]
            if x % 16 == 8 and y % 16 == 8:
                c = GOLD[2]
            p[x, y] = c
    return img


def tex_noise(shades, seed, S=32, cells=4, specks=None):
    rng = random.Random(seed)
    g = [[rng.random() for _ in range(cells)] for _ in range(cells)]
    step = S / cells
    def f(x, y):
        gx, gy = x / step, y / step
        x0, y0 = int(gx) % cells, int(gy) % cells
        x1, y1 = (x0 + 1) % cells, (y0 + 1) % cells
        tx, ty = gx - int(gx), gy - int(gy)
        a = g[y0][x0] * (1 - tx) + g[y0][x1] * tx
        b = g[y1][x0] * (1 - tx) + g[y1][x1] * tx
        return a * (1 - ty) + b * ty
    img = new(S, S)
    p = img.load()
    n = len(shades)
    for y in range(S):
        for x in range(S):
            t = f(x, y) + (BAYER[y % 2][x % 2] - 1.5) * 0.05
            p[x, y] = shades[max(0, min(n - 1, int(t * n)))]
    if specks:
        for _ in range(specks[1]):
            p[rng.randrange(S), rng.randrange(S)] = rng.choice(specks[0])
    return img


def tex_hedge_top():
    rng = random.Random(9)
    img = tex_noise(LEAF[1:5], 9)
    p = img.load()
    for _ in range(40):
        x, y = rng.randrange(32), rng.randrange(32)
        p[x, y] = LEAF[4]; p[(x + 1) % 32, y] = LEAF[3]; p[x, (y + 1) % 32] = LEAF[1]
    return img


def tex_hedge_face():
    rng = random.Random(10)
    W, H = 32, 20
    img = new(W, H)
    p = img.load()
    for y in range(H):
        for x in range(W):
            t = 2 - (y * 2) // H
            if rng.random() < 0.25: t += rng.choice([-1, 1])
            p[x, y] = LEAF[max(0, min(4, t))]
    return img


def tex_water():
    rng = random.Random(11)
    S = 64
    img = tex_noise(ramp('2a5e88', '306a96', '3878a4', '3f84b0'), 11, S, 4)
    p = img.load()
    for _ in range(26):
        x, y = rng.randrange(S), rng.randrange(S)
        for i in range(rng.randrange(4, 9)):
            p[(x + i) % S, y] = hexc('7ab8de') if i % 3 else hexc('a8d4f0')
    return img


def tex_embank():
    """Stone side of the moat, wet and mossy toward the water."""
    img = blocks(32, 24, 2, [12, 16, 20], ramp('5a5246', '6b6255', '7a7062', '8a7f6e'), '403a32', 12, moss=0.6)
    p = img.load()
    for x in range(32):
        p[x, 23] = hexc('2a3e2a')
        if x % 3: p[x, 22] = hexc('3e5e34')
    return img


def tex_wood():
    rng = random.Random(13)
    img = new(32, 32)
    p = img.load()
    for y in range(32):
        plank = y // 8
        for x in range(32):
            seam = (x + plank * 11) % 32 == 0
            t = 2 + (1 if y % 8 == 0 else 0) - (1 if y % 8 == 7 else 0)
            if seam: t = 0
            c = WOOD[max(0, min(4, t))]
            if rng.random() < 0.08: c = shade(c, -0.1)
            p[x, y] = c
    return img


# ============================================================ sprites

def tower(name, W, body_h, cone_h, flag=True, seed=1):
    rng = random.Random(seed)
    H = body_h + cone_h + (30 if flag else 8)
    img = new(W, H)
    d = ImageDraw.Draw(img)
    p = img.load()
    top = H - body_h
    R = W // 2
    # round body with horizontal courses, lit on the left
    for y in range(top, H):
        for x in range(2, W - 2):
            u = (x - R) / (R - 2)
            if abs(u) > 1: continue
            t = 3.4 - u * 1.6 - 0.4
            course = (y - top) // 12
            bx = (x + course * 7) % 16
            if (y - top) % 12 == 11: t -= 1.3
            elif (y - top) % 12 == 0: t += 0.6
            if bx == 0: t -= 0.8
            c = STONE[max(0, min(5, int(t)))]
            if rng.random() < 0.05: c = shade(c, -0.08)
            p[x, y] = c
    # base flare and bottom ellipse
    d.rectangle([1, H - 10, W - 2, H - 1], fill=STONE[2])
    d.line([(1, H - 10), (W - 2, H - 10)], fill=STONE[4])
    # arrow slits and a window
    for (yy, h) in ((top + 30, 14), (top + body_h // 2 + 10, 16)):
        d.rectangle([R - 2, yy, R + 1, yy + h], fill=hexc('1a1410'))
    d.rectangle([R - 6, top + 60, R + 5, top + 78], fill=hexc('1a1410'))
    d.ellipse([R - 6, top + 54, R + 5, top + 66], fill=hexc('1a1410'))
    d.rectangle([R - 4, top + 62, R + 3, top + 77], fill=hexc('f2c060'))
    d.line([(R, top + 60), (R, top + 77)], fill=hexc('5a3a20'))
    # corbelled parapet ring
    d.rectangle([0, top - 6, W - 1, top + 6], fill=STONE[3])
    d.line([(0, top - 6), (W - 1, top - 6)], fill=STONE[5])
    for x in range(2, W - 2, 6):
        d.rectangle([x, top + 6, x + 3, top + 10], fill=STONE[2])
    # blue cone roof with slate rows and a gold finial
    ct = top - 6 - cone_h
    for y in range(ct, top - 5):
        frac = (y - ct) / cone_h
        hw = int(2 + frac * (W / 2 + 2))
        for x in range(R - hw, R + hw + 1):
            if not (0 <= x < W): continue
            u = (x - R) / max(1, hw)
            t = 3.2 - u * 1.4
            if (y - ct) % 7 == 6: t -= 1
            if (x + (y - ct) // 7 * 3) % 7 == 0 and frac > 0.2: t -= 0.6
            p[x, y] = SLATE[max(0, min(5, int(t)))]
    d.line([(R - W // 2 - 2, top - 6), (R + W // 2 + 2, top - 6)], fill=SLATE[0])
    d.rectangle([R - 1, ct - 6, R, ct], fill=GOLD[2])
    d.ellipse([R - 2, ct - 9, R + 2, ct - 5], fill=GOLD[3])
    if flag:
        d.line([(R, ct - 22), (R, ct - 8)], fill=IRON[1])
        d.polygon([(R + 1, ct - 22), (R + 16, ct - 18), (R + 1, ct - 14)], fill=BLUE[3])
        d.line([(R + 1, ct - 21), (R + 12, ct - 18)], fill=BLUE[4])
        d.point((R + 6, ct - 18), fill=GOLD[3])
    return save(name, img)


def gate():
    """The front of the gatehouse between its two towers: a deep arch with a raised portcullis."""
    W, H = 132, 128
    img = new(W, H)
    d = ImageDraw.Draw(img)
    base = blocks(W, H, 8, [16, 20, 24], STONE[1:5], '5a5246', 21, moss=0.2)
    img.paste(base, (0, 0))
    # arch opening
    ax0, ax1, atop = 30, 101, 46
    d.rectangle([ax0, atop + 18, ax1, H - 1], fill=hexc('120c08'))
    d.ellipse([ax0, atop, ax1, atop + 40], fill=hexc('120c08'))
    # passage floor and inner light
    d.rectangle([ax0 + 6, H - 24, ax1 - 6, H - 1], fill=hexc('3a3228'))
    d.rectangle([ax0 + 14, H - 30, ax1 - 14, H - 26], fill=hexc('5a4e3c'))
    # voussoirs around the arch
    for k in range(13):
        a = math.pi + k * math.pi / 12
        cx, cy = (ax0 + ax1) / 2, atop + 20
        x0, y0 = cx + math.cos(a) * 37, cy + math.sin(a) * 22
        x1, y1 = cx + math.cos(a) * 44, cy + math.sin(a) * 28
        d.line([(x0, y0), (x1, y1)], fill=STONE[0])
    d.arc([ax0 - 7, atop - 7, ax1 + 7, atop + 47], 180, 360, fill=STONE[5])
    # raised portcullis teeth
    for x in range(ax0 + 6, ax1 - 4, 8):
        d.rectangle([x, atop + 10, x + 2, atop + 26], fill=IRON[1])
        d.point((x + 1, atop + 26), fill=IRON[3])
    d.line([(ax0 + 6, atop + 14), (ax1 - 6, atop + 14)], fill=IRON[1], width=2)
    # royal crest above the arch
    cx = W // 2
    d.polygon([(cx - 12, 8), (cx + 12, 8), (cx + 12, 22), (cx, 32), (cx - 12, 22)], fill=BLUE[2])
    d.line([(cx - 12, 8), (cx + 12, 8)], fill=GOLD[3], width=2)
    d.polygon([(cx, 12), (cx + 5, 19), (cx, 26), (cx - 5, 19)], fill=GOLD[2])
    d.point((cx, 18), fill=GOLD[4])
    # battlement on top
    bt = tex_battlement()
    for x in range(0, W, 32):
        img.paste(bt, (x, 0), bt)
    return save('cit_gate', img)


def door(name, W=64, H=84, open_=False):
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # stone frame
    d.rectangle([0, 18, W - 1, H - 1], fill=STONE[2])
    d.ellipse([0, 0, W - 1, 40], fill=STONE[2])
    d.arc([0, 0, W - 1, 40], 180, 360, fill=STONE[4])
    d.rectangle([5, 22, W - 6, H - 1], fill=hexc('1a1008'))
    d.ellipse([5, 5, W - 6, 39], fill=hexc('1a1008'))
    if open_:
        # doors swung open, warm light from inside
        d.rectangle([12, 26, W - 13, H - 1], fill=hexc('4a2e18'))
        d.rectangle([16, 30, W - 17, H - 1], fill=hexc('8a5a2a'))
        d.rectangle([20, 34, W - 21, H - 1], fill=hexc('c8883a'))
        d.rectangle([7, 22, 12, H - 1], fill=WOOD[1])
        d.rectangle([W - 13, 22, W - 8, H - 1], fill=WOOD[1])
    else:
        for x in range(7, W - 7, 6):
            d.rectangle([x, 12, x + 4, H - 1], fill=WOOD[2])
            d.line([(x, 12), (x, H - 1)], fill=WOOD[3])
        d.line([(W // 2, 8), (W // 2, H - 1)], fill=WOOD[0], width=2)
        for y in (34, H - 18):
            d.line([(7, y), (W - 8, y)], fill=IRON[1], width=3)
            d.line([(7, y - 1), (W - 8, y - 1)], fill=IRON[3])
        for x in (W // 2 - 6, W // 2 + 4):
            d.ellipse([x, 50, x + 3, 54], fill=GOLD[2])
    return save(name, img)


def window(name, W, H, glass, mullion=True):
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, W // 2, W - 1, H - 1], fill=STONE[1])
    d.ellipse([0, 0, W - 1, W], fill=STONE[1])
    d.rectangle([2, W // 2, W - 3, H - 3], fill=glass[0])
    d.ellipse([2, 2, W - 3, W - 2], fill=glass[0])
    for i, c in enumerate(glass[1:]):
        x = 3 + (i * 3) % (W - 6)
        d.rectangle([x, W // 2 + i * 3 % (H - W), x + 2, W // 2 + i * 3 % (H - W) + 3], fill=c)
    if mullion:
        d.line([(W // 2, 3), (W // 2, H - 3)], fill=STONE[0])
        d.line([(2, H * 0.6), (W - 3, H * 0.6)], fill=STONE[0])
    d.rectangle([0, H - 3, W - 1, H - 1], fill=STONE[3])
    return save(name, img)


def banner(name, body, trim):
    W, H = 22, 66
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, 3], fill=GOLD[1])
    d.line([(0, 0), (W - 1, 0)], fill=GOLD[3])
    d.polygon([(2, 4), (W - 3, 4), (W - 3, H - 10), (W // 2, H - 1), (2, H - 10)], fill=body[2])
    d.line([(2, 4), (2, H - 10)], fill=body[3])
    d.line([(W - 3, 4), (W - 3, H - 10)], fill=body[1])
    d.line([(4, 7), (W - 5, 7)], fill=trim[2])
    d.line([(4, H - 14), (W - 5, H - 14)], fill=trim[2])
    cx = W // 2
    d.polygon([(cx, 18), (cx + 6, 27), (cx, 38), (cx - 6, 27)], fill=trim[2])
    d.polygon([(cx, 22), (cx + 3, 27), (cx, 33), (cx - 3, 27)], fill=trim[3])
    d.point((cx, 27), fill=trim[4])
    return save(name, img)


def brazier():
    W, H = 26, 40
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([7, 16, 18, H - 4], fill=STONE[3])
    d.line([(7, 16), (7, H - 4)], fill=STONE[4])
    d.line([(18, 16), (18, H - 4)], fill=STONE[1])
    d.rectangle([4, H - 5, 21, H - 1], fill=STONE[2])
    d.polygon([(1, 6), (24, 6), (20, 16), (5, 16)], fill=IRON[1])
    d.line([(1, 6), (24, 6)], fill=IRON[3])
    d.rectangle([3, 3, 22, 6], fill=hexc('4a2a14'))
    return save('cit_brazier', img)


def lamp():
    W, H = 18, 64
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([7, 14, 9, H - 4], fill=IRON[1])
    d.line([(7, 14), (7, H - 4)], fill=IRON[3])
    d.rectangle([4, H - 5, 12, H - 1], fill=IRON[0])
    d.rectangle([3, 2, 13, 14], fill=IRON[1])
    d.rectangle([5, 4, 11, 12], fill=hexc('ffd870'))
    d.rectangle([6, 5, 8, 8], fill=hexc('fff4c0'))
    d.polygon([(2, 2), (14, 2), (8, -2)], fill=IRON[0])
    d.line([(8, 4), (8, 12)], fill=IRON[1])
    return save('cit_lamp', img)


def fountain():
    W, H = 132, 100
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # lower basin
    d.ellipse([2, 40, W - 3, H - 2], fill=STONE[2])
    d.ellipse([2, 36, W - 3, H - 8], fill=STONE[4])
    d.ellipse([10, 42, W - 11, H - 14], fill=hexc('3878a4'))
    d.ellipse([18, 48, W - 19, H - 20], fill=hexc('4a90bc'))
    for (x, y) in ((30, 60), (90, 66), (60, 74), (44, 52), (84, 54)):
        d.line([(x, y), (x + 8, y)], fill=hexc('a8d8f4'))
    # column and upper bowl
    cx = W // 2
    d.rectangle([cx - 7, 24, cx + 6, 66], fill=STONE[3])
    d.line([(cx - 7, 24), (cx - 7, 66)], fill=STONE[5])
    d.ellipse([cx - 28, 18, cx + 27, 38], fill=STONE[3])
    d.ellipse([cx - 28, 15, cx + 27, 33], fill=STONE[5])
    d.ellipse([cx - 22, 19, cx + 21, 30], fill=hexc('4a90bc'))
    # spout and falling water
    d.rectangle([cx - 2, 2, cx + 1, 19], fill=STONE[4])
    d.ellipse([cx - 4, 0, cx + 3, 6], fill=STONE[5])
    for dx in (-24, -14, 13, 23):
        d.line([(cx + dx, 30), (cx + dx * 1.3, 58)], fill=hexc('cfe8f6'))
    return save('cit_fountain', img)


def statue():
    W, H = 40, 92
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # plinth
    d.rectangle([4, 62, 35, H - 1], fill=STONE[3])
    d.rectangle([2, 58, 37, 64], fill=STONE[4])
    d.line([(4, 62), (4, H - 1)], fill=STONE[5])
    d.line([(35, 62), (35, H - 1)], fill=STONE[1])
    d.rectangle([12, 72, 27, 80], fill=STONE[2])
    # knight in pale stone with a sword point-down
    g = ramp('8a8678', 'a6a294', 'c0bcae', 'd8d4c6')
    d.rectangle([14, 30, 25, 57], fill=g[2])
    d.rectangle([14, 30, 15, 57], fill=g[3])
    d.rectangle([24, 32, 25, 57], fill=g[0])
    d.ellipse([14, 16, 25, 30], fill=g[2])
    d.rectangle([15, 21, 24, 23], fill=g[0])
    d.rectangle([9, 32, 14, 46], fill=g[1])
    d.rectangle([25, 32, 30, 46], fill=g[1])
    d.rectangle([18, 4, 21, 57], fill=g[3])
    d.rectangle([13, 44, 26, 46], fill=g[2])
    d.polygon([(10, 34), (14, 34), (14, 54), (8, 50)], fill=g[1])  # cape
    return save('cit_statue', img)


def topiary(name, kind):
    W, H = 48, 84
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # stone planter
    d.rectangle([10, H - 16, W - 11, H - 1], fill=STONE[3])
    d.rectangle([8, H - 18, W - 9, H - 14], fill=STONE[4])
    d.line([(10, H - 1), (W - 11, H - 1)], fill=STONE[1])
    d.rectangle([22, H - 30, 25, H - 17], fill=WOOD[1])
    m = mask(W, H)
    md = ImageDraw.Draw(m)
    if kind == 'ball':
        md.ellipse([6, 18, W - 7, H - 26], fill=255)
        md.ellipse([14, 2, W - 15, 26], fill=255)
    else:
        md.polygon([(W // 2, 0), (W - 10, H - 30), (W // 2, H - 24), (9, H - 30)], fill=255)
    paint_mask(img, m, LEAF, light=(-0.8, -0.8), rng=random.Random(3), dither=0.3)
    p = img.load()
    rng = random.Random(4)
    for _ in range(60):
        x, y = rng.randrange(W), rng.randrange(H)
        if m.getpixel((x, y)) and m.getpixel((min(W - 1, x + 1), y)):
            p[x, y] = LEAF[4] if x < W // 2 else LEAF[3]
    return save(name, img)


def flowerbed():
    W, H = 72, 34
    img = new(W, H)
    d = ImageDraw.Draw(img)
    rng = random.Random(14)
    d.rectangle([0, 6, W - 1, H - 1], fill=STONE[3])
    d.rectangle([0, 6, W - 1, 8], fill=STONE[5])
    d.rectangle([3, 9, W - 4, H - 5], fill=hexc('4a3222'))
    cols = ['e8384a', 'f2c83a', 'f2f0e8', 'c86ae0', 'ff8a3a']
    for _ in range(46):
        x, y = rng.randrange(5, W - 6), rng.randrange(2, H - 7)
        c = hexc(rng.choice(cols))
        d.point((x, y + 2), fill=LEAF[2])
        d.rectangle([x - 1, y, x + 1, y + 1], fill=c)
        d.point((x, y - 1), fill=mix(c, (255, 255, 255, 255), 0.4))
    return save('cit_flowerbed', img)


def bench():
    W, H = 56, 26
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([2, 4, W - 3, 12], fill=STONE[4])
    d.line([(2, 4), (W - 3, 4)], fill=STONE[5])
    d.rectangle([2, 12, W - 3, 15], fill=STONE[2])
    for x in (6, W - 14):
        d.rectangle([x, 15, x + 7, H - 1], fill=STONE[2])
        d.line([(x, 15), (x, H - 1)], fill=STONE[3])
    return save('cit_bench', img)


def throne():
    W, H = 76, 104
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # tall back with a crest
    d.polygon([(10, 26), (W - 11, 26), (W - 11, 70), (10, 70)], fill=GOLD[2])
    d.polygon([(14, 10), (W - 15, 10), (W - 11, 26), (10, 26)], fill=GOLD[2])
    d.polygon([(W // 2, 0), (W // 2 + 10, 12), (W // 2 - 10, 12)], fill=GOLD[3])
    d.rectangle([16, 18, W - 17, 66], fill=RED[2])
    d.rectangle([16, 18, 18, 66], fill=RED[3])
    d.line([(10, 26), (10, 70)], fill=GOLD[3])
    d.line([(W - 11, 26), (W - 11, 70)], fill=GOLD[1])
    cx = W // 2
    d.polygon([(cx, 24), (cx + 8, 36), (cx, 50), (cx - 8, 36)], fill=GOLD[3])
    d.polygon([(cx, 30), (cx + 4, 36), (cx, 44), (cx - 4, 36)], fill=BLUE[3])
    # seat, arms and legs
    d.rectangle([6, 66, W - 7, 80], fill=GOLD[1])
    d.rectangle([10, 64, W - 11, 74], fill=RED[3])
    d.line([(10, 64), (W - 11, 64)], fill=RED[4])
    for x in (2, W - 12):
        d.rectangle([x, 54, x + 9, 72], fill=GOLD[2])
        d.ellipse([x - 1, 50, x + 10, 58], fill=GOLD[3])
    d.rectangle([8, 80, 15, H - 1], fill=GOLD[1])
    d.rectangle([W - 16, 80, W - 9, H - 1], fill=GOLD[1])
    d.rectangle([8, 80, 9, H - 1], fill=GOLD[3])
    return save('cit_throne', img)


def pillar():
    W, H = 34, 120
    img = new(W, H)
    d = ImageDraw.Draw(img)
    for x in range(5, W - 5):
        u = (x - W / 2) / (W / 2 - 5)
        t = 3.2 - u * 1.5
        flute = (x - 5) % 6 == 5
        c = MARBLE[max(0, min(4, int(t - (1 if flute else 0))))]
        d.line([(x, 16), (x, H - 14)], fill=c)
    # capital and base
    for (y0, y1) in ((4, 16), (H - 14, H - 1)):
        d.rectangle([1, y0, W - 2, y1], fill=MARBLE[3])
        d.line([(1, y0), (W - 2, y0)], fill=MARBLE[4])
        d.line([(1, y1), (W - 2, y1)], fill=MARBLE[1])
    d.rectangle([3, 0, W - 4, 4], fill=MARBLE[4])
    d.rectangle([3, 16, W - 4, 18], fill=GOLD[2])
    d.rectangle([3, H - 16, W - 4, H - 14], fill=GOLD[2])
    return save('cit_pillar', img)


def dummy():
    W, H = 32, 60
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([15, 20, 17, H - 2], fill=WOOD[2])
    d.rectangle([4, 24, W - 5, 27], fill=WOOD[2])
    d.ellipse([8, 18, 24, 46], fill=hexc('c8a870'))
    d.ellipse([10, 20, 18, 30], fill=hexc('e0c48a'))
    for y in (26, 34, 40):
        d.line([(9, y), (23, y)], fill=hexc('8a6a3a'))
    d.ellipse([10, 4, 22, 18], fill=hexc('c8a870'))
    d.line([(12, 11), (20, 11)], fill=hexc('8a6a3a'))
    d.rectangle([9, H - 4, 23, H - 1], fill=WOOD[1])
    return save('cit_dummy', img)


def target():
    W, H = 40, 58
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.line([(8, 24), (4, H - 1)], fill=WOOD[1], width=2)
    d.line([(31, 24), (35, H - 1)], fill=WOOD[1], width=2)
    for r, c in ((18, 'f2ead2'), (14, 'c83a3a'), (10, 'f2ead2'), (6, 'c83a3a'), (2, 'f2c83a')):
        d.ellipse([20 - r, 22 - r, 20 + r, 22 + r], fill=hexc(c))
    d.line([(20, 22), (30, 12)], fill=WOOD[2])
    return save('cit_target', img)


def pew():
    W, H = 76, 30
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([2, 0, W - 3, 10], fill=WOOD[2])
    d.line([(2, 0), (W - 3, 0)], fill=WOOD[4])
    d.rectangle([2, 10, W - 3, 18], fill=WOOD[3])
    d.rectangle([2, 18, W - 3, 21], fill=WOOD[1])
    for x in (2, W - 8):
        d.rectangle([x, 0, x + 5, H - 1], fill=WOOD[1])
    return save('cit_pew', img)


def altar():
    W, H = 84, 60
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 24, W - 5, H - 1], fill=MARBLE[3])
    d.line([(4, 24), (W - 5, 24)], fill=MARBLE[4])
    d.rectangle([4, 24, W - 5, 30], fill=hexc('f2ead8'))
    d.rectangle([W // 2 - 12, 30, W // 2 + 11, H - 4], fill=BLUE[2])
    d.line([(W // 2 - 12, 30), (W // 2 + 11, 30)], fill=GOLD[3])
    d.polygon([(W // 2, 34), (W // 2 + 5, 42), (W // 2, 50), (W // 2 - 5, 42)], fill=GOLD[2])
    for x in (12, 22, W - 24, W - 14):
        d.rectangle([x, 12, x + 3, 24], fill=hexc('f2ead2'))
        d.ellipse([x - 1, 6, x + 4, 12], fill=hexc('ffcc4a'))
        d.point((x + 1, 7), fill=hexc('fff4c0'))
    return save('cit_altar', img)


def stairs(name, up=True):
    W, H = 72, 64
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, H - 1], fill=STONE[1])
    d.rectangle([6, 0, W - 7, H - 1], fill=hexc('140e0a'))
    steps = 7
    for i in range(steps):
        if up:
            y = H - 1 - i * 9
            shade_t = 4 - i * 0.5
        else:
            y = 8 + i * 8
            shade_t = 4 - i * 0.55
        c = STONE[max(0, min(5, int(shade_t)))]
        d.rectangle([6, y - 7, W - 7, y], fill=c)
        d.line([(6, y - 7), (W - 7, y - 7)], fill=shade(c, 0.2))
    d.rectangle([0, 0, 5, H - 1], fill=STONE[3])
    d.rectangle([W - 6, 0, W - 1, H - 1], fill=STONE[2])
    return save(name, img)


def crest():
    W, H = 34, 40
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.polygon([(2, 2), (W - 3, 2), (W - 3, 20), (W // 2, H - 2), (2, 20)], fill=BLUE[2])
    d.line([(2, 2), (W - 3, 2)], fill=GOLD[3], width=2)
    d.line([(2, 2), (2, 20)], fill=GOLD[2])
    d.line([(W - 3, 2), (W - 3, 20)], fill=GOLD[1])
    d.polygon([(W // 2, 8), (W // 2 + 7, 18), (W // 2, 30), (W // 2 - 7, 18)], fill=GOLD[2])
    d.polygon([(W // 2, 12), (W // 2 + 3, 18), (W // 2, 25), (W // 2 - 3, 18)], fill=GOLD[4])
    return save('cit_crest', img)


TEXTURES = {
    'stone': tex_stone, 'walltop': tex_walltop, 'battlement': tex_battlement, 'roof': tex_roof,
    'marble': tex_marble, 'flag': tex_flag, 'carpet': tex_carpet,
    'gravel': lambda: tex_noise(ramp('b8ab90', 'c4b89c', 'd0c4a8', 'dbd0b6'), 7, specks=([hexc('8e8270'), hexc('ece4d0')], 30)),
    'sand': lambda: tex_noise(ramp('c8a46a', 'd2b078', 'dcbc86', 'e4c894'), 8, specks=([hexc('a8885a')], 20)),
    'hedge_top': tex_hedge_top, 'hedge_face': tex_hedge_face, 'water': tex_water,
    'embank': tex_embank, 'wood': tex_wood,
    'lawn': lambda: tex_noise(ramp('4e8a34', '559238', '5c9a3c', '64a242'), 15, specks=([hexc('7cb852'), hexc('437a2c')], 40)),
}


def build():
    for name, fn in TEXTURES.items():
        fn().save(OUT + 'cit_tex_%s.png' % name)
    tower('cit_tower', 84, 170, 104, seed=1)
    tower('cit_tower_small', 60, 130, 76, seed=2)
    gate()
    door('cit_door')
    door('cit_door_open', open_=True)
    door('cit_door_big', 88, 108, open_=True)
    window('cit_window', 14, 26, [hexc('f2b850'), hexc('ffd880'), hexc('e09838')])
    window('cit_window_dark', 14, 26, [hexc('2a3448'), hexc('3a4a66')])
    window('cit_window_stained', 24, 46, [hexc('2f4f94'), hexc('c83a3a'), hexc('f2c83a'), hexc('3aa85a'), hexc('6a8ad6'), hexc('c86ae0'),
                                          hexc('f2c83a'), hexc('c83a3a'), hexc('3aa85a')])
    banner('cit_banner_blue', BLUE, GOLD)
    banner('cit_banner_red', RED, GOLD)
    brazier(); lamp(); fountain(); statue()
    topiary('cit_topiary', 'ball'); topiary('cit_cypress', 'cone')
    flowerbed(); bench(); throne(); pillar(); dummy(); target(); pew(); altar(); crest()
    stairs('cit_stairs_up', True); stairs('cit_stairs_down', False)


if __name__ == '__main__':
    build()
    import glob, os
    files = sorted(glob.glob(OUT + 'cit_*.png'))
    sprites = [f for f in files if 'cit_tex_' not in f]
    texs = [f for f in files if 'cit_tex_' in f]
    W = 1400
    prev = Image.new('RGBA', (W, 760), hexc('5c9a3c'))
    x, y, rowh = 6, 6, 0
    for f in sprites:
        im = Image.open(f)
        if x + im.width > W:
            x, y, rowh = 6, y + rowh + 8, 0
        prev.paste(im, (x, y), im)
        x += im.width + 8
        rowh = max(rowh, im.height)
    y += rowh + 12
    x = 6
    for f in texs:
        t = Image.open(f)
        tile = Image.new('RGBA', (96, 96))
        for yy in range(0, 96, t.height):
            for xx in range(0, 96, t.width):
                tile.paste(t, (xx, yy))
        prev.paste(tile, (x, y))
        x += 100
    prev.save('/home/claude/preview_citadel.png')
    print(len(sprites), 'sprites', len(texs), 'textures')
