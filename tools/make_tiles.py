"""Ground tiles: 32x32 pixel tiles, 4 variants per row. Drawn 1:1 in game."""
import random
from PIL import Image
from pixel import hexc, new, mix

T = 32
ROWS = ["grass", "grass_dark", "grass_light", "path", "cobble", "plaza", "yard", "field",
        "rocky", "cliff_top", "cliff_face", "water", "mountain", "fringe", "brick", "brick_edge"]

BAYER = [[0, 2], [3, 1]]


def wrap_noise(rng, cells):
    """Tileable value noise over the tile: returns f(x, y) -> 0..1."""
    g = [[rng.random() for _ in range(cells)] for _ in range(cells)]
    step = T / cells
    def f(x, y):
        gx, gy = x / step, y / step
        x0, y0 = int(gx) % cells, int(gy) % cells
        x1, y1 = (x0 + 1) % cells, (y0 + 1) % cells
        tx, ty = gx - int(gx), gy - int(gy)
        tx = tx * tx * (3 - 2 * tx); ty = ty * ty * (3 - 2 * ty)
        a = g[y0][x0] * (1 - tx) + g[y0][x1] * tx
        b = g[y1][x0] * (1 - tx) + g[y1][x1] * tx
        return a * (1 - ty) + b * ty
    return f


def soft_grass(rng, v, shades, tuft_dark, tuft_light, flower_n=0):
    """Calm mottled grass: big soft patches, dithered edges, a few tufts."""
    img = new(T, T)
    p = img.load()
    shared = random.Random(hash(tuple(shades)) & 0xffff)
    big = wrap_noise(shared, 2)
    mid = wrap_noise(shared, 4)
    n = len(shades)
    for y in range(T):
        for x in range(T):
            t = big(x, y) * 0.65 + mid(x, y) * 0.35
            t += (BAYER[y % 2][x % 2] - 1.5) * 0.025
            p[x, y] = shades[max(0, min(n - 1, int(t * n)))]
    for _ in range(6):  # little V-shaped tufts
        x, y = rng.randrange(1, T - 1), rng.randrange(2, T)
        dark = rng.random() < 0.6
        c = tuft_dark if dark else tuft_light
        p[x, y] = c; p[x - 1, y - 1] = c; p[x + 1, y - 1] = c
        if not dark:
            p[x, y - 1] = c
    if flower_n:
        flowers(img, rng, flower_n)
    return img


def brick(rng, v):
    """Warm red brick paving in running bond."""
    img = new(T, T)
    p = img.load()
    mortar = hexc('7a3f2c')
    cols = ['b5603f', 'a95638', 'c06a46', 'b05a3a', '9e4f34', 'c4744e']
    bw, bh = 8, 5
    for y in range(T):
        for x in range(T):
            p[x, y] = mortar
    rows = T // bh + 1
    for r in range(rows):
        off = (r % 2) * (bw // 2)
        for k in range(-1, T // bw + 1):
            x0 = k * bw + off
            c = hexc(rng.choice(cols))
            if rng.random() < 0.06:
                c = hexc('8a8478')  # odd grey stone
            for yy in range(r * bh, r * bh + bh - 1):
                for xx in range(x0, x0 + bw - 1):
                    if 0 <= xx < T and 0 <= yy < T:
                        t = 0.0
                        if yy == r * bh: t = 0.16
                        elif yy == r * bh + bh - 2: t = -0.16
                        if xx == x0 + bw - 2: t -= 0.08
                        cc = mix(c, (255, 235, 200, 255), t) if t > 0 else mix(c, (40, 15, 10, 255), -t)
                        if rng.random() < 0.05: cc = mix(cc, (40, 15, 10, 255), 0.12)
                        p[xx, yy] = cc
    for _ in range(3):  # moss in the cracks
        x, y = rng.randrange(T), rng.randrange(T)
        if p[x, y] == mortar:
            p[x, y] = hexc('5e8a3a')
    return img


def brick_edge(rng, v):
    """A border of pale kerb stones along the top edge (rotated in game)."""
    img = new(T, T)
    p = img.load()
    x = 0
    while x < T:
        w = rng.randrange(4, 7)
        c = hexc(rng.choice(['b8b0a0', 'aaa292', 'c4bcac']))
        for yy in range(0, 4):
            for xx in range(x, min(T, x + w - 1)):
                t = 0.15 if yy == 0 else (-0.2 if yy == 3 else 0)
                p[xx, yy] = mix(c, (255, 255, 255, 255), t) if t > 0 else mix(c, (0, 0, 0, 255), -t)
        x += w
    for xx in range(T):
        p[xx, 4] = hexc('5a3a26')
    return img

def speckle(img, rng, base, others, weights):
    p = img.load()
    for y in range(T):
        for x in range(T):
            p[x, y] = rng.choices([base] + others, [1.0] + weights)[0]

def blades(img, rng, cols, n):
    p = img.load()
    for _ in range(n):
        x, y = rng.randrange(T), rng.randrange(2, T)
        c = rng.choice(cols)
        p[x, y] = c
        p[x, y - 1] = c
        if rng.random() < 0.5 and x + 1 < T:
            p[x + 1, y] = c

def flowers(img, rng, n):
    p = img.load()
    petals = [hexc('f25c6e'), hexc('ffd94a'), hexc('ffffff'), hexc('b47cff'), hexc('ff9a3c'), hexc('6ec6ff')]
    for _ in range(n):
        x, y = rng.randrange(1, T - 1), rng.randrange(1, T - 1)
        c = rng.choice(petals)
        for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
            p[x + dx, y + dy] = c
        p[x, y] = hexc('ffe066') if c != hexc('ffd94a') else hexc('e07b20')

def clumps(img, rng, col, n, r=3):
    p = img.load()
    for _ in range(n):
        cx, cy = rng.randrange(T), rng.randrange(T)
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and rng.random() < 0.7:
                    p[x % T, y % T] = col

def grass(rng, v, base, dark, light, extra_flowers=0):
    img = new(T, T)
    speckle(img, rng, hexc(base), [hexc(dark), hexc(light)], [0.16, 0.1])
    clumps(img, rng, mix(hexc(base), hexc(dark), 0.5), 3, 4)
    clumps(img, rng, mix(hexc(base), hexc(light), 0.5), 2, 3)
    blades(img, rng, [hexc(dark), hexc(light)], 30)
    if v >= 2 or extra_flowers:
        flowers(img, rng, (1 if v == 2 else 3) + extra_flowers)
    return img

def path(rng, v):
    img = new(T, T)
    f = wrap_noise(random.Random(55), 4)
    pp = img.load()
    shades = [hexc('a8784a'), hexc('b48450'), hexc('c09058'), hexc('c99c62')]
    for y in range(T):
        for x in range(T):
            t = f(x, y) + (BAYER[y % 2][x % 2] - 1.5) * 0.07
            pp[x, y] = shades[max(0, min(3, int(t * 4)))]
    p = img.load()
    for _ in range(1 + v):
        x, y = rng.randrange(1, T - 2), rng.randrange(1, T - 2)
        p[x, y] = hexc('a39a8c'); p[x + 1, y] = hexc('c9c2b4'); p[x, y + 1] = hexc('8a8174'); p[x + 1, y + 1] = hexc('a39a8c')
    return img

def stones(rng, v, base_cols, mortar, size=5):
    img = new(T, T)
    p = img.load()
    for y in range(T):
        for x in range(T):
            p[x, y] = hexc(mortar)
    rows = T // size + 1
    for r in range(rows):
        off = (r % 2) * (size // 2 + 1) + v
        y0 = r * size
        x = -off
        while x < T:
            w = size + rng.randrange(0, 3)
            c = hexc(rng.choice(base_cols))
            for yy in range(y0, min(T, y0 + size - 1)):
                for xx in range(max(0, x), min(T, x + w - 1)):
                    t = 0.0
                    if yy == y0: t = 0.25
                    if yy == y0 + size - 2 or xx == x + w - 2: t = -0.2
                    cc = mix(c, (255, 255, 255, 255), t) if t > 0 else mix(c, (0, 0, 0, 255), -t)
                    p[xx, yy] = cc
            x += w
    return img

def yard(rng, v):
    img = new(T, T)
    speckle(img, rng, hexc('b08a56'), [hexc('9c784a'), hexc('c49c66'), hexc('7d6a3e')], [0.25, 0.15, 0.08])
    return img

def field(rng, v):
    img = new(T, T)
    p = img.load()
    for y in range(T):
        for x in range(T):
            row = (y // 4) % 2
            if row == 0:
                p[x, y] = rng.choice([hexc('7a5232'), hexc('6b4629'), hexc('86603a')])
            else:
                p[x, y] = rng.choice([hexc('8a5e38'), hexc('7a5232')])
        if (y // 4) % 2 == 0 and y % 4 in (1, 2):
            for x in range(1 + (v % 2), T, 3):
                p[x, y] = hexc('6cc24a') if y % 4 == 1 else hexc('4f9a34')
                if y % 4 == 1 and rng.random() < 0.3:
                    p[x, y - 1] = hexc('9be06a')
    return img

def rocky(rng, v):
    img = new(T, T)
    speckle(img, rng, hexc('c4a06a'), [hexc('b08c58'), hexc('d6b47e'), hexc('9a7848')], [0.25, 0.15, 0.1])
    p = img.load()
    for _ in range(3 + v):
        x, y = rng.randrange(1, T - 3), rng.randrange(1, T - 3)
        for dx in range(3):
            for dy in range(2):
                p[x + dx, y + dy] = hexc('8c7a64') if dy else hexc('b3a28a')
    for _ in range(2):
        x, y = rng.randrange(2, T - 8), rng.randrange(2, T - 2)
        for i in range(7):
            p[x + i, y + (i // 3) % 2] = hexc('8a6a40')
    return img

def cliff_top(rng, v):
    img = new(T, T)
    speckle(img, rng, hexc('a99f8c'), [hexc('bdb4a0'), hexc('8e8574'), hexc('7cb04a')], [0.25, 0.2, 0.06])
    return img

def cliff_face(rng, v):
    img = new(T, T)
    p = img.load()
    for x in range(T):
        col = rng.choice(['7a6f60', '6a6052', '857a6a', '5c5348'])
        for y in range(T):
            c = hexc(col)
            if rng.random() < 0.12:
                c = hexc('4a4238')
            if (x + v) % 5 == 0:
                c = hexc('4f463b')
            p[x, y] = c
    for _ in range(8):
        x, y = rng.randrange(T), rng.randrange(T)
        p[x, y] = hexc('5f9a3a')
    for _ in range(4):
        y = rng.randrange(T); x0 = rng.randrange(T - 8)
        for i in range(8):
            p[x0 + i, y] = hexc('9a8e7c')
    return img

def water(rng, v):
    img = new(T, T)
    speckle(img, rng, hexc('3f8fd0'), [hexc('3580c2'), hexc('4c9ddb')], [0.25, 0.15])
    p = img.load()
    for _ in range(7):
        x, y = rng.randrange(T - 4), rng.randrange(T)
        for i in range(4):
            p[x + i, y] = hexc('9fd4f5') if i in (1, 2) else hexc('6cb6e8')
    return img

def mountain(rng, v):
    img = new(T, T)
    speckle(img, rng, hexc('8d8a86'), [hexc('a3a09b'), hexc('77736e'), hexc('b9b5ae')], [0.25, 0.2, 0.08])
    return img

def fringe(rng, v):
    """Grass blades hanging over the top edge of a path tile (rotated in game)."""
    img = new(T, T)
    p = img.load()
    cols = [hexc('5c9a3c'), hexc('528f36'), hexc('64a442')]
    for x in range(T):
        depth = 2 + rng.randrange(0, 4) + (2 if (x // 3) % 3 == 0 else 0)
        for y in range(depth):
            p[x, y] = cols[(x + y) % 3] if y < depth - 1 else hexc('3f7428')
        if rng.random() < 0.3:
            p[x, depth] = (0, 0, 0, 60)
    return img

def build():
    atlas = Image.new('RGBA', (T * 4, T * len(ROWS)), (0, 0, 0, 0))
    for r, name in enumerate(ROWS):
        for v in range(4):
            rng = random.Random(r * 100 + v)
            if name == "grass":
                img = soft_grass(rng, v, [hexc('4f8c34'), hexc('568f37'), hexc('5c9a3c'), hexc('64a442'), hexc('6dab47')],
                                 hexc('437a2c'), hexc('86bf58'), flower_n=[0, 0, 2, 4][v])
            elif name == "grass_dark":
                img = soft_grass(rng, v, [hexc('2f5e2a'), hexc('35682e'), hexc('3b7232'), hexc('427b36'), hexc('4a843a')],
                                 hexc('284f24'), hexc('5a9444'), flower_n=[0, 0, 1, 2][v])
            elif name == "grass_light":
                img = soft_grass(rng, v, [hexc('62a040'), hexc('6aa845'), hexc('72b04a'), hexc('7cb851'), hexc('86c058')],
                                 hexc('558f38'), hexc('9cd06a'), flower_n=[1, 2, 4, 6][v])
            elif name == "brick": img = brick(rng, v)
            elif name == "brick_edge": img = brick_edge(rng, v)
            elif name == "path": img = path(rng, v)
            elif name == "cobble": img = stones(rng, v, ['9aa0a8', '8a9098', 'a8aeb6', '7f8a96'], '5e646c', size=8)
            elif name == "plaza": img = stones(rng, v, ['d6c6a4', 'cbb994', 'e0d2b2'], 'a8987a', size=11)
            elif name == "yard": img = yard(rng, v)
            elif name == "field": img = field(rng, v)
            elif name == "rocky": img = rocky(rng, v)
            elif name == "cliff_top": img = cliff_top(rng, v)
            elif name == "cliff_face": img = cliff_face(rng, v)
            elif name == "water": img = water(rng, v)
            elif name == "mountain": img = mountain(rng, v)
            elif name == "fringe": img = fringe(rng, v)
            atlas.paste(img, (v * T, r * T))
    atlas.save('../art/tiles.png')
    return atlas

if __name__ == '__main__':
    a = build()
    a.resize((a.width * 4, a.height * 4), Image.NEAREST).save('/home/claude/preview_tiles.png')
