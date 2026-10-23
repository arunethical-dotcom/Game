"""Royal Castle v5: crisp building and tower sprites from the high-quality castle kit
(source_art/castle5/sheet5.png), placed over the castle map exactly where the map
draws the same building.

source_art/castle5/placements.json: [sheet object index, scale, x, y, name], where x, y
is the top-left on the 1728 px castle map (castle4/castle_map.png) and scale is
map px per sheet px. Towers were found by template matching against the map; unique
buildings by matching inside their area; a few (fountain, knight statues) by hand.

Writes art/castle5/obj_<k>_<scale>.png (drawn in game at 2x: 1 sprite px = 2 world px,
so 1 map-1728 px = 2.5 world px like the map), art/castle5/sprites.json (world feet
positions) and art/castle5/cover.png (864 px mask of what the sprites cover, used by
castle_mask4.py so the map's own copy of a covered building is not drawn over Kael).
"""
import json, os
import numpy as np
from PIL import Image, ImageFilter
import import_castle as ic

SHEET = '../source_art/castle5/sheet5.png'
PLACE = '../source_art/castle5/placements.json'
OUT = '../art/castle5/'
WORLD_PER_MAP = 2.5          # world px per 1728-map px (the 864 map is shown at 5x)
ORIGIN = (-2160, 5616)       # Geo.CASTLE_O


def build():
    os.makedirs(OUT, exist_ok=True)
    rgb, fg, lab, boxes = ic.segment(SHEET, dilate=1)
    boxes = [b for b in boxes if (b[2] - b[0]) * (b[3] - b[1]) >= 120]
    rgb2, bg = rgb, None
    places = json.load(open(PLACE))
    cover = Image.new('L', (1728, 1728), 0)
    made = {}
    out = []
    for k, s, x, y, name in sorted(places, key=lambda p: p[3]):
        key = 'obj_%d_%d' % (k, round(s * 100))
        c, a = ic.cut(rgb, fg, lab, boxes[k])
        a = a > 0.5
        w0, h0 = a.shape[1], a.shape[0]
        if key not in made:
            im = Image.fromarray(np.dstack([np.clip(c, 0, 255), a * 255]).astype(np.uint8), 'RGBA')
            tw, th = max(1, round(w0 * s * WORLD_PER_MAP / 2)), max(1, round(h0 * s * WORLD_PER_MAP / 2))
            col = im.convert('RGB').resize((tw, th), Image.Resampling.LANCZOS).filter(ImageFilter.UnsharpMask(1, 70, 1))
            al = np.array(im.split()[3].resize((tw, th), Image.Resampling.BILINEAR)) >= 128
            q = np.array(col.quantize(colors=64, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB'))
            o = np.dstack([q, np.where(al, 255, 0)]).astype(np.uint8)
            Image.fromarray(o, 'RGBA').save(OUT + key + '.png')
            made[key] = (tw, th)
        tw, th = made[key]
        # feet = bottom centre on the map, in world px
        fx = ORIGIN[0] + (x + w0 * s / 2) * WORLD_PER_MAP
        fy = ORIGIN[1] + (y + h0 * s) * WORLD_PER_MAP
        out.append({'tex': key, 'x': round(fx), 'y': round(fy), 'name': name})
        m = Image.fromarray((a * 255).astype(np.uint8)).resize((max(1, round(w0 * s)), max(1, round(h0 * s))))
        cover.paste(255, (int(x), int(y)), m)
    json.dump(out, open(OUT + 'sprites.json', 'w'), indent=0)
    cover.resize((864, 864), Image.Resampling.BOX).point(lambda v: 255 if v > 160 else 0).save(OUT + 'cover.png')
    print(len(out), 'sprites,', len(made), 'textures')


if __name__ == '__main__':
    build()
