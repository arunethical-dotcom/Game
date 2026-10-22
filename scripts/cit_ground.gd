extends Node2D
## Ground inside the citadel walls: courtyard flagstones, garden lawns and gravel paths,
## the sand arena with its stone ring, the training yard, the red carpet and the grand
## steps in front of the throne hall, and the stone bridge over the moat.

const Geo = preload("res://scripts/geo.gd")
const Tiles = preload("res://scripts/tiles.gd")

var areas := []      # [Rect2, texture name, tint]
var circles := []    # [centre, radius, texture name]
var rings := []      # [centre, inner radius, outer radius, texture name]
var steps := []      # Rect2: a flight of steps (drawn as lit stone treads)
var carpets := []    # Rect2
var cobbles := []    # Rect2: cobbled avenue with dark kerbs along its sides
var kerbs := []      # Rect2: dark stone border bands
var beds := []       # [centre, radii]: irregular planting beds with a stone edge
var tex := {}


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for n in ["flag", "lawn", "gravel", "sand", "walltop", "carpet", "stone"]:
		tex[n] = load("res://art/cit_tex_%s.png" % n)


func _tile(t: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	var s := t.get_size()
	draw_texture_rect_region(t, rect, Rect2(Vector2(fposmod(rect.position.x, s.x), fposmod(rect.position.y, s.y)), rect.size), tint)


func _poly(pts: PackedVector2Array, t: Texture2D) -> void:
	var uv := PackedVector2Array()
	for p in pts:
		uv.append(p / t.get_size())
	draw_colored_polygon(pts, Color.WHITE, uv, t)


func _circle_pts(c: Vector2, r: float, n := 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append((c + Vector2.from_angle(TAU * i / n) * r).round())
	return pts


## An irregular rounded outline, so planting beds never look like boxes.
func _blob(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 28
	for i in n:
		var a := TAU * i / n
		var wob := 1.0 + 0.12 * sin(a * 3.0 + c.x * 0.01) + 0.07 * sin(a * 5.0 + c.y * 0.02)
		pts.append((c + Vector2(cos(a) * r.x, sin(a) * r.y) * wob).round())
	return pts


func _draw() -> void:
	# courtyard flagstones under the whole citadel, each tile one of four layouts
	Tiles.fill(self, Geo.CIT_WALL, Tiles.FLAG, [0, 0, 1, 1, 2, 2, 3])
	for a in areas:
		_tile(tex[a[1]], a[0], a[2])
	# a limestone kerb around every lawn so the edges read clearly
	for a in areas:
		if a[1] == "lawn":
			var r: Rect2 = a[0]
			for k in [Rect2(r.position.x, r.position.y, r.size.x, 6), Rect2(r.position.x, r.end.y - 6, r.size.x, 6),
					Rect2(r.position.x, r.position.y, 6, r.size.y), Rect2(r.end.x - 6, r.position.y, 6, r.size.y)]:
				Tiles.band(self, k, Tiles.FLAG)
				draw_rect(k, Color(0.15, 0.12, 0.08, 0.5), false, 1.0)
	for c in cobbles:
		Tiles.fill(self, c, Tiles.COBBLE)
	for k in kerbs:
		Tiles.band(self, k, Tiles.BORDER)
		draw_rect(k, Color(0.12, 0.1, 0.08, 0.6), false, 1.0)
	for b in beds:
		var pts := _blob(b[0], b[1])
		var rim := PackedVector2Array()
		for p in pts:
			rim.append(b[0] + (p - b[0]) * 1.0)
		_poly(pts, tex["lawn"])
		draw_colored_polygon(pts, Color(0.2, 0.13, 0.06, 0.35))
		rim.append(rim[0])
		draw_polyline(rim, Color(0.76, 0.71, 0.62), 4.0)
		draw_polyline(rim, Color(0.3, 0.25, 0.2, 0.7), 1.0)
	for c in circles:
		_poly(_circle_pts(c[0], c[1]), tex[c[2]])
	for r in rings:
		var n := 64
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n + 0.01
			_poly(PackedVector2Array([
				(r[0] + Vector2.from_angle(a0) * r[1]).round(), (r[0] + Vector2.from_angle(a1) * r[1]).round(),
				(r[0] + Vector2.from_angle(a1) * r[2]).round(), (r[0] + Vector2.from_angle(a0) * r[2]).round()]), tex[r[3]])
		draw_arc(r[0], r[1], 0, TAU, 64, Color(0.25, 0.2, 0.15, 0.6), 2.0)
		# arena markings: an inner circle and the royal emblem raked into the sand
		draw_arc(r[0], r[1] * 0.55, 0, TAU, 48, Color(0.6, 0.45, 0.25, 0.35), 2.0)
		draw_arc(r[0], r[1] * 0.2, 0, TAU, 32, Color(0.6, 0.45, 0.25, 0.35), 2.0)
		for k in 8:
			var d := Vector2.from_angle(k * TAU / 8.0)
			draw_line((r[0] + d * r[1] * 0.2).round(), (r[0] + d * r[1] * 0.55).round(), Color(0.6, 0.45, 0.25, 0.3), 1.0)
	for c in carpets:
		_tile(tex["carpet"], c)
		draw_rect(Rect2(c.position.x, c.position.y, 4, c.size.y), Color(0.85, 0.66, 0.3))
		draw_rect(Rect2(c.end.x - 4, c.position.y, 4, c.size.y), Color(0.85, 0.66, 0.3))
	for s in steps:
		var rows := int(s.size.y / 10)
		for i in rows:
			var y: float = s.position.y + i * 10
			var l := 1.08 - i * 0.04
			_tile(tex["walltop"], Rect2(s.position.x, y, s.size.x, 10), Color(l, l, l))
			draw_rect(Rect2(s.position.x, y + 9, s.size.x, 1), Color(0.2, 0.17, 0.14, 0.7))
		draw_rect(Rect2(s.position.x - 6, s.position.y, 6, s.size.y), Color(0.55, 0.5, 0.44))
		draw_rect(Rect2(s.end.x, s.position.y, 6, s.size.y), Color(0.45, 0.4, 0.36))
	# bridge over the moat, with low stone parapets
	var b := Geo.CIT_BRIDGE
	_tile(tex["walltop"], b)
	draw_rect(Rect2(b.position.x, b.end.y - 4, b.size.x, 4), Color(0, 0, 0, 0.25))
	for x in [b.position.x - 6, b.end.x - 4]:
		_tile(tex["stone"], Rect2(x, b.position.y, 10, b.size.y))
		draw_rect(Rect2(x, b.position.y, 10, 2), Color(0.95, 0.9, 0.8))
