extends StaticBody2D
## A single sprite from art/x_<name>.png, drawn with its bottom-centre on this node.
## `solid` adds a collision box across the base so the player walks around it.

var sprite := "crates"
var solid := true
var base := Vector2.ZERO   # collision size; zero = guess from the sprite
var tex: Texture2D


func _ready() -> void:
	tex = load("res://art/x_%s.png" % sprite)
	collision_layer = 1
	collision_mask = 0
	if not solid:
		return
	var sz := base
	if sz == Vector2.ZERO:
		sz = Vector2(tex.get_width() * 0.85, minf(tex.get_height() * 0.35, 40.0))
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = sz
	cs.shape = r
	cs.position = Vector2(0, -sz.y * 0.5)
	add_child(cs)


func _draw() -> void:
	var w := tex.get_width()
	var h := tex.get_height()
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, w * 0.5, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_texture(tex, Vector2(-w / 2, -h + 2))
