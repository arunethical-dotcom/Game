"""Import the castle6 sheets at their NATIVE size (no resampling) for the stage-17 castle.

Same cutting and cleaning as import_castle6.py (magenta + fringe removal, connected
components, hand cuts, hard alpha, one palette per sheet, no dithering), but every
object keeps the sheet's own pixels: resampling AI art blurs it further.

Each group is drawn in game at a whole-number scale (world px per sprite px):
  runs, buildings, water: 2   (a run tower, 115 px -> 230 world px, ~87 castle-map px)
  kit:                    3
  props, trees:           1   (the same pixel size as Kael)

Run:  cd tools && python3 import_castle7.py   ->  art/castle7/<group>/*.png + manifest.json
"""
import import_castle6 as m

m.OUT = '../art/castle7/'
DRAW = {'runs': 2, 'buildings': 2, 'water': 2, 'kit': 3, 'props': 1, 'trees': 1}
m.SHEETS = {s: (g, 1.0, whole, 128 if g in ('runs', 'buildings') else 96)
            for s, (g, _f, whole, _n) in m.SHEETS.items()}
m.DRAW_SCALE = 0

if __name__ == '__main__':
    man = m.build()
    import json
    for k, v in man.items():
        v['draw_scale'] = DRAW[k.split('/')[0]]
    json.dump(man, open(m.OUT + 'manifest.json', 'w'), indent=1, sort_keys=True)
