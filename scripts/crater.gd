extends Node2D
## Ground damage left by a heavy slam. Fades after a while.

const LIFE := 14.0
var age := 0.0
var cracks := []
var radius := 26.0


func _ready() -> void:
	radius = randf_range(22, 30)
	for i in 6:
		var a := randf() * TAU
		var mid := Vector2.from_angle(a) * radius * randf_range(1.0, 1.5) + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		var end := Vector2.from_angle(a + randf_range(-0.4, 0.4)) * radius * randf_range(1.6, 2.4)
		cracks.append([Vector2.from_angle(a) * radius * 0.7, mid, end])


func _process(delta: float) -> void:
	age += delta
	if age >= LIFE:
		queue_free()
		return
	if age > LIFE - 3.0:
		queue_redraw()


func _draw() -> void:
	var a := 1.0 if age < LIFE - 3.0 else (LIFE - age) / 3.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.55))
	draw_circle(Vector2.ZERO, radius + 6, Color(0.3, 0.22, 0.14, 0.35 * a))
	draw_circle(Vector2.ZERO, radius, Color(0.16, 0.11, 0.08, 0.75 * a))
	draw_circle(Vector2(0, -4), radius * 0.6, Color(0.1, 0.07, 0.05, 0.8 * a))
	for c in cracks:
		draw_line(c[0], c[1], Color(0.12, 0.08, 0.06, 0.8 * a), 3.0)
		draw_line(c[1], c[2], Color(0.12, 0.08, 0.06, 0.6 * a), 2.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
