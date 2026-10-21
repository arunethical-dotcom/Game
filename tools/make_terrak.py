"""Terrak, the ancient beast. Side view facing right.
Frames: 0-3 walk, 4-5 roar (wind-up before the lunge), 6 lunge.
Two sizes: the pack leader and the young ones."""
import math, random
from PIL import Image, ImageDraw
from pixel import hexc, new, mix, mask

OUT = '../art/'
def ramp(*hs): return [hexc(h) for h in hs]
GREEN = ramp('121a0b', '1c2912', '29391a', '384c22', '4a632c', '5f7b38', '7a9648')
BELLY = ramp('2e1e12', '45301c', '5e4428', '7a5a34', '967244')
BONE  = ramp('5e543c', '867a58', 'ad9f78', 'd2c59c', 'efe6c4')
DARK  = hexc('10140a')

def bezier(p0, p1, p2, t):
    a = (1 - t) ** 2; b = 2 * (1 - t) * t; c = t * t
    return (a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1])

def tube(dr, p0, p1, p2, r0, r1, steps=24):
    for i in range(steps + 1):
        t = i / steps
        x, y = bezier(p0, p1, p2, t)
        r = r0 + (r1 - r0) * t
        dr.ellipse([x - r, y - r, x + r, y + r], fill=255)

def frame(f, s, crystal):
    W, H = int(112 * s), int(88 * s)
    OY = 12
    S = lambda *v: tuple((c + (OY if i % 2 else 0)) * s for i, c in enumerate(v))
    walk = f if f < 4 else 0
    phase = [0, 1, 0, -1][walk]
    bob = -1 if walk in (1, 3) else 0
    roar = f in (4, 5)
    lunge = f == 6
    dx = 6 if lunge else 0
    hy = -4 if roar else (2 if lunge else 0)

    parts = {k: mask(W, H) for k in ('far', 'tail', 'body', 'head', 'jaw', 'near', 'horn', 'spike', 'claw')}
    D = {k: ImageDraw.Draw(m) for k, m in parts.items()}

    def leg(dr, hip, foot, thick):
        hx, hy_ = hip; fx, fy = foot
        kx, ky = (hx + fx) / 2 - 2 * s, (hy_ + fy) / 2 + 1 * s
        dr.ellipse([hx - thick * 1.25, hy_ - thick * 1.1, hx + thick * 1.25, hy_ + thick * 1.3], fill=255)
        tube(dr, (hx, hy_), (kx, ky), (fx, fy - thick * 0.4), thick * 0.75, thick * 0.5, 14)
        dr.ellipse([fx - thick * 0.7, fy - thick * 0.7, fx + thick * 1.1, fy + thick * 0.2], fill=255)

    ground = (70 + OY) * s
    swing = 6 * s
    # far legs (darker, behind)
    back_f = (-1 if not lunge else -2) * phase
    leg(D['far'], (S(40, 46 + bob)), (40 * s - swing * phase - (8 * s if lunge else 0), ground), 5.5 * s)
    leg(D['far'], (S(66 + dx, 46 + bob)), (66 * s + dx * s + swing * phase + (8 * s if lunge else 0), ground), 5 * s)
    # tail: thick at the body, curling up at the end
    sway = phase * 2
    tube(D['tail'], S(36, 40 + bob), S(14, 48 + sway), S(6, 26 + sway), 9 * s, 2.2 * s)
    tube(D['tail'], S(6, 26 + sway), S(2, 16), S(10, 10), 2.2 * s, 1.0 * s, 10)
    # body: hips + barrel chest
    D['body'].ellipse(list(S(26, 26 + bob, 62, 54 + bob)), fill=255)
    D['body'].ellipse(list(S(48 + dx, 20 + bob, 80 + dx, 56 + bob)), fill=255)
    # neck and head
    hx, hyy = 84 + dx, 24 + hy + bob
    tube(D['head'], S(68 + dx, 34 + bob), S(78 + dx, 28 + bob + hy / 2), S(hx, hyy), 10 * s, 7 * s, 12)
    D['head'].ellipse(list(S(hx - 10, hyy - 9, hx + 10, hyy + 8)), fill=255)
    D['head'].polygon([S(hx + 2, hyy - 7), S(hx + 21, hyy - 2), S(hx + 21, hyy + 4), S(hx + 2, hyy + 6)], fill=255)
    # lower jaw
    open_ = 9 if roar else (6 if lunge else 1)
    D['jaw'].polygon([S(hx - 2, hyy + 3), S(hx + 16, hyy + 4 + open_), S(hx + 14, hyy + 8 + open_), S(hx - 3, hyy + 8)], fill=255)
    # near legs
    leg(D['near'], S(36, 44 + bob), (36 * s + swing * phase - (10 * s if lunge else 0), ground + s), 7 * s)
    leg(D['near'], S(62 + dx, 46 + bob), (62 * s + dx * s - swing * phase + (10 * s if lunge else 0), ground + s), 6.5 * s)
    # horns: sweep up and back, tips curl forward
    for k, off in ((0, 0), (1, -3)):
        tube(D['horn'], S(hx - 5 + off, hyy - 6), S(hx - 16 + off, hyy - 11), S(hx - 13 + off, hyy - 19), 3.0 * s, 2.0 * s, 16)
        tube(D['horn'], S(hx - 13 + off, hyy - 19), S(hx - 10 + off, hyy - 26), S(hx - 3 + off, hyy - 21), 2.0 * s, 0.7 * s, 14)
    # spikes along the back and tail
    spine = [(44, 25), (52, 21), (60, 18), (70, 21), (76, 22), (34, 30), (26, 36), (18, 42)]
    for i, (x, y) in enumerate(spine):
        x += dx if x > 48 else 0
        y += bob
        h = (8 if 2 <= i <= 3 else 6) * s
        yy = (y + OY) * s
        D['spike'].polygon([(x * s - 3 * s, yy + 2 * s), (x * s + 3 * s, yy + 2 * s), (x * s - 1 * s, yy - h)], fill=255)
    for x, y in ((hx + 3, hyy - 9), (hx - 4, hyy - 10)):
        D['spike'].polygon([S(x - 2, y + 3), S(x + 2, y + 3), S(x, y - 2)], fill=255)

    img = new(W, H)
    rng = random.Random(f * 7 + int(s * 10))
    order = [('far', GREEN, -2), ('tail', GREEN, 0), ('body', GREEN, 0), ('head', GREEN, 0),
             ('jaw', GREEN, -1), ('near', GREEN, 0), ('spike', BONE, 0), ('horn', BONE, 0)]
    p = img.load()
    for name, rp, bias in order:
        m = parts[name].load()
        bb = parts[name].getbbox()
        if not bb: continue
        x0, y0, x1, y1 = bb
        for y in range(y0, y1):
            for x in range(x0, x1):
                if not m[x, y]: continue
                v = (y - y0) / max(1, y1 - y0)
                u = (x - x0) / max(1, x1 - x0)
                t = 0.95 - v * 0.75 + (u - 0.5) * 0.15
                # edge darkening at the bottom of each part
                if y + 1 < H and not m[x, y + 1]: t -= 0.25
                if y - 1 >= 0 and not m[x, y - 1]: t += 0.2
                n = len(rp)
                idx = int(t * n) + bias
                # scale pattern
                if rp is GREEN:
                    cs = max(3, int(2.6 * s))
                    row = y // cs
                    sx_ = x + (row % 2) * (cs // 2)
                    lx, ly = sx_ % cs, y % cs
                    cell_r = ((sx_ // cs) * 7 + row * 13) % 5
                    if ly == 0 and 0 < lx < cs - 1 and cell_r != 0:
                        idx += 1
                    elif ly == cs - 1 and 0 < lx < cs - 1:
                        idx -= 1
                if rp is BONE and (x + y * 2) % 6 == 0:
                    idx -= 1
                if rp is GREEN and rng.random() < 0.06:
                    idx += 1
                p[x, y] = rp[max(0, min(n - 1, idx))]
    # belly plates on the underside of the body and neck
    bm = parts['body'].load(); hm = parts['head'].load()
    for y in range(H):
        for x in range(W):
            cx, cy = (64 + dx) * s, (38 + bob + OY) * s
            inside_body = bm[x, y] and ((x - cx) / (15 * s)) ** 2 + ((y - cy - 9 * s) / (8 * s)) ** 2 < 1.0 and y > cy + 4 * s
            inside_neck = hm[x, y] and y > (31 + bob + OY) * s and x < (hx - 4) * s and x > (66 + dx) * s
            if (inside_body or inside_neck) and not parts['near'].getpixel((x, y)):
                row = int(y / max(2, 2.5 * s)) % 2
                t = 3 - row - (1 if y > (50 + bob + OY) * s else 0)
                p[x, y] = BELLY[max(0, min(4, t))]
    nm = parts['near'].load()
    for y in range(1, H):
        for x in range(W):
            if nm[x, y] and not nm[x, y - 1]:
                p[x, y] = GREEN[6]
                if y + 1 < H and nm[x, y + 1]:
                    p[x, y + 1] = GREEN[5]
    # mouth interior, teeth, eye, nostril
    d = ImageDraw.Draw(img)
    if open_ > 2:
        d.polygon([S(hx + 1, hyy + 4), S(hx + 17, hyy + 4), S(hx + 15, hyy + 3 + open_), S(hx, hyy + 7)], fill=hexc('6a1414'))
        d.polygon([S(hx + 4, hyy + 5), S(hx + 14, hyy + 5), S(hx + 12, hyy + 2 + open_), S(hx + 4, hyy + 6)], fill=hexc('a82a2a'))
        for i in range(5):
            tx = (hx + 4 + i * 3) * s
            d.polygon([(tx, (hyy + 4 + OY) * s), (tx + 2 * s, (hyy + 4 + OY) * s), (tx + s, (hyy + 6.5 + OY) * s)], fill=BONE[4])
            ty = (hyy + 3 + open_ + OY) * s
            d.polygon([(tx, ty + s), (tx + 2 * s, ty + s), (tx + s, ty - 1.5 * s)], fill=BONE[3])
    else:
        for i in range(4):
            tx = (hx + 6 + i * 3) * s
            d.polygon([(tx, (hyy + 4 + OY) * s), (tx + 1.5 * s, (hyy + 4 + OY) * s), (tx + s, (hyy + 6 + OY) * s)], fill=BONE[4])
    ex, ey = hx + 2, hyy - 3
    d.ellipse(list(S(ex - 3.2, ey - 2.4, ex + 3.4, ey + 2.4)), fill=hexc('5a1a08'))
    d.ellipse(list(S(ex - 2.4, ey - 1.8, ex + 2.6, ey + 1.8)), fill=hexc('ff8a1a'))
    d.ellipse(list(S(ex - 1.2, ey - 1.0, ex + 1.6, ey + 1.0)), fill=hexc('ffd040'))
    d.line([S(ex - 0.2, ey - 1.6), S(ex - 0.2, ey + 1.6)], fill=hexc('1a0a04'), width=max(1, int(s)))
    d.point(S(ex + 1.2, ey - 1.0), fill=hexc('ffffff'))
    d.line([S(ex - 3, ey - 3), S(ex + 3, ey - 2)], fill=GREEN[1], width=max(1, int(s)))
    d.point(S(hx + 17, hyy - 1), fill=hexc('10140a'))
    d.line([S(hx - 4, hyy - 6), S(hx + 6, hyy - 5)], fill=GREEN[5], width=max(1, int(s)))
    for i in range(3):
        d.point(S(hx + 8 + i * 3, hyy + 0), fill=GREEN[1])
    # claws
    for fx in (36 * s + swing * phase - (10 * s if lunge else 0), 62 * s + dx * s - swing * phase + (10 * s if lunge else 0)):
        for c in range(3):
            cx = fx + (4 + c * 2.5) * s
            d.polygon([(cx, ground + s), (cx + 2 * s, ground + s), (cx + 3 * s, ground + 3 * s)], fill=BONE[3])
    if crystal:
        # moonsteel crystals grown into its back
        for (x, y, h) in ((50, 22, 10), (56, 19, 13), (62, 20, 9)):
            x += 0; y += bob
            d.polygon([S(x - 2.5, y + 2), S(x + 2.5, y + 2), S(x + 0.5, y - h)], fill=hexc('9ec8ff'))
            d.line([S(x + 0.5, y - h), S(x + 0.5, y + 1)], fill=hexc('e8f6ff'))
            d.line([S(x - 2.2, y + 1), S(x - 0.2, y - h + 3)], fill=hexc('6a9ae0'))
    if roar and f == 5:
        for i in range(5):  # breath puffs
            bx, by = hx + 22 + i * 3, hyy + 2 + (i % 2) * 3
            d.point(S(bx, by), fill=hexc('cfe8f4'))
            d.point(S(bx + 1, by), fill=hexc('9fd0e8'))
    # outline
    out = img.copy()
    src = img.load(); o = out.load()
    for y in range(H):
        for x in range(W):
            if src[x, y][3] == 0:
                for ddx, ddy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx, ny = x + ddx, y + ddy
                    if 0 <= nx < W and 0 <= ny < H and src[nx, ny][3] > 0:
                        o[x, y] = DARK; break
    return out

def sheet(s, crystal, name):
    frames = [frame(i, s, crystal) for i in range(7)]
    W, H = frames[0].size
    sh = new(W * 7, H)
    for i, fr in enumerate(frames):
        sh.paste(fr, (i * W, 0))
    sh.save(OUT + name)
    return sh

if __name__ == '__main__':
    a = sheet(1.6, True, 'terrak_leader.png')
    b = sheet(1.1, False, 'terrak_young.png')
    prev = Image.new('RGBA', (a.width, a.height + b.height + 10), hexc('3f8a34'))
    prev.paste(a, (0, 0), a)
    prev.paste(b, (0, a.height + 10), b)
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save('/home/claude/preview_terrak.png')
    big = a.crop((0, 0, a.width // 7, a.height))
    big.resize((big.width * 3, big.height * 3), Image.NEAREST).save('/home/claude/preview_terrak_big.png')
    print(a.size, b.size)
