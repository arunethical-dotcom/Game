"""Seamless textures for smooth roads and paved areas (art/tex_*.png).
They repeat across the world 1:1, so road shapes can be any curve."""
import random
from PIL import Image
from pixel import hexc, new, mix

OUT = '../art/'
BAYER = [[0, 2], [3, 1]]


def shade(c, t):
    return mix(c, (255, 240, 210, 255), t) if t > 0 else mix(c, (30, 12, 8, 255), -t)


def bond(W, H, bw, bh, cols, mortar, seed, odd=None, moss=None, bevel=0.16):
    """Seamless running-bond bricks or stones. W % bw == 0, H % bh == 0, H // bh even."""
    rng = random.Random(seed)
    img = new(W, H)
    p = img.load()
    for y in range(H):
        for x in range(W):
            p[x, y] = hexc(mortar)
    for r in range(H // bh):
        off = (r % 2) * (bw // 2)
        for k in range(W // bw + 1):
            x0 = k * bw + off
            c = hexc(rng.choice(cols))
            if odd and rng.random() < 0.05:
                c = hexc(odd)
            for yy in range(r * bh, r * bh + bh - 1):
                for xx in range(x0, x0 + bw - 1):
                    t = 0.0
                    if yy == r * bh: t = bevel
                    elif yy == r * bh + bh - 2: t = -bevel
                    if xx % W == (x0 + bw - 2) % W: t -= bevel * 0.5
                    if (xx % W) == x0 % W: t += bevel * 0.3
                    cc = shade(c, t)
                    if rng.random() < 0.06:
                        cc = shade(cc, -0.08)
                    p[xx % W, yy] = cc
    if moss:
        for _ in range(W * H // 180):
            x, y = rng.randrange(W), rng.randrange(H)
            if p[x, y] == hexc(mortar):
                p[x, y] = hexc(moss)
    return img


def wrap_noise(rng, cells, size):
    g = [[rng.random() for _ in range(cells)] for _ in range(cells)]
    step = size / cells
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


def dirt(size=64):
    rng = random.Random(5)
    img = new(size, size)
    p = img.load()
    f = wrap_noise(rng, 4, size)
    g = wrap_noise(rng, 8, size)
    shades = [hexc('9a6c42'), hexc('a8784a'), hexc('b48450'), hexc('bf8e57'), hexc('c79a62')]
    for y in range(size):
        for x in range(size):
            t = f(x, y) * 0.7 + g(x, y) * 0.3 + (BAYER[y % 2][x % 2] - 1.5) * 0.04
            p[x, y] = shades[max(0, min(4, int(t * 5)))]
    for _ in range(size * size // 400):  # pebbles
        x, y = rng.randrange(size - 2), rng.randrange(size - 2)
        p[x, y] = hexc('c9c0b0'); p[x + 1, y] = hexc('a89e8e'); p[x, y + 1] = hexc('857a6a'); p[x + 1, y + 1] = hexc('7a6e5e')
    for _ in range(size * size // 700):  # wheel ruts
        x, y = rng.randrange(size), rng.randrange(size)
        for i in range(6):
            p[(x + i) % size, y] = hexc('94683f')
    return img


def field(W=48, H=32):
    rng = random.Random(8)
    img = new(W, H)
    p = img.load()
    for y in range(H):
        for x in range(W):
            soil = (y // 4) % 2 == 0
            p[x, y] = hexc(rng.choice(['7a5232', '6f4a2c', '83593a'] if soil else ['8a5e38', '7f5634']))
        if (y // 4) % 2 == 0 and y % 4 in (1, 2):
            for x in range(1, W, 3):
                p[x, y] = hexc('6cb04a') if y % 4 == 1 else hexc('4f8f34')
                if y % 4 == 1 and rng.random() < 0.4:
                    p[x, y - 1] = hexc('94d06a')
                if y % 4 == 2 and rng.random() < 0.12:
                    p[x, y] = hexc('e8c84a')
    return img


def cliff(W=64, H=64):
    """Rock face with vertical cracks and ledges, seamless."""
    rng = random.Random(11)
    img = new(W, H)
    p = img.load()
    f = wrap_noise(rng, 4, W)
    cols = [hexc('5c5246'), hexc('6a5e50'), hexc('786b5b'), hexc('857767'), hexc('948573')]
    colw = [rng.randrange(4, 9) for _ in range(20)]
    edges = []
    x = 0
    for w in colw:
        edges.append(x)
        x += w
        if x >= W:
            break
    for y in range(H):
        for xx in range(W):
            t = f(xx, y) * 0.8 + 0.1
            # each rock column lit on its left, shaded on its right
            for e in edges:
                if xx == e:
                    t -= 0.35
                elif xx == e + 1:
                    t += 0.2
            t += (BAYER[y % 2][xx % 2] - 1.5) * 0.03
            p[xx, y] = cols[max(0, min(4, int(t * 5)))]
    for _ in range(6):  # ledges
        y = rng.randrange(H); x0 = rng.randrange(W)
        for i in range(rng.randrange(6, 14)):
            p[(x0 + i) % W, y] = hexc('a39380')
            p[(x0 + i) % W, (y + 1) % H] = hexc('4a4238')
    for _ in range(14):  # moss and little plants
        x, y = rng.randrange(W), rng.randrange(H)
        p[x, y] = hexc('5f8a3a'); p[(x + 1) % W, y] = hexc('4f7a30')
    return img


def rim(W=32, H=32):
    rng = random.Random(12)
    img = new(W, H)
    p = img.load()
    f = wrap_noise(rng, 4, W)
    cols = [hexc('9a8e7a'), hexc('a99c86'), hexc('b8ab94'), hexc('c4b8a0')]
    for y in range(H):
        for x in range(W):
            t = f(x, y) + (BAYER[y % 2][x % 2] - 1.5) * 0.05
            p[x, y] = cols[max(0, min(3, int(t * 4)))]
    for _ in range(10):
        x, y = rng.randrange(W), rng.randrange(H)
        p[x, y] = hexc('6e9a44')
    return img


def build():
    cliff().save(OUT + 'tex_cliff.png')
    rim().save(OUT + 'tex_rim.png')
    bond(40, 40, 10, 5, ['b5603f', 'a95638', 'c06a46', 'b05a3a', '9e4f34', 'c4744e'], '7a3f2c', 1,
         moss='5e8a3a').save(OUT + 'tex_brick.png')
    bond(32, 32, 8, 4, ['b8b0a0', 'aaa292', 'c4bcac', '9e9686'], '6e665a', 2, bevel=0.2).save(OUT + 'tex_kerb.png')
    bond(44, 44, 11, 11, ['d8c8a4', 'ccba94', 'e2d4b2', 'd2c0a0', 'c4b28c'], 'a08a6a', 3, moss='7a9a4a').save(OUT + 'tex_plaza.png')
    bond(40, 40, 10, 10, ['9ea4ae', '8e949e', 'acb2bc', '858c98', 'a4a0a8'], '5e646e', 4, moss='6a8a4a').save(OUT + 'tex_cobble.png')
    dirt(128).save(OUT + 'tex_dirt.png')
    field().save(OUT + 'tex_field.png')


if __name__ == '__main__':
    build()
    names = ['brick', 'kerb', 'plaza', 'cobble', 'dirt', 'field']
    prev = Image.new('RGBA', (6 * 140, 140), (0, 0, 0, 255))
    for i, n in enumerate(names):
        t = Image.open(OUT + 'tex_%s.png' % n)
        tile = Image.new('RGBA', (140, 140))
        for y in range(0, 140, t.height):
            for x in range(0, 140, t.width):
                tile.paste(t, (x, y))
        prev.paste(tile, (i * 140, 0))
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save('/home/claude/preview_paving.png')
    print('ok')
