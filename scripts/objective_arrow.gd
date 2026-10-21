extends Node2D
## A small arrow around the player pointing at the current objective.

var main
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if main.player == null:
		return
	var target: Vector2 = main.objective_target()
	if target == Vector2.INF:
		return
	var from: Vector2 = main.player.global_position + Vector2(0, -16)
	var to := target - from
	if to.length() < 140.0:
		return
	var d := to.normalized()
	var side := Vector2(-d.y, d.x)
	var tip := from + d * (62.0 + sin(t * 5.0) * 4.0)
	var pts := PackedVector2Array([tip, tip - d * 16.0 + side * 9.0, tip - d * 16.0 - side * 9.0])
	draw_colored_polygon(pts, Color(1, 0.82, 0.35, 0.9))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0.25, 0.15, 0.05, 0.9), 2.0)
