extends Node2D
## Smooth roads and paved areas, drawn as textured shapes instead of square tiles,
## so curves and diagonals stay clean. Textures repeat across the world 1:1.
##
## Draw order: soft grass shadow -> kerb stones -> road surface, each pass for all roads
## together, so crossings merge cleanly.

const Geo = preload("res://scripts/geo.gd")
const TEX := {
	"brick": preload("res://art/tex_brick.png"),
	"kerb": preload("res://art/tex_kerb.png"),
	"plaza": preload("res://art/tex_plaza.png"),
	"cobble": preload("res://art/tex_cobble.png"),
	"dirt": preload("res://art/tex_dirt.png"),
	"field": preload("res://art/tex_field.png"),
	"cliff": preload("res://art/tex_cliff.png"),
	"rim": preload("res://art/tex_rim.png"),
}

const STREET_HALF := 30.0
const ROAD_HALF := 34.0

var streets := []   # polylines inside the city
var roads := []     # dirt roads outside
var areas := []     # [polygon, texture name, border texture name or ""]


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_build()


func _arc(r: float, a0: float, a1: float, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		pts.append((Vector2.from_angle(lerpf(a0, a1, float(i) / steps)) * r).round())
	return pts


func _build() -> void:
	# City streets: 8 spokes from the castle to the wall, the ring road, the castle ring
	for k in 8:
		var d := Vector2.from_angle(-PI / 2.0 + k * PI / 4.0)
		var start := Geo.TOWN_SQUARE.end.y if k % 2 == 0 else Geo.RING_ROAD   # the four avenues run to the town square
		streets.append(PackedVector2Array([(d * start).round(), (d * (Geo.R_WALL + 40.0)).round()]))
	# rings are drawn as four overlapping arcs (a closed loop would fill its middle)
	for q in 4:
		streets.append(_arc(Geo.RING_ROAD, q * TAU / 4.0, (q + 1) * TAU / 4.0 + 0.04, 60))
	# Dirt roads outside the walls
	roads.append(PackedVector2Array(Geo.SERPENT_WAY))
	roads.append(PackedVector2Array(Geo.ELDER_PATH))
	roads.append(PackedVector2Array(Geo.SOUTH_ROAD))
	# Castle courtyard (cobbles), market square (pale stone), fields
	var m := _arc(Geo.MARKET_R.x + 5.0, -1.50, -1.24, 30)
	m.append_array(_arc(Geo.MARKET_R.y - 2.0, -1.24, -1.50, 40))
	areas.append([m, "plaza", "kerb"])
	var f := _arc(Geo.MARKET_R.x + 15.0, -1.24, -1.04, 24)
	f.append_array(_arc(Geo.MARKET_R.y - 10.0, -1.04, -1.24, 30))
	areas.append([f, "field", "dirt"])


func _fill(poly: PackedVector2Array, tex: Texture2D, tint := Color.WHITE) -> void:
	if poly.size() < 3:
		return
	var uv := PackedVector2Array()
	var s := tex.get_size()
	for p in poly:
		uv.append(p / s)
	draw_colored_polygon(poly, tint, uv, tex)


func _stroke(line: PackedVector2Array, half: float, tex: Texture2D, tint := Color.WHITE) -> void:
	for poly in Geometry2D.offset_polyline(line, half, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
		_fill(poly, tex, tint)


func _shadow(poly_or_line: PackedVector2Array, half: float, is_line: bool) -> void:
	var polys: Array
	if is_line:
		polys = Geometry2D.offset_polyline(poly_or_line, half, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	else:
		polys = Geometry2D.offset_polygon(poly_or_line, half, Geometry2D.JOIN_ROUND)
	for p in polys:
		draw_colored_polygon(p, Color(0.12, 0.22, 0.08, 0.28))


func _ring(r0: float, r1: float, tex: Texture2D, segs: int, shade_north := 0.0) -> void:
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs + 0.002
		var quad := PackedVector2Array([
			Vector2.from_angle(a0) * r0, Vector2.from_angle(a1) * r0,
			Vector2.from_angle(a1) * r1, Vector2.from_angle(a0) * r1])
		# faces on the far (north) side are in shadow
		var l := 1.0 - shade_north * maxf(0.0, -sin((a0 + a1) * 0.5))
		_fill(quad, tex, Color(l, l, l))


func _draw() -> void:
	# 0. the cliff around the plateau: a pale rim on top, the rock face going down, a shadow below
	var rc := Geo.R_CLIFF
	var hc := Geo.CLIFF_HALF
	for i in 260:
		var a0 := TAU * i / 260.0
		var a1 := TAU * (i + 1) / 260.0 + 0.002
		var q := PackedVector2Array([
			Vector2.from_angle(a0) * (rc + hc), Vector2.from_angle(a1) * (rc + hc),
			Vector2.from_angle(a1) * (rc + hc + 26.0), Vector2.from_angle(a0) * (rc + hc + 26.0)])
		draw_colored_polygon(q, Color(0.05, 0.1, 0.03, 0.3))
	_ring(rc - hc + 14.0, rc + hc, TEX["cliff"], 260, 0.35)
	_ring(rc - hc, rc - hc + 16.0, TEX["rim"], 260)

	# 1. soft dark edge where paving meets grass
	for s in streets:
		_shadow(s, STREET_HALF + 8.0, true)
	for r in roads:
		_shadow(r, ROAD_HALF + 6.0, true)
	for a in areas:
		if a[2] != "":
			_shadow(a[0], 9.0, false)
	# 2. borders
	for s in streets:
		_stroke(s, STREET_HALF + 5.0, TEX["kerb"])
	for a in areas:
		if a[2] != "":
			for p in Geometry2D.offset_polygon(a[0], 5.0, Geometry2D.JOIN_ROUND):
				_fill(p, TEX[a[2]])
	# 3. surfaces
	for a in areas:
		_fill(a[0], TEX[a[1]])
	for r in roads:
		_stroke(r, ROAD_HALF, TEX["dirt"])
	for s in streets:
		_stroke(s, STREET_HALF, TEX["brick"])
