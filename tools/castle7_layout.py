"""Stage-17 castle layout: the pieces (crops of the castle6 sprites) and where each stands
on the castle map (1728 px map coordinates, feet = bottom centre unless `anchor` is given).

PIECES[name] = {src: art/castle7 sprite, box: crop (sprite px), scale: world px per sprite px,
                anchor: feet point (sprite px), regions: [(kind, box, *arg)]}
  region kinds: 'flat' (lies on the ground: causeway floors, stairs), 'stand' (each blob
  stands on its own feet: posts, statues), 'rise' (a wall running north-south: each pixel
  stands arg px below itself)
LAYOUT entries: {p: piece, x, y: map px, mirror, sym: also place mirrored about x = 864,
                 fit: search radius (map px) for template matching against the map}
"""

R = 'runs/'
B = 'buildings/'
T = 'trees/'

PIECES = {
    # ---- the outer front: gatehouse, wings and causeway (one piece) ----
    'gate_front': {'src': R + 'gatehouse_causeway', 'scale': 2, 'anchor': (700, 465),
                   'regions': [('flat', (820, 360, 925, 770)), ('stand', (760, 330, 990, 770)),
                               ('open', (832, 284, 912, 356))]},
    # ---- towers ----
    'blue_end': {'src': R + 'wall_curve_south', 'box': (0, 0, 100, 300), 'scale': 2},
    'round_a': {'src': R + 'wall_curve_south', 'box': (172, 165, 252, 392), 'scale': 2},
    'blue_a': {'src': R + 'wall_curve_south', 'box': (360, 195, 484, 500), 'scale': 2},
    'round_b': {'src': R + 'wall_curve_south', 'box': (568, 290, 648, 512), 'scale': 2},
    'blue_b': {'src': R + 'wall_curve_south', 'box': (762, 230, 882, 528), 'scale': 2},
    'wblue_a': {'src': R + 'wall_diagonal_west', 'box': (15, 0, 140, 335), 'scale': 2},
    'wblue_b': {'src': R + 'wall_diagonal_west', 'box': (445, 300, 560, 600), 'scale': 2},
    'wblue_c': {'src': R + 'wall_diagonal_west', 'box': (835, 460, 960, 812), 'scale': 2},
    'eblue_flag': {'src': R + 'wall_east_bridges', 'box': (0, 590, 115, 862), 'scale': 2},
    'eblue_a': {'src': R + 'wall_east_bridges', 'box': (665, 550, 785, 856), 'scale': 2},
    # ---- palace, buildings ----
    'palace': {'src': R + 'palace_with_wings', 'scale': 2, 'anchor': (870, 755),
               'regions': [('flat', (815, 630, 935, 755))]},
    'cathedral': {'src': B + 'bld_000', 'scale': 2},
    'domed_hall': {'src': B + 'bld_002', 'scale': 2},
    'manor': {'src': B + 'bld_006', 'scale': 2},
    'chapel': {'src': B + 'bld_009', 'scale': 2},
    'market_a': {'src': B + 'bld_007', 'scale': 2, 'regions': [('flat', (0, 0, 9999, 9999))]},
    'market_b': {'src': B + 'bld_008', 'scale': 2},
    'training': {'src': B + 'bld_010', 'scale': 2},
    'fountain': {'src': B + 'bld_017', 'scale': 2},
    'grand_stairs': {'src': B + 'bld_048', 'scale': 2, 'regions': [('flat', (118, 0, 207, 262))]},
    'angel': {'src': B + 'bld_011', 'scale': 2},
    'knight': {'src': B + 'bld_015', 'scale': 2},
    'brazier': {'src': B + 'bld_018', 'scale': 2},
    'pool': {'src': B + 'bld_016', 'scale': 2},
}
# wall sections for wall runs: feet = (left foot, right foot) in crop px
PIECES['wall_h'] = {'src': R + 'wall_curve_south', 'box': (650, 340, 760, 505), 'scale': 2, 'feet': (154, 154)}
PIECES['wall_d'] = {'src': R + 'wall_diagonal_west', 'box': (560, 430, 835, 775), 'scale': 2, 'feet': (168, 300)}
PIECES['cause'] = {'src': R + 'gatehouse_causeway', 'box': (775, 500, 965, 600), 'scale': 2, 'ns': True,
                   'regions': [('flat', (822, 500, 922, 600))]}
PIECES['gate_inner'] = {'src': R + 'gatehouse_causeway', 'box': (748, 0, 998, 470), 'scale': 2, 'anchor': (873, 420),
                        'regions': [('flat', (822, 400, 922, 470)), ('open', (832, 284, 912, 356))]}
for k in (31, 32, 33, 35, 36, 37, 38, 39, 42, 50, 53, 54, 58, 59, 55, 56):
    PIECES['bed%02d' % k] = {'src': B + 'bld_%03d' % k, 'scale': 2}
PIECES['walkway'] = {'src': R + 'gatehouse_causeway', 'box': (775, 598, 965, 642), 'scale': 2, 'ns': True, 'stand': 10,
                     'regions': [('flat', (822, 598, 922, 642))]}
PIECES['arches'] = {'src': R + 'wall_diagonal_west', 'box': (955, 590, 1085, 775), 'scale': 2, 'feet': (176, 176)}
W = 'water/'
for k in (7, 8, 9, 20, 36, 37, 39, 40):
    PIECES['cliff_w%02d' % k] = {'src': W + 'water_%03d' % k, 'scale': 2, 'nowater': True, 'nowater_lum': 256}
for k in (76, 78, 82, 86, 87, 88, 92, 93, 94):
    PIECES['cliff_t%02d' % k] = {'src': T + 'tree_%03d' % k, 'scale': 1, 'nowater': True, 'nowater_lum': 256}
for k in (43, 44, 47, 42):
    PIECES['fall%02d' % k] = {'src': W + 'water_%03d' % k, 'scale': 2, 'nowater': True, 'nowater_lum': 120}
for k in (50, 51, 52, 57, 62, 63, 64, 73, 74, 77, 78):
    PIECES['rock%02d' % k] = {'src': W + 'water_%03d' % k, 'scale': 2, 'nowater': True, 'nowater_lum': 140}
# market yard: the sand patch is ground, the houses stand on it
PIECES['market_a']['regions'] = []

# trees (drawn at 1x, Kael's pixel size)
for i, k in enumerate((2, 3, 4, 6, 8, 9)):
    PIECES['pine%d' % i] = {'src': T + 'tree_%03d' % k, 'scale': 1}
for i, k in enumerate((19, 20, 21)):
    PIECES['cypress%d' % i] = {'src': T + 'tree_%03d' % k, 'scale': 1}

LAYOUT = [
    {'p': 'gate_front', 'x': 713, 'y': 1550, 'fit': 20},
    # inner front
    {'p': 'wblue_a', 'x': 470, 'y': 1345, 'fit': 20, 'sym': True},
    {'p': 'blue_a', 'x': 285, 'y': 1205, 'fit': 20, 'sym': True},
    {'p': 'blue_a', 'x': 665, 'y': 1235, 'fit': 15, 'sym': True},
    {'p': 'blue_a', 'x': 773, 'y': 1225, 'fit': 15, 'sym': True},
    {'p': 'blue_end', 'x': 45, 'y': 1095, 'fit': 20, 'sym': True},
    # west ring
    {'p': 'blue_a', 'x': 178, 'y': 948, 'fit': 20, 'sym': True},
    {'p': 'wblue_b', 'x': 62, 'y': 770, 'fit': 20, 'sym': True},
    {'p': 'blue_a', 'x': 112, 'y': 635, 'fit': 20, 'sym': True},
    {'p': 'blue_a', 'x': 210, 'y': 500, 'fit': 20, 'sym': True},
    {'p': 'blue_a', 'x': 476, 'y': 540, 'fit': 15, 'sym': True},
    # middle ring
    {'p': 'blue_b', 'x': 605, 'y': 790, 'fit': 15, 'sym': True},
    {'p': 'blue_a', 'x': 530, 'y': 880, 'fit': 15, 'sym': True},
    {'p': 'blue_a', 'x': 640, 'y': 855, 'fit': 15, 'sym': True},
    # palace and the terrace in front of it
    {'p': 'palace', 'x': 864, 'y': 545, 'fit': 20},
    {'p': 'grand_stairs', 'x': 864, 'y': 690, 'fit': 20},
    {'p': 'angel', 'x': 765, 'y': 560, 'fit': 15, 'sym': True},
    {'p': 'knight', 'x': 742, 'y': 705, 'fit': 15, 'sym': True},
    {'p': 'fountain', 'x': 864, 'y': 805, 'fit': 15},
    {'p': 'brazier', 'x': 790, 'y': 875, 'fit': 15, 'sym': True},
    {'p': 'pool', 'x': 575, 'y': 948, 'fit': 15, 'sym': True},
    # buildings
    {'p': 'cathedral', 'x': 355, 'y': 835, 'fit': 25},
    {'p': 'chapel', 'x': 362, 'y': 540, 'fit': 20},
    {'p': 'domed_hall', 'x': 1395, 'y': 615, 'fit': 25},
    {'p': 'manor', 'x': 1385, 'y': 835, 'fit': 25},
    {'p': 'market_a', 'x': 300, 'y': 965, 'fit': 25},
    {'p': 'market_b', 'x': 330, 'y': 1060, 'fit': 25},
    {'p': 'training', 'x': 1420, 'y': 1062, 'fit': 25},
    {'p': 'gate_inner', 'x': 864, 'y': 1222},
    {'run': 'cause', 'pts': [(864 - 72, 1240), (864 - 72, 1450)]},
    # gardens
    {'p': 'bed35', 'x': 706, 'y': 702, 'sym': True},
    {'p': 'bed36', 'x': 730, 'y': 890, 'sym': True},
    {'p': 'bed36', 'x': 668, 'y': 890, 'sym': True},
    {'p': 'bed50', 'x': 820, 'y': 1002, 'sym': True},
    {'p': 'bed32', 'x': 700, 'y': 1002, 'sym': True},
    {'p': 'bed58', 'x': 560, 'y': 1040, 'sym': True},
    # walls
    {'run': 'wall', 'pts': [(250, 888), (430, 888)], 'sym': True, 'h': 100},
    {'run': 'wall', 'pts': [(45, 1098), (285, 1200)], 'sym': True},
    {'run': 'wall', 'pts': [(285, 1200), (665, 1232), (773, 1222)], 'sym': True},
    {'run': 'wall', 'pts': [(455, 500), (590, 595)], 'sym': True, 'h': 110},
    {'run': 'wall', 'pts': [(590, 595), (742, 595)], 'sym': True, 'h': 110},
    {'run': 'wall', 'pts': [(240, 562), (452, 562)], 'sym': True, 'h': 90},
    {'run': 'wall', 'pts': [(530, 878), (640, 860)], 'sym': True, 'h': 90},
    {'run': 'wall', 'pts': [(420, 1016), (640, 1016)], 'sym': True, 'h': 80},
    # west / east ring
    {'run': 'walkway', 'pts': [(186, 385), (180, 500)], 'sym': True},
    {'run': 'walkway', 'pts': [(165, 505), (80, 640)], 'sym': True},
    {'run': 'walkway', 'pts': [(118, 780), (118, 1000)], 'sym': True},
    {'run': 'arches', 'pts': [(70, 712), (205, 712)], 'sym': True},
    {'run': 'arches', 'pts': [(60, 1058), (160, 1058)], 'sym': True},
]
TREES = []
# walkable passages (map px) through gatehouses and up stairs; Kael passes behind what is drawn there
PASSAGES = [
    (846, 1225, 882, 1570),     # outer gate (and the bridge behind it)
    (846, 895, 882, 1250),      # inner gate
    (836, 440, 892, 700),       # grand stairs, landing and palace stairs
]
NATURE = [
    {'p': 'fall47', 'x': 95, 'y': 240},
    {'p': 'fall43', 'x': 255, 'y': 1600},
    {'p': 'fall43', 'x': 1473, 'y': 1600, 'mirror': True},
    {'p': 'rock52', 'x': 330, 'y': 1650}, {'p': 'rock74', 'x': 440, 'y': 1600},
    {'p': 'rock57', 'x': 520, 'y': 1660}, {'p': 'rock63', 'x': 1300, 'y': 1610},
    {'p': 'rock73', 'x': 1400, 'y': 1660}, {'p': 'rock51', 'x': 1200, 'y': 1680},
    {'p': 'rock64', 'x': 160, 'y': 340}, {'p': 'rock62', 'x': 1520, 'y': 420},
    {'p': 'rock77', 'x': 1620, 'y': 380},
]

# map areas where no trees are planted (castle interior is handled by the layout)
TREES_OFF = [(790, 380, 940, 1240), (560, 1240, 1168, 1728)]
