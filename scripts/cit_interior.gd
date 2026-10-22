extends Node2D
## The inside of a citadel building, drawn on the ground below everything else:
## floor, the back wall's inner face (with windows and banners), side walls, a carpet,
## a raised dais and stair openings. Only seen when the building's roof fades away.

const T_STONE = preload("res://art/cit_tex_stone.png")
const T_TOP = preload("res://art/cit_tex_walltop.png")
const T_CARPET = preload("res://art/cit_tex_carpet.png")
const TALL_WINDOW = preload("res://art/cit_window_stained.png")
const BANNERS = [preload("res://art/cit_banner_blue.png"), preload("res://art/cit_banner_red.png")]
const CREST = preload("res://art/cit_crest.png")
const Tiles = preload("res://scripts/tiles.gd")

var footprint := Rect2()
var wall_h := 112
var floor_tex: Texture2D
var carpet := Rect2()          # world rect, empty = none
var dais := Rect2()            # world rect, empty = none
var stairs := []               # [world position (top-left), Texture2D]
var stained := false
var tile_row := -1             # >= 0: floor from the tile atlas (scripts/tiles.gd) instead of floor_tex
var tile_vars := [0, 1, 2, 3]
var nave := Rect2()            # checkerboard area in the middle of the floor
var nave_alt := []
var bands := []                # [Rect2, atlas row] inlaid border bands
var rugs := []                 # [Texture2D, centre]
var pools := []                # [centre, radius] warm light on the floor
var shafts := true             # daylight falling from the back-wall windows


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _tile(tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	var s := tex.get_size()
	draw_texture_rect_region(tex, rect, Rect2(Vector2(fposmod(rect.position.x, s.x), fposmod(rect.position.y, s.y)), rect.size), tint)


func _draw() -> void:
	var f := footprint
	var h := float(wall_h)
	# floor
	if tile_row >= 0:
		Tiles.fill(self, f, tile_row, tile_vars)
		if nave.size != Vector2.ZERO:
			Tiles.fill(self, nave, tile_row, tile_vars, nave_alt)
		for b in bands:
			Tiles.fill(self, b[0], b[1], [0, 1, 2, 3])
	else:
		_tile(floor_tex, f)
	for g in rugs:
		var t: Texture2D = g[0]
		draw_texture(t, (g[1] - t.get_size() / 2).round())
	# dais: a raised marble platform with two steps
	if dais.size != Vector2.ZERO:
		if tile_row >= 0:
			Tiles.fill(self, dais, tile_row, [0, 1], [], Vector2.ZERO, Color(1.06, 1.06, 1.08))
		else:
			_tile(floor_tex, dais, Color(1.12, 1.12, 1.15))
		draw_rect(Rect2(dais.position.x, dais.end.y, dais.size.x, 6), Color(0.85, 0.82, 0.78))
		draw_rect(Rect2(dais.position.x, dais.end.y + 6, dais.size.x, 6), Color(0.7, 0.68, 0.66))
		draw_rect(Rect2(dais.position.x, dais.end.y + 12, dais.size.x, 2), Color(0.3, 0.28, 0.3))
		draw_rect(Rect2(dais.position.x, dais.position.y, dais.size.x, 2), Color(0.85, 0.66, 0.3))
	# carpet with a gold border
	if carpet.size != Vector2.ZERO:
		_tile(T_CARPET, carpet)
		draw_rect(Rect2(carpet.position.x, carpet.position.y, 4, carpet.size.y), Color(0.85, 0.66, 0.3))
		draw_rect(Rect2(carpet.end.x - 4, carpet.position.y, 4, carpet.size.y), Color(0.85, 0.66, 0.3))
		draw_rect(Rect2(carpet.position.x + 4, carpet.position.y, 1, carpet.size.y), Color(1.0, 0.85, 0.45))
	# daylight falling from the windows onto the floor, and warm light from the sconces
	var n := int(f.size.x / 110)
	if shafts:
		for i in n:
			if stained or i % 2 == 0:
				var wx := roundf(f.position.x + (i + 0.5) * f.size.x / n)
				var l := minf(f.size.y * 0.5, 260.0)
				draw_colored_polygon(PackedVector2Array([Vector2(wx - 10, f.position.y), Vector2(wx + 10, f.position.y),
						Vector2(wx + 10 + l * 0.35, f.position.y + l), Vector2(wx - 10 + l * 0.35, f.position.y + l)]), Color(1.0, 0.86, 0.55, 0.05))
	for p in pools:
		draw_circle(p[0], p[1], Color(1.0, 0.6, 0.22, 0.06))
		draw_circle(p[0], p[1] * 0.55, Color(1.0, 0.68, 0.3, 0.07))
	# back wall, inner face
	var back := Rect2(f.position.x, f.position.y - h, f.size.x, h)
	_tile(T_STONE, back, Color(1.0, 0.98, 0.94))
	draw_rect(Rect2(back.position.x, back.end.y - 6, back.size.x, 6), Color(0, 0, 0, 0.25))
	_tile(T_TOP, Rect2(back.position.x - 4, back.position.y - 8, back.size.x + 8, 8))
	for i in n:
		var x := roundf(back.position.x + (i + 0.5) * back.size.x / n)
		if stained or i % 2 == 0:
			draw_texture(TALL_WINDOW, Vector2(x - 12, back.position.y + 14))
		else:
			draw_texture(BANNERS[(i / 2) % 2], Vector2(x - 11, back.position.y + 6))
	draw_texture(CREST, Vector2(roundf(f.get_center().x - 17), back.position.y + 6))
	# wainscot along the bottom of the back wall
	draw_rect(Rect2(back.position.x, back.end.y - 24, back.size.x, 24), Color(0.33, 0.22, 0.13))
	draw_rect(Rect2(back.position.x, back.end.y - 24, back.size.x, 2), Color(0.85, 0.66, 0.3))
	var px := back.position.x + 8
	while px < back.end.x - 12:
		draw_rect(Rect2(px, back.end.y - 19, 18, 14), Color(0.27, 0.17, 0.1))
		px += 24
	# side walls seen from above
	for x in [f.position.x - 6, f.end.x - 14]:
		_tile(T_STONE, Rect2(x, back.position.y - 8, 20, f.size.y + h + 8), Color(0.9, 0.87, 0.82))
		_tile(T_TOP, Rect2(x, back.position.y - 8, 20, 6))
		var inner: float = x + 20 if x < f.get_center().x else x - 6
		draw_rect(Rect2(inner, back.end.y, 6, f.size.y), Color(0, 0, 0, 0.22))   # shadow on the floor
		draw_rect(Rect2(x, back.position.y - 8, 1, f.size.y + h + 8), Color(0.15, 0.12, 0.1))
		draw_rect(Rect2(x + 19, back.position.y - 8, 1, f.size.y + h + 8), Color(0.15, 0.12, 0.1))
	# stairs to the other floors (the up stairs climb into an arch in the back wall)
	for s in stairs:
		draw_texture(s[1], s[0])
	# (the front wall is drawn by the building: tall from outside, cut low from inside)
