"""Ground tiles: 16x16 pixel tiles, 4 variants per row. Drawn at 2x in game."""
import random
from PIL import Image
from pixel import hexc, new, mix

T = 32
ROWS = ["grass", "grass_dark", "grass_light", "path", "cobble", "plaza", "yard", "field",
        "rocky", "cliff_top", "cliff_face", "water", "mountain", "fringe"]

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
    speckle(img, rng, hexc('dcbf82'), [hexc('ccac6c'), hexc('e8d29c'), hexc('bf9d5f')], [0.25, 0.15, 0.06])
    p = img.load()
    for _ in range(6 + v * 2):
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
    cols = [hexc('5ea83a'), hexc('4c932e'), hexc('74bf48')]
    for x in range(T):
        depth = 3 + rng.randrange(0, 5)
        for y in range(depth):
            p[x, y] = rng.choice(cols)
        if rng.random() < 0.4:
            p[x, depth] = hexc('3f7f26')
    return img

def build():
    atlas = Image.new('RGBA', (T * 4, T * len(ROWS)), (0, 0, 0, 0))
    for r, name in enumerate(ROWS):
        for v in range(4):
            rng = random.Random(r * 100 + v)
            if name == "grass":
                img = grass(rng, v, '5ea83a', '4c932e', '74bf48')
            elif name == "grass_dark":
                img = grass(rng, v, '3f8a34', '2f7329', '52a043')
            elif name == "grass_light":
                img = grass(rng, v, '72bd48', '5ea83a', '8fd35e', extra_flowers=1 if v == 2 else 0)
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
