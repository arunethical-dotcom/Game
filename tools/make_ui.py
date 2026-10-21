"""Pixel-art interface pieces: dialogue panel, wooden frame, bronze buttons,
joystick, heart icon and health bar fill. Saved in art/ui_*.png."""
import math
from PIL import Image, ImageDraw
from pixel import hexc, new, mix

OUT = '../art/'
GOLD = [hexc('6e4a1c'), hexc('a0702c'), hexc('d0a050'), hexc('f2d080')]
WOOD = [hexc('2e1a0e'), hexc('4a2c16'), hexc('6a4222'), hexc('8a5a30')]


def panel():
    """9-slice dialogue panel, 32x32, margins 9: dark leather with a gold border and rivets."""
    S = 32
    img = new(S, S)
    p = img.load()
    for y in range(S):
        for x in range(S):
            e = min(x, y, S - 1 - x, S - 1 - y)
            if e == 0:
                c = hexc('140c08')
            elif e == 1:
                c = GOLD[1]
            elif e == 2:
                c = GOLD[3] if (x < S // 2 and y < S // 2) else GOLD[2]
            elif e == 3:
                c = GOLD[0]
            else:
                c = hexc('241812') if (x + y) % 7 else hexc('2a1c14')
                c = (c[0], c[1], c[2], 238)
            p[x, y] = c
    for (x, y) in ((4, 4), (S - 5, 4), (4, S - 5), (S - 5, S - 5)):
        p[x, y] = GOLD[3]; p[x + 1, y] = GOLD[2]; p[x, y + 1] = GOLD[2]; p[x + 1, y + 1] = GOLD[1]
    img.save(OUT + 'ui_panel.png')


def frame():
    """9-slice wooden frame with a thin gold inner edge, transparent middle. 32x32, margins 7."""
    S = 32
    img = new(S, S)
    p = img.load()
    for y in range(S):
        for x in range(S):
            e = min(x, y, S - 1 - x, S - 1 - y)
            if e == 0:
                c = hexc('140c08')
            elif e <= 4:
                grain = (x * 3 + y * 5) % 9 == 0
                c = WOOD[2] if e in (2, 3) else WOOD[1]
                if e == 1 and (x < S // 2 or y < S // 2):
                    c = WOOD[3]
                if grain:
                    c = WOOD[1]
            elif e == 5:
                c = GOLD[2]
            elif e == 6:
                c = hexc('140c08')
            else:
                c = (0, 0, 0, 0)
            p[x, y] = c
    for (x, y) in ((2, 2), (S - 4, 2), (2, S - 4), (S - 4, S - 4)):
        for dx in range(2):
            for dy in range(2):
                p[x + dx, y + dy] = GOLD[3] if dx == 0 and dy == 0 else GOLD[1]
    img.save(OUT + 'ui_frame.png')


def button(R):
    """Round bronze button, normal and pressed, side by side."""
    S = R * 2
    sheet = new(S * 2, S)
    for k in range(2):
        img = new(S, S)
        p = img.load()
        for y in range(S):
            for x in range(S):
                dx, dy = x - R + 0.5, y - R + 0.5
                d = math.hypot(dx, dy)
                if d > R - 0.5:
                    continue
                light = (-dx - dy) / (R * 1.4)  # lit from top-left
                if d > R - 2:
                    c = hexc('140c08')
                elif d > R - 6:
                    t = 0.5 + light * 0.5
                    c = GOLD[max(0, min(3, int(t * 4)))]
                elif d > R - 7:
                    c = GOLD[0]
                else:
                    t = 0.45 - light * 0.25 - (0.1 if k else 0)
                    base = [hexc('2a1a10'), hexc('3a2616'), hexc('4a321e')]
                    c = base[max(0, min(2, int(t * 3)))]
                    c = (c[0], c[1], c[2], 235)
                if k == 1 and d <= R - 2:
                    c = mix(c, (0, 0, 0, 255), 0.25)
                p[x, y] = c
        sheet.paste(img, (k * S, 0))
    sheet.save(OUT + 'ui_button_%d.png' % R)


def joystick():
    R = 48
    S = R * 2
    img = new(S + 40, S)
    p = img.load()
    for y in range(S):
        for x in range(S):
            d = math.hypot(x - R + 0.5, y - R + 0.5)
            if R - 3 < d <= R - 0.5:
                p[x, y] = GOLD[1] if (x + y) % 2 else GOLD[2]
            elif d <= R - 3:
                p[x, y] = (20, 12, 8, 90)
    # knob, 36x36 to the right
    r = 18
    for y in range(36):
        for x in range(36):
            dx, dy = x - r + 0.5, y - r + 0.5
            d = math.hypot(dx, dy)
            if d <= r - 0.5:
                light = (-dx - dy) / (r * 1.4)
                c = hexc('140c08') if d > r - 2 else GOLD[max(0, min(3, int((0.5 + light * 0.6) * 4)))]
                p[S + 2 + x, 30 + y - 30] = c
    img.save(OUT + 'ui_joystick.png')


def small():
    img = new(48, 16)
    d = ImageDraw.Draw(img)
    # heart 14x13 at (1,1)
    heart = ["..XXX...XXX..", ".XrrrX.XrrrX.", "XrwwrrXrrrrrX", "XrwrrrrrrrrrX", "XrrrrrrrrrrdX",
             ".XrrrrrrrrdX.", "..XrrrrrrdX..", "...XrrrrdX...", "....XrrdX....", ".....XdX.....", "......X......"]
    cols = {'X': hexc('140c08'), 'r': hexc('d8383a'), 'w': hexc('ffb0a8'), 'd': hexc('8a1a1c')}
    for y, row in enumerate(heart):
        for x, ch in enumerate(row):
            if ch in cols:
                img.putpixel((1 + x, 2 + y), cols[ch])
    # health fill 8x8 at (16,0): red with highlight
    for y in range(8):
        for x in range(8):
            c = hexc('ff7a6a') if y == 1 else (hexc('c8282a') if y < 5 else hexc('9a1a1c'))
            if y == 0: c = hexc('ff9a8a')
            img.putpixel((16 + x, y), c)
    # empty bar 8x8 at (24,0)
    for y in range(8):
        for x in range(8):
            img.putpixel((24 + x, y), hexc('2a1612') if y else hexc('1a0c08'))
    img.save(OUT + 'ui_small.png')


if __name__ == '__main__':
    panel(); frame(); button(32); button(24); joystick(); small()
    prev = Image.new('RGBA', (300, 120), hexc('5c9a3c'))
    x = 4
    for n in ['ui_panel', 'ui_frame', 'ui_button_32', 'ui_button_24', 'ui_joystick', 'ui_small']:
        im = Image.open(OUT + n + '.png')
        prev.paste(im, (x, 4), im)
        x += im.width + 4
        if x > 200:
            x = 4
    prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save('/home/claude/preview_ui.png')
    print('ok')
