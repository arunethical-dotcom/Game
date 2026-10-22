extends StaticBody2D
## A straight run of castle curtain wall, axis-aligned so every brick sits on whole pixels.
##
## Horizontal walls (along x) show their front face and the walkway with battlements
## on top. Vertical walls (along y) are seen from above as a walkway strip; they are
## built from short pieces so each piece sorts correctly against people beside it.
##
## The node's position is the wall's base line (the point where it meets the ground),
## which is what the y-sort uses.

const T_STONE = preload("res://art/cit_tex_stone.png")
const T_TOP = preload("res://art/cit_tex_walltop.png")
const T_BATTLE = preload("res://art/cit_tex_battlement.png")

const HEIGHT := 72       # height of the wall face
const THICK := 28        # thickness of the walkway on top

var length := 100        # along x for horizontal, along y for vertical
var vertical := false
var front_battlements := true


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	if vertical:
		r.size = Vector2(THICK, length)
		cs.position = Vector2(0, -length / 2.0)
	else:
		r.size = Vector2(length, 24)
		cs.position = Vector2(0, -12)
	cs.shape = r
	add_child(cs)


## Tile a texture over a rect, anchored to the world so neighbouring pieces line up.
func _tile(tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	var s := tex.get_size()
	var world := rect.position + position
	var src := Rect2(Vector2(fposmod(world.x, s.x), fposmod(world.y, s.y)), rect.size)
	draw_texture_rect_region(tex, rect, src, tint)


func _draw() -> void:
	if vertical:
		_draw_vertical()
	else:
		_draw_horizontal()


func _draw_horizontal() -> void:
	var x0 := -length / 2
	# soft shadow on the ground in front
	draw_rect(Rect2(x0, 0, length, 6), Color(0.05, 0.08, 0.03, 0.28))
	draw_rect(Rect2(x0, 6, length, 5), Color(0.05, 0.08, 0.03, 0.14))
	# face
	_tile(T_STONE, Rect2(x0, -HEIGHT, length, HEIGHT))
	draw_rect(Rect2(x0, -8, length, 8), Color(0.0, 0.0, 0.0, 0.16))         # plinth shade
	draw_rect(Rect2(x0, -HEIGHT, length, 3), Color(1.0, 0.95, 0.85, 0.18))  # cornice light
	# walkway on top, with battlements along the back and (optionally) the front edge
	var top := -HEIGHT - THICK
	_tile(T_TOP, Rect2(x0, top, length, THICK))
	_tile(T_BATTLE, Rect2(x0, top - 12, length, 18))
	if front_battlements:
		_tile(T_BATTLE, Rect2(x0, -HEIGHT - 14, length, 18))
	draw_rect(Rect2(x0, -HEIGHT - 1, length, 1), Color(0.2, 0.16, 0.12, 0.6))


func _draw_vertical() -> void:
	var w := THICK
	var x0 := -w / 2
	var y0 := -length - HEIGHT
	_tile(T_TOP, Rect2(x0, y0, w, length))
	# parapet stones along both edges
	for y in range(int(y0), int(y0 + length), 16):
		draw_rect(Rect2(x0 - 2, y, 6, 10), Color(0.80, 0.76, 0.68))
		draw_rect(Rect2(x0 - 2, y, 6, 2), Color(0.9, 0.87, 0.8))
		draw_rect(Rect2(x0 + w - 4, y, 6, 10), Color(0.62, 0.58, 0.52))
	draw_rect(Rect2(x0 - 2, y0, 1, length), Color(0.2, 0.16, 0.12, 0.7))
	draw_rect(Rect2(x0 + w + 1, y0, 1, length), Color(0.2, 0.16, 0.12, 0.7))
