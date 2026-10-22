extends Control
## Small map in the corner, centred on the player.

const Geo = preload("res://scripts/geo.gd")
const VIEW := 4400.0   # world units shown across the map

var main


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _process(_delta: float) -> void:
	queue_redraw()


func _w2m(p: Vector2) -> Vector2:
	return size / 2.0 + (p - main.player.global_position) * (size.x / VIEW)


func _draw() -> void:
	if main == null or main.player == null:
		return
	if main.floor_name != "":
		# indoors on another floor of the citadel: show a simple marker instead
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.1, 0.09))
		draw_rect(Rect2(size / 2.0 - Vector2(18, 10), Vector2(36, 20)), Color(0.5, 0.42, 0.3), false, 2.0)
		draw_circle(size / 2.0, 3.0, Color(1.0, 0.9, 0.5))
		return
	var s := size.x / VIEW
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.48, 0.28))
	# Forest of Elders
	draw_circle(_w2m(Vector2(-2600, -3700)), 1500 * s, Color(0.2, 0.33, 0.18))
	# Plateau, cliffs, city
	draw_circle(_w2m(Vector2.ZERO), (Geo.R_CLIFF + 70) * s, Color(0.3, 0.27, 0.24))
	draw_circle(_w2m(Vector2.ZERO), (Geo.R_CLIFF - 70) * s, Color(0.42, 0.53, 0.3))
	draw_circle(_w2m(Vector2.ZERO), Geo.R_WALL * s, Color(0.5, 0.52, 0.36))
	draw_arc(_w2m(Vector2.ZERO), Geo.R_WALL * s, 0, TAU, 64, Color(0.82, 0.78, 0.68), 3.0)
	var moat := Geo.CIT_MOAT
	draw_rect(Rect2(_w2m(moat.position), moat.size * s), Color(0.3, 0.5, 0.65))
	var cw := Geo.CIT_WALL
	draw_rect(Rect2(_w2m(cw.position), cw.size * s), Color(0.62, 0.6, 0.56))
	# Roads
	for path in [Geo.SERPENT_WAY, Geo.ELDER_PATH]:
		var pts := PackedVector2Array()
		for p in path:
			pts.append(_w2m(p))
		draw_polyline(pts, Color(0.85, 0.75, 0.55), 2.0)
	# Objective and player
	var goal: Vector2 = main.objective_goal()
	if goal != Vector2.INF:
		var g := _w2m(goal).clamp(Vector2(6, 6), size - Vector2(6, 6))
		draw_circle(g, 5, Color(1, 0.82, 0.3))
		draw_arc(g, 7, 0, TAU, 16, Color(0.3, 0.15, 0.05), 1.5)
	var c := size / 2.0
	var f: Vector2 = main.player.facing
	draw_colored_polygon(PackedVector2Array([c + f * 7.0, c + f.orthogonal() * 5.0 - f * 4.0, c - f.orthogonal() * 5.0 - f * 4.0]), Color(1, 1, 1))
