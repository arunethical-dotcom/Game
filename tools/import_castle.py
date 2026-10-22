"""Import an AI-drawn castle asset sheet into game-ready sprites.

  source_art/castle/sheet1.png  (objects on a pure magenta background)
    -> art/castle/tiles/<name>.png      floor tiles, exactly 32x32
       art/castle/rugs/<name>.png       rugs and runners (flat, drawn on the floor)
       art/castle/furniture/<name>.png  beds, tables, chairs, chests...
       art/castle/decor/<name>.png      banners, statues, plants, lights...
       art/castle/walls/<name>.png      wall pieces, doors, arches, stairs
       art/castle/kitchen/<name>.png    hearths, barrels, pots...
       art/castle/tiles.png             tile atlas (4 variants per row, see TILE_ROWS)
       art/castle/manifest.json         size, pivot and collision footprint per sprite

What it does to every object:
  1. removes the magenta background, including the pink fringe AI images leave on edges
  2. cuts each object out on its own (objects are found by connected regions)
  3. scales by one fixed factor, so every object shares the same pixel size as Kael
     (AI "pixels" are about 2 screen pixels; tiles are scaled to exactly 32x32)
  4. hardens the alpha (no half-transparent pixels) and trims to the object
  5. pivot = bottom centre (the object's feet), which is how the game places sprites

To add a new sheet: put it in source_art/castle/, add a NAMES table for it, run
  python3 import_castle.py
"""
import json
import os

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = '../source_art/castle/'
OUT = '../art/castle/'
SCALE = 2          # sheet pixels per game pixel for objects
TILE = 32

# group/name -> a point inside that object on sheet1.png (x, y in sheet pixels).
# Naming by position keeps names stable even if the cut-out order changes.
NAMES_1 = {
    'decor/banner_lion_blue': (733, 394),
    'decor/banner_fleur_red': (807, 387),
    'decor/banner_fleur_wide': (891, 406),
    'decor/curtain_blue': (995, 411),
    'decor/banner_lion_red': (1092, 418),
    'decor/throne_dais': (111, 468),
    'decor/torch_pole': (476, 487),
    'decor/banner_fleur_framed': (527, 486),
    'decor/pillar_white': (587, 487),
    'decor/candelabra_a': (1168, 448),
    'decor/portrait_lady': (1260, 439),
    'decor/candelabra_b': (1325, 442),
    'decor/weapon_rack': (1397, 443),
    'decor/shield_stand': (1481, 453),
    'decor/banner_lion_blue_b': (261, 494),
    'decor/banner_fleur_blue': (341, 493),
    'decor/banner_fleur_red_b': (421, 493),
    'decor/pillar_banner': (652, 491),
    'decor/pillar_banner_tall': (749, 560),
    'decor/halberd_stand': (814, 508),
    'decor/portrait_king': (872, 514),
    'decor/fire_bowl': (1026, 517),
    'decor/painting_castle': (939, 512),
    'decor/armour_a': (1097, 553),
    'decor/armour_b': (1161, 553),
    'decor/statue_queen': (1230, 554),
    'decor/statue_saint': (1304, 553),
    'decor/plant_urn': (1369, 553),
    'decor/plant_pot': (1436, 557),
    'decor/vase_blue': (1502, 555),
    'decor/pillar_stub': (810, 602),
    'decor/pedestal': (870, 602),
    'decor/flower_planter': (957, 592),
    'decor/pedestal_small': (1041, 592),
    'decor/coat_stand': (665, 955),
    'furniture/bed_simple': (54, 290),
    'furniture/bed_blue': (178, 292),
    'furniture/bed_canopy': (338, 305),
    'furniture/bench_red': (480, 252),
    'furniture/desk': (617, 263),
    'furniture/nightstand': (724, 266),
    'furniture/armchair': (788, 264),
    'furniture/dining_table': (929, 268),
    'furniture/bookshelf_a': (1087, 280),
    'furniture/bookshelf_b': (1169, 276),
    'furniture/chair_blue': (1239, 248),
    'furniture/chair_red': (1290, 248),
    'furniture/chair_red_b': (1338, 247),
    'furniture/chair_blue_b': (1391, 247),
    'furniture/dresser': (1470, 264),
    'furniture/sofa_blue': (474, 321),
    'furniture/chair_blue_small': (477, 376),
    'furniture/chair_blue_side': (533, 334),
    'furniture/royal_chair': (613, 365),
    'furniture/jewel_box': (1172, 375),
    'furniture/chest_wood': (1261, 336),
    'furniture/chest_gold': (1365, 341),
    'furniture/chest_blue': (1474, 363),
    'furniture/cabinet_bottles': (391, 812),
    'furniture/alchemy_table': (812, 807),
    'furniture/kitchen_table': (102, 916),
    'furniture/food_shelf': (268, 940),
    'furniture/side_table': (488, 886),
    'furniture/screen': (586, 935),
    'furniture/stool_box': (809, 882),
    'furniture/low_table': (59, 980),
    'furniture/stand_bottles': (146, 977),
    'furniture/washstand': (720, 956),
    'furniture/bath': (811, 959),
    'furniture/stool': (887, 958),
    'furniture/pail': (932, 957),
    'furniture/high_chair': (984, 947),
    'furniture/footstool': (541, 989),
    'kitchen/fireplace': (73, 814),
    'kitchen/oven': (182, 818),
    'kitchen/stove': (282, 816),
    'kitchen/barrels_stack': (487, 812),
    'kitchen/pans_rack': (586, 813),
    'kitchen/washtub_stand': (665, 807),
    'kitchen/tub': (726, 813),
    'kitchen/jug': (362, 890),
    'kitchen/barrel_small': (409, 892),
    'kitchen/bucket': (677, 876),
    'kitchen/bucket_b': (723, 876),
    'kitchen/bread_basket': (901, 886),
    'kitchen/sack_basket': (377, 962),
    'kitchen/barrel_sack': (464, 962),
    'rugs/runner_blue': (829, 102),
    'rugs/runner_red': (906, 101),
    'rugs/rug_red_medallion': (991, 102),
    'rugs/rug_blue_diamond': (1094, 102),
    'rugs/runner_blue_plain': (1181, 101),
    'rugs/rug_red_small': (1258, 45),
    'rugs/runner_blue_thin': (1316, 102),
    'rugs/rug_blue_small': (1388, 45),
    'rugs/rug_red': (1476, 70),
    'rugs/rug_red_tall': (1258, 140),
    'rugs/rug_red_corner': (1406, 139),
    'rugs/rug_red_mini': (1492, 165),
    'tiles/limestone_a': (60, 56),
    'tiles/limestone_b': (157, 56),
    'tiles/limestone_inlay': (256, 56),
    'tiles/limestone_frame_b': (351, 55),
    'tiles/marble_diamond': (447, 55),
    'tiles/marble_medallion': (543, 56),
    'tiles/blue_gold': (638, 55),
    'tiles/wood_planks': (733, 56),
    'tiles/limestone_c': (60, 150),
    'tiles/bluestone': (157, 150),
    'tiles/limestone_frame': (256, 149),
    'tiles/darkstone': (351, 149),
    'tiles/limestone_cross': (447, 149),
    'tiles/marble_cross': (543, 149),
    'tiles/wood_chevron': (638, 149),
    'tiles/wood_parquet': (735, 150),
    'walls/stairs_grand': (100, 658),
    'walls/stairs_banners': (260, 655),
    'walls/stairs_worn': (427, 660),
    'walls/wall_column': (564, 665),
    'walls/wall_ledge': (664, 649),
    'walls/wall_broken': (773, 706),
    'walls/door_arch': (887, 702),
    'walls/door_arch_open': (990, 704),
    'walls/door_royal': (1095, 686),
    'walls/archway': (1268, 688),
    'walls/pier_banner': (1420, 687),
    'walls/pier_banner_b': (1490, 697),
    'walls/door_small': (903, 810),
    'walls/wall_door_narrow': (1098, 830),
    'walls/wall_grate': (1173, 823),
    'walls/wall_door': (1265, 824),
    'walls/wall_breach': (1373, 828),
    'walls/wall_cell': (1002, 835),
    'walls/wall_rubble': (1482, 825),
    'walls/wall_hatch': (1061, 950),
    'walls/wall_slit': (1157, 947),
    'walls/wall_bookshelf': (1260, 944),
    'walls/wall_window_bars': (1371, 949),
    'walls/wall_ring': (1483, 942),
}


# tile atlas rows (4 variants each) used by scripts/tiles.gd
# ":x" / ":y" / ":xy" = the same tile mirrored, so a row of one tile still varies
TILE_ROWS = [
    ('limestone', ['limestone_a', 'limestone_b', 'limestone_c', 'limestone_a:xy']),
    ('limestone_deco', ['limestone_cross', 'limestone_inlay', 'limestone_frame', 'limestone_frame_b']),
    ('marble_deco', ['marble_diamond', 'marble_medallion', 'marble_cross', 'blue_gold']),
    ('wood', ['wood_planks', 'wood_planks:x', 'wood_planks:y', 'wood_planks:xy']),
    ('wood_chevron', ['wood_chevron', 'wood_chevron:x', 'wood_chevron', 'wood_chevron:x']),
    ('darkstone', ['darkstone', 'darkstone:x', 'darkstone:y', 'darkstone:xy']),
    ('bluestone', ['bluestone', 'bluestone:x', 'bluestone:y', 'bluestone:xy']),
]


def background(rgb):
    """True where a pixel is magenta background, or pink fringe from it."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lo = np.minimum(r, b)
    core = (np.abs(r - b) < 70) & (lo > 110) & (g < lo * 0.45)
    # fringe: pixels next to the background that are still mostly magenta
    near = ndimage.binary_dilation(core, iterations=2)
    fringe = near & (np.abs(r - b) < 80) & (lo > 70) & (g < lo * 0.62)
    return core | fringe


def despill(rgb, bg):
    """Near the background, take the magenta tint back out of edge pixels (AI images blend
    the background colour into the outline); strongly tinted ones become background."""
    near = ndimage.binary_dilation(bg, iterations=3) & ~bg
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    spill = np.minimum(r, b) - g
    hard = near & (spill > 70) & (np.abs(r - b) < 90)
    soft = near & (spill > 25) & ~hard
    out = rgb.copy()
    k = np.where(soft, spill - 25, 0)
    out[..., 0] -= k
    out[..., 2] -= k
    return out, bg | hard


def segment(path):
    img = Image.open(path).convert('RGB')
    rgb = np.array(img).astype(int)
    bg = background(rgb)
    rgb, bg = despill(rgb, bg)
    fg = ndimage.binary_opening(~bg, iterations=1)
    lab, _ = ndimage.label(ndimage.binary_dilation(fg, iterations=3))
    boxes = []
    for i, s in enumerate(ndimage.find_objects(lab)):
        h = s[0].stop - s[0].start
        w = s[1].stop - s[1].start
        if h * w < 150:
            continue
        boxes.append((s[1].start, s[0].start, s[1].stop, s[0].stop, i + 1))
    boxes.sort(key=lambda b: (b[1] // 60, b[0]))
    return rgb, fg, lab, boxes


def cut(rgb, fg, lab, box):
    x0, y0, x1, y1, li = box
    m = fg[y0:y1, x0:x1] & (lab[y0:y1, x0:x1] == li)
    c = rgb[y0:y1, x0:x1].astype(float)
    return c, m.astype(float)


def shrink(c, a, f):
    """Scale down by an integer factor without inventing colours: each output pixel takes
    the real source pixel closest to its block's median, so highlights, shadows and
    outlines keep their original values (averaging would blur them into muddy in-betweens)."""
    h, w = a.shape
    H, W = (h + f - 1) // f, (w + f - 1) // f
    pad_c = np.zeros((H * f, W * f, 3))
    pad_a = np.zeros((H * f, W * f))
    pad_c[:h, :w] = c
    pad_a[:h, :w] = a
    blocks_c = pad_c.reshape(H, f, W, f, 3).transpose(0, 2, 1, 3, 4).reshape(H, W, f * f, 3)
    blocks_a = pad_a.reshape(H, f, W, f).transpose(0, 2, 1, 3).reshape(H, W, f * f)
    opaque = blocks_a > 0.5
    masked = np.where(opaque[..., None], blocks_c, np.nan)
    import warnings
    warnings.simplefilter('ignore', RuntimeWarning)
    with np.errstate(all='ignore'):
        med = np.nanmedian(masked, axis=2) if True else None
    med = np.nan_to_num(med)
    dist = ((blocks_c - med[:, :, None, :]) ** 2).sum(-1)
    dist = np.where(opaque, dist, np.inf)
    pick = np.argmin(dist, axis=2)
    col = np.take_along_axis(blocks_c, pick[..., None, None], axis=2)[:, :, 0, :]
    alpha = opaque.sum(-1) >= (f * f) / 2.0
    # drop leftover pink fringe on the outline (magenta mixed into an edge pixel)
    edge = alpha & ndimage.binary_dilation(~alpha)
    r, g, b = col[..., 0], col[..., 1], col[..., 2]
    pink = (np.minimum(r, b) - g > 55) & (np.abs(r - b) < 90)
    alpha = alpha & ~(edge & pink)
    return col, alpha


def shrink_average(c, a, f):
    """(old method, kept for comparison) average colour over opaque pixels."""
    h, w = a.shape
    H, W = (h + f - 1) // f, (w + f - 1) // f
    pad_c = np.zeros((H * f, W * f, 3))
    pad_a = np.zeros((H * f, W * f))
    pad_c[:h, :w] = c
    pad_a[:h, :w] = a
    pa = pad_a.reshape(H, f, W, f)
    pc = (pad_c * pad_a[..., None]).reshape(H, f, W, f, 3)
    asum = pa.sum(axis=(1, 3))
    col = pc.sum(axis=(1, 3)) / np.maximum(asum, 1e-6)[..., None]
    alpha = (asum / (f * f)) >= 0.5
    return col, alpha


def to_image(col, alpha, colours=0):
    out = np.zeros(col.shape[:2] + (4,), dtype=np.uint8)
    out[..., :3] = np.clip(col, 0, 255).astype(np.uint8)
    out[..., 3] = np.where(alpha, 255, 0)
    im = Image.fromarray(out, 'RGBA')
    if colours:
        # reduce to a small palette of the object's own colours, like hand-made pixel art
        rgb = im.convert('RGB').quantize(colors=colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB')
        q = np.array(rgb)
        out[..., :3] = q
        im = Image.fromarray(out, 'RGBA')
    bb = im.getbbox()
    return im.crop(bb) if bb else im


def tile_image(c, a):
    """Floor tiles: trim the soft edge, resample to exactly 32x32, then snap every pixel
    back to the tile's own source palette so the joints and highlights stay crisp."""
    ys, xs = np.nonzero(a)
    # skip the drawn frame around each tile too, so tiles join without a visible grid
    m = 9
    t = c[ys.min() + m:ys.max() - m + 1, xs.min() + m:xs.max() - m + 1]
    src = Image.fromarray(np.clip(t, 0, 255).astype(np.uint8), 'RGB')
    pal = src.quantize(colors=20, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    small = src.resize((TILE, TILE), Image.Resampling.LANCZOS).filter(ImageFilter.UnsharpMask(1, 120, 0))
    return small.quantize(palette=pal, dither=Image.Dither.NONE).convert('RGBA')


def footprint(group, w, h):
    if group in ('tiles', 'rugs'):
        return None
    if group == 'walls':
        return [w, min(h, 20)]
    return [max(8, round(w * 0.8)), max(6, min(round(h * 0.3), 24))]


def build():
    rgb, fg, lab, boxes = segment(SRC + 'sheet1.png')
    manifest = {}
    tiles = {}
    for key, (px, py) in NAMES_1.items():
        group, name = key.split('/')
        box = next(b for b in boxes if b[0] <= px < b[2] and b[1] <= py < b[3]
                   and lab[py, px] in (b[4], 0))
        c, a = cut(rgb, fg, lab, box)
        if group == 'tiles':
            im = tile_image(c, a)
            tiles[name] = im
        else:
            im = to_image(*shrink(c, a, SCALE), colours=0)
        os.makedirs(OUT + group, exist_ok=True)
        im.save(OUT + '%s/%s.png' % (group, name))
        manifest['%s/%s' % (group, name)] = {
            'size': [im.width, im.height],
            'pivot': [im.width // 2, im.height] if group != 'tiles' else [0, 0],
            'footprint': footprint(group, im.width, im.height),
        }
    atlas = Image.new('RGBA', (TILE * 4, TILE * len(TILE_ROWS)))
    for r, (_, names) in enumerate(TILE_ROWS):
        for v, n in enumerate(names):
            name, _, flip = n.partition(':')
            t = tiles[name]
            if 'x' in flip:
                t = t.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            if 'y' in flip:
                t = t.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
            atlas.paste(t, (v * TILE, r * TILE))
    atlas.save(OUT + 'tiles.png')
    json.dump(manifest, open(OUT + 'manifest.json', 'w'), indent=1, sort_keys=True)
    return manifest


if __name__ == '__main__':
    man = build()
    print(len(man), 'sprites')
    # preview of everything, by group
    groups = {}
    for key in sorted(man):
        groups.setdefault(key.split('/')[0], []).append(key)
    prev = Image.new('RGBA', (1400, 900), (92, 126, 70, 255))
    y = 6
    for gname, keys in groups.items():
        x, rowh = 6, 0
        for key in keys:
            im = Image.open(OUT + key + '.png')
            if x + im.width > 1394:
                x, y, rowh = 6, y + rowh + 6, 0
            prev.paste(im, (x, y), im)
            x += im.width + 6
            rowh = max(rowh, im.height)
        y += rowh + 14
    prev.crop((0, 0, 1400, y)).save('/tmp/claude-0/imp/preview.png')
