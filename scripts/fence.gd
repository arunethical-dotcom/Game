extends StaticBody2D
## Wooden fence between two points (local a and b).

var a := Vector2.ZERO
var b := Vector2.ZERO


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(a.distance_to(b), 8)
	cs.shape = r
	cs.rotation = (b - a).angle()
	cs.position = (a + b) * 0.5
	add_child(cs)


func _draw() -> void:
	var wood := Color(0.42, 0.3, 0.18)
	var posts := int(a.distance_to(b) / 26.0) + 1
	for i in posts + 1:
		var p := a.lerp(b, float(i) / posts)
		draw_rect(Rect2(p + Vector2(-2, -18), Vector2(4, 18)), wood.darkened(0.2))
	draw_line(a + Vector2(0, -14), b + Vector2(0, -14), wood, 3.0)
	draw_line(a + Vector2(0, -7), b + Vector2(0, -7), wood, 3.0)
