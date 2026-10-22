extends StaticBody2D
## A clipped garden hedge running along x, seen from the front and above.
## Position = the middle of its base line.

const T_TOP = preload("res://art/cit_tex_hedge_top.png")
const T_FACE = preload("res://art/cit_tex_hedge_face.png")
const DEPTH := 20
const HIGH := 20

var length := 100


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(length, 14)
	cs.shape = r
	cs.position = Vector2(0, -7)
	add_child(cs)


func _tile(tex: Texture2D, rect: Rect2) -> void:
	var s := tex.get_size()
	var world := rect.position + position
	draw_texture_rect_region(tex, rect, Rect2(Vector2(fposmod(world.x, s.x), fposmod(world.y, s.y)), rect.size))


func _draw() -> void:
	var x0 := -length / 2
	draw_rect(Rect2(x0 + 2, 0, length, 5), Color(0.05, 0.1, 0.03, 0.3))
	_tile(T_FACE, Rect2(x0, -HIGH, length, HIGH))
	_tile(T_TOP, Rect2(x0, -HIGH - DEPTH, length, DEPTH))
	# rounded ends and a darker outline
	draw_rect(Rect2(x0, -HIGH - DEPTH, length, 1), Color(0.08, 0.16, 0.06))
	draw_rect(Rect2(x0, -HIGH - DEPTH, 1, HIGH + DEPTH), Color(0.08, 0.16, 0.06))
	draw_rect(Rect2(x0 + length - 1, -HIGH - DEPTH, 1, HIGH + DEPTH), Color(0.08, 0.16, 0.06))
	draw_rect(Rect2(x0, -1, length, 1), Color(0.08, 0.16, 0.06))
