extends Control
## Health bar fill, drawn inside the wooden frame.

const UI_SMALL = preload("res://art/ui_small.png")
var max_value := 100.0
var value := 100.0:
	set(v):
		value = v
		queue_redraw()


func _draw() -> void:
	draw_texture_rect_region(UI_SMALL, Rect2(Vector2.ZERO, size), Rect2(24, 0, 8, 8))
	var w := roundf(size.x * clampf(value / max_value, 0.0, 1.0))
	if w > 0:
		draw_texture_rect_region(UI_SMALL, Rect2(0, 0, w, size.y), Rect2(16, 0, 8, 8))
