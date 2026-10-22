extends RefCounted
## Draws areas from the citadel tile atlas (art/cit_tiles.png, 32 px tiles, 4 variants
## per row). Tiles are aligned to the world grid and each cell picks its variant from a
## hash of its position, so a floor never shows the same tile repeating in a pattern.

const ATLAS = preload("res://art/cit_tiles.png")
const CASTLE = preload("res://art/castle/tiles.png")   # imported from the AI sheet (tools/import_castle.py)
const T := 32

# atlas rows (see tools/make_decor.py)
const FLAG := 0
const BORDER := 1
const COBBLE := 2
const MARBLE := 3
const MARBLE_BORDER := 4
const WOOD := 5
const LAWN_EDGE := 6
const MARBLE_BORDER_V := 7
# rows of the imported castle atlas (numbered from 100 so one parameter picks the atlas)
const C_LIMESTONE := 100
const C_LIMESTONE_DECO := 101
const C_MARBLE_DECO := 102
const C_WOOD := 103
const C_WOOD_CHEVRON := 104
const C_DARKSTONE := 105
const C_BLUESTONE := 106


## Fill `rect` (in the canvas item's local space) with tiles from `row`.
## `vars`: variants to choose from. `alt`: if set, checkerboard cells use these instead.
## `origin`: the canvas item's world position, so tiles line up with the world grid.
static func fill(ci: CanvasItem, rect: Rect2, row: int, vars := [0, 1, 2, 3], alt := [],
		origin := Vector2.ZERO, tint := Color.WHITE) -> void:
	var tex: Texture2D = ATLAS
	if row >= 100:
		tex = CASTLE
		row -= 100
	var wr := Rect2(rect.position + origin, rect.size)
	var tx0 := floori(wr.position.x / T)
	var ty0 := floori(wr.position.y / T)
	var tx1 := floori((wr.end.x - 0.01) / T)
	var ty1 := floori((wr.end.y - 0.01) / T)
	for ty in range(ty0, ty1 + 1):
		for tx in range(tx0, tx1 + 1):
			var cell := Rect2(Vector2(tx * T, ty * T), Vector2(T, T))
			var c := cell.intersection(wr)
			if c.size.x <= 0.0 or c.size.y <= 0.0:
				continue
			var pick: Array = alt if (not alt.is_empty() and posmod(tx + ty, 2) == 1) else vars
			var v: int = pick[posmod(hash(Vector2i(tx, ty)), pick.size())]
			var src := Rect2(Vector2(v * T, row * T) + (c.position - cell.position), c.size)
			ci.draw_texture_rect_region(tex, Rect2(c.position - origin, c.size), src, tint)


## A band (kerb or inlay) along a rectangle: horizontal bands use the tile's top
## `thick` pixels, vertical bands its left `thick` pixels.
static func band(ci: CanvasItem, rect: Rect2, row: int, origin := Vector2.ZERO, tint := Color.WHITE) -> void:
	var x := rect.position.x
	var i := 0
	if rect.size.x >= rect.size.y:
		while x < rect.end.x:
			var w := minf(T, rect.end.x - x)
			var v := posmod(hash(Vector2i(int(x + origin.x), int(rect.position.y + origin.y))), 4)
			ci.draw_texture_rect_region(ATLAS, Rect2(x, rect.position.y, w, rect.size.y), Rect2(v * T, row * T, w, minf(rect.size.y, T)), tint)
			x += w
			i += 1
	else:
		var y := rect.position.y
		while y < rect.end.y:
			var h := minf(T, rect.end.y - y)
			var v := posmod(hash(Vector2i(int(rect.position.x + origin.x), int(y + origin.y))), 4)
			ci.draw_texture_rect_region(ATLAS, Rect2(rect.position.x, y, rect.size.x, h), Rect2(v * T, row * T, minf(rect.size.x, T), h), tint)
			y += h
