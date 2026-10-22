"""Second-pass citadel art: tile variants for floors and borders, plus furniture and
decor for the throne hall, corridors and rooms. Same palette as make_citadel.py:
aged limestone, dark stone, walnut, muted green, royal blue and restrained gold.

  art/cit_tiles.png   32x32 tiles; one row per floor type, 4 variants per row
  art/dec_<name>.png  single sprites, feet at the bottom centre
Run: python3 make_decor.py
"""
import math
import random
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, mask, outline, paint_mask

OUT = '../art/'
OL = hexc('1e1610')
T = 32


def ramp(*hs):
    return [hexc(h) for h in hs]


LIME = ramp('8e8370', 'a39784', 'b5aa95', 'c4b9a3', 'd1c7b1', 'ddd4bf')   # aged limestone
DARK = ramp('3e3a36', '4e4944', '5e5852', '6e6760', '7e776e')               # dark stone
WALNUT = ramp('2e1c10', '432a18', '5a3a22', '70492c', '8a5c38')
GREEN = ramp('233f22', '2f5229', '3c6632', '4a7a3c', '5e8e4a')
BLUE = ramp('16264a', '22386c', '2f4f94', '4268b8', '6a8ad6')
GOLD = ramp('6e4a1c', 'a0702c', 'c89a48', 'e8c070', 'f8e0a8')
RED = ramp('4a0c10', '6e1418', '8e2024', 'aa2e30', 'c84444')
MARBLE = ramp('a8a296', 'beb8ac', 'd0cbc0', 'ddd8ce', 'e8e4dc')


def shade(c, t):
    return mix(c, (255, 244, 220, 255), t) if t > 0 else mix(c, (20, 14, 10, 255), -t)


def save(name, img, ol=True):
    if ol:
        img = outline(img, OL)
    img.save(OUT + name + '.png')
    return img


# ============================================================ tile variants

def slab(p, x0, y0, w, h, base, rng, bevel=0.12, crack=0.0, moss=0.0):
    """One stone slab with a lit top-left edge and a shadowed bottom-right edge."""
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            c = base
            if y == y0 or x == x0:
                c = shade(base, bevel)
            elif y == y0 + h - 1 or x == x0 + w - 1:
                c = shade(base, -bevel * 1.3)
            elif rng.random() < 0.08:
                c = shade(base, rng.choice([-0.05, 0.05]))
            p[x, y] = c
    if crack and rng.random() < crack:
        cx, cy = rng.randrange(x0 + 2, x0 + w - 2), rng.randrange(y0 + 2, y0 + h - 2)
        for i in range(rng.randrange(3, 7)):
            xx, yy = cx + i // 2 * rng.choice([-1, 1]), cy + i
            if x0 < xx < x0 + w - 1 and y0 < yy < y0 + h - 1:
                p[xx, yy] = shade(base, -0.3)
    if moss and rng.random() < moss:
        for i in range(rng.randrange(2, 6)):
            xx = x0 + rng.choice([0, w - 1]) if rng.random() < 0.5 else rng.randrange(x0, x0 + w)
            yy = y0 + h - 1 if rng.random() < 0.6 else rng.randrange(y0, y0 + h)
            p[min(xx, x0 + w - 1), min(yy, y0 + h - 1)] = rng.choice([hexc('5e7e3a'), hexc('4c6a30')])


def tile_flag(v):
    """Courtyard flagstones: each tile is complete on its own, so any variant can sit next
    to any other without seams. Four layouts so the grid never reads as a repeat."""
    rng = random.Random(100 + v)
    img = new(T, T)
    p = img.load()
    for y in range(T):
        for x in range(T):
            p[x, y] = hexc('7a6f5e')
    layouts = [
        [(0, 0, 16, 16), (16, 0, 16, 16), (0, 16, 16, 16), (16, 16, 16, 16)],
        [(0, 0, 32, 16), (0, 16, 12, 16), (12, 16, 20, 16)],
        [(0, 0, 20, 20), (20, 0, 12, 20), (0, 20, 32, 12)],
        [(0, 0, 32, 32)],
    ]
    for (x, y, w, h) in layouts[v]:
        base = LIME[rng.randrange(2, 5)]
        slab(p, x + 1, y + 1, w - 1, h - 1, base, rng, crack=0.35, moss=0.25)
    return img


def tile_border(v):
    """Dark stone kerb band used to frame paths, buildings and the arena."""
    rng = random.Random(200 + v)
    img = new(T, T)
    p = img.load()
    for y in range(T):
        for x in range(T):
            p[x, y] = DARK[0]
    for (x, y, w, h) in [(0, 0, 16, 32), (16, 0, 16, 32)] if v % 2 else [(0, 0, 32, 16), (0, 16, 32, 16)]:
        slab(p, x + 1, y + 1, w - 1, h - 1, DARK[rng.randrange(2, 4)], rng, bevel=0.16, moss=0.2)
    return img


def tile_cobble(v):
    """Small rounded cobbles in limestone with a few dark stones, for the main avenue."""
    rng = random.Random(300 + v)
    img = new(T, T)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, T - 1, T - 1], fill=hexc('6e6454'))
    for row in range(4):
        off = (row % 2) * 4
        for col in range(4):
            x = col * 8 + off - 4
            y = row * 8
            base = DARK[3] if rng.random() < 0.15 else LIME[rng.randrange(1, 5)]
            for (xx0, xx1) in ((x, x + 7), (x + 32, x + 39)):
                d.ellipse([xx0, y, xx1 - 1, y + 7], fill=base)
                d.point((xx0 + 2, y + 1), fill=shade(base, 0.2))
                d.line([(xx0 + 2, y + 6), (xx1 - 3, y + 6)], fill=shade(base, -0.25))
    return img


def tile_marble(v):
    """Throne hall floor: large soft marble slabs, alternating cream and blue-grey by position
    (the game picks the colour), with faint veins."""
    rng = random.Random(400 + v)
    img = new(T, T)
    p = img.load()
    cream = v < 2
    base = [hexc('e0d3b8'), hexc('e6dac1')] if cream else [hexc('5f7ec2'), hexc('6785c6')]
    for y in range(T):
        for x in range(T):
            c = base[(x * 7 + y * 3) % 5 == 0]
            if x == 0 or y == 0:
                c = shade(c, 0.12)
            if x == T - 1 or y == T - 1:
                c = shade(c, -0.22)
            p[x, y] = c
    for _ in range(2):
        x, y = rng.randrange(4, 28), rng.randrange(4, 28)
        for i in range(rng.randrange(6, 14)):
            x += rng.choice([0, 1]); y += rng.choice([0, 1, 1])
            if 1 <= x < T - 1 and 1 <= y < T - 1:
                p[x, y] = shade(p[x, y], -0.1)
    return img


def tile_marble_border(v):
    """Inlaid border band: dark blue-grey marble with a gold line and a repeating diamond."""
    img = new(T, T)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, T - 1, T - 1], fill=hexc('1f2f66'))
    d.rectangle([0, 3, T - 1, T - 4], fill=hexc('2a3f84'))
    d.line([(0, 2), (T - 1, 2)], fill=GOLD[2])
    d.line([(0, T - 3), (T - 1, T - 3)], fill=GOLD[2])
    cx, cy = 16, 16
    d.polygon([(cx, cy - 8), (cx + 8, cy), (cx, cy + 8), (cx - 8, cy)], fill=GOLD[3])
    d.polygon([(cx, cy - 5), (cx + 5, cy), (cx, cy + 5), (cx - 5, cy)], fill=BLUE[2])
    d.point((cx, cy), fill=GOLD[3])
    if v % 2:
        for x in (2, 29):
            d.rectangle([x, 12, x + 1, 19], fill=GOLD[1])
    return img


def tile_wood(v):
    """Walnut parquet in short staggered planks."""
    rng = random.Random(600 + v)
    img = new(T, T)
    p = img.load()
    for y in range(T):
        plank = y // 8
        for x in range(T):
            off = (plank * 11 + v * 5) % 16
            seam = (x + off) % 16 == 0
            base = WALNUT[2 + ((x + off) // 16 + plank + v) % 2]
            t = 0.0
            if y % 8 == 0: t = 0.12
            if y % 8 == 7 or seam: t = -0.3
            c = shade(base, t)
            if rng.random() < 0.1:
                c = shade(c, -0.08)
            p[x, y] = c
    return img


def tile_lawn_edge(v):
    """Grass with a pale stone kerb along its top edge (rotated by the game)."""
    rng = random.Random(700 + v)
    img = new(T, T)
    p = img.load()
    for y in range(T):
        for x in range(T):
            p[x, y] = (0, 0, 0, 0)
    x = 0
    while x < T:
        w = rng.randrange(6, 11)
        slab(p, x, 0, min(w, T - x), 5, LIME[rng.randrange(2, 5)], rng, bevel=0.18)
        x += w
    for x in range(T):
        p[x, 5] = hexc('2f4a24')
        if rng.random() < 0.6:
            p[x, 6] = hexc('3c6632')
    return img


def tile_marble_border_v(v):
    return tile_marble_border(v).transpose(Image.Transpose.ROTATE_90)


# row order is used by the game (scripts/tiles.gd)
ROWS = [('flag', tile_flag), ('border', tile_border), ('cobble', tile_cobble), ('marble', tile_marble),
        ('marble_border', tile_marble_border), ('wood', tile_wood), ('lawn_edge', tile_lawn_edge),
        ('marble_border_v', tile_marble_border_v)]


def tiles():
    sheet = new(T * 4, T * len(ROWS))
    for r, (name, fn) in enumerate(ROWS):
        for v in range(4):
            sheet.paste(fn(v), (v * T, r * T))
    sheet.save(OUT + 'cit_tiles.png')
    return sheet


# ============================================================ furniture and decor

def sconce():
    W, H = 16, 30
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 14, 9, 22], fill=hexc('3a3c42'))
    d.polygon([(3, 22), (12, 22), (9, 28), (6, 28)], fill=hexc('4a4e56'))
    d.line([(3, 22), (12, 22)], fill=hexc('8a8e96'))
    d.rectangle([6, 6, 9, 14], fill=WALNUT[3])
    d.rectangle([5, 4, 10, 7], fill=hexc('2a1a10'))
    return save('dec_sconce', img)


def candelabra():
    W, H = 24, 50
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([11, 14, 12, H - 6], fill=GOLD[1])
    d.line([(11, 14), (11, H - 6)], fill=GOLD[3])
    d.polygon([(5, H - 1), (18, H - 1), (14, H - 6), (9, H - 6)], fill=GOLD[1])
    d.arc([3, 6, 20, 22], 0, 180, fill=GOLD[2], width=2)
    for x in (4, 11, 19):
        d.rectangle([x - 1, 4, x + 1, 12], fill=hexc('f2ead8'))
    return save('dec_candelabra', img)


def bed(name, W, H, blanket, royal):
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # headboard
    d.rectangle([0, 0, W - 1, 18], fill=WALNUT[2])
    d.rectangle([0, 0, W - 1, 3], fill=WALNUT[4])
    if royal:
        d.polygon([(W // 2 - 10, 2), (W // 2, -4 + 4), (W // 2 + 10, 2)], fill=GOLD[2])
        d.rectangle([W // 2 - 6, 6, W // 2 + 5, 14], fill=GOLD[2])
        d.rectangle([W // 2 - 4, 8, W // 2 + 3, 12], fill=blanket[2])
    # mattress, pillows, blanket
    d.rectangle([2, 16, W - 3, H - 8], fill=hexc('ece4d4'))
    for px in ((5, W // 2 - 3), (W // 2 + 2, W - 6)):
        d.rectangle([px[0], 20, px[1], 30], fill=hexc('f8f2e6'))
        d.line([(px[0], 30), (px[1], 30)], fill=hexc('c8bca8'))
    d.rectangle([2, 34, W - 3, H - 8], fill=blanket[2])
    d.rectangle([2, 34, W - 3, 37], fill=blanket[3])
    d.line([(2, 34), (2, H - 8)], fill=blanket[3])
    if royal:
        d.rectangle([2, 40, W - 3, 42], fill=GOLD[2])
    for x in range(8, W - 8, 10):
        d.line([(x, 44), (x + 3, H - 10)], fill=blanket[1])
    # footboard
    d.rectangle([0, H - 8, W - 1, H - 1], fill=WALNUT[1])
    d.line([(0, H - 8), (W - 1, H - 8)], fill=WALNUT[3])
    return save(name, img)


def table(name, W, H, cloth=None):
    img = new(W, H)
    d = ImageDraw.Draw(img)
    top_h = H - 14
    d.rectangle([0, 0, W - 1, top_h], fill=WALNUT[3])
    d.line([(0, 0), (W - 1, 0)], fill=WALNUT[4])
    for x in range(6, W - 4, 12):
        d.line([(x, 2), (x, top_h - 2)], fill=WALNUT[2])
    d.rectangle([0, top_h, W - 1, top_h + 4], fill=WALNUT[1])
    if cloth:
        d.rectangle([W // 4, 0, 3 * W // 4, top_h + 8], fill=cloth[2])
        d.line([(W // 4, top_h + 8), (3 * W // 4, top_h + 8)], fill=GOLD[2])
    for x in (2, W - 7):
        d.rectangle([x, top_h + 4, x + 4, H - 1], fill=WALNUT[1])
    return img


def table_items(img, rng, W):
    d = ImageDraw.Draw(img)
    for _ in range(4):
        x = rng.randrange(6, W - 10)
        kind = rng.random()
        if kind < 0.4:
            d.ellipse([x, 6, x + 7, 10], fill=hexc('d8dde3'))
            d.ellipse([x + 2, 7, x + 5, 9], fill=hexc('c86a3a'))
        elif kind < 0.7:
            d.rectangle([x, 2, x + 3, 9], fill=GOLD[2])
            d.point((x + 1, 2), fill=GOLD[4])
        else:
            d.rectangle([x, 4, x + 6, 9], fill=hexc('e8dcc0'))
            d.line([(x + 1, 6), (x + 5, 6)], fill=hexc('5a4a3a'))
    return img


def chair():
    W, H = 20, 34
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([2, 0, W - 3, 16], fill=WALNUT[2])
    d.rectangle([4, 2, W - 5, 14], fill=BLUE[2])
    d.line([(4, 2), (W - 5, 2)], fill=BLUE[3])
    d.rectangle([1, 16, W - 2, 22], fill=WALNUT[3])
    d.rectangle([3, 17, W - 4, 20], fill=BLUE[3])
    for x in (2, W - 5):
        d.rectangle([x, 22, x + 2, H - 1], fill=WALNUT[1])
    return save('dec_chair', img)


def bookshelf():
    W, H = 52, 76
    img = new(W, H)
    d = ImageDraw.Draw(img)
    rng = random.Random(9)
    d.rectangle([0, 0, W - 1, H - 1], fill=WALNUT[2])
    d.rectangle([0, 0, W - 1, 3], fill=WALNUT[4])
    for shelf in range(4):
        y0 = 6 + shelf * 17
        d.rectangle([4, y0, W - 5, y0 + 13], fill=WALNUT[0])
        x = 5
        while x < W - 7:
            w = rng.randrange(2, 5)
            h = rng.randrange(9, 13)
            c = rng.choice([RED[2], BLUE[2], GREEN[2], hexc('8a6a3a'), hexc('5a3a5a'), GOLD[1]])
            d.rectangle([x, y0 + 13 - h, x + w - 1, y0 + 13], fill=c)
            d.point((x, y0 + 13 - h), fill=shade(c, 0.3))
            x += w + (1 if rng.random() < 0.2 else 0)
        d.rectangle([4, y0 + 14, W - 5, y0 + 15], fill=WALNUT[3])
    return save('dec_bookshelf', img)


def wardrobe():
    W, H = 48, 78
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 6, W - 1, H - 1], fill=WALNUT[2])
    d.rectangle([-2 + 2, 0, W - 1, 7], fill=WALNUT[3])
    d.line([(0, 0), (W - 1, 0)], fill=WALNUT[4])
    for x0 in (4, W // 2 + 1):
        d.rectangle([x0, 12, x0 + W // 2 - 6, H - 8], fill=WALNUT[3])
        d.rectangle([x0 + 3, 16, x0 + W // 2 - 9, H - 12], fill=WALNUT[2])
    d.rectangle([W // 2 - 3, 40, W // 2 - 2, 46], fill=GOLD[2])
    d.rectangle([W // 2 + 1, 40, W // 2 + 2, 46], fill=GOLD[2])
    d.rectangle([2, H - 6, W - 3, H - 1], fill=WALNUT[1])
    return save('dec_wardrobe', img)


def chest():
    W, H = 38, 30
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 8, W - 1, H - 1], fill=WALNUT[2])
    d.rounded_rectangle([0, 0, W - 1, 12], radius=5, fill=WALNUT[3])
    d.line([(2, 1), (W - 3, 1)], fill=WALNUT[4])
    for x in (5, W - 8):
        d.rectangle([x, 0, x + 2, H - 1], fill=hexc('4a4e56'))
    d.rectangle([W // 2 - 3, 10, W // 2 + 2, 16], fill=GOLD[2])
    return save('dec_chest', img)


def portrait(name, coat, bg):
    W, H = 34, 44
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, H - 1], fill=GOLD[1])
    d.rectangle([1, 1, W - 2, H - 2], fill=GOLD[3])
    d.rectangle([3, 3, W - 4, H - 4], fill=GOLD[1])
    d.rectangle([5, 5, W - 6, H - 6], fill=bg)
    d.ellipse([12, 10, 21, 21], fill=hexc('d8a882'))
    d.rectangle([12, 9, 21, 12], fill=hexc('3a2618'))
    d.polygon([(8, H - 6), (25, H - 6), (23, 24), (10, 24)], fill=coat)
    d.polygon([(13, 7), (20, 7), (19, 4), (16, 6), (14, 4)], fill=GOLD[3])
    return save(name, img)


def plant():
    W, H = 30, 48
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.polygon([(6, H - 18), (W - 7, H - 18), (W - 9, H - 1), (8, H - 1)], fill=hexc('a0603a'))
    d.rectangle([5, H - 20, W - 6, H - 17], fill=hexc('c07848'))
    d.line([(9, H - 12), (W - 10, H - 12)], fill=hexc('80482a'))
    m = mask(W, H)
    md = ImageDraw.Draw(m)
    for (x, y, r) in ((15, 14, 10), (8, 20, 7), (22, 20, 7), (15, 6, 6)):
        md.ellipse([x - r, y - r, x + r, y + r], fill=255)
    paint_mask(img, m, GREEN, light=(-0.8, -0.8), rng=random.Random(5), dither=0.35)
    return save('dec_plant', img)


def urn():
    W, H = 26, 38
    img = new(W, H)
    m = mask(W, H)
    md = ImageDraw.Draw(m)
    md.ellipse([2, 6, W - 3, H - 8], fill=255)
    md.rectangle([8, 0, W - 9, 8], fill=255)
    md.rectangle([6, H - 9, W - 7, H - 1], fill=255)
    paint_mask(img, m, ramp('1c2c52', '2a4078', '3a58a0', '5276c4', '7a9ade'), light=(-1, -0.4))
    d = ImageDraw.Draw(img)
    d.line([(3, 18), (W - 4, 18)], fill=GOLD[2], width=2)
    d.rectangle([7, 0, W - 8, 1], fill=GOLD[3])
    return save('dec_urn', img)


def armour():
    W, H = 30, 68
    img = new(W, H)
    d = ImageDraw.Draw(img)
    steel = ramp('4a4e56', '6a6e76', '8a9098', 'b0b6be', 'd8dde3')
    d.rectangle([4, H - 6, W - 5, H - 1], fill=WALNUT[1])
    for x in (9, 17):
        d.rectangle([x, 40, x + 4, H - 6], fill=steel[2])
        d.line([(x, 40), (x, H - 6)], fill=steel[3])
    m = mask(W, H)
    ImageDraw.Draw(m).polygon([(6, 16), (W - 7, 16), (W - 8, 40), (8, 40)], fill=255)
    paint_mask(img, m, steel, light=(-1, -0.5))
    d.rectangle([2, 15, 8, 22], fill=steel[3])
    d.rectangle([W - 9, 15, W - 3, 22], fill=steel[2])
    d.rectangle([3, 22, 6, 36], fill=steel[2])
    d.rectangle([W - 7, 22, W - 4, 36], fill=steel[1])
    m2 = mask(W, H)
    ImageDraw.Draw(m2).ellipse([9, 2, 20, 16], fill=255)
    paint_mask(img, m2, steel, light=(-1, -0.8))
    d.rectangle([10, 8, 19, 9], fill=steel[0])
    d.rectangle([13, 0, 15, 3], fill=RED[3])
    d.rectangle([W - 6, 2, W - 5, 46], fill=WALNUT[3])
    d.polygon([(W - 8, 2), (W - 3, 2), (W - 5, -4 + 4)], fill=steel[4])
    return save('dec_armour', img)


def noble_bench():
    W, H = 68, 30
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, 12], fill=WALNUT[2])
    d.line([(0, 0), (W - 1, 0)], fill=WALNUT[4])
    d.rectangle([2, 12, W - 3, 20], fill=RED[2])
    d.line([(2, 12), (W - 3, 12)], fill=RED[4])
    d.rectangle([0, 20, W - 1, 23], fill=WALNUT[1])
    for x in (2, W - 7):
        d.rectangle([x, 0, x + 4, H - 1], fill=WALNUT[1])
        d.point((x + 2, 1), fill=GOLD[3])
    return save('dec_bench', img)


def hay():
    W, H = 40, 28
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 4, W - 1, H - 1], fill=hexc('c8a050'))
    d.rectangle([0, 0, W - 1, 6], fill=hexc('dcb868'))
    rng = random.Random(3)
    for _ in range(40):
        x, y = rng.randrange(W), rng.randrange(H)
        d.point((x, y), fill=rng.choice([hexc('a8823a'), hexc('e8cc80')]))
    for x in (9, W - 11):
        d.line([(x, 0), (x, H - 1)], fill=hexc('7a5a2a'))
    return save('dec_hay', img)


def canopy():
    """Velvet drape behind the throne, hung from a gold rail with a crown on top."""
    W, H = 168, 176
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 16, W - 5, 22], fill=GOLD[2])
    d.line([(4, 16), (W - 5, 16)], fill=GOLD[4])
    cx = W // 2
    d.polygon([(cx - 16, 16), (cx - 16, 4), (cx - 8, 10), (cx, 0), (cx + 8, 10), (cx + 16, 4), (cx + 16, 16)], fill=GOLD[2])
    for x in (cx - 8, cx, cx + 8):
        d.point((x, 6), fill=RED[4])
    for x in range(8, W - 8):
        u = (x - 8) / (W - 16)
        fold = math.sin(u * math.pi * 9)
        c = BLUE[2] if fold > 0.3 else (BLUE[1] if fold < -0.3 else BLUE[2])
        if fold > 0.8: c = BLUE[3]
        d.line([(x, 22), (x, H - 8 + int(3 * math.sin(u * 12)))], fill=c)
    d.line([(8, H - 9), (W - 9, H - 9)], fill=GOLD[2], width=2)
    for x in range(10, W - 10, 8):
        d.line([(x, H - 8), (x, H - 4)], fill=GOLD[3])
    for side in (-1, 1):
        x = cx + side * 52
        d.polygon([(x - 6, 30), (x + 6, 30), (x + 4, 120), (x - 4, 120)], fill=GOLD[1])
    return save('dec_canopy', img)


def rug(name, W, H, body, border):
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, H - 1], fill=border[1])
    d.rectangle([3, 3, W - 4, H - 4], fill=border[2])
    d.rectangle([6, 6, W - 7, H - 7], fill=body[2])
    for x in range(9, W - 9, 10):
        d.point((x, 4), fill=border[3]); d.point((x, H - 5), fill=border[3])
    for y in range(9, H - 9, 10):
        d.point((4, y), fill=border[3]); d.point((W - 5, y), fill=border[3])
    cx, cy = W // 2, H // 2
    r = min(W, H) // 4
    d.polygon([(cx, cy - r), (cx + r * 1.4, cy), (cx, cy + r), (cx - r * 1.4, cy)], fill=body[3])
    d.polygon([(cx, cy - r // 2), (cx + r * 0.7, cy), (cx, cy + r // 2), (cx - r * 0.7, cy)], fill=border[3])
    for (x, y) in ((14, 14), (W - 15, 14), (14, H - 15), (W - 15, H - 15)):
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=body[3])
    # tassels on the short ends
    for x in range(2, W - 2, 4):
        img.putpixel((x, 0), border[3]); img.putpixel((x, H - 1), border[3])
    img.save(OUT + name + '.png')
    return img


def stairs_up():
    """A stone stair rising north into an arched opening, with balustrades."""
    W, H = 96, 112
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # arch in the wall at the top
    d.rectangle([12, 0, W - 13, 34], fill=hexc('140e0a'))
    d.ellipse([12, -18, W - 13, 26], fill=hexc('140e0a'))
    d.arc([8, -22, W - 9, 30], 180, 360, fill=LIME[4], width=4)
    # treads getting darker as they climb
    n = 9
    for i in range(n):
        y = H - 8 - i * 9
        t = 4 - i * 0.42
        c = LIME[max(0, min(5, int(t)))]
        d.rectangle([16, y - 8, W - 17, y], fill=c)
        d.line([(16, y - 8), (W - 17, y - 8)], fill=shade(c, 0.25))
        d.line([(16, y), (W - 17, y)], fill=shade(c, -0.35))
    # balustrades with posts and gold caps
    for x0 in (2, W - 16):
        d.rectangle([x0, 26, x0 + 13, H - 1], fill=LIME[2])
        d.line([(x0, 26), (x0, H - 1)], fill=LIME[4])
        d.line([(x0 + 13, 26), (x0 + 13, H - 1)], fill=LIME[0])
        for y in range(34, H - 6, 10):
            d.rectangle([x0 + 3, y, x0 + 10, y + 5], fill=LIME[1])
        d.rectangle([x0 - 1, H - 18, x0 + 14, H - 1], fill=LIME[3])
        d.rectangle([x0 + 2, H - 22, x0 + 11, H - 18], fill=GOLD[2])
    # red runner up the middle
    d.rectangle([W // 2 - 12, 30, W // 2 + 11, H - 8], fill=RED[2])
    for i in range(n):
        y = H - 8 - i * 9
        d.line([(W // 2 - 12, y), (W // 2 + 11, y)], fill=RED[1])
    d.line([(W // 2 - 12, 30), (W // 2 - 12, H - 8)], fill=GOLD[2])
    d.line([(W // 2 + 11, 30), (W // 2 + 11, H - 8)], fill=GOLD[2])
    return save('dec_stairs_up', img)


def stairs_down():
    """A stairwell going down, seen from above: an opening in the floor with a balustrade."""
    W, H = 96, 96
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, H - 1], fill=LIME[2])
    d.rectangle([10, 10, W - 11, H - 1], fill=hexc('120c08'))
    n = 8
    for i in range(n):
        y = 14 + i * 10
        t = 4 - i * 0.5
        c = LIME[max(0, min(5, int(t)))]
        d.rectangle([12, y, W - 13, y + 8], fill=c)
        d.line([(12, y), (W - 13, y)], fill=shade(c, 0.25))
    d.rectangle([W // 2 - 12, 14, W // 2 + 11, H - 1], fill=RED[1])
    for x0, y0, x1, y1 in ((0, 0, W - 1, 9), (0, 0, 9, H - 1), (W - 10, 0, W - 1, H - 1)):
        d.rectangle([x0, y0, x1, y1], fill=LIME[3])
    d.line([(0, 0), (W - 1, 0)], fill=LIME[5])
    for x in range(14, W - 14, 12):
        d.rectangle([x, 2, x + 4, 7], fill=LIME[1])
    for (x, y) in ((0, 0), (W - 10, 0)):
        d.rectangle([x, y, x + 9, y + 9], fill=LIME[4])
        d.rectangle([x + 2, y + 2, x + 7, y + 7], fill=GOLD[2])
    return save('dec_stairs_down', img)


def fence():
    """One section of the arena's wooden fence: two posts and a rope, 32 px wide."""
    W, H = 32, 26
    img = new(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 4, 4, H - 1], fill=WALNUT[2])
    d.line([(0, 4), (0, H - 1)], fill=WALNUT[4])
    d.rectangle([0, 2, 4, 5], fill=GOLD[2])
    d.line([(4, 9), (W - 1, 12)], fill=RED[3], width=2)
    d.line([(4, 15), (W - 1, 17)], fill=RED[2])
    img.save(OUT + 'dec_fence.png')
    return img


def shrub(name, W, H, ramp_, berries=None, seed=1):
    img = new(W, H)
    m = mask(W, H)
    md = ImageDraw.Draw(m)
    rng = random.Random(seed)
    for _ in range(6):
        r = rng.randrange(W // 5, W // 3)
        x = rng.randrange(r, W - r)
        y = rng.randrange(r, H - r)
        md.ellipse([x - r, y - r, x + r, y + r], fill=255)
    md.ellipse([2, H // 3, W - 3, H - 1], fill=255)
    paint_mask(img, m, ramp_, light=(-0.8, -0.9), rng=rng, dither=0.3)
    if berries:
        p = img.load()
        for _ in range(W * H // 40):
            x, y = rng.randrange(2, W - 2), rng.randrange(2, H - 3)
            if p[x, y][3] and p[x, y + 1][3]:
                p[x, y] = berries[0]
                p[x, y + 1] = berries[1]
    return save(name, img)


def flowers():
    W, H = 22, 12
    img = new(W, H)
    p = img.load()
    rng = random.Random(8)
    for _ in range(14):
        x, y = rng.randrange(1, W - 1), rng.randrange(3, H)
        for yy in range(y, H):
            p[x, yy] = GREEN[2]
    for _ in range(9):
        x, y = rng.randrange(1, W - 1), rng.randrange(1, H - 4)
        c = rng.choice([hexc('e8d8f0'), hexc('f0c048'), hexc('c84a6a'), hexc('f4f0e8')])
        p[x, y] = c
        p[x + 1 if x < W - 1 else x - 1, y] = shade(c, -0.2)
    img.save(OUT + 'dec_flowers.png')
    return img


def build():
    shrub('dec_shrub', 30, 24, GREEN, seed=2)
    shrub('dec_roses', 32, 26, GREEN, (hexc('c83040'), hexc('8e1c28')), seed=3)
    shrub('dec_lavender', 26, 20, ramp('3a3a5a', '4e4a78', '6a5e9a', '8a78b8', 'a898d0'), seed=4)
    flowers()
    tiles()
    sconce(); candelabra(); chair(); bookshelf(); wardrobe(); chest(); plant(); urn(); armour()
    noble_bench(); hay(); canopy(); stairs_up(); stairs_down(); fence()
    bed('dec_bed_royal', 72, 88, BLUE, True)
    bed('dec_bed', 40, 66, ramp('3a3a2e', '4e4a3a', '6a6450', '868066', 'a09a80'), False)
    rng = random.Random(4)
    save('dec_table_long', table_items(table('x', 132, 46, RED), rng, 132))
    save('dec_table', table('x', 52, 40))
    portrait('dec_portrait_king', BLUE[2], hexc('3a2a1a'))
    portrait('dec_portrait_queen', RED[2], hexc('2a2a3a'))
    portrait('dec_portrait_old', hexc('4a5a3a'), hexc('3a3020'))
    rug('dec_rug_throne', 176, 104, RED, GOLD)
    rug('dec_rug_blue', 112, 72, BLUE, GOLD)


if __name__ == '__main__':
    build()
    import glob
    files = sorted(glob.glob(OUT + 'dec_*.png'))
    prev = Image.new('RGBA', (1300, 560), hexc('5c7e46'))
    x, y, rowh = 6, 6, 0
    for f in files:
        im = Image.open(f)
        if x + im.width > 1300:
            x, y, rowh = 6, y + rowh + 8, 0
        prev.paste(im, (x, y), im)
        x += im.width + 8
        rowh = max(rowh, im.height)
    t = Image.open(OUT + 'cit_tiles.png')
    prev.paste(t, (6, y + rowh + 10), t)
    big = Image.new('RGBA', (256, 224))
    for yy in range(0, 224, 32):
        for xx in range(0, 256, 32):
            v = (xx * 7 + yy * 13) // 32 % 4
            big.paste(t.crop((v * 32, 0, v * 32 + 32, 32)), (xx, yy))
    prev.paste(big, (150, y + rowh + 10))
    prev.save('/home/claude/preview_decor.png')
    print(len(files), 'sprites')
