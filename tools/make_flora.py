"""Small decoration sprites scattered over the ground: bushes, flower patches,
grass tufts, ferns, mushrooms, pebbles. Saved as art/flora.png, one 32x32 cell each.
Order of cells (index): see NAMES."""
import random, math
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, outline

OUT = '../art/'
OL = hexc('243018')
NAMES = ['bush', 'bush_berry', 'bush_flower', 'flowers_red', 'flowers_yellow', 'flowers_purple',
         'flowers_white', 'tuft', 'tuft_tall', 'fern', 'mushrooms', 'pebbles']
C = 32


def bush(seed, extra=None):
    rng = random.Random(seed)
    img = new(C, C)
    p = img.load()
    shades = [hexc('2e5a26'), hexc('3a6e2e'), hexc('478236'), hexc('56953f'), hexc('6aa84c')]
    blobs = [(16, 18, 9), (9, 21, 7), (23, 21, 7), (12, 14, 6), (20, 14, 6)]
    for (x, y, r) in sorted(blobs, key=lambda b: b[1]):
        for yy in range(y - r, y + r + 1):
            for xx in range(x - r, x + r + 1):
                d = ((xx - x) ** 2 + (yy - y) ** 2) / (r * r)
                if d <= 1.0 and 0 <= xx < C and 0 <= yy < C:
                    t = 0.55 - (xx - x) / r * 0.25 - (yy - y) / r * 0.4 + (rng.random() - 0.5) * 0.15
                    if d > 0.75 and yy > y: t -= 0.25
                    p[xx, yy] = shades[max(0, min(4, int(t * 5)))]
    for _ in range(10):
        x, y = rng.randrange(6, 26), rng.randrange(9, 22)
        if p[x, y][3] and p[x + 1, y][3]:
            p[x, y] = shades[4]; p[x + 1, y] = shades[4]
    if extra:
        for _ in range(9):
            x, y = rng.randrange(6, 26), rng.randrange(10, 26)
            if p[x, y][3]:
                p[x, y] = hexc(extra)
                if p[x, y - 1][3]:
                    p[x, y - 1] = mix(hexc(extra), (255, 255, 255, 255), 0.45)
    return outline(img, OL)


def flowers(seed, petal):
    rng = random.Random(seed)
    img = new(C, C)
    p = img.load()
    d = ImageDraw.Draw(img)
    pc = hexc(petal)
    for _ in range(9):
        x, y = rng.randrange(5, 27), rng.randrange(8, 28)
        d.line([(x, y), (x, y + 4)], fill=hexc('3f7a2c'))
        p[x - 1, y + 3] = hexc('4f8f34')
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p[x + dx, y + dy] = pc
        p[x - 1, y - 1] = mix(pc, (255, 255, 255, 255), 0.4)
        p[x, y] = hexc('ffe066')
    return img


def tuft(seed, tall):
    rng = random.Random(seed)
    img = new(C, C)
    d = ImageDraw.Draw(img)
    cols = [hexc('3f7a2c'), hexc('4f8f34'), hexc('62a442'), hexc('7cbc52')]
    h = 18 if tall else 10
    for i in range(14 if tall else 9):
        x = 16 + rng.randrange(-9, 10)
        lean = rng.choice([-3, -2, -1, 1, 2, 3])
        top = 30 - rng.randrange(h // 2, h)
        d.line([(x, 30), (x + lean, top)], fill=rng.choice(cols))
        img.putpixel((x + lean, top), cols[3])
    return img


def fern(seed):
    rng = random.Random(seed)
    img = new(C, C)
    d = ImageDraw.Draw(img)
    for k in range(5):
        a = math.radians(-160 + k * 35)
        x1, y1 = 16 + math.cos(a) * 13, 28 + math.sin(a) * 13
        d.line([(16, 28), (x1, y1)], fill=hexc('2f6a2a'), width=1)
        for t in range(2, 12, 2):
            px = 16 + math.cos(a) * t; py = 28 + math.sin(a) * t
            d.line([(px, py), (px + math.cos(a + 1.2) * 3, py + math.sin(a + 1.2) * 3)], fill=hexc('4a8c38'))
            d.line([(px, py), (px + math.cos(a - 1.2) * 3, py + math.sin(a - 1.2) * 3)], fill=hexc('5ea445'))
    return outline(img, OL)


def mushrooms(seed):
    img = new(C, C)
    d = ImageDraw.Draw(img)
    for (x, y, r) in ((12, 26, 5), (21, 28, 4), (17, 22, 3)):
        d.rectangle([x - 1, y - r, x + 1, y], fill=hexc('efe6d2'))
        d.ellipse([x - r, y - r - 3, x + r, y - r + 2], fill=hexc('c83a2c'))
        d.point((x - 1, y - r - 1), fill=hexc('ffffff'))
        d.point((x + 2, y - r), fill=hexc('ffffff'))
    return outline(img, OL)


def pebbles(seed):
    rng = random.Random(seed)
    img = new(C, C)
    d = ImageDraw.Draw(img)
    for _ in range(5):
        x, y = rng.randrange(6, 26), rng.randrange(18, 28)
        r = rng.randrange(2, 4)
        d.ellipse([x - r, y - r + 1, x + r, y + r - 1], fill=hexc('8e8a80'))
        d.point((x - 1, y - 1), fill=hexc('c6c0b4'))
    return outline(img, OL)


def build():
    cells = [bush(1), bush(2, 'c83a5a'), bush(3, 'f2f0e6'),
             flowers(4, 'e8484a'), flowers(5, 'ffd23a'), flowers(6, 'a868e0'), flowers(7, 'ffffff'),
             tuft(8, False), tuft(9, True), fern(10), mushrooms(11), pebbles(12)]
    sheet = new(C * len(cells), C)
    for i, c in enumerate(cells):
        sheet.paste(c, (i * C, 0))
    sheet.save(OUT + 'flora.png')
    return sheet


if __name__ == '__main__':
    s = build()
    bg = Image.new('RGBA', s.size, hexc('5c9a3c'))
    bg.paste(s, (0, 0), s)
    bg.resize((s.width * 4, s.height * 4), Image.NEAREST).save('/home/claude/preview_flora.png')
    print('ok')
