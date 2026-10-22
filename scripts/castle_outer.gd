extends RefCounted
## The Royal Castle, outer layer (stage 13), built from the castle reference map and the
## outer-castle kit (art/castle3, imported by tools/import_castle3.py at 2x).
##
## The castle stands on its own lake south of the city, at a realistic scale: the plan is
## 336 x 224 tiles (10,752 x 7,168 px, about 290 x 195 m). Coordinates below are plan tiles
## (Geo.ct / Geo.ctr turn them into world pixels).
##
##   north shore ---- north bridge (165-171) to the road from the city's south gate
##   +--------------------------------------------------------------+  lake (8,12)-(328,212)
##   |   +==========================================+               |
##   |===|   INNER WARD (26,26)-(310,142)             |=== bridges   |
##   |===|   (keep, gardens, wings: next stages)      |=== east/west |
##   |   +=================[ MAIN GATE ]=============+               |
##   |                 moat     | causeway |                         |
##   |   ===towers===== BARBICAN WALL (y 178) =====towers===          |
##   +--------------------------| (165-171)|-------------------------+
##                            south road

const Geo = preload("res://scripts/geo.gd")
const Spr = preload("res://scripts/cit_sprite.gd")
const Story = preload("res://scripts/story.gd")
const A := "castle3/"

const LAKE := [8, 12, 328, 212]
const ISLAND := [26, 26, 310, 142]
const CAUSEWAY := [165, 142, 171, 224]
const NORTH_BRIDGE := [165, 12, 171, 26]
const SIDE_BRIDGES := [[8, 66, 26, 74], [8, 104, 26, 112], [310, 66, 328, 74], [310, 104, 328, 112]]
const NORTH_WALL_Y := 28.0
const SOUTH_WALL_Y := 142.0
const BARBICAN_Y := 178.0
const GATE_X := [165.0, 171.0]

static var main_ref
static var layer: Node2D


static func build(main) -> void:
	main_ref = main
	layer = main.entity_layer
	_town_square(main)
	main.ground_layer.add_child(_Ground.new())
	_lake_collision()
	_main_walls()
	_barbican()
	_shore()
	_people(main)


# ---------------------------------------------------------------- helpers

static func R(a: Array) -> Rect2:
	return Geo.ctr(a[0], a[1], a[2], a[3])


static func _spr(name: String, p: Vector2, solid := Vector2.ZERO, shadow := true) -> Node2D:
	var s = Spr.new()
	s.sprite = name
	s.position = p.round()
	s.solid = solid
	s.shadow = shadow
	layer.add_child(s)
	return s


## A castle3 sprite with its feet at plan tile (x, y).
static func _put(name: String, x: float, y: float, solid := Vector2.ZERO, shadow := true) -> Node2D:
	return _spr(A + name, Geo.ct(x, y), solid, shadow)


static func _block(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	cs.shape = s
	cs.position = r.get_center()
	body.add_child(cs)
	layer.add_child(body)


static func _sub(a: Rect2, b: Rect2) -> Array:
	if not a.intersects(b):
		return [a]
	var i := a.intersection(b)
	var out := []
	if i.position.y > a.position.y:
		out.append(Rect2(a.position.x, a.position.y, a.size.x, i.position.y - a.position.y))
	if i.end.y < a.end.y:
		out.append(Rect2(a.position.x, i.end.y, a.size.x, a.end.y - i.end.y))
	if i.position.x > a.position.x:
		out.append(Rect2(a.position.x, i.position.y, i.position.x - a.position.x, i.size.y))
	if i.end.x < a.end.x:
		out.append(Rect2(i.end.x, i.position.y, a.end.x - i.end.x, i.size.y))
	return out


## Horizontal wall: wall sprites side by side on base line y from x0 to x1 (plan tiles),
## with a collision band 2 tiles deep (the wall's thickness) behind the base line.
static func _hwall(x0: float, x1: float, y: float) -> void:
	var tex: Texture2D = load("res://art/castle3/walls/wall_banner.png")
	var w := float(tex.get_width())
	var wx0 := Geo.ct(x0, 0).x
	var wx1 := Geo.ct(x1, 0).x
	var n := maxi(1, int(ceil((wx1 - wx0) / (w - 8.0))))
	var step := (wx1 - wx0 - w) / maxf(1.0, n - 1) if n > 1 else 0.0
	for i in n:
		var cx := wx0 + w / 2.0 + i * step if n > 1 else (wx0 + wx1) / 2.0
		_spr(A + "walls/wall_banner", Vector2(cx, Geo.ct(0, y).y), Vector2.ZERO, false)
	_block(Rect2(wx0, Geo.ct(0, y - 3).y, wx1 - wx0, 3 * Geo.TILE))


## Vertical wall: a wall walk seen from above, from y0 to y1 at x (plan tiles).
static func _vwall(x: float, y0: float, y1: float) -> void:
	var tex: Texture2D = load("res://art/castle3/walls/walkway_v.png")
	var h := float(tex.get_height())
	var y := Geo.ct(0, y0).y
	var end := Geo.ct(0, y1).y
	while y < end - 4.0:
		var seg := minf(h, end - y)
		var s = _VWall.new()
		s.tex = tex
		s.length = seg
		s.position = Vector2(Geo.ct(x, 0).x, y + seg).round()
		layer.add_child(s)
		y += seg
	_block(Rect2(Geo.ct(x - 1.5, 0).x, Geo.ct(0, y0).y, 3 * Geo.TILE, end - Geo.ct(0, y0).y))


# ---------------------------------------------------------------- the town square

static func _town_square(main) -> void:
	# the old citadel ground in the middle of the city is now an open square
	_spr("castle2/vegetation/fountain", Vector2(0, 40), Vector2(50, 18))
	for p in [Vector2(-90, 110), Vector2(90, 110)]:
		_spr("cit_bench", p, Vector2(44, 10))
	for p in [Vector2(-200, -200), Vector2(200, -200), Vector2(-200, 240), Vector2(200, 240)]:
		_spr("cit_lamp", p, Vector2(10, 6))


# ---------------------------------------------------------------- lake

static func _lake_collision() -> void:
	# the lake blocks everything except the island, the causeway and the bridges
	var parts := [R(LAKE)]
	var open := [R(ISLAND), R(CAUSEWAY), R(NORTH_BRIDGE)]
	for b in SIDE_BRIDGES:
		open.append(R(b))
	for o in open:
		var next := []
		for p in parts:
			next.append_array(_sub(p, o))
		parts = next
	for p in parts:
		_block(p)
	# bridge parapets
	for b in SIDE_BRIDGES:
		var r := R(b)
		_block(Rect2(r.position.x, r.position.y - 4, r.size.x, 8))
		_block(Rect2(r.position.x, r.end.y - 4, r.size.x, 8))
	for b in [NORTH_BRIDGE, [CAUSEWAY[0], 142, CAUSEWAY[2], 212]]:
		var r := R(b)
		_block(Rect2(r.position.x - 4, r.position.y, 8, r.size.y))
		_block(Rect2(r.end.x - 4, r.position.y, 8, r.size.y))


# ---------------------------------------------------------------- main curtain wall

static func _main_walls() -> void:
	# north wall, open in the middle for the north gate and its bridge
	_hwall(ISLAND[0], GATE_X[0] - 6, NORTH_WALL_Y)
	_hwall(GATE_X[1] + 6, ISLAND[2], NORTH_WALL_Y)
	# south (front) wall either side of the main gatehouse
	_hwall(ISLAND[0], GATE_X[0] - 6, SOUTH_WALL_Y)
	_hwall(GATE_X[1] + 6, ISLAND[2], SOUTH_WALL_Y)
	# west and east walls, open where the side bridges come in
	for x in [ISLAND[0] + 1, ISLAND[2] - 1]:
		_vwall(x, NORTH_WALL_Y - 2, 66)
		_vwall(x, 74, 104)
		_vwall(x, 112, SOUTH_WALL_Y - 2)
	# gatehouses: an open arch between two towers, north and south
	for y in [NORTH_WALL_Y, SOUTH_WALL_Y]:
		_put("gates/gate_arch", 168, y, Vector2.ZERO, false)
		_put("towers/tower_blue_a", GATE_X[0] - 3.5, y + 0.6, Vector2(140, 40))
		_put("towers/tower_blue_a", GATE_X[1] + 3.5, y + 0.6, Vector2(140, 40))
		_block(Rect2(Geo.ct(GATE_X[0] - 6, 0).x, Geo.ct(0, y - 3).y, 6 * Geo.TILE, 3 * Geo.TILE))
		_block(Rect2(Geo.ct(GATE_X[1], 0).x, Geo.ct(0, y - 3).y, 6 * Geo.TILE, 3 * Geo.TILE))
	# great corner towers
	for p in [[ISLAND[0] + 1, NORTH_WALL_Y + 0.5], [ISLAND[2] - 1, NORTH_WALL_Y + 0.5],
			[ISLAND[0] + 1, SOUTH_WALL_Y + 0.5], [ISLAND[2] - 1, SOUTH_WALL_Y + 0.5]]:
		_put("towers/tower_tall", p[0], p[1], Vector2(150, 44))
	# towers along the north and south walls
	var north := ["towers/tower_flag", "towers/tower_flag_b"]
	var south := ["towers/tower_blue_c", "towers/tower_blue_d"]
	var xs := [60, 96, 132, 204, 240, 276]
	for i in xs.size():
		_put(north[i % 2], xs[i], NORTH_WALL_Y + 0.6, Vector2(140, 40))
		_put(south[i % 2], xs[i], SOUTH_WALL_Y + 0.6, Vector2(180, 44))
	# towers along the side walls, and small gate towers either side of each side bridge
	for x in [ISLAND[0] + 1, ISLAND[2] - 1]:
		for y in [48, 88, 128]:
			_put("towers/tower_battlement", x, y, Vector2(140, 40))
		for y in [65.4, 76.4, 103.4, 114.4]:
			_put("towers/tower_round", x, y, Vector2(120, 34))


# ---------------------------------------------------------------- barbican

static func _barbican() -> void:
	_hwall(34, GATE_X[0] - 6, BARBICAN_Y)
	_hwall(GATE_X[1] + 6, 302, BARBICAN_Y)
	_put("gates/gate_arch", 168, BARBICAN_Y, Vector2.ZERO, false)
	for x in [GATE_X[0] - 3.5, GATE_X[1] + 3.5]:
		_put("towers/tower_blue_b", x, BARBICAN_Y + 0.6, Vector2(140, 40))
	var kinds := ["towers/tower_battlement_b", "towers/tower_cone_a", "towers/tower_battlement", "towers/tower_cone_b"]
	var xs := [34, 66, 98, 130, 206, 238, 270, 302]
	for i in xs.size():
		_put(kinds[i % 4], xs[i], BARBICAN_Y + 0.6, Vector2(140, 40))
	# torches and guardian statues along the causeway
	for y in [150, 162, 174, 190, 202]:
		for x in [164.6, 171.4]:
			_put("decor/torch", x, y, Vector2(10, 6))
			main_ref.lights.add(Geo.ct(x, y) - Vector2(0, 100), "torch")
	for x in [163.4, 172.6]:
		_put("decor/angel_a" if x < 168 else "decor/angel_b", x, 214.5, Vector2(70, 24))


# ---------------------------------------------------------------- shore, cliffs, waterfalls

static func _shore() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var cliffs := ["cliffs/cliff_a", "cliffs/cliff_b", "cliffs/cliff_c", "cliffs/cliff_d"]
	var trees := ["trees/pine_a", "trees/pine_b", "trees/pine_big", "trees/pine_pair", "trees/cypress", "trees/bush_round"]
	# rocky banks along the west, east and south shores; the north shore is lower ground
	for y in range(16, 210, 9):
		if _near_bridge(y):
			continue
		_put(cliffs[rng.randi() % 4], LAKE[0] - 4, y + 8, Vector2(160, 50))
		_put(cliffs[rng.randi() % 4], LAKE[2] + 4, y + 8, Vector2(160, 50))
		_put(trees[rng.randi() % trees.size()], LAKE[0] - 11 - rng.randf_range(0, 4), y + 5, Vector2(30, 10))
		_put(trees[rng.randi() % trees.size()], LAKE[2] + 11 + rng.randf_range(0, 4), y + 5, Vector2(30, 10))
	for x in range(14, 326, 9):
		if absf(x - 168) < 12:
			continue
		_put(cliffs[rng.randi() % 4], x, LAKE[3] + 8, Vector2(160, 50))
		_put(trees[rng.randi() % trees.size()], x + 3, LAKE[3] + 13, Vector2(30, 10))
	# trees along the north shore, leaving the road clear
	for x in range(12, 326, 7):
		if absf(x - 168) < 10:
			continue
		_put(trees[rng.randi() % trees.size()], x + rng.randf_range(-2, 2), LAKE[1] - 1.5 - rng.randf_range(0, 6), Vector2(30, 10))
	# waterfalls: the lake spills out at its south-west and south-east corners, and a stream
	# falls into it from the north-west hills
	_put("water/waterfall_big", 30, LAKE[3] + 12, Vector2.ZERO, false)
	_put("water/waterfall_big", 306, LAKE[3] + 12, Vector2.ZERO, false)
	_put("water/waterfall_mid", 18, LAKE[1] + 7, Vector2.ZERO, false)


static func _near_bridge(y: float) -> bool:
	for b in SIDE_BRIDGES:
		if y > b[1] - 10 and y < b[3] + 4:
			return true
	return false


# ---------------------------------------------------------------- people

static func _people(main) -> void:
	main._npc("guard", Geo.ct(163.6, 216), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.ct(172.4, 216), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.ct(163.8, 10.5), "Castle guard", Story.CASTLE_NORTH_GUARD)
	main._npc("guard", Geo.ct(172.2, 10.5), "Castle guard", Story.CASTLE_NORTH_GUARD)


# ---------------------------------------------------------------- drawing

## A piece of side wall seen from above (the wall walk), y-sorted at its south end.
class _VWall extends Node2D:
	var tex: Texture2D
	var length := 100.0

	func _draw() -> void:
		var w := tex.get_width()
		draw_texture_rect_region(tex, Rect2(-w / 2.0, -length, w, length), Rect2(0, 0, w, length))
		draw_rect(Rect2(-w / 2.0 + 4, 0, w - 8, 10), Color(0, 0, 0, 0.18))


## Ground of the castle: the lake (moving water), the island, causeway and bridges.
class _Ground extends Node2D:
	const Geo = preload("res://scripts/geo.gd")
	const WATER = preload("res://art/castle3/tex_water.png")
	const FLAG = preload("res://art/castle3/tex_flag.png")
	const PAVE = preload("res://art/castle3/tex_flag_b.png")
	const TOP = preload("res://art/cit_tex_walltop.png")
	const SHADER := """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV + vec2(TIME * 0.006, TIME * 0.003);
	vec4 c = texture(TEXTURE, uv);
	c.rgb += 0.025 * sin(TIME * 1.4 + (UV.x + UV.y) * 9.0);
	COLOR = c;
}
"""
	var water: Node2D

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		water = Node2D.new()
		water.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		var sh := Shader.new()
		sh.code = SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		water.material = mat
		water.show_behind_parent = true
		water.draw.connect(func():
			var r := _r([8, 12, 328, 212])
			water.draw_texture_rect_region(WATER, r, Rect2(r.position, r.size)))
		add_child(water)

	func _r(a: Array) -> Rect2:
		return Geo.ctr(a[0], a[1], a[2], a[3])

	func _tile(t: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
		draw_texture_rect_region(t, rect, Rect2(rect.position, rect.size), tint)

	func _draw() -> void:
		var lake := _r([8, 12, 328, 212])
		# stone embankment around the lake
		draw_rect(lake.grow(6), Color(0.42, 0.4, 0.38), false, 12.0)
		draw_rect(lake.grow(12), Color(0.2, 0.18, 0.16), false, 2.0)
		# island: a stone quay all round the walls, grass inside (the inner ward comes next)
		var isl := _r([26, 26, 310, 142])
		draw_rect(isl.grow(8), Color(0.36, 0.34, 0.33), false, 16.0)
		_tile(FLAG, isl)
		_tile(PAVE, _r([30, 30, 306, 138]), Color(0.98, 0.98, 0.96))
		draw_rect(_r([36, 36, 300, 132]), Color(0.36, 0.52, 0.26))
		# the processional way from the main gate to the north gate
		_tile(PAVE, _r([163, 30, 173, 142]))
		draw_rect(_r([163, 30, 173, 142]), Color(0.25, 0.22, 0.2), false, 2.0)
		# causeway, north bridge and side bridges
		for b in [[165, 142, 171, 224], [165, 12, 171, 26], [8, 66, 26, 74], [8, 104, 26, 112], [310, 66, 328, 74], [310, 104, 328, 112]]:
			var r := _r(b)
			_tile(PAVE, r)
			var vertical: bool = r.size.y > r.size.x
			if vertical:
				_tile(TOP, Rect2(r.position.x - 8, r.position.y, 12, r.size.y))
				_tile(TOP, Rect2(r.end.x - 4, r.position.y, 12, r.size.y))
				draw_rect(Rect2(r.position.x - 8, r.position.y, r.size.x + 16, r.size.y), Color(0.15, 0.12, 0.1), false, 2.0)
			else:
				_tile(TOP, Rect2(r.position.x, r.position.y - 8, r.size.x, 12))
				_tile(TOP, Rect2(r.position.x, r.end.y - 4, r.size.x, 12))
				draw_rect(Rect2(r.position.x, r.end.y + 8, r.size.x, 10), Color(0, 0.05, 0.12, 0.35))
		# the barbican wall's footing in the water
		draw_rect(_r([33, 176.5, 303, 179]), Color(0.38, 0.36, 0.34))
