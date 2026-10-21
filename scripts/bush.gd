extends Node2D
## A bush or other upright plant from flora.png. Decorative only: you can walk through it.

const FLORA = preload("res://art/flora.png")
var cell := 0


func _draw() -> void:
	draw_set_transform(Vector2(3, 0), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 14, Color(0.05, 0.1, 0.03, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_texture_rect_region(FLORA, Rect2(-16, -30, 32, 32), Rect2(cell * 32, 0, 32, 32))
