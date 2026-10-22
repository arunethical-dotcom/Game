extends StaticBody2D
## A citadel building: stone front with windows and doors, and a blue slate hip roof.
## Seen in 3/4 view: the roof sits above the footprint, raised by the wall height.
##
## Enterable buildings have an interior (floor, back wall, carpet...) drawn on the ground
## underneath. When Kael steps inside, the roof and tall front fade away so you see the
## room, and a low cut-down front wall (cit_cutaway.gd) takes their place.
##
## Position = middle of the front (south) wall's base, so y-sorting works.

const T_STONE = preload("res://art/cit_tex_stone.png")
const T_TOP = preload("res://art/cit_tex_walltop.png")
const T_ROOF = preload("res://art/cit_tex_roof.png")
const WINDOW = preload("res://art/cit_window.png")
const WINDOW_TALL = preload("res://art/cit_window_stained.png")
const DOOR = preload("res://art/cit_door.png")
const DOOR_OPEN = preload("res://art/cit_door_open.png")
const DOOR_BIG = preload("res://art/cit_door_big.png")
const CREST = preload("res://art/cit_crest.png")
const BANNER = preload("res://art/cit_banner_blue.png")
const KEEP = preload("res://art/cit_tower.png")

const WALL := 16            # wall thickness for collision

var main
var footprint := Rect2()    # ground area in world coordinates
var wall_h := 112
var doors := []             # door centres (world x) on the front wall
var big_door := false
var enterable := false
var keep_spire := false     # a tall tower rising from the middle of the roof
var banners := true
var interior: Node2D        # the floor node, created by the builder
var cutaway: Node2D         # low front wall shown while Kael is inside
var fade := 1.0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	collision_layer = 1
	collision_mask = 0
	var f := _local(footprint)
	if enterable:
		add_to_group("enterable_buildings")
		# side and back walls, and the front wall broken by the doors
		_box(Rect2(f.position.x, f.position.y, f.size.x, WALL))
		_box(Rect2(f.position.x, f.position.y, WALL, f.size.y))
		_box(Rect2(f.end.x - WALL, f.position.y, WALL, f.size.y))
		var gap := 60.0 if not big_door else 76.0
		var xs := [f.position.x]
		for d in doors:
			xs.append(d - position.x - gap / 2.0)
			xs.append(d - position.x + gap / 2.0)
		xs.append(f.end.x)
		for i in range(0, xs.size(), 2):
			if xs[i + 1] > xs[i]:
				_box(Rect2(xs[i], f.end.y - WALL, xs[i + 1] - xs[i], WALL))
		cutaway = preload("res://scripts/cit_cutaway.gd").new()
		cutaway.x0 = f.position.x
		cutaway.x1 = f.end.x
		for d in doors:
			cutaway.gaps.append([d - position.x - gap / 2.0, d - position.x + gap / 2.0])
		cutaway.position = position
		cutaway.visible = false
		get_parent().add_child.call_deferred(cutaway)
	else:
		_box(f)


func _box(r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.get_center()
	add_child(cs)


func _local(r: Rect2) -> Rect2:
	return Rect2(r.position - position, r.size)


func _process(delta: float) -> void:
	if not enterable or main == null:
		return
	var inside := footprint.grow(-4).has_point(main.player.global_position)
	var target := 0.0 if inside else 1.0
	if absf(fade - target) > 0.001:
		fade = move_toward(fade, target, delta * 4.0)
		modulate.a = fade
		cutaway.visible = fade < 0.999
		cutaway.modulate.a = 1.0 - fade


func _tile(tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	var s := tex.get_size()
	var world := rect.position + position
	draw_texture_rect_region(tex, rect, Rect2(Vector2(fposmod(world.x, s.x), fposmod(world.y, s.y)), rect.size), tint)


func _poly(pts: PackedVector2Array, tex: Texture2D, tint: Color) -> void:
	var uv := PackedVector2Array()
	var s := tex.get_size()
	for p in pts:
		uv.append((p + position) / s)
	draw_colored_polygon(pts, tint, uv, tex)


func _dormer(p: Vector2) -> void:
	# a small gabled window sticking out of the roof
	var w := 26.0
	_poly(PackedVector2Array([p + Vector2(-w / 2 - 3, 0), p + Vector2(0, -16), p + Vector2(w / 2 + 3, 0)]), T_ROOF, Color(1.12, 1.12, 1.15))
	draw_rect(Rect2(p + Vector2(-w / 2 + 2, 0), Vector2(w - 4, 18)), Color(0.78, 0.74, 0.66))
	draw_rect(Rect2(p + Vector2(-6, 3), Vector2(12, 12)), Color(0.18, 0.14, 0.1))
	draw_rect(Rect2(p + Vector2(-5, 4), Vector2(10, 10)), Color(0.95, 0.72, 0.32))
	draw_rect(Rect2(p + Vector2(-1, 4), Vector2(1, 10)), Color(0.35, 0.25, 0.15))
	draw_rect(Rect2(p + Vector2(-w / 2 + 2, 18), Vector2(w - 4, 2)), Color(0.08, 0.12, 0.22))
	draw_polyline(PackedVector2Array([p + Vector2(-w / 2 - 3, 0), p + Vector2(0, -16), p + Vector2(w / 2 + 3, 0)]), Color(0.08, 0.12, 0.22), 1.0)


func _chimney(p: Vector2) -> void:
	_tile(T_STONE, Rect2(p + Vector2(0, -26), Vector2(18, 26)))
	draw_rect(Rect2(p + Vector2(-2, -30), Vector2(22, 5)), Color(0.72, 0.68, 0.6))
	draw_rect(Rect2(p + Vector2(-2, -30), Vector2(22, 1)), Color(0.9, 0.86, 0.78))
	draw_rect(Rect2(p + Vector2(14, -26), Vector2(4, 26)), Color(0, 0, 0, 0.2))


func _draw() -> void:
	var f := _local(footprint)
	var x0 := f.position.x
	var x1 := f.end.x
	var y0 := f.position.y
	var y1 := f.end.y
	var h := float(wall_h)

	# ground shadow in front
	draw_rect(Rect2(x0 + 6, y1, f.size.x, 6), Color(0.05, 0.08, 0.03, 0.3))
	draw_rect(Rect2(x0 + 10, y1 + 6, f.size.x - 4, 6), Color(0.05, 0.08, 0.03, 0.15))

	# --- front wall
	_tile(T_STONE, Rect2(x0, y1 - h, f.size.x, h))
	draw_rect(Rect2(x0, y1 - 10, f.size.x, 10), Color(0, 0, 0, 0.14))
	_tile(T_TOP, Rect2(x0 - 2, y1 - h - 6, f.size.x + 4, 6))   # cornice
	draw_rect(Rect2(x0 - 2, y1 - h, f.size.x + 4, 1), Color(0.15, 0.12, 0.1, 0.8))

	# windows in one or two rows, skipping the doors
	var rows := [y1 - h + 18] if h < 110 else [y1 - h + 16, y1 - h + 62]
	var step := 52
	for row in rows:
		var x := x0 + 30
		while x < x1 - 30:
			var clear := true
			for d in doors:
				if absf(x - (d - position.x)) < (60 if big_door else 46):
					clear = false
			if clear and (row == rows[0] or h >= 110):
				draw_texture(WINDOW, Vector2(roundf(x - 7), row))
			x += step

	# doors, banners and the royal crest
	for d in doors:
		var dx: float = d - position.x
		var tex := DOOR_BIG if big_door else (DOOR_OPEN if enterable else DOOR)
		var dw := tex.get_width()
		draw_texture(tex, Vector2(roundf(dx - dw / 2.0), y1 - tex.get_height()))
		if banners:
			for side in [-1, 1]:
				draw_texture(BANNER, Vector2(roundf(dx + side * (dw / 2.0 + 20) - 11), y1 - h + 8))
		draw_texture(CREST, Vector2(roundf(dx - 17), y1 - h + 6))

	# --- hip roof: front slope, side hips, back slope, ridge
	var eave_f := y1 - h - 6
	var eave_b := y0 - h - 6
	var rise := minf(f.size.y * 0.32, 150.0)
	var ridge := roundf((y0 + y1) * 0.5 - h - rise)
	var hip := minf(f.size.y * 0.42, f.size.x * 0.3)
	var o := 10.0
	var back := PackedVector2Array([Vector2(x0 - o, eave_b), Vector2(x1 + o, eave_b), Vector2(x1 - hip, ridge), Vector2(x0 + hip, ridge)])
	var front := PackedVector2Array([Vector2(x0 - o, eave_f), Vector2(x0 + hip, ridge), Vector2(x1 - hip, ridge), Vector2(x1 + o, eave_f)])
	var left := PackedVector2Array([Vector2(x0 - o, eave_b), Vector2(x0 + hip, ridge), Vector2(x0 - o, eave_f)])
	var right := PackedVector2Array([Vector2(x1 + o, eave_b), Vector2(x1 + o, eave_f), Vector2(x1 - hip, ridge)])
	if ridge > eave_b:
		_poly(back, T_ROOF, Color(0.72, 0.74, 0.82))
	_poly(left, T_ROOF, Color(1.08, 1.08, 1.1))
	_poly(right, T_ROOF, Color(0.82, 0.84, 0.9))
	_poly(front, T_ROOF, Color(0.98, 0.98, 1.0))
	var edge := Color(0.08, 0.12, 0.22)
	draw_polyline(PackedVector2Array([Vector2(x0 - o, eave_f), Vector2(x1 + o, eave_f)]), edge, 2.0)
	draw_polyline(PackedVector2Array([Vector2(x0 - o, eave_f), Vector2(x0 - o, eave_b), Vector2(x1 + o, eave_b), Vector2(x1 + o, eave_f)]), edge, 1.0)
	draw_line(Vector2(x0 + hip, ridge), Vector2(x1 - hip, ridge), Color(0.85, 0.66, 0.3), 3.0)
	draw_line(Vector2(x0 - o, eave_f), Vector2(x0 + hip, ridge), Color(0.6, 0.72, 0.95, 0.7), 1.0)
	draw_line(Vector2(x1 + o, eave_f), Vector2(x1 - hip, ridge), Color(0.1, 0.16, 0.3), 1.0)
	# dormer windows along the front slope and stone chimneys behind the ridge
	# raised seams running up the front slope
	var seams := int(f.size.x / 140)
	for i in range(1, seams):
		var bx := lerpf(x0 - o, x1 + o, float(i) / seams)
		var tx := lerpf(x0 + hip, x1 - hip, float(i) / seams)
		draw_line(Vector2(roundf(bx), eave_f), Vector2(roundf(tx), ridge), Color(0.5, 0.64, 0.9, 0.55), 2.0)
		draw_line(Vector2(roundf(bx) + 2, eave_f), Vector2(roundf(tx) + 2, ridge), Color(0.06, 0.1, 0.2, 0.5), 1.0)
	# rows of dormers: more rows on taller roofs, each row as wide as the slope there
	var dormer_rows := [0.45] if (eave_f - ridge) < 260 else [0.28, 0.58]
	for t in dormer_rows:
		var dy := roundf(lerpf(eave_f, ridge, t))
		var row_l := lerpf(x0 - o, x0 + hip, t) + 40
		var row_r := lerpf(x1 + o, x1 - hip, t) - 40
		var count := maxi(1, int((row_r - row_l) / 96.0) + 1)
		for k in count:
			var dxp := row_l + (row_r - row_l) * (k + 0.5) / count
			_dormer(Vector2(roundf(dxp), dy))
	for cx in [x0 + hip + 30, x1 - hip - 50]:
		_chimney(Vector2(roundf(cx), ridge - 4))
	# gold finials along the ridge
	for i in range(0, 5):
		var fx := roundf(lerpf(x0 + hip, x1 - hip, i / 4.0))
		draw_rect(Rect2(fx - 1, ridge - 8, 2, 8), Color(0.85, 0.66, 0.3))
		draw_rect(Rect2(fx - 2, ridge - 10, 4, 3), Color(1.0, 0.85, 0.45))
	if keep_spire:
		var kw := KEEP.get_width()
		var kh := KEEP.get_height()
		draw_texture(KEEP, Vector2(roundf(-kw / 2.0), ridge + 40 - kh))
