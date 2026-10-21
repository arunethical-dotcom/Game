extends StaticBody2D
const Shadow = preload("res://scripts/shadow.gd")
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
	Shadow.soft(self, Vector2(10, -4), 215.0, 22.0, 0.45)
	draw_texture_rect_region(CASTLE, Rect2(-220, -396, 440, 400), Rect2(0, 0, 440, 400))
