"""Import the castle6 asset sheets (source_art/castle6/) into crisp game sprites (art/castle6/).

  source_art/castle6/<sheet>.png
    -> art/castle6/<group>/<name>.png   one sprite per object, pivot = bottom centre
       art/castle6/manifest.json        size, pivot, source sheet + box, resample factor
       art/castle6/contact_<group>.png  labelled contact sheets for checking the cuts

Scale
  Every castle6 sprite is drawn at DRAW_SCALE = 3 in game (1 sprite px = 3 world px =
  1.2 px on the 1728 castle map), so the whole castle shares one pixel size.
  The AI drew each sheet at its own scale, so each sheet gets a resample factor F
  (sprite px per sheet px) that brings it to the castle map's scale:
    - architecture (the five big runs, buildings, water/cliffs): F = 0.63. A run tower is
      ~115 sheet px wide -> 72 sprite px -> 87 map px, like the map's towers (80-90).
      The cathedral (274 px) and domed hall (177 px) land within ~10 % of the map too.
    - wall_kit: F = 1.0 (its towers are ~62 px wide -> 74 map px; no upscaling blur).
    - props: F = 0.30 (a statue on its plinth ~50 sprite px = 150 world px, ~2.3x Kael).
    - trees: F = 0.27 (the biggest pine ~38 sprite px -> 46 map px, like the map's pines).

Cleaning (per object)
  1. remove the magenta and its pink fringe (palace sheet: its own alpha channel)
  2. cut objects by connected components; the five run sheets are one object each
  3. fill the background with the nearest object colour (so no magenta bleeds in), then
     resample with Lanczos and a light unsharp mask
  4. hard alpha (>= 50 % coverage), drop pink leftovers on the outline
  5. snap to one palette per sheet (no dithering), so pieces of a sheet match exactly

Run:  cd tools && python3 import_castle6.py
"""
import json
import os
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

import import_castle as ic

SRC = '../source_art/castle6/'
OUT = '../art/castle6/'
DRAW_SCALE = 3
WORLD_PER_MAP = 2.5          # world px per 1728-map px

# sheet -> (group, resample factor, whole sheet is one object, palette size)
SHEETS = {
    'palace_with_wings':       ('runs', 0.63, True, 64),
    'gatehouse_causeway':      ('runs', 0.63, True, 64),
    'wall_curve_south':        ('runs', 0.63, True, 64),
    'wall_diagonal_west':      ('runs', 0.63, True, 64),
    'wall_east_bridges':       ('runs', 0.63, True, 64),
    'wall_kit':                ('kit', 1.0, False, 64),
    'buildings_gardens':       ('buildings', 0.63, False, 64),
    'trees_cliffs':            ('trees', 0.27, False, 48),
    'water_cliffs_waterfalls': ('water', 0.63, False, 48),
    'props_banners_statues':   ('props', 0.30, False, 64),
}
SHORT = {'wall_kit': 'kit', 'buildings_gardens': 'bld', 'trees_cliffs': 'tree',
         'water_cliffs_waterfalls': 'water', 'props_banners_statues': 'prop'}
MIN_AREA = 90               # foreground px: smaller blobs are sparkles / noise
DILATE = 2                  # px gap bridged when grouping parts of one object
ERODE = 4                   # px eroded to split objects that touch on the sheet
MIN_CORE = 400              # px: an eroded core this big counts as an object of its own
# props are drawn apart already, and splitting would cut flags from their poles
NO_SPLIT = {'props_banners_statues'}
# objects joined along a wide seam (erosion cannot part them): cut by hand along a polyline in
# sheet px. 'x': the polyline gives the cut x for each y (pixels left of it are one piece);
# 'y': it gives the cut y for each x (pixels above it are one piece).
# Each entry: sheet -> [(blob box on the sheet, mode, polyline)]
CUTS = {
    'water_cliffs_waterfalls': [
        ((495, 517, 797, 771), 'x', [(600, 517), (600, 629), (593, 633), (655, 703), (655, 772)]),  # two waterfalls
        ((1026, 776, 1247, 1000), 'y', [(1026, 895), (1100, 904), (1140, 878), (1150, 866), (1247, 866)]),  # two rock groups
    ],
    'trees_cliffs': [
        ((274, 512, 525, 783), 'y', [(274, 507), (394, 507), (397, 582), (437, 664), (439, 812), (525, 812)]),
        ((727, 514, 1100, 795), 'x', [(952, 514), (952, 634), (924, 649), (924, 795)]),
        ((16, 591, 287, 850), 'y', [(16, 891), (111, 891), (114, 751), (151, 725), (287, 725)]),
    ],
}


def load(sheet):
    """Sheet colours (int array) and a foreground mask."""
    im = Image.open(SRC + sheet + '.png')
    if im.mode == 'RGBA':
        a = np.array(im)
        rgb = a[..., :3].astype(int)
        fg = a[..., 3] >= 128
        return rgb, ndimage.binary_opening(fg, iterations=1)
    rgb = np.array(im.convert('RGB')).astype(int)
    bg = ic.background(rgb)
    rgb, bg = ic.despill(rgb, bg)
    return rgb, ndimage.binary_opening(~bg, iterations=1)


def objects(fg, whole, erode=ERODE, cuts=()):
    """Connected components -> list of (x0, y0, x1, y1, mask) in reading order."""
    lab, n = ndimage.label(ndimage.binary_dilation(fg, iterations=DILATE))
    lab = np.where(fg, lab, 0)
    if not whole and erode:
        # objects drawn touching (tiles corner to corner, two cliffs side by side): erode to
        # cut the thin bridges, label the cores, then hand every pixel back to its nearest
        # core inside the same blob (so poles, crosses and flags stay with their object)
        core = ndimage.binary_erosion(fg, iterations=erode)
        cl, cn = ndimage.label(core)
        big = ndimage.sum(np.ones_like(cl), cl, index=np.arange(1, cn + 1)) >= MIN_CORE
        cl = np.where(np.isin(cl, np.nonzero(big)[0] + 1), cl, 0)
        idx = ndimage.distance_transform_edt(cl == 0, return_distances=False, return_indices=True)
        near = cl[idx[0], idx[1]]
        # a blob keeps its own label if it has no core (small things) or only one core
        out = lab.copy()
        for i, s in enumerate(ndimage.find_objects(lab)):
            if s is None:
                continue
            blob = lab[s] == i + 1
            cores = np.unique(cl[s][blob & (cl[s] > 0)])
            if len(cores) > 1:
                sub = near[s]
                out[s] = np.where(blob, n + sub, out[s])
        lab = out
        ids = np.unique(lab[lab > 0])
        remap = np.zeros(lab.max() + 1, int)
        remap[ids] = np.arange(1, len(ids) + 1)
        lab = remap[lab]
        n = len(ids)
    for box, mode, line in cuts:
        lab, n = cut_blob(lab, n, box, mode, line)
    areas = ndimage.sum(np.ones_like(lab), lab, index=np.arange(1, n + 1))
    keep = [i + 1 for i in range(n) if areas[i] >= MIN_AREA]
    if whole:
        m = np.isin(lab, keep)
        ys, xs = np.nonzero(m)
        return [(xs.min(), ys.min(), xs.max() + 1, ys.max() + 1, m[ys.min():ys.max() + 1, xs.min():xs.max() + 1])]
    out = []
    sl = ndimage.find_objects(lab)
    for i in keep:
        s = sl[i - 1]
        out.append((s[1].start, s[0].start, s[1].stop, s[0].stop, lab[s] == i))
    # reading order: group into rows by top edge, then left to right
    out.sort(key=lambda o: (o[1], o[0]))
    rows, cur, top = [], [], None
    for o in out:
        if top is None or o[1] - top > 40:
            if cur:
                rows.append(cur)
            cur, top = [], o[1]
        cur.append(o)
    rows.append(cur)
    return [o for r in rows for o in sorted(r, key=lambda o: o[0])]


def cut_blob(lab, n, box, mode, line):
    """Split the blob whose bounding box is `box` along a hand-drawn polyline."""
    x0, y0, x1, y1 = box
    sl = ndimage.find_objects(lab)
    hit = [i + 1 for i, s in enumerate(sl) if s is not None and
           max(abs(s[1].start - x0), abs(s[0].start - y0), abs(s[1].stop - x1), abs(s[0].stop - y1)) <= 3]
    if len(hit) != 1:
        raise SystemExit('cut: no unique blob at %s (found %d)' % (box, len(hit)))
    i = hit[0]
    ys, xs = np.mgrid[y0:y1, x0:x1]
    px, py = np.array(line, float).T
    if mode == 'x':
        side = xs >= np.interp(ys, py, px)
    else:
        side = ys >= np.interp(xs, px, py)
    sub = lab[y0:y1, x0:x1]
    blob = sub == i
    part = blob & side
    # specks cut off on the wrong side of the line go back to the piece they touch most
    for p in (part, blob & ~side):
        cl, cn = ndimage.label(p)
        if cn > 1:
            sz = ndimage.sum(p, cl, index=np.arange(1, cn + 1))
            for j in np.nonzero(sz < 0.05 * sz.max())[0]:
                part = part ^ (cl == j + 1)
    sub[part] = n + 1
    return lab, n + 1


def resample(rgb, x0, y0, x1, y1, m, f):
    """Cut one object and resample it by f. Returns (colours HxWx3 uint8, hard alpha)."""
    pad = 2
    h, w = m.shape
    c = np.zeros((h + 2 * pad, w + 2 * pad, 3))
    a = np.zeros((h + 2 * pad, w + 2 * pad), bool)
    c[pad:pad + h, pad:pad + w] = rgb[y0:y1, x0:x1]
    a[pad:pad + h, pad:pad + w] = m
    # background takes the nearest object colour, so resampling never blends in magenta
    idx = ndimage.distance_transform_edt(~a, return_distances=False, return_indices=True)
    c = c[idx[0], idx[1]]
    tw, th = max(1, round(c.shape[1] * f)), max(1, round(c.shape[0] * f))
    src = Image.fromarray(np.clip(c, 0, 255).astype(np.uint8), 'RGB')
    if f == 1.0:
        col = np.array(src)
        al = a
    else:
        col = np.array(src.resize((tw, th), Image.Resampling.LANCZOS)
                      .filter(ImageFilter.UnsharpMask(1, 60, 1)))
        al = np.array(Image.fromarray(a.astype(np.uint8) * 255).resize((tw, th), Image.Resampling.BOX)) >= 128
    # pink left on the outline (magenta mixed into an edge pixel) becomes transparent
    edge = al & ndimage.binary_dilation(~al)
    r, g, b = (col[..., i].astype(int) for i in range(3))
    pink = (np.minimum(r, b) - g > 55) & (np.abs(r - b) < 90)
    al = al & ~(edge & pink)
    return col, al


def sheet_palette(pieces, n):
    """One palette for a whole sheet, from all of its (resampled) object pixels."""
    px = np.concatenate([c[a] for c, a in pieces if a.any()])
    strip = Image.fromarray(px.reshape(1, -1, 3).astype(np.uint8), 'RGB')
    return strip.quantize(colors=n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


def finish(col, al, pal):
    q = np.array(Image.fromarray(col, 'RGB').quantize(palette=pal, dither=Image.Dither.NONE).convert('RGB'))
    o = np.dstack([q, np.where(al, 255, 0)]).astype(np.uint8)
    im = Image.fromarray(o, 'RGBA')
    bb = im.getbbox()
    return im.crop(bb) if bb else im


def build():
    if os.path.isdir(OUT):
        # keep Godot's .import files out of the way of stale sprites: start clean
        for g in {v[0] for v in SHEETS.values()}:
            shutil.rmtree(OUT + g, ignore_errors=True)
    man = {}
    for sheet, (group, f, whole, ncol) in SHEETS.items():
        rgb, fg = load(sheet)
        objs = objects(fg, whole, 0 if sheet in NO_SPLIT else ERODE, CUTS.get(sheet, ()))
        pieces = [resample(rgb, *o, f) for o in objs]
        pal = sheet_palette(pieces, ncol)
        os.makedirs(OUT + group, exist_ok=True)
        for i, (o, (col, al)) in enumerate(zip(objs, pieces)):
            name = sheet if whole else '%s_%03d' % (SHORT[sheet], i)
            im = finish(col, al, pal)
            im.save(OUT + group + '/' + name + '.png')
            man[group + '/' + name] = {
                'size': [im.width, im.height], 'pivot': [im.width // 2, im.height],
                'sheet': sheet, 'box': [int(v) for v in o[:4]], 'f': f, 'draw_scale': DRAW_SCALE}
        print('%-24s %-10s F=%.2f  %3d objects' % (sheet, group, f, len(objs)))
    json.dump(man, open(OUT + 'manifest.json', 'w'), indent=1, sort_keys=True)
    return man


def font(size):
    for p in ('/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf',
              '/usr/share/fonts/liberation-sans-fonts/LiberationSans-Regular.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def contact(man, group, zoom, width=2400):
    """Labelled contact sheet: every sprite of a group at `zoom` x sprite px on a checker,
    with Kael drawn at the same world scale in the top-left for reference."""
    fnt = font(13)
    keys = sorted(k for k in man if k.startswith(group + '/'))
    kael = Image.open('../art/kael_idle.png').convert('RGBA').crop((0, 0, 96, 96))
    kb = kael.getbbox()
    kael = kael.crop(kb)
    ks = zoom / DRAW_SCALE                       # Kael is drawn at 1 world px per px
    kael = kael.resize((max(1, round(kael.width * ks)), max(1, round(kael.height * ks))), Image.Resampling.NEAREST)
    tiles = [('KAEL (scale ref)', kael)]
    for k in keys:
        im = Image.open(OUT + k + '.png')
        tiles.append((k.split('/')[1], im.resize((im.width * zoom, im.height * zoom), Image.Resampling.NEAREST)))
    gap, lab_h = 10, 18
    x, y, rowh, pos = gap, gap + 30, 0, []
    for name, im in tiles:
        w = max(im.width, int(fnt.getlength(name)) + 4)
        if x + w > width - gap and x > gap:
            x, y, rowh = gap, y + rowh + lab_h + gap, 0
        pos.append((x, y, w, name, im))
        x += w + gap
        rowh = max(rowh, im.height)
    H = y + rowh + lab_h + gap
    W = width if len(tiles) > 1 and (H > 200 or x > width / 2) else x + gap
    # mid-grey checker, so both dark outlines and light stone read
    chk = (((np.arange(H)[:, None] // 16) + (np.arange(W)[None, :] // 16)) % 2).astype(np.uint8)
    base = np.where(chk[..., None] == 1, [118, 128, 112, 255], [104, 114, 98, 255]).astype(np.uint8)
    sheet = Image.fromarray(base, 'RGBA')
    d = ImageDraw.Draw(sheet)
    d.text((gap, 6), 'castle6 / %s  (%d sprites, shown at %dx sprite px; in game they are drawn at %dx)'
           % (group, len(tiles) - 1, zoom, DRAW_SCALE), font=font(16), fill=(255, 255, 255))
    for x, y, w, name, im in pos:
        ox = x + (w - im.width) // 2
        sheet.paste(im, (ox, y + rowh_of(pos, y) - im.height), im)
        d.text((x, y + rowh_of(pos, y) + 2), name, font=fnt, fill=(255, 240, 120) if name.startswith('KAEL') else (255, 255, 255))
    out = OUT + 'contact_%s.png' % group
    sheet.convert('RGB').save(out)
    return out


def rowh_of(pos, y):
    return max(im.height for (_, yy, _, _, im) in pos if yy == y)


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    man = build()
    print(len(man), 'sprites')
    for g, z in (('runs', 1), ('kit', 1), ('buildings', 1), ('water', 1), ('trees', 3), ('props', 2)):
        print(contact(man, g, z))
