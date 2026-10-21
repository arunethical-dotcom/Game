"""Turn the AI-made Kael sheets (source_art/kael/*_src.png, magenta background)
into clean game sprite sheets in art/kael_*.png.

Steps for every sheet:
1. Remove the magenta background (and the pink fringe around the character).
2. Split the image into an even grid of frames (rows = directions).
3. Find the feet line of each row and the character height, so every sheet ends up
   the same size in game even though the AI drew them at different scales.
4. Shrink each frame to game size with a "most common colour" filter, which keeps
   pixel-art edges crisp instead of blurring them.
5. Paste every frame into a fixed FW x FH cell, centred, feet on the same line.

Run:  python3 import_kael.py
"""
import numpy as np
from PIL import Image

SRC = '../source_art/kael/'
OUT = '../art/'
FW, FH = 96, 96          # frame size in the game sheets
FEET_Y = 88              # where the feet sit inside each frame
TARGET_H = 64            # standing height of Kael in game pixels
PALETTE = 48

# name: (source file, rows, cols, (row, col) of a standing frame used to measure height)
SHEETS = {
    'idle':   ('kael_idle_src.png', 3, 4, (0, 0)),
    'walk':   ('kael_walk_src.png', 3, 6, (0, 0)),
    'attack': ('kael_attack_src.png', 3, 6, (0, 0)),
    'roll':   ('kael_roll_hurt_src.png', 4, 6, (0, 5)),
}
# rows whose figures are wider than their grid cell (lying down): split them by the
# empty gaps between figures instead of by an even grid
FREE_ROWS = {'roll': {3: 7}}   # row 3 holds 7 poses: hurt x2, fall, lie x2, get up, stand


def foreground(rgb):
    r, g, b = rgb[..., 0].astype(int), rgb[..., 1].astype(int), rgb[..., 2].astype(int)
    magenta = (r > 150) & (b > 150) & (g < 140) & (np.abs(r - b) < 80)
    pinkish = ((r + b) / 2 - g > 70) & (b > 110)
    return ~(magenta | pinkish)


def clean_mask(m):
    """Drop isolated specks of noise."""
    m2 = m.copy()
    n = (np.roll(m, 1, 0).astype(int) + np.roll(m, -1, 0) + np.roll(m, 1, 1) + np.roll(m, -1, 1))
    m2[(n <= 1)] = False
    return m2


def frame_box(mask, top, left, h, w):
    sub = mask[top:top + h, left:left + w]
    ys, xs = np.nonzero(sub)
    if len(ys) == 0:
        return None
    return ys.min(), ys.max(), xs.min(), xs.max()


def mode_downscale(idx, mask, scale, out_w, out_h, ox, oy):
    """idx: palette index image, mask: fg. Returns (out index, out mask) of size out_h x out_w.
    Source pixel (x, y) maps to target (ox + x*scale, oy + y*scale)."""
    H, W = idx.shape
    out_i = np.zeros((out_h, out_w), dtype=np.int32)
    out_m = np.zeros((out_h, out_w), dtype=bool)
    inv = 1.0 / scale
    for ty in range(out_h):
        sy0 = int(round((ty - oy) * inv)); sy1 = int(round((ty + 1 - oy) * inv))
        if sy1 <= 0 or sy0 >= H:
            continue
        sy0 = max(sy0, 0); sy1 = min(max(sy1, sy0 + 1), H)
        for tx in range(out_w):
            sx0 = int(round((tx - ox) * inv)); sx1 = int(round((tx + 1 - ox) * inv))
            if sx1 <= 0 or sx0 >= W:
                continue
            sx0 = max(sx0, 0); sx1 = min(max(sx1, sx0 + 1), W)
            bm = mask[sy0:sy1, sx0:sx1]
            if bm.mean() < 0.45:
                continue
            vals = idx[sy0:sy1, sx0:sx1][bm]
            out_i[ty, tx] = np.bincount(vals).argmax()
            out_m[ty, tx] = True
    return out_i, out_m


def process(name, file, rows, cols, ref):
    img = Image.open(SRC + file).convert('RGB')
    rgb = np.array(img)
    mask = clean_mask(foreground(rgb))
    H, W = mask.shape
    ch, cw = H / rows, W / cols

    # palette from the character pixels only
    fg_pixels = rgb[mask].reshape(-1, 1, 3)
    pal_img = Image.fromarray(fg_pixels.astype(np.uint8)).quantize(colors=PALETTE, method=Image.Quantize.MEDIANCUT)
    palette = np.array(pal_img.getpalette()[:PALETTE * 3]).reshape(-1, 3)
    full_q = img.quantize(palette=pal_img, dither=Image.Dither.NONE)
    idx = np.array(full_q).astype(np.int32)

    # feet line per row = median of the lowest character pixel in each frame
    feet = []
    for r in range(rows):
        bottoms = []
        for c in range(cols):
            b = frame_box(mask, int(r * ch), int(c * cw), int(ch), int(cw))
            if b:
                bottoms.append(b[1])
        feet.append(int(np.median(bottoms)))

    # scale so the reference standing frame is TARGET_H tall
    rr, rc = ref
    b = frame_box(mask, int(rr * ch), int(rc * cw), int(ch), int(cw))
    stand_h = feet[rr] - b[0]
    scale = TARGET_H / stand_h
    print('%-7s source %dx%d  grid %dx%d  standing height %d px  scale %.3f' % (name, W, H, rows, cols, stand_h, scale))

    sheet = Image.new('RGBA', (FW * max(cols, max(FREE_ROWS.get(name, {0: 0}).values())), FH * rows), (0, 0, 0, 0))
    for r in range(rows):
        if r in FREE_ROWS.get(name, []):
            free_row(sheet, idx, mask, palette, r, ch, W, feet[r], scale, FREE_ROWS[name][r])
            continue
        for c in range(cols):
            top, left = int(r * ch), int(c * cw)
            sub_i = idx[top:top + int(ch), left:left + int(cw)]
            sub_m = mask[top:top + int(ch), left:left + int(cw)]
            # the cell centre lands on the frame centre, the feet line on FEET_Y
            cx = cw / 2.0
            ox = FW / 2.0 - cx * scale
            oy = FEET_Y - feet[r] * scale
            oi, om = mode_downscale(sub_i, sub_m, scale, FW, FH, ox, oy)
            om = drop_strays(om, cw * scale)
            frame = np.zeros((FH, FW, 4), dtype=np.uint8)
            frame[om, :3] = palette[oi[om]]
            frame[om, 3] = 255
            sheet.paste(Image.fromarray(frame, 'RGBA'), (c * FW, r * FH))
    return sheet


def components(m):
    """4-connected components of a boolean image -> list of (ys, xs) arrays."""
    H, W = m.shape
    seen = np.zeros_like(m, dtype=bool)
    out = []
    for y0 in range(H):
        for x0 in range(W):
            if m[y0, x0] and not seen[y0, x0]:
                stack = [(y0, x0)]; seen[y0, x0] = True; ys = []; xs = []
                while stack:
                    y, x = stack.pop(); ys.append(y); xs.append(x)
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < H and 0 <= nx < W and m[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True; stack.append((ny, nx))
                out.append((np.array(ys), np.array(xs)))
    return out


def drop_strays(om, cell_px):
    """Remove bits that belong to the neighbouring frame: small pieces sitting
    right at the left or right edge of this frame's grid cell."""
    lo = FW / 2.0 - cell_px / 2.0
    hi = FW / 2.0 + cell_px / 2.0
    for ys, xs in components(om):
        near_edge = xs.max() < lo + 16 or xs.min() > hi - 16
        if near_edge and len(xs) < 400:
            om[ys, xs] = False
    return om


def free_row(sheet, idx, mask, palette, r, ch, W, feet_r, scale, cols):
    top = int(r * ch)
    sub_i = idx[top:top + int(ch), :]
    sub_m = mask[top:top + int(ch), :]
    strip_w = int(W * scale) + 2
    oy = FEET_Y - feet_r * scale
    oi, om = mode_downscale(sub_i, sub_m, scale, strip_w, FH, 0.0, oy)
    used = om.any(axis=0)
    segs = []
    x = 0
    while x < strip_w:
        if used[x]:
            x0 = x
            while x < strip_w and used[x]:
                x += 1
            segs.append([x0, x])
        x += 1
    # figures that touch: split the widest piece at its thinnest column
    counts = om.sum(axis=0)
    while len(segs) < cols:
        i = int(np.argmax([b - a for a, b in segs]))
        a, b = segs[i]
        lo, hi = a + (b - a) // 4, b - (b - a) // 4
        cut = lo + int(np.argmin(counts[lo:hi]))
        segs[i:i + 1] = [[a, cut], [cut, b]]
    # merge the closest neighbours until there is one segment per frame
    while len(segs) > cols:
        gaps = [segs[i + 1][0] - segs[i][1] for i in range(len(segs) - 1)]
        i = int(np.argmin(gaps))
        segs[i] = [segs[i][0], segs[i + 1][1]]
        del segs[i + 1]
    for c, (x0, x1) in enumerate(segs[:cols]):
        frame = np.zeros((FH, FW, 4), dtype=np.uint8)
        off = int(round(FW / 2.0 - (x0 + x1) / 2.0))
        for y in range(FH):
            for xx in range(x0, x1):
                tx = xx + off
                if om[y, xx] and 0 <= tx < FW:
                    frame[y, tx, :3] = palette[oi[y, xx]]
                    frame[y, tx, 3] = 255
        sheet.paste(Image.fromarray(frame, 'RGBA'), (c * FW, r * FH))


def split_roll(sheet):
    """The roll sheet's 4th row is hurt (2 frames) + knocked down and up again (5 frames)."""
    roll = sheet.crop((0, 0, FW * 6, FH * 3))
    hurt = sheet.crop((0, FH * 3, FW * 7, FH * 4))
    return roll, hurt


if __name__ == '__main__':
    for name, (file, rows, cols, ref) in SHEETS.items():
        s = process(name, file, rows, cols, ref)
        if name == 'roll':
            roll, hurt = split_roll(s)
            roll.save(OUT + 'kael_roll.png')
            hurt.save(OUT + 'kael_hurt.png')
        else:
            s.save(OUT + 'kael_%s.png' % name)
    print('done')
