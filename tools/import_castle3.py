"""Import source_art/castle3/sheet3.png (the outer-castle kit) into art/castle3/.

Architecture on this sheet is drawn small, so every object is scaled up by a whole
number (nearest neighbour: pixels stay square and crisp): walls, towers, gates, cliffs,
waterfalls and trees 3x, small decor 2x. At 3x a tower is about 520 px tall and a
curtain wall 300 px (about 8 m), next to Kael's 64 px (1.75 m). Objects are named by their
position on the sheet (centre point), see NAMES. Pivot = bottom centre.
"""
import json, os
import numpy as np
from PIL import Image
import import_castle as ic

SRC = '../source_art/castle3/sheet3.png'
OUT = '../art/castle3/'
SCALE = 2
# castle-sized things are scaled up more, so towers and walls read at a real castle's size
SCALE_GROUP = {'walls': 3, 'towers': 3, 'gates': 3, 'stairs': 3, 'cliffs': 3, 'water': 3, 'trees': 3,
               'buildings': 3, 'garden': 3}

# name -> sheet box (x0, y0, x1, y1), picked from the labelled sheet
NAMES = {
    'walls/wall_banner': (5, 214, 168, 317), 'walls/wall_end': (392, 212, 492, 322),
    'walls/walkway': (509, 456, 599, 490),
    'towers/tower_flag': (479, 12, 530, 197), 'towers/tower_flag_b': (1217, 15, 1266, 205),
    'towers/tower_tall': (4, 532, 58, 704), 'towers/tower_battlement': (331, 209, 382, 320),
    'towers/tower_battlement_b': (497, 210, 539, 331), 'towers/tower_blue_a': (605, 456, 658, 580),
    'towers/tower_blue_b': (859, 434, 912, 560), 'towers/tower_blue_c': (468, 491, 546, 623),
    'towers/tower_blue_d': (551, 492, 600, 623), 'towers/tower_round': (1199, 356, 1246, 450),
    'towers/tower_cone_a': (662, 250, 736, 359), 'towers/tower_cone_b': (738, 256, 801, 350),
    'gates/gate_arch': (1182, 454, 1277, 519), 'gates/gate_door_l': (1284, 454, 1316, 519),
    'gates/gate_door_r': (1330, 454, 1361, 519), 'gates/gatehouse': (1072, 348, 1193, 454),
    'gates/gate_twin': (1254, 352, 1346, 450),
    'stairs/stairs_wide': (1184, 526, 1309, 570), 'stairs/stairs_narrow': (1316, 524, 1377, 576),
    'cliffs/cliff_a': (6, 843, 77, 935), 'cliffs/cliff_b': (213, 863, 315, 951),
    'cliffs/cliff_c': (941, 911, 1000, 1017), 'cliffs/cliff_d': (1106, 928, 1196, 1005),
    'water/waterfall_small': (335, 786, 388, 874), 'water/waterfall_big': (387, 891, 508, 1015),
    'water/waterfall_mid': (295, 875, 395, 1013),
    'trees/cypress': (393, 625, 418, 703), 'trees/cypress_b': (461, 629, 487, 703),
    'trees/pine_a': (611, 805, 639, 858), 'trees/pine_b': (640, 804, 667, 858),
    'trees/bush_round': (667, 805, 703, 839), 'trees/pine_small': (370, 706, 392, 751),
    'trees/pine_big': (571, 705, 602, 766), 'trees/pine_pair': (37, 729, 90, 782),
    'decor/angel_a': (909, 625, 960, 699), 'decor/angel_b': (964, 621, 1004, 699),
    'decor/banner_pole': (989, 707, 1015, 760), 'decor/flag': (1062, 706, 1109, 813),
    'decor/torch': (1017, 711, 1035, 768), 'decor/lamp_a': (735, 626, 752, 699),
    'decor/lamp_b': (749, 708, 765, 773), 'decor/lamp_c': (776, 713, 796, 773),
    # the castle's buildings (outer shell of the whole castle, stage 14)
    'buildings/palace': (531, 0, 1038, 248), 'buildings/towers_a': (14, 4, 212, 205),
    'buildings/towers_b': (212, 4, 339, 210), 'buildings/towers_c': (339, 2, 480, 204),
    'buildings/towers_d': (1030, 3, 1218, 209), 'buildings/domed_hall': (1271, 5, 1523, 217),
    'buildings/chapel_row': (853, 213, 1107, 350), 'buildings/chapel_a': (1251, 217, 1323, 343),
    'buildings/church': (1327, 217, 1408, 342), 'buildings/chapel_b': (1409, 215, 1482, 343),
    'buildings/keep_tower': (543, 212, 655, 350), 'buildings/wall_arches': (790, 347, 1067, 447),
    'buildings/wall_tower': (1356, 350, 1527, 519), 'buildings/gate_tower': (1072, 348, 1193, 454),
    'buildings/tower_hall': (176, 199, 328, 322), 'buildings/stair_big': (1464, 526, 1532, 637),
    'garden/lawn': (312, 626, 389, 700), 'garden/bed_big': (156, 621, 229, 697), 'garden/bed': (97, 621, 150, 687),
    'garden/planter': (261, 629, 304, 669), 'garden/hedge_bed': (487, 707, 568, 747), 'garden/flower_bed': (426, 706, 480, 745),
    'garden/arch_flowers': (653, 707, 705, 775), 'garden/arch_roses': (604, 703, 651, 775),
    'market/stall_a': (1109, 767, 1166, 828), 'market/stall_b': (1169, 766, 1216, 822), 'market/stall_c': (1216, 761, 1277, 828),
    'market/stall_d': (1321, 761, 1367, 825), 'market/stall_e': (1369, 766, 1411, 826), 'market/stall_f': (1415, 760, 1463, 825),
    'market/shed': (845, 784, 875, 829), 'market/rack': (907, 780, 960, 842),
    'training/dummy_stand': (1064, 820, 1102, 878), 'training/shelf': (1113, 832, 1166, 869), 'training/fence': (1174, 832, 1221, 866),
    'training/weapon_rack': (1396, 831, 1455, 869), 'training/tent_rack': (1465, 825, 1529, 869), 'training/gallows_rack': (918, 846, 980, 901),
}
TEX = {   # tiling textures cut from inside objects: name -> (box, scale)
    'tex_water': ((270, 800, 318, 858), 2), 'tex_flag': ((268, 706, 318, 778), 2),
    'tex_flag_b': ((121, 706, 161, 740), 2),
    # cut from the bannered wall piece: plain stone face, the slate wall walk, the merlon band
    'tex_wallface': ((76, 268, 130, 310), 3), 'tex_walltop': ((84, 234, 146, 241), 3),
    'tex_merlons': ((32, 241, 150, 250), 3),
}


def build():
    rgb, fg, lab, boxes = ic.segment(SRC, dilate=1)
    src = Image.open(SRC).convert('RGB')
    man = {}
    for key, box in NAMES.items():
        b = min(boxes, key=lambda q: sum(abs(q[i] - box[i]) for i in range(4)))
        c, a = ic.cut(rgb, fg, lab, b)
        im = ic.to_image(c, a > 0.5, colours=0)
        k = SCALE_GROUP.get(key.split('/')[0], SCALE)
        im = im.resize((im.width * k, im.height * k), Image.Resampling.NEAREST)
        os.makedirs(OUT + key.split('/')[0], exist_ok=True)
        im.save(OUT + key + '.png')
        man[key] = {'size': [im.width, im.height], 'pivot': [im.width // 2, im.height]}
    for key, (box, s) in TEX.items():
        t = src.crop(box)
        # the AI drew some foam flecks in magenta: repaint them with the surrounding colour
        a = np.array(t).astype(int)
        mag = (np.minimum(a[..., 0], a[..., 2]) - a[..., 1] > 40) & (a[..., 0] > a[..., 1] + 40)
        if mag.any():
            ok = a[~mag].reshape(-1, 3)
            from scipy import ndimage
            idx = ndimage.distance_transform_edt(mag, return_distances=False, return_indices=True)
            a = a[idx[0], idx[1]]
        t = Image.fromarray(a.astype(np.uint8))
        t = t.resize((t.width * s, t.height * s), Image.Resampling.NEAREST)
        t.save(OUT + key + '.png')
    # a red banner, cut from the wall piece (stone around it made transparent)
    b = np.array(src.crop((40, 252, 59, 304))).astype(int)
    sat = b.max(-1) - b.min(-1)
    alpha = np.where((sat > 45) | (b[..., 0] > 150), 255, 0).astype(np.uint8)
    bi = Image.fromarray(np.dstack([b.astype(np.uint8), alpha]), 'RGBA')
    bi = bi.resize((bi.width * 3, bi.height * 3), Image.Resampling.NEAREST)
    os.makedirs(OUT + 'decor', exist_ok=True)
    bi.save(OUT + 'decor/wall_banner.png')
    # the domed hall again at 2x: in the reference it is a smaller building than the palace
    rgb2, fg2, lab2, boxes2 = rgb, fg, lab, boxes
    b2 = min(boxes, key=lambda q: sum(abs(q[i] - (1271, 5, 1523, 217)[i]) for i in range(4)))
    c, a = ic.cut(rgb, fg, lab, b2)
    im = ic.to_image(c, a > 0.5, colours=0)
    im.resize((im.width * 2, im.height * 2), Image.Resampling.NEAREST).save(OUT + 'buildings/domed_hall_2x.png')
    # the wall walk seen from above, for the side (west/east) walls: the walkway turned 90 degrees
    w = Image.open(OUT + 'walls/walkway.png').transpose(Image.Transpose.ROTATE_90)
    w.save(OUT + 'walls/walkway_v.png')
    # seamless ground textures: the game's own grass and path tiles, and the water mirrored
    tiles = Image.open('../art/tiles.png').convert('RGB')
    tiles.crop((0, 0, 128, 32)).save(OUT + 'tex_grass.png')
    tiles.crop((0, 96, 128, 128)).save(OUT + 'tex_dirt.png')
    w = Image.open(OUT + 'tex_water.png')
    m = Image.new('RGB', (w.width * 2, w.height * 2))
    m.paste(w, (0, 0))
    m.paste(w.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (w.width, 0))
    m.paste(w.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, w.height))
    m.paste(w.transpose(Image.Transpose.ROTATE_180), (w.width, w.height))
    m.save(OUT + 'tex_water.png')
    json.dump(man, open(OUT + 'manifest.json', 'w'), indent=1, sort_keys=True)
    return man


if __name__ == '__main__':
    man = build()
    print(len(man), 'sprites')
    prev = Image.new('RGBA', (2200, 1500), (92, 126, 70, 255))
    x, y, rowh = 6, 6, 0
    for k in sorted(man):
        im = Image.open(OUT + k + '.png')
        if x + im.width > 2194:
            x, y, rowh = 6, y + rowh + 6, 0
        prev.paste(im, (x, y), im)
        x += im.width + 6
        rowh = max(rowh, im.height)
    prev.crop((0, 0, 2200, y + rowh + 6)).save('/tmp/claude-0/prev3.png')
