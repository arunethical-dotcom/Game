extends StaticBody2D
## One straight piece of a stone wall (the city wall or the castle wall).
## Set `gate` to draw closed wooden gate doors on it.

var a := Vector2.ZERO
var b := Vector2.ZERO
var height := 58.0
var thick := 28.0
var gate := false
var stone := Color(0.66, 0.62, 0.54)
const STONE_TEX = preload("res://art/wall_stone.png")


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(a.distance_to(b) + 6.0, thick)
	cs.shape = r
	cs.rotation = (b - a).angle()
	cs.position = (a + b) * 0.5
	add_child(cs)


func _uv(pts: PackedVector2Array) -> PackedVector2Array:
	# texture repeats every 32 world units (16 pixels at 2x), anchored to the world
	var uv := PackedVector2Array()
	for p in pts:
		uv.append((p + position) / 32.0)
	return uv


func _draw() -> void:
	var up := Vector2(0, -height)
	var n := (b - a).orthogonal().normalized() * thick * 0.5
	if n.y < 0.0:
		n = -n
	var shade := 0.82 + 0.18 * absf((b - a).normalized().x)
	# shadow at the base
	draw_colored_polygon(PackedVector2Array([a - n * 1.6, b - n * 1.6, b + n * 1.6, a + n * 1.6]), Color(0, 0, 0, 0.18))
	# wall face (brick texture) and top walkway
	var face := PackedVector2Array([a + n, b + n, b + n + up, a + n + up])
	draw_colored_polygon(face, Color(shade, shade, shade * 0.97), _uv(face), STONE_TEX)
	var top := PackedVector2Array([a - n + up, b - n + up, b + n + up, a + n + up])
	draw_colored_polygon(top, Color(1.12, 1.1, 1.05), _uv(top), STONE_TEX)
	draw_line(a + n + up, b + n + up, Color(0.45, 0.42, 0.38), 2.0)
	draw_line(a + n, b + n, Color(0.3, 0.28, 0.25), 2.0)
	# battlements, snapped to the 2px pixel grid
	var len := a.distance_to(b)
	var steps := int(len / 12.0)
	for i in steps:
		if i % 2 == 0:
			var p := (a.lerp(b, (i + 0.5) / steps) + n + up)
			p = (p / 2.0).round() * 2.0
			draw_rect(Rect2(p + Vector2(-4, -8), Vector2(8, 8)), Color(0.86, 0.82, 0.76))
			draw_rect(Rect2(p + Vector2(-4, -8), Vector2(8, 2)), Color(0.95, 0.93, 0.88))
			draw_rect(Rect2(p + Vector2(2, -6), Vector2(2, 6)), Color(0.6, 0.57, 0.52))
	if gate:
		var m := ((a + b) * 0.5 + n)
		m = (m / 2.0).round() * 2.0
		draw_rect(Rect2(m + Vector2(-32, -48), Vector2(64, 48)), Color(0.18, 0.12, 0.08))
		draw_rect(Rect2(m + Vector2(-28, -44), Vector2(56, 44)), Color(0.45, 0.28, 0.15))
		for k in 7:
			draw_rect(Rect2(m + Vector2(-28 + k * 8, -44), Vector2(2, 44)), Color(0.34, 0.2, 0.1))
		for k in 3:
			draw_rect(Rect2(m + Vector2(-28, -36 + k * 12), Vector2(56, 4)), Color(0.32, 0.33, 0.36))
			draw_rect(Rect2(m + Vector2(-28, -36 + k * 12), Vector2(56, 2)), Color(0.55, 0.56, 0.6))
