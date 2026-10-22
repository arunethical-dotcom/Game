extends RefCounted
## The Royal Castle's whole outer shell, traced from the reference map
## (source_art/castle3/reference_map.png) and built from the castle kit (art/castle3).
##
## Every coordinate below is a point on the reference map (1536 x 1024 px). Geo.rp() turns
## it into world pixels at 3 world px per map px, the scale the kit's sprites are drawn at,
## so each tower, wall and building lands where it stands in the picture.
##
## Walls follow the map's real outline (diagonals included): each wall line is drawn
## with the kit's stone face, slate wall walk and merlons, cut into short y-sorted pieces.
## Towers, the palace, chapels, halls, statues, trees and props are kit sprites.

const Geo = preload("res://scripts/geo.gd")
const Spr = preload("res://scripts/cit_sprite.gd")
const Story = preload("res://scripts/story.gd")
const A := "castle3/"

# ---------------------------------------------------------------- the traced plan

# land around the lake (grass); everything else in the map is water
const LAND := [
	[[0, 0], [1180, 0], [1170, 60], [1120, 116], [400, 112], [330, 128], [240, 112], [140, 118], [60, 120], [0, 126]],   # north hills
	[[1262, 0], [1536, 0], [1536, 380], [1478, 362], [1476, 300], [1440, 196], [1380, 150], [1318, 128], [1278, 86]],      # north-east (town shore)
	[[0, 166], [52, 170], [66, 232], [56, 300], [36, 360], [36, 420], [0, 440]],                                       # west shore
	[[0, 512], [66, 512], [96, 560], [112, 640], [112, 720], [140, 800], [176, 878], [214, 960], [232, 1024], [0, 1024]],  # south-west
	[[1536, 512], [1470, 512], [1440, 560], [1424, 640], [1424, 720], [1396, 800], [1360, 878], [1322, 960], [1304, 1024], [1536, 1024]],  # south-east
	[[600, 992], [936, 992], [956, 1024], [580, 1024]],                                                               # south shore (causeway end)
]
# the castle's own ground, inside and under the main curtain wall
const WARD := [[357, 110], [1179, 110], [1312, 198], [1330, 505], [1278, 716], [258, 716], [206, 505], [224, 198]]
# walkable bridge decks and the causeway
const DECKS := [
	[[44, 318], [240, 318], [240, 348], [44, 348]],         # west bridge
	[[1296, 318], [1492, 318], [1492, 348], [1296, 348]],   # east bridge
	[[48, 528], [240, 528], [240, 560], [48, 560]],          # south-west bridge
	[[1296, 528], [1488, 528], [1488, 560], [1296, 560]],    # south-east bridge
	[[1236, 176], [1256, 150], [1452, 98], [1466, 128], [1272, 192]],   # north-east bridge to the town shore
	[[727, 690], [809, 690], [809, 1000], [727, 1000]],      # causeway from the main gate
]
# green terraces, the market yard (dirt) and the training ground (sand)
const LAWNS := [
	[[300, 132], [505, 132], [512, 200], [452, 222], [300, 212]],
	[[1236, 132], [1031, 132], [1024, 200], [1084, 222], [1236, 212]],
	[[248, 250], [452, 250], [480, 330], [480, 444], [252, 444]],
	[[1288, 250], [1084, 250], [1056, 330], [1056, 444], [1284, 444]],
	[[478, 262], [552, 330], [478, 330]], [[1058, 262], [984, 330], [1058, 330]],
	[[500, 520], [690, 520], [690, 612], [500, 612]], [[846, 520], [1036, 520], [1036, 612], [846, 612]],
	[[290, 600], [470, 600], [470, 680], [300, 680]], [[1066, 600], [1246, 600], [1236, 680], [1066, 680]],
]
const DIRT := [[[244, 472], [400, 472], [400, 596], [244, 596]]]
const SAND := [[[1136, 472], [1292, 472], [1292, 596], [1136, 596]]]

# wall lines: [[from, to], ...], each with its height (face) and depth (wall walk)
const MAIN_WALL := [
	[[357, 125], [520, 125]], [[1016, 125], [1179, 125]],
	[[357, 125], [237, 205]], [[237, 205], [232, 316]], [[231, 350], [222, 505]],
	[[222, 505], [228, 526]], [[240, 562], [272, 692]], [[272, 692], [727, 692]],
	[[809, 692], [1264, 692]], [[1264, 692], [1296, 562]], [[1308, 526], [1314, 505]],
	[[1314, 505], [1305, 350]], [[1304, 316], [1299, 205]], [[1299, 205], [1276, 190]],
	[[1230, 158], [1179, 125]],
]
const BARBICAN := [
	[[150, 852], [295, 862]], [[295, 862], [395, 922]], [[395, 922], [512, 922]], [[512, 922], [690, 938]],
	[[846, 938], [1024, 922]], [[1024, 922], [1141, 922]], [[1141, 922], [1241, 862]], [[1241, 862], [1386, 852]],
]
const OUTER_LINKS := [   # walls joining the towers that stand in the water
	[[150, 205], [232, 205]], [[1304, 205], [1386, 205]],
	[[118, 262], [86, 306]], [[1418, 262], [1450, 306]],
	[[80, 380], [70, 512]], [[1456, 380], [1466, 512]],
]
const INNER_WALLS := [
	[[300, 210], [455, 218]], [[455, 218], [520, 206]], [[1236, 210], [1081, 218]], [[1081, 218], [1016, 206]],
	[[468, 256], [560, 330]], [[560, 330], [686, 330]], [[1068, 256], [976, 330]], [[976, 330], [850, 330]],
	[[500, 452], [686, 452]], [[850, 452], [1036, 452]],
	[[262, 462], [360, 462]], [[402, 462], [480, 462]], [[1056, 462], [1134, 462]], [[1176, 462], [1274, 462]],
]

static var main_ref
static var layer: Node2D
static var walls_body: StaticBody2D


static func build(main) -> void:
	main_ref = main
	layer = main.entity_layer
	walls_body = StaticBody2D.new()
	walls_body.collision_layer = 1
	walls_body.collision_mask = 0
	layer.add_child(walls_body)
	_town_square()
	main.ground_layer.add_child(_Ground.new())
	_water_collision()
	_walls()
	_towers()
	_buildings(main)
	_courts(main)
	_trees_and_shore()
	_people(main)


# ---------------------------------------------------------------- helpers

static func P(p) -> Vector2:
	return Geo.rp(p[0], p[1])


static func poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(P(p))
	return out


static func _spr(name: String, p: Vector2, solid := Vector2.ZERO, shadow := true, lift := 0, scale := 1.0) -> Node2D:
	var s = Spr.new()
	s.sprite = name
	s.position = p.round()
	s.solid = solid
	s.shadow = shadow
	s.lift = lift
	if scale != 1.0:
		s.scale = Vector2(scale, scale)
	layer.add_child(s)
	return s


## A kit sprite with its feet at reference-map point (x, y).
static func _put(name: String, x: float, y: float, solid := Vector2.ZERO, shadow := true) -> Node2D:
	if name.begins_with("buildings/"):
		shadow = false
	return _spr(A + name, Geo.rp(x, y), solid, shadow)


static func _box(center: Vector2, size: Vector2, angle := 0.0) -> void:
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = size
	cs.shape = s
	cs.position = center
	cs.rotation = angle
	walls_body.add_child(cs)


## A wall line from map point a to b: face height h, wall-walk depth d (world px).
static func _wall(a, b, h: float, d: float, banners := false, arches := false) -> void:
	var pa := P(a)
	var pb := P(b)
	var dir := (pb - pa).normalized()
	var n := Vector2(dir.y, -dir.x)
	if n.y > 0.0 or (absf(n.y) < 0.001 and n.x < 0.0):
		n = -n   # the wall walk always extends away from the viewer (north)
	var length := pa.distance_to(pb)
	var pieces := maxi(1, int(ceil(length / 48.0)))
	for i in pieces:
		var q0 := pa.lerp(pb, float(i) / pieces)
		var q1 := pa.lerp(pb, float(i + 1) / pieces)
		var w = _WallPiece.new()
		w.position = (q0 if q0.y > q1.y else q1).round()
		w.a = q0 - w.position
		w.b = q1 - w.position
		w.n = n
		w.h = h
		w.d = d
		w.u0 = length * float(i) / pieces
		w.banner = banners and i % 4 == 2 and absf(dir.x) > 0.5
		w.arch = arches and i % 2 == 0
		layer.add_child(w)
	_box((pa + pb) / 2.0 + n * d / 2.0, Vector2(length + 8.0, d + 8.0), dir.angle())


# ---------------------------------------------------------------- the town square

static func _town_square() -> void:
	# the old citadel ground in the middle of the city is now an open square
	_spr("castle2/vegetation/fountain", Vector2(0, 40), Vector2(50, 18))
	for p in [Vector2(-90, 110), Vector2(90, 110)]:
		_spr("cit_bench", p, Vector2(44, 10))
	for p in [Vector2(-200, -200), Vector2(200, -200), Vector2(-200, 240), Vector2(200, 240)]:
		_spr("cit_lamp", p, Vector2(10, 6))


# ---------------------------------------------------------------- water

static func walkable(p: Vector2) -> bool:
	for group in [LAND, [WARD], DECKS]:
		for pts in group:
			if Geometry2D.is_point_in_polygon(p, poly(pts)):
				return true
	return false


## The water blocks walking: every water cell next to walkable ground gets a collision box
## (rows of cells are merged into long boxes).
static func _water_collision() -> void:
	var C := 24.0
	var area := Geo.CASTLE_AREA
	var nx := int(area.size.x / C)
	var ny := int(area.size.y / C)
	var polys := []
	for group in [LAND, [WARD], DECKS]:
		for pts in group:
			polys.append(poly(pts))
	var walk := PackedByteArray()
	walk.resize(nx * ny)
	for j in ny:
		for i in nx:
			var p := area.position + Vector2(i + 0.5, j + 0.5) * C
			var ok := 0
			for pl in polys:
				if Geometry2D.is_point_in_polygon(p, pl):
					ok = 1
					break
			walk[j * nx + i] = ok
	var w := func(i: int, j: int) -> bool:
		if i < 0 or j < 0 or i >= nx or j >= ny:
			return true   # outside the map is dry land
		return walk[j * nx + i] == 1
	for j in ny:
		var run := -1
		for i in nx + 1:
			var blocked := false
			if i < nx and not w.call(i, j):
				blocked = w.call(i - 1, j) or w.call(i + 1, j) or w.call(i, j - 1) or w.call(i, j + 1) \
						or w.call(i - 1, j - 1) or w.call(i + 1, j + 1) or w.call(i - 1, j + 1) or w.call(i + 1, j - 1)
			if blocked and run < 0:
				run = i
			elif not blocked and run >= 0:
				var r := Rect2(area.position + Vector2(run, j) * C, Vector2(i - run, 1) * C)
				_box(r.get_center(), r.size)
				run = -1


# ---------------------------------------------------------------- walls and towers

static func _walls() -> void:
	for s in MAIN_WALL:
		_wall(s[0], s[1], 150.0, 66.0, true)
	for s in BARBICAN:
		_wall(s[0], s[1], 135.0, 54.0, true)
	for i in OUTER_LINKS.size():
		var s = OUTER_LINKS[i]
		_wall(s[0], s[1], 110.0, 44.0, false, i < 2)   # the first two are aqueduct arches
	for s in INNER_WALLS:
		_wall(s[0], s[1], 84.0, 34.0, false)
	# parapets along the causeway and the bridges
	for x in [725, 811]:
		_wall([x, 716], [x, 996], 22.0, 10.0)


static func _towers() -> void:
	var t := [
		# main curtain wall
		["towers/tower_flag", 357, 132], ["towers/tower_flag_b", 437, 129], ["towers/tower_flag", 1179, 132], ["towers/tower_flag_b", 1099, 129],
		["towers/tower_blue_c", 237, 212], ["towers/tower_blue_c", 1299, 212],
		["towers/tower_round", 234, 314], ["towers/tower_round", 231, 356], ["towers/tower_round", 1302, 314], ["towers/tower_round", 1305, 356],
		["towers/tower_blue_d", 222, 512], ["towers/tower_blue_d", 1314, 512],
		["towers/tower_round", 228, 526], ["towers/tower_round", 241, 568], ["towers/tower_round", 1308, 526], ["towers/tower_round", 1295, 568],
		["towers/tower_blue_c", 272, 700], ["towers/tower_blue_c", 1264, 700],
		["towers/tower_blue_a", 603, 708], ["towers/tower_blue_a", 933, 708],
		["towers/tower_blue_c", 700, 712], ["towers/tower_blue_c", 836, 712],
		["towers/tower_round", 1278, 192], ["towers/tower_round", 1228, 158],
		# great towers standing in the moat
		["towers/tower_tall", 440, 808], ["towers/tower_tall", 1096, 808],
		# towers in the water west and east, joined by the aqueducts and links
		["towers/tower_blue_c", 123, 262], ["towers/tower_blue_c", 1413, 262],
		["towers/tower_blue_d", 82, 316], ["towers/tower_blue_d", 1454, 316],
		["towers/tower_blue_c", 62, 628], ["towers/tower_blue_c", 1474, 628],
		# barbican
		["towers/tower_battlement", 150, 858], ["towers/tower_battlement_b", 295, 868], ["towers/tower_battlement", 395, 928],
		["towers/tower_cone_a", 512, 928], ["towers/tower_flag", 640, 942], ["towers/tower_flag_b", 896, 942],
		["towers/tower_cone_a", 1024, 928], ["towers/tower_battlement", 1141, 928], ["towers/tower_battlement_b", 1241, 868],
		["towers/tower_battlement", 1386, 858],
		# inner terrace towers
		["towers/tower_cone_a", 455, 224], ["towers/tower_cone_a", 1081, 224],
		["towers/tower_blue_a", 560, 338], ["towers/tower_blue_a", 976, 338],
		["towers/tower_round", 690, 338], ["towers/tower_round", 846, 338],
		["towers/tower_cone_b", 500, 458], ["towers/tower_cone_b", 1036, 458],
		["towers/tower_round", 262, 468], ["towers/tower_round", 1274, 468],
	]
	for e in t:
		var tex: Texture2D = load("res://art/castle3/%s.png" % e[0])
		var w := tex.get_width() * 0.8
		_put(e[0], e[1], e[2], Vector2(w, maxf(40.0, w * 0.32)))
	# gate arches: the main gate and the barbican gate
	_put("gates/gate_arch", 768, 694, Vector2.ZERO, false)
	_put("gates/gate_arch", 768, 940, Vector2.ZERO, false)
	# angels on the inner stair towers
	for x in [690, 846]:
		_spr(A + "decor/angel_a" if x < 768 else A + "decor/angel_b", Geo.rp(x, 338), Vector2.ZERO, false, 330)


# ---------------------------------------------------------------- buildings

static func _buildings(main) -> void:
	# the palace (keep) at the north, facing the gate
	_put("buildings/palace", 768, 220, Vector2(1300, 70))
	# the west church with its two chapels, and a small chapel on the upper terrace
	_put("buildings/chapel_a", 290, 430, Vector2(170, 50))
	_put("buildings/church", 350, 432, Vector2(200, 50))
	_put("buildings/chapel_b", 412, 430, Vector2(170, 50))
	_put("buildings/chapel_b", 378, 250, Vector2(170, 50))
	# the east domed hall and the manor below it
	_put("buildings/domed_hall_2x", 1196, 312, Vector2(430, 60))
	_put("buildings/chapel_a", 1166, 440, Vector2(170, 50))
	_put("buildings/chapel_b", 1226, 440, Vector2(170, 50))
	# the fountain court
	_spr("castle2/vegetation/fountain", Geo.rp(768, 430), Vector2(46, 18), true, 0, 3.0)
	for x in [720, 816]:
		_put("decor/angel_a" if x < 768 else "decor/angel_b", x, 404, Vector2(60, 24))
	for x in [700, 836]:
		_put("decor/angel_b" if x < 768 else "decor/angel_a", x, 268, Vector2(60, 24))


static func _courts(main) -> void:
	# gardens of the fountain court: flower beds and rows of cypress
	for x in [640, 896]:
		_put("garden/bed_big", x, 380, Vector2(180, 40))
	for x in [626, 656, 880, 910]:
		for y in [430, 470, 505]:
			_put("trees/cypress", x, y, Vector2(30, 12))
	for e in [["garden/arch_roses", 560, 430], ["garden/arch_flowers", 976, 430], ["garden/hedge_bed", 600, 560], ["garden/hedge_bed", 936, 560],
			["garden/flower_bed", 560, 600], ["garden/flower_bed", 976, 600], ["garden/planter", 600, 330], ["garden/planter", 936, 330]]:
		_put(e[0], e[1], e[2], Vector2(80, 24))
	# lamps along the avenue to the gate, and torches along the causeway
	for y in [480, 540, 600, 660]:
		for x in [735, 801]:
			_put("decor/lamp_a", x, y, Vector2(14, 8))
			main_ref.lights.add(Geo.rp(x, y) - Vector2(0, 130), "candle")
	for y in [730, 790, 850, 910, 970]:
		for x in [722, 814]:
			_put("decor/torch", x, y, Vector2(14, 8))
			main_ref.lights.add(Geo.rp(x, y) - Vector2(0, 100), "torch")
	for x in [712, 824]:
		_put("decor/angel_a" if x < 768 else "decor/angel_b", x, 980, Vector2(60, 24))
	# the market yard (west)
	var stalls := ["market/stall_a", "market/stall_b", "market/stall_c", "market/stall_d", "market/stall_e", "market/stall_f"]
	var k := 0
	for y in [510, 570]:
		for x in [268, 308, 348]:
			_put(stalls[k % stalls.size()], x, y, Vector2(80, 26))
			k += 1
	_put("market/shed", 384, 510, Vector2(40, 16))
	_put("market/rack", 384, 568, Vector2(70, 16))
	# the training ground (east)
	for x in [1158, 1192, 1226, 1260]:
		_put("training/dummy_stand", x, 510, Vector2(40, 14))
	_put("training/weapon_rack", 1170, 576, Vector2(90, 18))
	_put("training/gallows_rack", 1220, 576, Vector2(90, 18))
	_put("training/tent_rack", 1272, 576, Vector2(90, 18))


# ---------------------------------------------------------------- trees and shores

static func _trees_and_shore() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var pines := ["trees/pine_a", "trees/pine_b", "trees/pine_big", "trees/pine_small", "trees/bush_round"]
	# trees on the green terraces, kept off the buildings and the walls
	var keep_out := [Rect2(500, 0, 540, 240), Rect2(250, 380, 200, 70), Rect2(330, 200, 100, 60), Rect2(1080, 220, 230, 100),
			Rect2(1110, 390, 160, 70), Rect2(590, 340, 100, 60), Rect2(846, 340, 100, 60)]
	for pts in LAWNS:
		var pl := PackedVector2Array()
		for p in pts:
			pl.append(Vector2(p[0], p[1]))
		var box := Rect2(pl[0], Vector2.ZERO)
		for p in pl:
			box = box.expand(p)
		var count := int(box.get_area() / 1800.0)
		for i in count:
			var q := Vector2(rng.randf_range(box.position.x, box.end.x), rng.randf_range(box.position.y + 20, box.end.y))
			if not Geometry2D.is_point_in_polygon(q, pl):
				continue
			var blocked := false
			for r in keep_out:
				if r.has_point(q):
					blocked = true
			if blocked:
				continue
			_put(pines[rng.randi() % pines.size()], q.x, q.y, Vector2(30, 12))
	# cliffs along the south-west and south-east shores, under the barbican's ends
	var cliffs := ["cliffs/cliff_a", "cliffs/cliff_b", "cliffs/cliff_c", "cliffs/cliff_d"]
	for p in [[118, 700], [128, 770], [150, 840], [176, 905], [26, 140], [60, 135], [110, 140],
			[1418, 700], [1408, 770], [1386, 840], [1360, 905]]:
		_put(cliffs[rng.randi() % 4], p[0], p[1], Vector2(150, 44))
	for p in [[30, 600], [40, 700], [60, 800], [90, 900], [120, 980], [1500, 640], [1490, 720], [1476, 820], [1440, 900], [1420, 990],
			[20, 240], [30, 320], [1500, 420], [1510, 470]]:
		_put(pines[rng.randi() % 3], p[0], p[1], Vector2(30, 12))
	# waterfalls: the lake spills over at the barbican's ends, and a stream falls from the north-west hills
	_put("water/waterfall_big", 236, 1000, Vector2.ZERO, false)
	_put("water/waterfall_big", 1300, 1000, Vector2.ZERO, false)
	_put("water/waterfall_small", 76, 150, Vector2.ZERO, false)


# ---------------------------------------------------------------- people

static func _people(main) -> void:
	main._npc("guard", Geo.rp(738, 1004), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.rp(798, 1004), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.rp(745, 236), "Castle guard", Story.CASTLE_NORTH_GUARD)
	main._npc("guard", Geo.rp(791, 236), "Castle guard", Story.CASTLE_NORTH_GUARD)


# ---------------------------------------------------------------- drawing

## One short piece of a wall line: stone face, slate wall walk and merlons, y-sorted at
## its lower end. a, b: the piece's base (front-bottom edge) relative to its position.
class _WallPiece extends Node2D:
	const FACE = preload("res://art/castle3/tex_wallface.png")
	const TOP = preload("res://art/castle3/tex_walltop.png")
	const MERLONS = preload("res://art/castle3/tex_merlons.png")
	const BANNER = preload("res://art/castle3/decor/wall_banner.png")
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var n := Vector2.UP
	var h := 150.0
	var d := 60.0
	var u0 := 0.0
	var banner := false
	var arch := false

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		var up := Vector2(0, -h)
		var dir := (b - a)
		var seg := dir.length()
		var flat := absf(dir.x) > 2.0
		# the wall walk on top
		var top := PackedVector2Array([a + up, b + up, b + up + n * d, a + up + n * d])
		var uv := PackedVector2Array()
		for p in top:
			uv.append((p + position) / TOP.get_size())
		draw_colored_polygon(top, Color(0.92, 0.92, 0.95), uv, TOP)
		# the stone face toward the viewer
		if flat:
			var shade := clampf(0.86 - 0.12 * (dir.normalized().y if a.x < b.x else -dir.normalized().y), 0.7, 1.0)
			var face := PackedVector2Array([a, b, b + up, a + up])
			var fs := FACE.get_size()
			var fuv := PackedVector2Array([Vector2(u0, h) / fs, Vector2(u0 + seg, h) / fs, Vector2(u0 + seg, 0) / fs, Vector2(u0, 0) / fs])
			draw_colored_polygon(face, Color(shade, shade, shade), fuv, FACE)
			if arch:
				var m := (a + b) / 2.0
				draw_circle(m + Vector2(0, -h * 0.35), minf(seg * 0.32, h * 0.3), Color(0.05, 0.1, 0.18))
				draw_rect(Rect2(m.x - minf(seg * 0.32, h * 0.3), m.y - h * 0.35, minf(seg * 0.32, h * 0.3) * 2.0, h * 0.35), Color(0.12, 0.3, 0.5))
			# merlons along the front edge
			var ms := MERLONS.get_size()
			var mq := PackedVector2Array([a + up + Vector2(0, -16), b + up + Vector2(0, -16), b + up + Vector2(0, 10), a + up + Vector2(0, 10)])
			var muv := PackedVector2Array([Vector2(u0, 0) / ms, Vector2(u0 + seg, 0) / ms, Vector2(u0 + seg, ms.y) / ms, Vector2(u0, ms.y) / ms])
			draw_colored_polygon(mq, Color.WHITE, muv, MERLONS)
			draw_line(a, b, Color(0.12, 0.1, 0.1, 0.8), 2.0)
			if banner:
				var m := (a + b) / 2.0 + up + Vector2(0, 22)
				draw_texture(BANNER, (m - Vector2(BANNER.get_width() / 2.0, 0)).round())
		else:
			# a wall seen end-on: stone parapets with merlons down both sides of the walk
			var side_n := n.normalized()
			for side in [Vector2.ZERO, n * d - side_n * 12.0]:
				var strip := PackedVector2Array([a + up + side, b + up + side, b + up + side + side_n * 12.0, a + up + side + side_n * 12.0])
				draw_colored_polygon(strip, Color(0.72, 0.68, 0.62))
			for k in int(seg / 18.0):
				var p := a.lerp(b, (k + 0.5) / (seg / 18.0)) + up
				for side in [Vector2.ZERO, n * d - side_n * 12.0]:
					draw_rect(Rect2(p + side + Vector2(0, -8), Vector2(12, 9)), Color(0.84, 0.8, 0.72))
					draw_rect(Rect2(p + side + Vector2(0, -8), Vector2(12, 2)), Color(0.96, 0.93, 0.86))
			# the side of the wall walk
			draw_line(a + up, b + up, Color(0.15, 0.13, 0.12), 2.0)
			draw_line(a + up + n * d, b + up + n * d, Color(0.15, 0.13, 0.12), 2.0)


## The ground of the castle map: water everywhere, then the shores, the castle's ground,
## its terraces, yards, bridges and the causeway.
class _Ground extends Node2D:
	const Geo = preload("res://scripts/geo.gd")
	const Castle = preload("res://scripts/castle_outer.gd")
	const WATER = preload("res://art/castle3/tex_water.png")
	const PAVE = preload("res://art/castle3/tex_flag_b.png")
	const FLAG = preload("res://art/castle3/tex_flag.png")
	const GRASS = preload("res://art/castle3/tex_grass.png")
	const SAND = preload("res://art/castle3/tex_dirt.png")
	const SHADER := """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV + vec2(TIME * 0.006, TIME * 0.003);
	vec4 c = texture(TEXTURE, uv);
	c.rgb += 0.025 * sin(TIME * 1.4 + (UV.x + UV.y) * 9.0);
	COLOR = c;
}
"""

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		var water := Node2D.new()
		water.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		var sh := Shader.new()
		sh.code = SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		water.material = mat
		water.show_behind_parent = true
		water.draw.connect(func():
			var r := Geo.CASTLE_AREA
			water.draw_texture_rect_region(WATER, r, Rect2(r.position, r.size)))
		add_child(water)

	func _fill(pts: Array, tex: Texture2D, scale := 1.0, tint := Color.WHITE) -> void:
		var pl: PackedVector2Array = Castle.poly(pts)
		var uv := PackedVector2Array()
		for p in pl:
			uv.append(p / (tex.get_size() * scale))
		draw_colored_polygon(pl, tint, uv, tex)

	func _edge(pts: Array, col: Color, width: float) -> void:
		var pl: PackedVector2Array = Castle.poly(pts)
		pl.append(pl[0])
		draw_polyline(pl, col, width)

	func _draw() -> void:
		# shores: grass with a rocky edge where they meet the water
		for pts in Castle.LAND:
			_edge(pts, Color(0.32, 0.3, 0.3), 26.0)
			_fill(pts, GRASS, 1.0)
		# the castle's ground: a stone embankment, then paving
		_edge(Castle.WARD, Color(0.4, 0.38, 0.36), 30.0)
		_fill(Castle.WARD, PAVE, 1.0)
		for pts in Castle.LAWNS:
			_edge(pts, Color(0.62, 0.58, 0.5), 8.0)
			_fill(pts, GRASS, 1.0)
		for pts in Castle.DIRT:
			_fill(pts, SAND, 1.0, Color(0.92, 0.8, 0.68))
		for pts in Castle.SAND:
			_fill(pts, SAND, 1.0, Color(1.15, 1.08, 0.95))
		# bridges and the causeway
		for pts in Castle.DECKS:
			_edge(pts, Color(0.25, 0.22, 0.2), 10.0)
			_fill(pts, FLAG, 1.0)
		# the grand stairs up to the palace, with a red carpet
		for st in [[736, 228, 800, 250], [736, 284, 800, 336]]:
			var r := Rect2(Geo.rp(st[0], st[1]), Geo.rp(st[2], st[3]) - Geo.rp(st[0], st[1]))
			var rows := int(r.size.y / 12.0)
			for i in rows:
				var l := 1.05 - i * 0.03
				draw_rect(Rect2(r.position.x, r.position.y + i * 12, r.size.x, 12), Color(0.82 * l, 0.8 * l, 0.76 * l))
				draw_rect(Rect2(r.position.x, r.position.y + i * 12 + 11, r.size.x, 1), Color(0.3, 0.27, 0.25))
		var carpet := Rect2(Geo.rp(756, 224), Geo.rp(780, 700) - Geo.rp(756, 224))
		draw_rect(carpet, Color(0.62, 0.1, 0.12))
		draw_rect(Rect2(carpet.position.x, carpet.position.y, 4, carpet.size.y), Color(0.85, 0.66, 0.3))
		draw_rect(Rect2(carpet.end.x - 4, carpet.position.y, 4, carpet.size.y), Color(0.85, 0.66, 0.3))
