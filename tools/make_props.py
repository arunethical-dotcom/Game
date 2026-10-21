"""Trees, ore rocks, houses, market stalls, well, garden plots."""
import random, math
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, mask, outline, paint_mask, finish

OUT = '../art/'
OUTLINE = hexc('2a1e16')

def ramp(*hs):
    return [hexc(h) for h in hs]

# ---------------------------------------------------------------- trees
TREE_KINDS = {
    'oak':     ramp('1f5a26', '2e7a2f', '3f9a38', '58b648', '7fd060'),
    'pine':    ramp('163f2a', '1f5a38', '2d7444', '3f8f52', '5aa866'),
    'blossom': ramp('8a2f5c', 'b8417a', 'dd6a9c', 'f39bbf', 'ffc9de'),
    'autumn':  ramp('8a3a14', 'b5571c', 'dc7f26', 'f2a83a', 'ffd36a'),
    'violet':  ramp('3e2a6a', '5a3c94', '7a56bd', '9f7fdb', 'c8b0f2'),
}

def tree(kind, seed):
    K = 2
    W, H = 32 * K, 44 * K
    img = new(W, H)
    rng = random.Random(seed)
    tm = mask(W, H)
    ImageDraw.Draw(tm).rectangle([27, 52, 36, 82], fill=255)
    ImageDraw.Draw(tm).polygon([(22, 85), (41, 85), (36, 74), (27, 74)], fill=255)
    paint_mask(img, tm, ramp('3d2414', '5a3820', '7a4e2c', '96663a'), light=(-1, 0), rng=rng, dither=0.3)
    p = img.load()
    for _ in range(10):  # bark lines
        x, y = rng.randrange(28, 35), rng.randrange(56, 80)
        for i in range(4):
            if tm.getpixel((x, y + i)):
                p[x, y + i] = hexc('3d2414')
    m = mask(W, H)
    md = ImageDraw.Draw(m)
    rp = TREE_KINDS[kind]
    import math
    if kind == 'pine':
        tiers = [(6, 10), (22, 16), (38, 22), (54, 27)]
        for i, (y, w) in enumerate(tiers):
            tier = mask(W, H)
            td = ImageDraw.Draw(tier)
            pts = [(32, y - 8)]
            n = 7
            for k in range(n + 1):  # jagged bottom edge
                x = 32 - w + k * (2 * w) / n
                pts.append((x, y + 18 + (3 if k % 2 else 0)))
            pts = [pts[0]] + pts[1:][::-1] if False else pts
            td.polygon([(32, y - 8), (32 + w, y + 18)] + [(32 + w - k * (2 * w) / n, y + 18 + (3 if k % 2 else 0)) for k in range(n + 1)] + [(32 - w, y + 18)], fill=255)
            tp = tier.load()
            for yy in range(H):
                for xx in range(W):
                    if tp[xx, yy]:
                        u = (xx - 32) / max(1, w)
                        v = (yy - (y - 8)) / 26.0
                        t = 0.75 - u * 0.35 - v * 0.45 + (rng.random() - 0.5) * 0.2
                        if (xx + yy) % 5 == 0 and v > 0.4:
                            t -= 0.2
                        p[xx, yy] = rp[max(0, min(4, int(t * 5)))]
                        m.putpixel((xx, yy), 255)
    else:
        cx, cy, rx, ry = 32, 34, 27, 27
        clumps = []
        for _ in range(36):
            ang = rng.random() * math.tau
            rr = math.sqrt(rng.random())
            x = cx + math.cos(ang) * rx * rr * 0.85
            y = cy + math.sin(ang) * ry * rr * 0.85
            clumps.append((x, y, rng.uniform(6.5, 9.5)))
        clumps.sort(key=lambda c: c[1])
        for (x, y, r) in clumps:
            for yy in range(int(y - r), int(y + r) + 1):
                for xx in range(int(x - r), int(x + r) + 1):
                    if not (0 <= xx < W and 0 <= yy < H):
                        continue
                    u, v = (xx - x) / r, (yy - y) / r
                    d = u * u + v * v
                    if d > 1.0:
                        continue
                    tg = 0.5 - ((xx - cx) / rx) * 0.3 - ((yy - cy) / ry) * 0.4
                    tl = -(u * 0.45 + v * 0.7) * 0.5
                    t = 0.02 + tg * 0.6 + tl + (rng.random() - 0.5) * 0.12
                    if d > 0.78 and v > -0.2:
                        t -= 0.3
                    p[xx, yy] = rp[max(0, min(4, int(t * 5 + 1)))]
                    m.putpixel((xx, yy), 255)
        for _ in range(18):  # sparkling leaf tips on the lit side
            x, y = rng.randrange(10, 40), rng.randrange(8, 34)
            if m.getpixel((x, y)) and m.getpixel((x + 1, y)):
                p[x, y] = rp[4]
                p[x + 1, y] = rp[4]
    if kind == 'oak' and seed % 2 == 0:
        for _ in range(6):
            x, y = rng.randrange(8 * K, 24 * K), rng.randrange(10 * K, 24 * K)
            if m.getpixel((x, y)) and m.getpixel((x + 1, y + 1)):
                p[x, y] = hexc('e0383a'); p[x + 1, y] = hexc('c02a2c'); p[x, y + 1] = hexc('c02a2c'); p[x + 1, y + 1] = hexc('8a1a1c')
                p[x, y] = hexc('ff8080')
    if kind == 'blossom':
        for _ in range(12):
            x, y = rng.randrange(6, W - 6), rng.randrange(6, H // 2)
            if m.getpixel((x, y)):
                p[x, y] = hexc('ffffff')
    img = outline(img, OUTLINE)
    return img


def trees():
    kinds = list(TREE_KINDS.keys())
    sheet = new(64 * len(kinds) * 2, 88)
    for i, k in enumerate(kinds):
        for v in range(2):
            sheet.paste(tree(k, i * 10 + v), ((i * 2 + v) * 64, 0))
    sheet.save(OUT + 'trees.png')
    return sheet

# ---------------------------------------------------------------- ore rocks
def rocks():
    K = 2
    sheet = new(48 * 3, 40)
    for v in range(3):
        img = new(48, 40)
        rng = random.Random(50 + v)
        m = mask(48, 40)
        pts = [(2, 18), (1, 11), (5, 5), (11, 2), (17, 4), (22, 9), (22, 16), (18, 19)]
        pts = [((x + rng.randrange(-1, 2)) * K, (y + rng.randrange(-1, 2)) * K) for x, y in pts]
        ImageDraw.Draw(m).polygon(pts, fill=255)
        paint_mask(img, m, ramp('4a4744', '676360', '85807a', 'a39d95', 'c6c0b6'), light=(-0.8, -1), rng=rng, dither=0.25)
        p = img.load()
        for _ in range(4):  # facet cracks
            x, y = rng.randrange(8, 40), rng.randrange(8, 30)
            for i in range(6):
                if m.getpixel((x + i // 2, y + i)):
                    p[x + i // 2, y + i] = hexc('4a4744')
        for _ in range(9):  # rusty iron ore veins
            x, y = rng.randrange(10, 38), rng.randrange(12, 32)
            for dx, dy, c in ((0, 0, 'c2652e'), (1, 0, 'e98a44'), (2, 0, 'c2652e'), (0, 1, '8c4020'), (1, 1, 'a4502a')):
                if m.getpixel((x + dx, y + dy)):
                    p[x + dx, y + dy] = hexc(c)
        for _ in range(4):  # glints
            x, y = rng.randrange(12, 32), rng.randrange(10, 24)
            if m.getpixel((x, y)):
                p[x, y] = hexc('fff0b0')
        img = outline(img, OUTLINE)
        sheet.paste(img, (v * 48, 0))
    sheet.save(OUT + 'rocks.png')
    return sheet

# ---------------------------------------------------------------- houses
ROOFS = {
    'red':   ramp('6e2418', '8e3220', 'b04628', 'd0603a', 'e88456'),
    'brown': ramp('4a2a18', '643a22', '80502e', '9c683c', 'b8844e'),
    'blue':  ramp('1e3460', '2c4a84', '3c62a8', '5482c8', '7aa6e0'),
    'teal':  ramp('16463e', '1f6256', '2b7f6e', '3f9e88', '62bea6'),
    'slate': ramp('2c3240', '3c4456', '505a70', '687490', '8a96b0'),
}

ROOFS['thatch'] = ramp('6e5420', '8e6e2c', 'b08a3c', 'cca650', 'e6c46a')


def house(W, H, roof, seed, chimney=True, storeys=1, sign=None):
    """Native double-resolution house. W, H in final pixels."""
    rng = random.Random(seed)
    img = new(W, H)
    p = img.load()
    d = ImageDraw.Draw(img)
    wall_h = 30 * storeys
    wall_top = H - wall_h
    # plaster walls with subtle texture
    plaster = ramp('c9ac80', 'dcc296', 'ead6ae', 'f4e6c4')
    for y in range(wall_top, H - 2):
        for x in range(3, W - 3):
            t = 2 if x < W * 0.7 else 1
            if rng.random() < 0.06: t -= 1
            if rng.random() < 0.03: t += 1
            if y > H - 6: t -= 1
            p[x, y] = plaster[max(0, min(3, t))]
    timber = hexc('6a4426'); timber_l = hexc('8a5a32')
    # frame: posts, beams, diagonal braces
    for x in list(range(3, W - 3, 18)) + [W - 5]:
        d.rectangle([x, wall_top, x + 1, H - 3], fill=timber)
        d.line([(x, wall_top), (x, H - 3)], fill=timber_l)
    for k in range(storeys):
        y = wall_top + k * 30
        d.rectangle([3, y, W - 4, y + 1], fill=timber)
        d.line([(3, y), (W - 4, y)], fill=timber_l)
    d.rectangle([3, H - 3, W - 4, H - 2], fill=hexc('5a3a20'))
    # stone footing
    for x in range(3, W - 3, 5):
        d.rectangle([x, H - 5, x + 3, H - 3], fill=hexc('8a8478'))
        d.point((x, H - 5), fill=hexc('b0aa9c'))
    # door with planks, hinges and handle
    dx = W // 2 - 6 + rng.randrange(-8, 9)
    d.rectangle([dx - 1, H - 22, dx + 12, H - 3], fill=hexc('4a2c16'))
    d.rectangle([dx, H - 21, dx + 11, H - 3], fill=hexc('8a5a30'))
    for x in range(dx + 3, dx + 11, 3):
        d.line([(x, H - 21), (x, H - 3)], fill=hexc('6e4422'))
    d.line([(dx, H - 21), (dx + 11, H - 21)], fill=hexc('a8763e'))
    for y in (H - 18, H - 8):
        d.line([(dx, y), (dx + 4, y)], fill=hexc('3a3c42'))
    d.rectangle([dx + 9, H - 13, dx + 10, H - 12], fill=hexc('f0c850'))
    d.rectangle([dx - 2, H - 3, dx + 13, H - 2], fill=hexc('9a948a'))  # step
    # windows on each storey
    for k in range(storeys):
        wy = wall_top + k * 30 + 8
        xs = [9, W - 23] if W > 70 else [8, W - 22]
        if storeys > 1 and k == 0:
            xs = [9, W // 2 - 7, W - 23]
        for wx in xs:
            if k == storeys - 1 and abs(wx - dx) < 16:
                continue
            d.rectangle([wx - 3, wy - 1, wx - 1, wy + 11], fill=hexc(rng.choice(['3a6a3a', '3a5a8a', '8a3a2a'])))  # shutter
            d.rectangle([wx + 13, wy - 1, wx + 15, wy + 11], fill=hexc(rng.choice(['3a6a3a', '3a5a8a', '8a3a2a'])))
            d.rectangle([wx, wy - 1, wx + 12, wy + 11], fill=hexc('4a3020'))
            d.rectangle([wx + 1, wy, wx + 11, wy + 10], fill=hexc('6ab4e2'))
            d.rectangle([wx + 1, wy, wx + 5, wy + 4], fill=hexc('a8dcf6'))
            d.point((wx + 2, wy + 1), fill=hexc('ffffff'))
            d.line([(wx + 6, wy), (wx + 6, wy + 10)], fill=hexc('4a3020'))
            d.line([(wx + 1, wy + 5), (wx + 11, wy + 5)], fill=hexc('4a3020'))
            if rng.random() < 0.75:  # flower box
                d.rectangle([wx - 1, wy + 12, wx + 13, wy + 14], fill=hexc('7a4e2c'))
                for i in range(0, 14, 2):
                    c = rng.choice(['e8484a', 'ffd84a', 'f26aa8', 'ffffff', 'a060e0'])
                    d.point((wx + i, wy + 11), fill=hexc(c))
                    d.point((wx + i + 1, wy + 11), fill=hexc('4f9a34'))
    if sign:
        sx = dx + 16 if dx + 34 < W else dx - 22
        d.line([(sx, wall_top + 4), (sx + 18, wall_top + 4)], fill=hexc('3a3c42'))
        d.rectangle([sx + 2, wall_top + 6, sx + 16, wall_top + 18], fill=hexc('6a4426'))
        d.rectangle([sx + 3, wall_top + 7, sx + 15, wall_top + 17], fill=hexc('b07a44'))
        if sign == 'mug':
            d.rectangle([sx + 6, wall_top + 9, sx + 11, wall_top + 15], fill=hexc('e2b23a'))
            d.rectangle([sx + 6, wall_top + 9, sx + 11, wall_top + 10], fill=hexc('ffffff'))
            d.rectangle([sx + 12, wall_top + 11, sx + 13, wall_top + 13], fill=hexc('e2b23a'))
    # roof: overlapping shingle rows
    rr = ROOFS[roof]
    rt = 6
    rm = mask(W, H)
    ImageDraw.Draw(rm).polygon([(0, wall_top + 2), (W - 1, wall_top + 2), (W - 7, rt), (6, rt)], fill=255)
    for y in range(rt, wall_top + 3):
        row = (y - rt) // 5
        ry = (y - rt) % 5
        for x in range(W):
            if not rm.getpixel((x, y)):
                continue
            right = x > W // 2
            t = 3 if not right else 2
            if roof == 'thatch':
                if (x * 7 + row * 3) % 4 == 0: t -= 1
                if ry == 4: t -= 1
                if rng.random() < 0.15: t += 1 if rng.random() < 0.5 else -1
            else:
                tx = (x + row * 4) % 8
                if ry == 0: t += 1
                if ry == 4: t -= 2
                if tx == 7: t -= 1
                if rng.random() < 0.04: t -= 1
            if y > wall_top - 2: t -= 1
            p[x, y] = rr[max(0, min(4, t))]
    d.line([(6, rt), (W - 7, rt)], fill=rr[4])
    d.line([(6, rt + 1), (W - 7, rt + 1)], fill=rr[3])
    d.line([(W // 2, rt), (W // 2, wall_top + 1)], fill=rr[1])
    d.line([(0, wall_top + 2), (W - 1, wall_top + 2)], fill=rr[0])
    if chimney:
        cx = W - 22 if rng.random() < 0.5 else 14
        d.rectangle([cx, 0, cx + 9, 16], fill=hexc('8a7a6a'))
        for y in range(1, 16, 4):
            d.line([(cx, y), (cx + 9, y)], fill=hexc('6a5e52'))
            d.point((cx + (y % 8), y + 2), fill=hexc('a89888'))
        d.rectangle([cx - 1, 0, cx + 10, 1], fill=hexc('5a4e44'))
    img = outline(img, OUTLINE)
    return img


HOUSE_SIZES = [(72, 68), (84, 72), (96, 76), (112, 76)]

def houses():
    roofs = ['red', 'brown', 'blue', 'teal', 'slate']
    # sheet: rows = roof colour, columns = sizes (each cell 112x80)
    sheet = new(112 * len(HOUSE_SIZES), 80 * len(roofs))
    for r, roof in enumerate(roofs):
        for s, (w, h) in enumerate(HOUSE_SIZES):
            img = house(w, h, roof, r * 10 + s, chimney=(s + r) % 2 == 0)
            sheet.paste(img, (s * 112 + (112 - w) // 2, r * 80 + (80 - h)))
    sheet.save(OUT + 'houses.png')
    return sheet

# ---------------------------------------------------------------- market & garden
def stall(colors, seed):
    rng = random.Random(seed)
    W, H = 30, 30
    img = new(W, H)
    d = ImageDraw.Draw(img)
    p = img.load()
    # posts
    d.rectangle([3, 10, 4, 28], fill=hexc('6a4426'))
    d.rectangle([W - 5, 10, W - 4, 28], fill=hexc('6a4426'))
    # counter
    d.rectangle([2, 20, W - 3, 28], fill=hexc('8a5a30'))
    d.line([(2, 20), (W - 3, 20)], fill=hexc('b07a44'))
    for x in range(4, W - 4, 5):
        d.line([(x, 21), (x, 28)], fill=hexc('6e4422'))
    # goods
    goods = [hexc('e8383a'), hexc('ffb030'), hexc('7ed04a'), hexc('f2e05a'), hexc('a050d0')]
    for i in range(10):
        x, y = 4 + rng.randrange(W - 9), 16 + rng.randrange(4)
        c = rng.choice(goods)
        p[x, y] = c; p[x + 1, y] = c; p[x, y + 1] = mix(c, (0,0,0,255), 0.3); p[x + 1, y + 1] = mix(c, (0,0,0,255), 0.3)
    # striped awning
    for y in range(3, 12):
        for x in range(1 + (11 - y) // 3, W - 1 - (11 - y) // 3):
            c = colors[(x // 4) % 2]
            if y == 11: c = mix(c, (0, 0, 0, 255), 0.25)
            if y == 3: c = mix(c, (255, 255, 255, 255), 0.3)
            p[x, y] = c
    for x in range(1, W - 1):
        if x % 4 == 1:
            p[x, 12] = colors[(x // 4) % 2]
    return outline(img, OUTLINE)

def well():
    W, H = 22, 28
    img = new(W, H)
    d = ImageDraw.Draw(img)
    m = mask(W, H)
    ImageDraw.Draw(m).ellipse([1, 14, 20, 27], fill=255)
    paint_mask(img, m, ramp('5a5e66', '7a8088', '9aa0a8', 'b8bec6'), light=(-0.8, -0.6))
    d.ellipse([4, 15, 17, 21], fill=hexc('2e5a8a'))
    d.ellipse([6, 16, 14, 19], fill=hexc('4a86c0'))
    d.rectangle([2, 4, 3, 19], fill=hexc('6a4426'))
    d.rectangle([18, 4, 19, 19], fill=hexc('6a4426'))
    d.polygon([(0, 6), (21, 6), (17, 0), (4, 0)], fill=hexc('b04628'))
    d.line([(4, 0), (17, 0)], fill=hexc('e88456'))
    d.line([(10, 6), (10, 13)], fill=hexc('8a7a6a'))
    d.rectangle([9, 12, 11, 14], fill=hexc('7a4e2c'))
    return outline(img, OUTLINE)

def garden(seed):
    rng = random.Random(seed)
    W, H = 28, 18
    img = new(W, H)
    p = img.load()
    d = ImageDraw.Draw(img)
    d.rectangle([1, 2, W - 2, H - 2], fill=hexc('6b4629'))
    crops = [(hexc('6cc24a'), hexc('3f8a2e')), (hexc('e86a2a'), hexc('5aa83a')), (hexc('e83a4a'), hexc('4f9a34')), (hexc('f2d84a'), hexc('6cc24a'))]
    c1, c2 = crops[seed % len(crops)]
    for y in range(4, H - 3, 4):
        d.line([(3, y + 1), (W - 4, y + 1)], fill=hexc('5a3a20'))
        for x in range(3, W - 3, 3):
            p[x, y] = c2
            p[x, y - 1] = c2
            if rng.random() < 0.7:
                p[x + 1, y] = c1
    for x in range(0, W, 4):  # little fence
        d.line([(x, 0), (x, 3)], fill=hexc('8a5a30'))
    d.line([(0, 1), (W - 1, 1)], fill=hexc('a06c3a'))
    return outline(img, OUTLINE)

def market():
    sheet = new(30 * 4 + 22 + 28 * 4, 30)
    pal = [(hexc('e8483a'), hexc('f4efe6')), (hexc('3a74d0'), hexc('f4efe6')), (hexc('3aa85a'), hexc('f2d84a')), (hexc('9a4ad0'), hexc('f2c84a'))]
    for i, cols in enumerate(pal):
        sheet.paste(stall(cols, i), (i * 30, 0))
    sheet.paste(well(), (120, 2))
    for i in range(4):
        sheet.paste(garden(i), (142 + i * 28, 12))
    sheet = finish(sheet, OUTLINE, 21)
    sheet.save(OUT + 'market.png')
    return sheet

if __name__ == '__main__':
    t = trees(); r = rocks(); h = houses(); m = market()
    prev = Image.new('RGBA', (360, 300), hexc('5ea83a'))
    prev.paste(t, (0, 0), t)
    prev.paste(r, (0, 48), r)
    prev.paste(m, (80, 48), m)
    prev.paste(h, (0, 90), h)
    prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save('/home/claude/preview_props.png')
    print('ok')
