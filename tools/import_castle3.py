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
SCALE_GROUP = {'walls': 3, 'towers': 3, 'gates': 3, 'stairs': 3, 'cliffs': 3, 'water': 3, 'trees': 3}

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
}
TEX = {   # tiling textures cut from inside objects: name -> (box, scale)
    'tex_water': ((270, 800, 318, 858), 2), 'tex_flag': ((268, 706, 318, 778), 2),
    'tex_flag_b': ((121, 706, 161, 740), 2),
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
    # the wall walk seen from above, for the side (west/east) walls: the walkway turned 90 degrees
    w = Image.open(OUT + 'walls/walkway.png').transpose(Image.Transpose.ROTATE_90)
    w.save(OUT + 'walls/walkway_v.png')
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
