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
const STAIRS_UP = preload("res://art/cit_stairs_up.png")
const STAIRS_DOWN = preload("res://art/cit_stairs_down.png")

var footprint := Rect2()
var wall_h := 112
var floor_tex: Texture2D
var carpet := Rect2()          # world rect, empty = none
var dais := Rect2()            # world rect, empty = none
var stairs := []               # [world position (top-left), "up"/"down"]
var stained := false


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _tile(tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	var s := tex.get_size()
	draw_texture_rect_region(tex, rect, Rect2(Vector2(fposmod(rect.position.x, s.x), fposmod(rect.position.y, s.y)), rect.size), tint)


func _draw() -> void:
	var f := footprint
	var h := float(wall_h)
	# floor
	_tile(floor_tex, f)
	# dais: a raised marble platform with two steps
	if dais.size != Vector2.ZERO:
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
	# stairs to the other floors
	for s in stairs:
		draw_texture(STAIRS_UP if s[1] == "up" else STAIRS_DOWN, s[0])
	# back wall, inner face
	var back := Rect2(f.position.x, f.position.y - h, f.size.x, h)
	_tile(T_STONE, back, Color(0.82, 0.8, 0.78))
	draw_rect(Rect2(back.position.x, back.end.y - 6, back.size.x, 6), Color(0, 0, 0, 0.25))
	_tile(T_TOP, Rect2(back.position.x - 4, back.position.y - 8, back.size.x + 8, 8))
	var n := int(back.size.x / 110)
	for i in n:
		var x := roundf(back.position.x + (i + 0.5) * back.size.x / n)
		if stained or i % 2 == 0:
			draw_texture(TALL_WINDOW, Vector2(x - 12, back.position.y + 14))
		else:
			draw_texture(BANNERS[(i / 2) % 2], Vector2(x - 11, back.position.y + 6))
	draw_texture(CREST, Vector2(roundf(f.get_center().x - 17), back.position.y + 6))
	# side walls seen from above
	for x in [f.position.x - 6, f.end.x - 14]:
		_tile(T_STONE, Rect2(x, back.position.y - 8, 20, f.size.y + h + 8), Color(0.72, 0.7, 0.68))
		_tile(T_TOP, Rect2(x, back.position.y - 8, 20, 6))
		var inner: float = x + 20 if x < f.get_center().x else x - 6
		draw_rect(Rect2(inner, back.end.y, 6, f.size.y), Color(0, 0, 0, 0.22))   # shadow on the floor
		draw_rect(Rect2(x, back.position.y - 8, 1, f.size.y + h + 8), Color(0.15, 0.12, 0.1))
		draw_rect(Rect2(x + 19, back.position.y - 8, 1, f.size.y + h + 8), Color(0.15, 0.12, 0.1))
	# the front wall, as a low ledge with gaps (doors are open)
	_tile(T_TOP, Rect2(f.position.x - 4, f.end.y - 10, f.size.x + 8, 10), Color(0.95, 0.95, 0.95))
