"""Forge, wall stone texture, towers and the royal castle."""
import random
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, mask, outline, paint_mask, finish, rebrick

OUT = '../art/'
OUTLINE = hexc('2a1e16')
def ramp(*hs): return [hexc(h) for h in hs]
STONE = ramp('6e6a62', '8e8a80', 'aaa59a', 'c4beb2', 'dcd6ca')
SLATE = ramp('1c2c52', '2a4078', '3a58a0', '5276c4', '7a9ade')

def bricks(img, box, rng, ramp_cols, bw=6, bh=4, light_x=True):
    x0, y0, x1, y1 = box
    p = img.load()
    for y in range(y0, y1):
        row = (y - y0) // bh
        for x in range(x0, x1):
            if p[x, y][3] == 0:
                continue
            off = (row % 2) * (bw // 2)
            bx = (x - x0 + off) % bw
            by = (y - y0) % bh
            # cylinder-ish shading across width
            u = (x - x0) / max(1, x1 - x0)
            base = 2 + (1 if u < 0.35 else 0) - (1 if u > 0.75 else 0)
            if by == bh - 1 or bx == bw - 1:
                c = ramp_cols[max(0, base - 2)]
            elif by == 0:
                c = ramp_cols[min(4, base + 1)]
            else:
                c = ramp_cols[base]
                if rng.random() < 0.08:
                    c = ramp_cols[max(0, base - 1)]
            p[x, y] = c

def wall_texture():
    T = 32
    img = new(T, T)
    rng = random.Random(3)
    p = img.load()
    for y in range(T):
        row = y // 8
        for x in range(T):
            off = (row % 2) * 8
            bx = (x + off) % 16
            by = y % 8
            c = STONE[2]
            if by == 7 or bx == 15: c = STONE[0]
            elif by == 0: c = STONE[3]
            elif bx == 0: c = STONE[3]
            elif by == 6 or bx == 14: c = STONE[1]
            elif rng.random() < 0.1: c = STONE[1]
            elif rng.random() < 0.05: c = STONE[3]
            if rng.random() < 0.025: c = hexc('6aa040')
            p[x, y] = c
    img.save(OUT + 'wall_stone.png')
    return img

def tower(W, H, cone):
    rng = random.Random(W + H)
    top = 22 if cone else 6
    img = new(W, H + top)
    d = ImageDraw.Draw(img)
    body = (1, top + 3, W - 1, top + H - 1)
    d.rectangle([body[0], body[1], body[2] - 1, body[3]], fill=(255, 255, 255, 255))
    d.ellipse([1, top + H - 6, W - 2, top + H - 1], fill=(255, 255, 255, 255))
    bricks(img, body, rng, STONE)
    # window slit
    d.rectangle([W // 2 - 1, top + H // 2 - 4, W // 2, top + H // 2 + 3], fill=hexc('2a2420'))
    if cone:
        m = mask(W + 4, H + top)
        cm = Image.new('RGBA', img.size, (0, 0, 0, 0))
        dm = mask(*img.size)
        ImageDraw.Draw(dm).polygon([(0, top + 4), (W - 1, top + 4), (W // 2, 0)], fill=255)
        paint_mask(img, dm, SLATE, light=(-1, -0.3))
        p = img.load()
        for y in range(2, top + 4, 3):
            for x in range(W):
                if dm.getpixel((x, y)):
                    p[x, y] = SLATE[1]
        p[W // 2, 0] = hexc('f2c84a')
        d.line([(0, top + 4), (W - 1, top + 4)], fill=SLATE[0])
    else:
        # battlements
        d.rectangle([0, top, W - 1, top + 3], fill=STONE[3])
        for x in range(0, W, 5):
            d.rectangle([x, top - 3, x + 2, top], fill=STONE[3])
            d.point((x, top - 3), fill=STONE[4])
        d.line([(0, top + 3), (W - 1, top + 3)], fill=STONE[0])
    return outline(img, OUTLINE)

def towers():
    a = tower(30, 50, False)
    b = tower(26, 56, True)
    sheet = new(a.width + b.width, max(a.height, b.height))
    sheet.paste(a, (0, sheet.height - a.height))
    sheet.paste(b, (a.width, sheet.height - b.height))
    sheet = finish(sheet, OUTLINE, 11)
    rebrick(sheet, 8, 6)
    sheet.save(OUT + 'towers.png')
    return sheet, a.width

def forge():
    W, H = 72, 62
    rng = random.Random(9)
    img = new(W, H)
    d = ImageDraw.Draw(img)
    wall_top = 30
    d.rectangle([3, wall_top, W - 4, H - 4], fill=(255, 255, 255, 255))
    bricks(img, (3, wall_top, W - 3, H - 3), rng, STONE, bw=7, bh=4)
    # slate roof
    rm = mask(W, H)
    ImageDraw.Draw(rm).polygon([(0, wall_top + 1), (W - 1, wall_top + 1), (W - 6, 8), (5, 8)], fill=255)
    p = img.load()
    for y in range(H):
        for x in range(W):
            if rm.getpixel((x, y)):
                t = 2 + (1 if x < W // 2 else 0)
                if (y - 8) % 3 == 0: t -= 1
                if (x + ((y - 8) // 3) * 3) % 7 == 0: t -= 1
                p[x, y] = SLATE[max(0, min(4, t))]
    d.line([(5, 8), (W - 6, 8)], fill=SLATE[4])
    # chimney
    d.rectangle([W - 20, 0, W - 12, 18], fill=(255, 255, 255, 255))
    bricks(img, (W - 20, 0, W - 11, 19), rng, STONE, bw=4, bh=3)
    d.rectangle([W - 21, 0, W - 11, 2], fill=STONE[1])
    # furnace mouth (glow is animated in game)
    d.rectangle([24, 38, 47, 57], fill=hexc('2a1810'))
    d.rectangle([26, 41, 45, 57], fill=hexc('c84a14'))
    d.rectangle([29, 45, 42, 57], fill=hexc('f2902a'))
    d.rectangle([32, 49, 39, 57], fill=hexc('ffd860'))
    d.arc([24, 32, 47, 46], 180, 360, fill=hexc('2a1810'))
    # sign
    d.rectangle([6, 36, 18, 44], fill=hexc('8a5a30'))
    d.rectangle([7, 37, 17, 43], fill=hexc('b07a44'))
    d.line([(9, 42), (15, 38)], fill=hexc('c8ccd2'))
    d.line([(10, 40), (12, 42)], fill=hexc('6a4426'))
    # barrel and weapon rack
    d.rectangle([54, 44, 63, 57], fill=hexc('7a4e2c'))
    for y in (46, 52):
        d.line([(54, y), (63, y)], fill=hexc('5a5e66'))
    d.line([(55, 44), (55, 57)], fill=hexc('96663a'))
    for i, x in enumerate((57, 60)):
        d.line([(x, 36), (x, 45)], fill=hexc('d8dde3'))
        d.point((x, 35), fill=hexc('ffffff'))
        d.line([(x - 1, 45), (x + 1, 45)], fill=hexc('c8a03a'))
    img = outline(img, OUTLINE)
    # anvil as separate small sprite at the right
    anvil = new(18, 10)
    da = ImageDraw.Draw(anvil)
    da.rectangle([6, 4, 11, 9], fill=hexc('3a3c42'))
    da.rectangle([1, 1, 15, 4], fill=hexc('5a5e66'))
    da.line([(1, 1), (15, 1)], fill=hexc('9aa0a8'))
    da.polygon([(15, 1), (17, 2), (15, 4)], fill=hexc('5a5e66'))
    da.rectangle([4, 9, 13, 9], fill=hexc('2a2c32'))
    anvil = outline(anvil, OUTLINE)
    sheet = new(W + 20, H)
    sheet.paste(img, (0, 0))
    sheet.paste(anvil, (W + 1, H - 12))
    sheet = finish(sheet, OUTLINE, 12)
    rebrick(sheet, 9, 6)
    sheet.save(OUT + 'forge.png')
    return sheet

def castle():
    W, H = 220, 200
    rng = random.Random(21)
    img = new(W, H)
    d = ImageDraw.Draw(img)
    # main hall
    hall = (20, 120, 200, 196)
    d.rectangle([hall[0], hall[1], hall[2] - 1, hall[3]], fill=(255, 255, 255, 255))
    bricks(img, hall, rng, STONE, bw=8, bh=5)
    # hall roof
    rm = mask(W, H)
    ImageDraw.Draw(rm).polygon([(14, 121), (205, 121), (190, 92), (29, 92)], fill=255)
    p = img.load()
    for y in range(H):
        for x in range(W):
            if rm.getpixel((x, y)):
                t = 2 + (1 if x < W // 2 else 0)
                if (y - 92) % 4 == 0: t -= 1
                p[x, y] = SLATE[max(0, min(4, t))]
    # keep
    keep = (78, 40, 142, 124)
    d.rectangle([keep[0], keep[1], keep[2] - 1, keep[3]], fill=(255, 255, 255, 255))
    bricks(img, keep, rng, STONE, bw=7, bh=5)
    km = mask(W, H)
    ImageDraw.Draw(km).polygon([(72, 42), (148, 42), (110, 0)], fill=255)
    paint_mask(img, km, SLATE, light=(-1, -0.2))
    for y in range(4, 42, 4):
        for x in range(W):
            if km.getpixel((x, y)):
                p[x, y] = SLATE[1] if x > 110 else SLATE[2]
    p[110, 0] = hexc('f2c84a'); p[110, 1] = hexc('f2c84a')
    # arched windows
    def window(x, y, w=6, h=10):
        d.rectangle([x, y + 3, x + w - 1, y + h], fill=hexc('263046'))
        d.ellipse([x, y, x + w - 1, y + 6], fill=hexc('263046'))
        d.rectangle([x + 1, y + 4, x + w - 2, y + h - 1], fill=hexc('5a86c8'))
        d.point((x + 1, y + 4), fill=hexc('bfe0ff'))
    for x in range(30, 196, 18):
        if not 92 < x < 128:
            window(x, 136)
    window(104, 60, 12, 18)
    window(90, 86); window(124, 86)
    # great gate
    d.rectangle([96, 160, 123, 196], fill=hexc('3a2414'))
    d.ellipse([96, 150, 123, 172], fill=hexc('3a2414'))
    d.rectangle([99, 162, 120, 196], fill=hexc('6e4422'))
    d.ellipse([99, 153, 120, 171], fill=hexc('6e4422'))
    for x in range(102, 120, 5):
        d.line([(x, 158), (x, 196)], fill=hexc('5a3a20'))
    d.line([(99, 176), (120, 176)], fill=hexc('8a8e96'))
    # banners (Kingdom B: blue and gold, and royal red)
    for x, col in ((60, 'c83a3a'), (150, 'c83a3a'), (36, '2f56b0'), (176, '2f56b0')):
        c = hexc(col)
        d.rectangle([x, 124, x + 9, 150], fill=c)
        d.polygon([(x, 150), (x + 9, 150), (x + 4, 156)], fill=c)
        d.line([(x, 124), (x, 150)], fill=mix(c, (255, 255, 255, 255), 0.3))
        d.ellipse([x + 2, 132, x + 7, 137], fill=hexc('f2c84a'))
        d.line([(x - 1, 123), (x + 10, 123)], fill=hexc('c8a03a'))
    img = outline(img, OUTLINE)
    # spires
    sp = tower(22, 70, True)
    for x, y in ((14, 196), (184, 196), (54, 128), (144, 128)):
        img.paste(sp, (x - 11 + 11 - 11, y - sp.height + 4), sp)
    img = finish(img, OUTLINE, 13)
    rebrick(img, 10, 6)
    img.save(OUT + 'castle.png')
    return img

if __name__ == '__main__':
    wall_texture()
    t, tw = towers()
    f = forge()
    c = castle()
    prev = Image.new('RGBA', (900, 430), hexc('5ea83a'))
    prev.paste(c, (0, 10), c)
    prev.paste(f, (450, 10), f)
    prev.paste(t, (650, 10), t)
    wt = Image.open(OUT + 'wall_stone.png')
    for i in range(4):
        prev.paste(wt, (450 + i * 32, 200))
    prev.save('/home/claude/preview_build.png')
    print('ok', tw)
