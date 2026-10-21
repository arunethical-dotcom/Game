extends StaticBody2D
## The royal castle of Akropolis Aigidos, home of the king and his family.

const CASTLE = preload("res://art/castle.png")


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(390, 150)
	cs.shape = r
	cs.position = Vector2(0, -75)
	add_child(cs)


func _draw() -> void:
	draw_rect(Rect2(-200, -10, 400, 16), Color(0, 0, 0, 0.2))
	draw_texture_rect_region(CASTLE, Rect2(-220, -396, 440, 400), Rect2(0, 0, 440, 400))
