"""Extra sprites from the city plan, drawn natively at double resolution.
Each is saved as art/x_<name>.png, anchored bottom-centre in game."""
import random, math
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, mask, outline, paint_mask, rebrick
import make_props

OUT = '../art/'
OL = hexc('2a1e16')
def ramp(*hs): return [hexc(h) for h in hs]
WOOD = ramp('3d2414', '5a3820', '7a4e2c', '96663a', 'b8844e')
STONE = ramp('6e6a62', '8e8a80', 'aaa59a', 'c4beb2', 'dcd6ca')
IRON = ramp('2e3036', '4a4e56', '6a6e76', '9aa0a8', 'd8dde3')


def plank(d, x0, y0, x1, y1, vertical=False, seed=0):
    """A wooden beam with grain and a lit edge."""
    rng = random.Random(seed + x0 * 7 + y0)
    d.rectangle([x0, y0, x1, y1], fill=WOOD[2])
    if vertical:
        d.line([(x0, y0), (x0, y1)], fill=WOOD[3])
        d.line([(x1, y0), (x1, y1)], fill=WOOD[1])
        for _ in range(max(1, (y1 - y0) // 8)):
            y = rng.randrange(y0, y1 + 1)
            d.point((rng.randrange(x0, x1 + 1), y), fill=WOOD[1])
    else:
        d.line([(x0, y0), (x1, y0)], fill=WOOD[3])
        d.line([(x0, y1), (x1, y1)], fill=WOOD[1])
        for _ in range(max(1, (x1 - x0) // 8)):
            d.point((rng.randrange(x0, x1 + 1), rng.randrange(y0, y1 + 1)), fill=WOOD[1])


def save(name, img):
    img = outline(img, OL)
    img.save(OUT + 'x_%s.png' % name)
    return img


def headframe():
    W, H = 80, 120
    img = new(W, H); d = ImageDraw.Draw(img)
    # A-frame legs
    for (a, b) in (((8, 118), (34, 22)), ((72, 118), (46, 22)), ((22, 118), (36, 30)), ((58, 118), (44, 30))):
        d.line([a, b], fill=WOOD[1], width=5)
        d.line([(a[0] - 1, a[1]), (b[0] - 1, b[1])], fill=WOOD[3], width=1)
    for y in (50, 78, 102):  # cross braces
        x0 = 8 + (118 - y) * 26 / 96; x1 = 72 - (118 - y) * 26 / 96
        plank(d, int(x0), y, int(x1), y + 3)
    d.line([(int(8 + 16 * 26 / 96), 102), (int(72 - 68 * 26 / 96), 50)], fill=WOOD[1], width=2)
    # wheel
    cx, cy, r = 40, 18, 15
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=IRON[1], width=3)
    d.ellipse([cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1], outline=IRON[3], width=1)
    for k in range(8):
        a = k * math.pi / 4
        d.line([(cx, cy), (cx + math.cos(a) * (r - 2), cy + math.sin(a) * (r - 2))], fill=IRON[2], width=1)
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=IRON[1])
    d.point((cx - 1, cy - 1), fill=IRON[4])
    # rope down into the shaft
    d.line([(cx + r - 1, cy), (cx + r - 1, 108)], fill=hexc('c8a870'))
    d.rectangle([cx + r - 4, 96, cx + r + 2, 104], fill=IRON[2])  # bucket
    d.line([(cx + r - 4, 96), (cx + r + 2, 96)], fill=IRON[4])
    # platform
    plank(d, 4, 112, 76, 118)
    return save('headframe', img)


def mine_entrance():
    W, H = 96, 72
    img = new(W, H); d = ImageDraw.Draw(img)
    m = mask(W, H)
    ImageDraw.Draw(m).polygon([(0, 71), (4, 30), (18, 10), (40, 2), (62, 4), (82, 16), (95, 36), (95, 71)], fill=255)
    rng = random.Random(4)
    paint_mask(img, m, ramp('5a4a3a', '7a6650', '98806a', 'b49c80', 'cbb698'), light=(-0.6, -1), rng=rng, dither=0.3)
    p = img.load()
    for _ in range(20):
        x, y = rng.randrange(6, 90), rng.randrange(8, 66)
        for i in range(5):
            if m.getpixel((x + i, y)):
                p[x + i, y] = hexc('5a4a3a')
    # tunnel
    d.rectangle([30, 34, 66, 71], fill=hexc('140e0a'))
    d.ellipse([30, 22, 66, 46], fill=hexc('140e0a'))
    d.rectangle([34, 40, 62, 71], fill=hexc('22180f'))
    # timber frame
    plank(d, 26, 30, 31, 71, True); plank(d, 65, 30, 70, 71, True)
    plank(d, 22, 24, 74, 30)
    # rails
    for y in range(52, 72, 5):
        d.line([(38, y), (58, y)], fill=WOOD[1], width=2)
    d.line([(41, 50), (39, 71)], fill=IRON[3], width=1)
    d.line([(55, 50), (57, 71)], fill=IRON[3], width=1)
    # lantern
    d.rectangle([70, 34, 74, 40], fill=hexc('ffd860'))
    d.point((71, 35), fill=hexc('ffffff'))
    d.rectangle([69, 33, 75, 33], fill=IRON[1])
    return save('mine_entrance', img)


def ore_cart():
    W, H = 44, 34
    img = new(W, H); d = ImageDraw.Draw(img)
    rng = random.Random(7)
    for i in range(18):  # ore heap
        x, y = rng.randrange(8, 36), rng.randrange(4, 14)
        c = rng.choice(['85807a', 'a39d95', 'c2652e', '676360', 'e98a44'])
        d.ellipse([x - 3, y - 2, x + 3, y + 3], fill=hexc(c))
    d.polygon([(4, 12), (40, 12), (36, 26), (8, 26)], fill=IRON[2])
    d.line([(4, 12), (40, 12)], fill=IRON[4]); d.line([(5, 13), (39, 13)], fill=IRON[3])
    d.line([(8, 26), (36, 26)], fill=IRON[0])
    for x in (12, 22, 32):
        d.line([(x, 14), (x - 1, 25)], fill=IRON[1])
        d.point((x, 15), fill=IRON[4])
    for x in (12, 32):
        d.ellipse([x - 5, 24, x + 5, 33], fill=IRON[1])
        d.ellipse([x - 2, 27, x + 2, 30], fill=IRON[3])
    return save('ore_cart', img)


def ore_pile():
    W, H = 52, 28
    img = new(W, H); d = ImageDraw.Draw(img)
    rng = random.Random(9)
    for i in range(40):
        t = i / 40
        x = 26 + rng.uniform(-22, 22) * (1 - t * 0.7)
        y = 24 - t * 18 + rng.uniform(-2, 2)
        r = rng.randrange(3, 6)
        c = rng.choice(['85807a', 'a39d95', '676360', 'c2652e', 'e98a44', '4a4744'])
        d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=hexc(c))
        d.point((int(x - r / 2), int(y - r / 2)), fill=hexc('dcd6ca'))
    return save('ore_pile', img)


def crates():
    W, H = 52, 44
    img = new(W, H); d = ImageDraw.Draw(img)
    def crate(x, y, s):
        d.rectangle([x, y, x + s, y + s], fill=WOOD[3])
        d.rectangle([x, y, x + s, y + 2], fill=WOOD[4])
        d.rectangle([x, y + s - 2, x + s, y + s], fill=WOOD[1])
        d.rectangle([x, y, x + 2, y + s], fill=WOOD[2])
        d.rectangle([x + s - 2, y, x + s, y + s], fill=WOOD[1])
        d.line([(x + 2, y + s - 2), (x + s - 2, y + 2)], fill=WOOD[1], width=2)
        for k in range(1, 3):
            d.line([(x + 3, y + k * s // 3), (x + s - 3, y + k * s // 3)], fill=WOOD[2])
    crate(2, 18, 24); crate(26, 22, 20); crate(12, 0, 18)
    return save('crates', img)


def barrel():
    W, H = 26, 32
    img = new(W, H); d = ImageDraw.Draw(img)
    m = mask(W, H)
    ImageDraw.Draw(m).ellipse([1, 0, 24, 31], fill=255)
    ImageDraw.Draw(m).rectangle([3, 3, 22, 28], fill=255)
    paint_mask(img, m, WOOD, light=(-1, 0.2))
    for y in (6, 25):
        d.line([(2, y), (23, y)], fill=IRON[1], width=2)
        d.line([(3, y - 1), (22, y - 1)], fill=IRON[3])
    for x in (8, 13, 18):
        d.line([(x, 3), (x, 28)], fill=WOOD[1])
    d.ellipse([4, 0, 21, 6], fill=WOOD[2]); d.ellipse([6, 1, 19, 5], fill=WOOD[3])
    return save('barrel', img)


def weapon_rack():
    W, H = 64, 56
    img = new(W, H); d = ImageDraw.Draw(img)
    plank(d, 2, 22, 61, 25); plank(d, 2, 44, 61, 47)
    plank(d, 4, 14, 8, 55, True); plank(d, 55, 14, 59, 55, True)
    # swords
    for i, x in enumerate((14, 22, 30)):
        d.rectangle([x, 4, x + 2, 36], fill=IRON[3])
        d.line([(x, 4), (x, 36)], fill=IRON[4]); d.line([(x + 2, 6), (x + 2, 36)], fill=IRON[2])
        d.point((x + 1, 2), fill=IRON[4]); d.point((x + 1, 3), fill=IRON[4])
        d.rectangle([x - 3, 37, x + 5, 39], fill=hexc('e2b23a'))
        d.rectangle([x, 40, x + 2, 46], fill=hexc('6a4426'))
        d.rectangle([x - 1, 47, x + 3, 48], fill=hexc('e2b23a'))
    # axe
    d.rectangle([40, 8, 42, 50], fill=WOOD[3])
    d.polygon([(42, 10), (52, 6), (52, 22), (42, 18)], fill=IRON[2])
    d.line([(52, 6), (52, 22)], fill=IRON[4])
    # shield leaning
    d.ellipse([44, 30, 62, 52], fill=hexc('2f56b0'))
    d.ellipse([47, 33, 59, 49], fill=hexc('3f6fd0'))
    d.ellipse([51, 38, 55, 44], fill=hexc('e2b23a'))
    d.arc([44, 30, 62, 52], 200, 300, fill=hexc('8ab0ff'))
    return save('weapon_rack', img)


def armor_stand():
    W, H = 32, 60
    img = new(W, H); d = ImageDraw.Draw(img)
    plank(d, 14, 20, 17, 54, True)
    plank(d, 6, 54, 25, 58)
    m = mask(W, H)
    ImageDraw.Draw(m).polygon([(5, 18), (26, 18), (24, 38), (20, 42), (11, 42), (7, 38)], fill=255)
    paint_mask(img, m, IRON, light=(-1, -0.5))
    d.line([(15, 20), (15, 40)], fill=IRON[1])
    d.rectangle([3, 16, 9, 22], fill=IRON[3]); d.rectangle([22, 16, 28, 22], fill=IRON[2])  # pauldrons
    d.point((4, 17), fill=IRON[4])
    m2 = mask(W, H)
    ImageDraw.Draw(m2).ellipse([8, 1, 23, 16], fill=255)
    paint_mask(img, m2, IRON, light=(-1, -0.8))
    d.rectangle([10, 8, 21, 9], fill=IRON[0])  # visor slit
    d.rectangle([15, 0, 16, 2], fill=hexc('c83a3a'))
    return save('armor_stand', img)


def woodpile():
    W, H = 60, 34
    img = new(W, H); d = ImageDraw.Draw(img)
    rng = random.Random(3)
    rows = [(26, 8), (17, 7), (9, 5)]
    for r, (y, n) in enumerate(rows):
        for k in range(n):
            x = 6 + r * 4 + k * 7
            d.ellipse([x, y - 1, x + 8, y + 7], fill=WOOD[2])
            d.ellipse([x + 1, y, x + 7, y + 6], fill=hexc('d8b07a'))
            d.ellipse([x + 3, y + 2, x + 5, y + 4], fill=hexc('b08a56'))
            d.point((x + 2, y + 1), fill=hexc('f0d4a0'))
    d.line([(46, 4), (56, 30)], fill=WOOD[3], width=2)  # axe stuck in the stump
    d.polygon([(44, 2), (50, 0), (50, 8), (45, 7)], fill=IRON[3])
    return save('woodpile', img)


def watchtower():
    W, H = 64, 140
    img = new(W, H); d = ImageDraw.Draw(img)
    for x0, x1 in ((10, 18), (54, 46)):
        d.line([(x0, 139), (x1 + (4 if x0 < 30 else -4), 46)], fill=WOOD[1], width=5)
        d.line([(x0 - 1, 139), (x1 + (3 if x0 < 30 else -5), 46)], fill=WOOD[3])
    for y in (70, 100, 126):
        plank(d, 12 + (139 - y) // 12, y, 52 - (139 - y) // 12, y + 3)
    d.line([(14, 126), (46, 70)], fill=WOOD[1], width=2)
    d.line([(50, 126), (18, 70)], fill=WOOD[1], width=2)
    # ladder
    d.line([(29, 139), (29, 50)], fill=WOOD[3]); d.line([(35, 139), (35, 50)], fill=WOOD[3])
    for y in range(54, 139, 7):
        d.line([(29, y), (35, y)], fill=WOOD[2])
    # cabin
    plank(d, 6, 44, 58, 50)
    for x in range(8, 58, 6):
        plank(d, x, 30, x + 4, 44, True)
    d.rectangle([20, 32, 44, 40], fill=hexc('1a120c'))
    roof = mask(W, H)
    ImageDraw.Draw(roof).polygon([(2, 31), (62, 31), (32, 2)], fill=255)
    paint_mask(img, roof, ramp('6e2418', '8e3220', 'b04628', 'd0603a', 'e88456'), light=(-1, -0.4))
    p = img.load()
    for y in range(6, 31, 4):
        for x in range(W):
            if roof.getpixel((x, y)):
                p[x, y] = hexc('6e2418')
    d.rectangle([31, 0, 32, 5], fill=WOOD[1])
    d.polygon([(33, 0), (42, 2), (33, 5)], fill=hexc('2f56b0'))  # Kingdom B pennant
    return save('watchtower', img)


def outpost():
    W, H = 84, 160
    img = new(W, H); d = ImageDraw.Draw(img)
    # stone tower
    body = mask(W, H)
    ImageDraw.Draw(body).rectangle([18, 40, 66, 158], fill=255)
    paint_mask(img, body, STONE, light=(-1, 0.1))
    rebrick(img, 10, 6, seed=8)
    d.rectangle([14, 34, 70, 42], fill=STONE[3])
    for x in range(14, 70, 9):
        d.rectangle([x, 26, x + 5, 34], fill=STONE[3])
        d.line([(x, 26), (x + 5, 26)], fill=STONE[4])
    d.line([(14, 42), (70, 42)], fill=STONE[0])
    for y in (70, 110):
        d.rectangle([40, y, 44, y + 12], fill=hexc('1a1410'))
    d.rectangle([34, 136, 50, 158], fill=hexc('3a2414'))
    d.ellipse([34, 128, 50, 144], fill=hexc('3a2414'))
    d.rectangle([36, 138, 48, 158], fill=WOOD[2])
    # wooden scaffold on the side
    for x in (4, 14):
        plank(d, x, 60, x + 3, 158, True)
    for y in (60, 95, 130):
        plank(d, 2, y, 20, y + 3)
    d.line([(5, 130), (16, 95)], fill=WOOD[1], width=2)
    d.line([(5, 95), (16, 60)], fill=WOOD[1], width=2)
    # brazier fire on top
    d.rectangle([36, 18, 48, 26], fill=IRON[1])
    d.polygon([(37, 18), (42, 4), (47, 18)], fill=hexc('ff8a1a'))
    d.polygon([(39, 18), (42, 9), (45, 18)], fill=hexc('ffd860'))
    # banner
    d.rectangle([58, 44, 66, 66], fill=hexc('2f56b0'))
    d.polygon([(58, 66), (66, 66), (62, 72)], fill=hexc('2f56b0'))
    d.ellipse([60, 50, 64, 54], fill=hexc('f2c84a'))
    return save('outpost', img)


def buildings():
    inn = make_props.house(128, 104, 'teal', 31, chimney=True, storeys=2, sign='mug')
    inn.save(OUT + 'x_inn.png')
    shed = make_props.house(84, 72, 'thatch', 32, chimney=False)
    shed.save(OUT + 'x_shed.png')
    bunk = make_props.house(128, 72, 'brown', 33, chimney=True)
    bunk.save(OUT + 'x_bunkhouse.png')


def build_all():
    for f in (headframe, mine_entrance, ore_cart, ore_pile, crates, barrel, weapon_rack,
              armor_stand, woodpile, watchtower, outpost, buildings):
        f()


if __name__ == '__main__':
    build_all()
    names = ['headframe', 'mine_entrance', 'ore_cart', 'ore_pile', 'crates', 'barrel', 'weapon_rack',
             'armor_stand', 'woodpile', 'watchtower', 'outpost', 'inn', 'shed', 'bunkhouse']
    prev = Image.new('RGBA', (1000, 360), hexc('5ea83a'))
    x, y = 4, 4
    for n in names:
        im = Image.open(OUT + 'x_%s.png' % n)
        if x + im.width > 1000:
            x, y = 4, y + 170
        prev.paste(im, (x, y + 165 - im.height), im)
        x += im.width + 10
    prev.save('/home/claude/preview_extras.png')
    print('ok')
