extends Node2D
## An item lying on the ground. Walk over it to pick it up.

var main
var kind := "moonsteel"
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	if main.player.global_position.distance_to(global_position) < 34.0:
		main.collect(kind, global_position)
		queue_free()
		return
	queue_redraw()


const ITEMS = preload("res://art/items.png")


func _draw() -> void:
	var bob := roundf(sin(t * 3.0) * 2.0) * 2.0
	var glow := 0.6 + 0.4 * sin(t * 5.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var c := Vector2(0, -22 + bob)
	draw_circle(c, 26, Color(0.55, 0.75, 1.0, 0.16 * glow))
	draw_circle(c, 16, Color(0.6, 0.8, 1.0, 0.25 * glow))
	draw_texture_rect_region(ITEMS, Rect2(c - Vector2(12, 16), Vector2(24, 32)), Rect2(44, 2, 24, 32))
