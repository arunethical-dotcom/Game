"""People, drawn natively at 40x60 per frame (twice the detail of the old 20x30 sprites).
Sheet layout per character: rows = facing down, up, side (right); 4 walk frames each.
Also builds items.png (sword, hammer, moonsteel) at double resolution."""
import random
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, outline, finish

OUT = '../art/'
OUTLINE = hexc('24181a')
CW, CH = 40, 60

PEOPLE = {
    'kael':      dict(hair='4a2c1a', skin='f2c9a2', shirt='3a6cc0', pants='5a3e2a', shoes='3a2418', scarf='c8483a'),
    'haldor':    dict(hair='cfcfcb', skin='e6b48c', shirt='8a8478', pants='4a3a2c', shoes='2e2218', beard='f4f2ec', apron='7a4a24', bald=True, brows='d8d8d4'),
    'guard':     dict(hair='5a3a22', skin='e8bc94', shirt='2f56b0', pants='3a3e48', shoes='2a2a30', helmet='c0c6d0', tabard='f2c84a', spear=True),
    'worker':    dict(hair='4a3a2a', skin='d4a47e', shirt='8a7a62', pants='6a5a46', shoes='4a3a2a', chains=True, sack=True, ragged=True),
    'miner':     dict(hair='3a2a1e', skin='d8a882', shirt='a8643a', pants='4a4038', shoes='2e2620', cap='e2b23a', pick=True),
    'villager0': dict(hair='d0702e', skin='f4cea8', shirt='dc4a5e', pants='f2e2c0', shoes='6a4426', dress=True, long_hair=True),
    'villager1': dict(hair='2a1a12', skin='c48c64', shirt='46a85a', pants='5a4630', shoes='3a2418'),
    'villager2': dict(hair='f2d27a', skin='f6d4b2', shirt='9a5ad0', pants='f6eedc', shoes='6a4426', dress=True, long_hair=True),
    'villager3': dict(hair='8a8a8a', skin='e0b08a', shirt='e8a23a', pants='4a5a7a', shoes='3a2418'),
}


def H(h):
    return hexc(h)


def sh(h, t):
    """Shade a hex colour: t>0 darker, t<0 lighter."""
    c = hexc(h)
    return mix(c, (0, 0, 0, 255), t) if t > 0 else mix(c, (255, 255, 255, 255), -t)


class Painter:
    def __init__(self, img, flip=False):
        self.d = ImageDraw.Draw(img)
        self.p = img.load()
        self.w, self.h = img.size

    def rect(self, x0, y0, x1, y1, col):
        if x1 < x0 or y1 < y0:
            return
        self.d.rectangle([x0, y0, x1, y1], fill=col)

    def px(self, x, y, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[x, y] = col

    def block(self, x0, y0, x1, y1, base, light_left=True):
        """A shaded block: lit top-left edge, shadowed right side and bottom."""
        self.rect(x0, y0, x1, y1, H(base))
        if light_left:
            self.rect(x0, y0, x0, y1, sh(base, -0.18))
        self.rect(x0, y0, x1, y0, sh(base, -0.12))
        self.rect(x1 - 1, y0 + 1, x1, y1, sh(base, 0.22))
        self.rect(x0, y1, x1, y1, sh(base, 0.3))


def draw_person(spec, direction, frame):
    img = new(CW, CH)
    P = Painter(img)
    step = [0, 1, 0, -1][frame]
    bob = 1 if frame in (1, 3) else 0
    skin, shirt, pants, shoes = spec['skin'], spec['shirt'], spec['pants'], spec['shoes']
    side = direction == 'side'

    # ---------------- legs and boots
    if side:
        for k, (ox, col) in enumerate(((-3 * step, sh(pants, 0.22)), (3 * step, H(pants)))):
            x = 17 + ox
            P.rect(x, 40, x + 5, 50, col)
            P.rect(x + 4, 41, x + 5, 50, sh(pants, 0.32))
            P.rect(x - 1, 51, x + 7, 55, sh(shoes, 0.1) if k == 0 else H(shoes))
            P.rect(x - 1, 51, x + 7, 51, sh(shoes, -0.25))
            P.px(x + 7, 54, sh(shoes, -0.35))
    else:
        lift_l = 2 if frame == 1 else 0
        lift_r = 2 if frame == 3 else 0
        P.rect(13, 40, 18, 51 - lift_l, H(pants))
        P.rect(13, 40, 13, 51 - lift_l, sh(pants, -0.15))
        P.rect(17, 41, 18, 51 - lift_l, sh(pants, 0.25))
        P.rect(21, 40, 26, 51 - lift_r, H(pants))
        P.rect(25, 41, 26, 51 - lift_r, sh(pants, 0.3))
        P.rect(21, 40, 21, 51 - lift_r, sh(pants, 0.1))
        for x0, lift in ((12, lift_l), (21, lift_r)):
            P.rect(x0, 52 - lift, x0 + 6, 56 - lift, H(shoes))
            P.rect(x0, 52 - lift, x0 + 6, 52 - lift, sh(shoes, -0.3))
            P.rect(x0 + 1, 53 - lift, x0 + 2, 53 - lift, sh(shoes, -0.45))
    if spec.get('chains'):
        P.rect(13, 50, 26, 50, H('6a6e76'))
        for x in range(13, 27, 3):
            P.px(x, 50, H('c0c6d0'))
            P.px(x + 1, 49, H('8a8e96'))

    # ---------------- torso
    top = 23 - bob
    if side:
        x0, x1 = 15, 25
    else:
        x0, x1 = 11, 28
    if spec.get('dress'):
        # skirt flares out
        P.d.polygon([(x0, 33 - bob), (x1, 33 - bob), (x1 + 2, 44), (x0 - 2, 44)], fill=H(shirt))
        P.rect(x0 - 2, 43, x1 + 2, 44, sh(shirt, 0.3))
        for x in range(x0, x1 + 1, 4):
            P.rect(x, 36, x, 42, sh(shirt, 0.15))
    P.block(x0, top, x1, 39 - bob, shirt)
    # fabric folds
    for i in range(3):
        P.px(x0 + 3 + i, top + 8 + i, sh(shirt, 0.15))
        P.px(x1 - 4 - i, top + 9 + i, sh(shirt, 0.18))
    if spec.get('ragged'):
        for x in range(x0, x1 + 1, 3):
            P.px(x, 39 - bob, (0, 0, 0, 0))
            P.px(x + 1, 38 - bob, sh(shirt, 0.35))
        P.rect(x0 + 4, top + 5, x0 + 6, top + 6, sh(shirt, 0.3))  # patch
    if direction == 'down':
        # collar
        P.d.polygon([(17, top), (22, top), (20, top + 4)], fill=sh(skin, 0.1))
        P.rect(16, top, 16, top + 2, sh(shirt, -0.3))
        P.rect(23, top, 23, top + 2, sh(shirt, -0.3))
    if spec.get('tabard') and direction != 'up':
        tx0, tx1 = (15, 24) if not side else (18, 23)
        P.block(tx0, top + 1, tx1, 41, spec['tabard'])
        cx = (tx0 + tx1) // 2
        P.rect(cx - 2, top + 6, cx + 2, top + 10, H('2f56b0'))
        P.rect(cx - 1, top + 5, cx + 1, top + 11, H('2f56b0'))
        P.px(cx, top + 8, H('ffe680'))
    if spec.get('apron') and direction != 'up':
        ax0, ax1 = (13, 26) if not side else (19, 25)
        P.block(ax0, top + 4, ax1, 44, spec['apron'])
        P.rect(ax0 + 2, top, ax0 + 3, top + 4, sh(spec['apron'], 0.2))
        P.rect(ax1 - 3, top, ax1 - 2, top + 4, sh(spec['apron'], 0.2))
        P.rect(ax0 + 3, top + 12, ax1 - 3, top + 15, sh(spec['apron'], 0.18))  # pocket
        P.rect(ax0 + 5, top + 11, ax0 + 5, top + 14, H('9aa0a8'))  # tongs in pocket
    if spec.get('scarf') and direction != 'up':
        P.rect(x0 + 2, top, x1 - 2, top + 2, H(spec['scarf']))
        P.rect(x0 + 2, top + 2, x1 - 2, top + 2, sh(spec['scarf'], 0.3))
        if direction == 'down':
            P.rect(x1 - 6, top + 3, x1 - 4, top + 8, H(spec['scarf']))
    if direction == 'up' and spec.get('scarf'):
        P.rect(x0 + 2, top, x1 - 2, top + 2, H(spec['scarf']))
    # belt
    if not spec.get('dress'):
        P.rect(x0, 35 - bob, x1, 36 - bob, sh(shirt, 0.55))
        if direction == 'down':
            P.rect(18, 35 - bob, 21, 36 - bob, H('e2b23a'))
            P.px(19, 35 - bob, H('fff0a0'))

    # ---------------- arms
    swing = [0, 2, 0, -2][frame]
    if side:
        ax = 19 - swing
        P.rect(ax, top + 2, ax + 3, top + 11, sh(shirt, 0.12))
        P.rect(ax + 3, top + 2, ax + 3, top + 11, sh(shirt, 0.3))
        P.rect(ax, top + 12, ax + 3, top + 14, H(skin))
        P.rect(ax + 3, top + 13, ax + 3, top + 14, sh(skin, 0.2))
    else:
        for ax, s, d in ((8, max(0, swing), -0.15), (29, max(0, -swing), 0.25)):
            P.rect(ax, top + 1 + s, ax + 2, top + 11 + s, sh(shirt, 0.08 if d < 0 else 0.22))
            P.rect(ax, top + 1 + s, ax, top + 11 + s, sh(shirt, d))
            P.rect(ax, top + 12 + s, ax + 2, top + 14 + s, H(skin))
            P.px(ax + 2, top + 14 + s, sh(skin, 0.25))

    # ---------------- head
    ht = 5 - bob
    hx0, hx1 = (12, 27) if not side else (14, 28)
    P.rect(hx0 + 1, ht + 2, hx1 - 1, ht + 17, H(skin))
    P.rect(hx0, ht + 4, hx1, ht + 15, H(skin))
    P.rect(hx1 - 1, ht + 4, hx1, ht + 15, sh(skin, 0.15))
    P.rect(hx0 + 2, ht + 17, hx1 - 2, ht + 17, sh(skin, 0.2))
    P.rect(17, ht + 18, 22, top - 1, sh(skin, 0.2))  # neck
    hair = spec['hair']
    if spec.get('bald'):
        P.rect(hx0 + 2, ht + 2, hx1 - 3, ht + 3, sh(skin, -0.15))
        P.px(hx0 + 4, ht + 3, sh(skin, -0.35))
        for x in (hx0, hx0 + 1, hx1 - 1, hx1):
            P.rect(x, ht + 6, x, ht + 12, H(hair))
        P.rect(hx0, ht + 6, hx0, ht + 12, sh(hair, -0.2))
    else:
        if direction == 'up':
            P.rect(hx0, ht + 1, hx1, ht + 15, H(hair))
            P.rect(hx0 + 1, ht, hx1 - 1, ht, H(hair))
            for x in range(hx0 + 2, hx1 - 1, 3):
                P.rect(x, ht + 3, x, ht + 13, sh(hair, 0.2))
            P.rect(hx0 + 3, ht + 2, hx0 + 6, ht + 2, sh(hair, -0.3))
            P.rect(hx0, ht + 15, hx1, ht + 15, sh(hair, 0.25))
        elif side:
            P.rect(hx0, ht, hx1 - 1, ht + 5, H(hair))
            P.rect(hx0, ht + 5, hx0 + 6, ht + 13, H(hair))
            P.rect(hx1 - 4, ht + 5, hx1 - 2, ht + 6, H(hair))
            P.rect(hx0 + 2, ht + 1, hx0 + 8, ht + 1, sh(hair, -0.3))
            P.rect(hx0 + 2, ht + 6, hx0 + 2, ht + 12, sh(hair, 0.2))
        else:
            P.rect(hx0, ht + 1, hx1, ht + 6, H(hair))
            P.rect(hx0 + 1, ht, hx1 - 1, ht, H(hair))
            # bangs, jagged
            for i, x in enumerate(range(hx0, hx1 + 1)):
                P.rect(x, ht + 7, x, ht + 7 + (i * 7) % 3, H(hair))
            P.rect(hx0, ht + 6, hx0 + 1, ht + 12, H(hair))
            P.rect(hx1 - 1, ht + 6, hx1, ht + 12, H(hair))
            P.rect(hx0 + 3, ht + 2, hx0 + 7, ht + 2, sh(hair, -0.3))
            P.px(hx0 + 8, ht + 3, sh(hair, -0.3))
            for x in range(hx0 + 4, hx1 - 2, 4):
                P.rect(x, ht + 3, x, ht + 6, sh(hair, 0.2))
        if spec.get('long_hair') and direction != 'side':
            P.rect(hx0 - 1, ht + 6, hx0, ht + 22, H(hair))
            P.rect(hx1, ht + 6, hx1 + 1, ht + 22, H(hair))
            if direction == 'up':
                P.rect(hx0, ht + 15, hx1, ht + 21, H(hair))
                P.rect(hx0, ht + 21, hx1, ht + 21, sh(hair, 0.25))
        elif spec.get('long_hair') and side:
            P.rect(hx0, ht + 13, hx0 + 5, ht + 21, H(hair))
    if spec.get('helmet'):
        hm = spec['helmet']
        P.rect(hx0 - 1, ht - 1, hx1 + 1, ht + 6, H(hm))
        P.rect(hx0, ht - 2, hx1, ht - 2, H(hm))
        P.rect(hx0 + 1, ht - 1, hx1 - 4, ht, sh(hm, -0.35))
        P.rect(hx0 - 1, ht + 6, hx1 + 1, ht + 7, sh(hm, 0.3))
        P.rect(hx1 - 1, ht, hx1 + 1, ht + 6, sh(hm, 0.2))
        if direction == 'down':
            P.rect(19, ht + 6, 20, ht + 11, H(hm))  # nose guard
        P.rect(19, ht - 6, 20, ht - 2, H('c83a3a'))  # red plume
        P.rect(18, ht - 5, 21, ht - 3, H('c83a3a'))
        P.px(19, ht - 6, H('ff7a6a'))
    if spec.get('cap'):
        cp = spec['cap']
        P.rect(hx0 - 1, ht, hx1 + 1, ht + 5, H(cp))
        P.rect(hx0, ht - 1, hx1, ht - 1, H(cp))
        P.rect(hx0 - 1, ht + 5, hx1 + 1, ht + 6, sh(cp, 0.35))
        P.rect(hx0 + 1, ht, hx0 + 5, ht, sh(cp, -0.35))
        if direction != 'up':
            lx = 19 if direction == 'down' else hx1 - 3
            P.rect(lx - 1, ht + 1, lx + 1, ht + 3, H('fff4b0'))  # head lamp

    # ---------------- face
    eye = H('2a1a14')
    if direction == 'down':
        for ex in (15, 23):
            P.rect(ex, ht + 10, ex + 1, ht + 12, eye)
            P.px(ex, ht + 10, H('ffffff'))
        if spec.get('brows') or not spec.get('helmet'):
            br = H(spec.get('brows', spec['hair']))
            P.rect(14, ht + 8, 17, ht + 8, sh(spec.get('brows', spec['hair']), 0.2))
            P.rect(22, ht + 8, 25, ht + 8, sh(spec.get('brows', spec['hair']), 0.2))
        P.px(19, ht + 13, sh(skin, 0.18))
        P.px(20, ht + 13, sh(skin, 0.12))
        P.rect(18, ht + 15, 21, ht + 15, sh(skin, 0.3))
        P.rect(13, ht + 13, 14, ht + 13, mix(H(skin), H('ff7a7a'), 0.35))
        P.rect(25, ht + 13, 26, ht + 13, mix(H(skin), H('ff7a7a'), 0.35))
    elif side:
        P.rect(24, ht + 10, 25, ht + 12, eye)
        P.px(24, ht + 10, H('ffffff'))
        P.rect(29, ht + 12, 29, ht + 13, H(skin))
        P.px(29, ht + 13, sh(skin, 0.2))
        P.rect(25, ht + 15, 27, ht + 15, sh(skin, 0.3))
        P.rect(22, ht + 8, 25, ht + 8, sh(spec.get('brows', spec['hair']), 0.2))
        P.px(19, ht + 10, sh(skin, 0.2))  # ear
        P.px(19, ht + 11, sh(skin, 0.25))
    if spec.get('beard') and direction != 'up':
        b = spec['beard']
        if direction == 'down':
            P.d.polygon([(12, ht + 12), (27, ht + 12), (26, ht + 20), (23, ht + 26), (19, ht + 28), (16, ht + 26), (13, ht + 20)], fill=H(b))
            P.rect(16, ht + 13, 23, ht + 14, sh(b, 0.08))  # mustache
            P.rect(18, ht + 15, 21, ht + 15, sh(skin, 0.35))
            for x in range(14, 26, 3):
                P.rect(x, ht + 17, x, ht + 23, sh(b, 0.14))
            P.rect(17, ht + 26, 22, ht + 27, sh(b, 0.18))
        else:
            P.d.polygon([(21, ht + 12), (28, ht + 12), (28, ht + 19), (25, ht + 25), (21, ht + 22)], fill=H(b))
            for y in range(ht + 15, ht + 23, 3):
                P.rect(23, y, 26, y, sh(b, 0.14))

    # ---------------- carried things
    if spec.get('sack') and direction != 'down':
        sx = 10 if direction == 'up' else 9
        P.d.ellipse([sx, top - 4, sx + 13, top + 10], fill=H('a8946c'))
        P.rect(sx + 3, top - 3, sx + 8, top - 2, H('c8b48a'))
        P.rect(sx + 9, top + 2, sx + 12, top + 8, sh('a8946c', 0.2))
        P.px(sx + 4, top + 3, H('7a7e86'))
        P.px(sx + 7, top + 5, H('8a8e96'))
    if spec.get('spear') and direction != 'up':
        sx = 32 if direction == 'down' else 30
        P.rect(sx, 6, sx + 1, 56, H('7a4e2c'))
        P.rect(sx + 1, 6, sx + 1, 56, H('5a3820'))
        P.d.polygon([(sx - 2, 7), (sx + 3, 7), (sx + 1, 0), (sx, 0)], fill=H('dfe4ea'))
        P.rect(sx, 1, sx, 6, H('ffffff'))
        P.rect(sx - 1, 7, sx + 2, 8, H('e2b23a'))
    if spec.get('pick') and direction != 'up':
        px0 = 31 if direction == 'down' else 28
        P.rect(px0, 20, px0 + 1, 40, H('8a5a30'))
        P.d.polygon([(px0 - 5, 21), (px0 + 7, 19), (px0 + 7, 21), (px0 - 5, 23)], fill=H('8a8e96'))
        P.px(px0 - 5, 21, H('d8dde3'))
    return outline(img, OUTLINE)


def characters():
    for name, spec in PEOPLE.items():
        sheet = new(CW * 4, CH * 3)
        for r, direction in enumerate(['down', 'up', 'side']):
            for f in range(4):
                sheet.paste(draw_person(spec, direction, f), (f * CW, r * CH))
        sheet.save(OUT + 'char_%s.png' % name)


def items():
    """Low-res item art, finished to double resolution (96x48)."""
    sheet = new(48, 24)
    d = ImageDraw.Draw(sheet)
    d.rectangle([2, 1, 4, 15], fill=hexc('d8dde3'))
    d.line([(2, 1), (2, 15)], fill=hexc('ffffff'))
    d.line([(4, 1), (4, 15)], fill=hexc('9aa0a8'))
    d.point((3, 0), fill=hexc('ffffff'))
    d.rectangle([0, 16, 6, 17], fill=hexc('e2b23a'))
    d.rectangle([2, 18, 4, 21], fill=hexc('6a4426'))
    d.rectangle([2, 22, 4, 22], fill=hexc('e2b23a'))
    d.rectangle([13, 6, 14, 21], fill=hexc('8a5a30'))
    d.rectangle([10, 1, 17, 6], fill=hexc('6a6e76'))
    d.line([(10, 1), (17, 1)], fill=hexc('aab0b8'))
    pts = [(28, 2), (33, 8), (31, 16), (25, 16), (22, 8)]
    d.polygon(pts, fill=hexc('9ec8ff'))
    d.polygon([(28, 2), (33, 8), (28, 9)], fill=hexc('e8f4ff'))
    d.polygon([(22, 8), (28, 9), (25, 16)], fill=hexc('6a9ae0'))
    d.line([(28, 9), (31, 16)], fill=hexc('c8e2ff'))
    sheet = outline(sheet, OUTLINE)
    hi = finish(sheet, OUTLINE, seed=4)
    hi.save(OUT + 'items.png')
    return hi


if __name__ == '__main__':
    characters()
    items()
    names = list(PEOPLE)
    prev = Image.new('RGBA', (CW * 4 * 3, CH * 3 * 3), hexc('5ea83a'))
    for i, name in enumerate(names):
        s = Image.open(OUT + 'char_%s.png' % name)
        prev.paste(s, ((i % 3) * CW * 4, (i // 3) * CH * 3), s)
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save('/home/claude/preview_chars.png')
    print('ok')
