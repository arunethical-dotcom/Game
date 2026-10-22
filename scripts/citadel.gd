extends RefCounted
## Builds the Royal Citadel's main floor from the approved 100 x 90 tile plan
## (docs/images/citadel_v2_main_floor_plan.png). Every position below is a plan tile;
## Geo.tile() / Geo.trect() turn tiles into world pixels (1 tile = 32 px, plan tile
## (50, 45) = the city centre).
##
##        north curtain wall (towers at 5, 30, 70, 95)
##   +-----------+--------------------+-----------+
##   | WEST WING |  GRAND THRONE HALL | EAST WING |
##   |  S1 up    |    (38,8)-(62,28)  |  S2 up    |
##   +-----+-----+--+----steps-----+--+-----------+
##   |Chap.|gal-|NW |              | NE|  Library  |
##   +-----+lery|   |    ARENA     |   +-----+-----+
##   |Armo.| S3 |   | (50,52) r10  |   |Counc|Treas|
##   +-----+----+SW |              | SE| S4 down   |
##   | training |   |              |   | service S5|
##   +----------+---+----avenue----+---+-----------+
##                      SOUTH GATE (46,82)-(54,86)

const Geo = preload("res://scripts/geo.gd")
const Story = preload("res://scripts/story.gd")
const Wall = preload("res://scripts/cit_wall.gd")
const Spr = preload("res://scripts/cit_sprite.gd")
const Building = preload("res://scripts/cit_building.gd")
const Interior = preload("res://scripts/cit_interior.gd")
const Ground = preload("res://scripts/cit_ground.gd")
const Moat = preload("res://scripts/cit_moat.gd")
const Deco = preload("res://scripts/deco.gd")
const Tiles = preload("res://scripts/tiles.gd")
const Fence = preload("res://scripts/cit_fence.gd")
const Floors = preload("res://scripts/citadel_floors.gd")

const PIECE := 32         # vertical walls are built from pieces this long
const A := "castle2/"     # imported atlas (tools/import_castle.py, sheet 2)

# The five staircases: footprint and landing, in plan tiles [x0, y0, x1, y1).
# The same tiles are used on the floors they connect to.
const STAIRS := {
	"S1": {"foot": [24, 24, 27, 27], "land": [24, 27, 27, 29], "dir": "up"},
	"S2": {"foot": [73, 24, 76, 27], "land": [73, 27, 76, 29], "dir": "up"},
	"S3": {"foot": [23, 53, 26, 56], "land": [23, 51, 26, 53], "dir": "down"},
	"S4": {"foot": [86, 50, 89, 53], "land": [86, 53, 89, 55], "dir": "down"},
	"S5": {"foot": [86, 72, 89, 75], "land": [86, 75, 89, 77], "dir": "down"},
}

static var main_ref
static var layer: Node2D


static func build(main) -> void:
	main_ref = main
	layer = main.entity_layer
	_grounds(main)
	_curtain_wall()
	_throne_hall(main)
	_west_side(main)
	_east_side(main)
	_gardens()
	_courtyard()
	_yards()
	_stairs(main)
	_people(main)
	Floors.build(main)
	# camera: the whole castle is one zone; each building frames itself (see _building)
	main.add_camera_zone(Geo.CIT_MOAT.grow_individual(0, 120, 0, 260))


# ---------------------------------------------------------------- helpers

static func T(x: float, y: float) -> Vector2:
	return Geo.tile(x, y)


static func TR(x0: float, y0: float, x1: float, y1: float) -> Rect2:
	return Geo.trect(x0, y0, x1, y1)


static func _spr(name: String, p: Vector2, solid := Vector2.ZERO, flame := Vector2.INF, shadow := true, lift := 0) -> Node2D:
	var s = Spr.new()
	s.sprite = name
	s.lift = lift
	s.position = p.round()
	s.solid = solid
	s.flame = flame
	s.shadow = shadow
	layer.add_child(s)
	return s


## An atlas sprite with its feet at plan tile (x, y); `solid` is its collision box.
static func _put(name: String, x: float, y: float, solid := Vector2.ZERO, shadow := true) -> Node2D:
	return _spr(A + name, T(x, y), solid, Vector2.INF, shadow)


static func _deco(name: String, p: Vector2, base := Vector2.ZERO) -> void:
	var d = Deco.new()
	d.sprite = name
	d.position = p.round()
	d.base = base
	layer.add_child(d)


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


static func _vwall(x: float, y0: float, y1: float, thick := 28) -> void:
	var y := y0
	while y < y1:
		var w = Wall.new()
		w.vertical = true
		w.thick = thick
		w.length = int(minf(PIECE, y1 - y))
		w.position = Vector2(x, y + w.length)
		layer.add_child(w)
		y += PIECE


## A run of atlas wall sprites standing on base line y, from x0 to x1, with collision.
static func _wall_run(x0: float, x1: float, y: float, pieces: Array) -> void:
	var x := x0
	var i := 0
	while x < x1 - 8:
		var name: String = pieces[i % pieces.size()]
		var tex: Texture2D = load("res://art/%s%s.png" % [A, name])
		var w := float(tex.get_width())
		if x + w > x1 + 4:
			# finish the run with the shortest piece, overlapping the previous one
			name = "walls/wall_low"
			tex = load("res://art/%swalls/wall_low.png" % A)
			w = float(tex.get_width())
			x = x1 - w
		_spr(A + name, Vector2(x + w / 2.0, y), Vector2.ZERO, Vector2.INF, false)
		x += w - 2
		i += 1
	_block(Rect2(x0, y - 24, x1 - x0, 24))


## One enterable building. `r` is its whole plan rect (back wall included); the floor
## starts below the back wall. Doors are plan x on the front (south) wall; side doors
## are ["w" or "e", y0, y1] in plan tiles.
static func _building(main, r: Array, wall_h: int, doors: Array, floor_row: int, side_doors := []) -> Array:
	var full := TR(r[0], r[1], r[2], r[3])
	var fp := Rect2(full.position.x, full.position.y + wall_h, full.size.x, full.size.y - wall_h)
	var inside = Interior.new()
	inside.footprint = fp
	inside.wall_h = wall_h
	inside.tile_row = floor_row
	for sd in side_doors:
		inside.side_gaps.append([sd[0], T(0, sd[1]).y, T(0, sd[2]).y])
	main.ground_layer.add_child(inside)
	var b = Building.new()
	b.main = main
	b.footprint = fp
	b.wall_h = wall_h
	var xs := []
	for d in doors:
		xs.append(T(d, 0).x)
	b.doors = xs
	b.enterable = true
	for sd in side_doors:
		b.side_doors.append([sd[0], (T(0, sd[1]).y + T(0, sd[2]).y) / 2.0, (sd[2] - sd[1]) * Geo.TILE])
	b.position = Vector2(roundf(fp.get_center().x), fp.end.y)
	layer.add_child(b)
	main.add_camera_zone(full.grow_individual(24, 24, 24, 40))
	return [inside, b, fp]


# ---------------------------------------------------------------- grounds

static func _grounds(main) -> void:
	main.ground_layer.add_child(Moat.new())
	main.ground_layer.add_child(Moat.Edges.new())
	var g = Ground.new()
	# four formal gardens around the courtyard
	for gr in [[31, 30, 40, 40], [60, 30, 69, 40], [31, 62, 40, 72], [60, 62, 69, 72]]:
		var rect := TR(gr[0], gr[1], gr[2], gr[3])
		g.areas.append([rect, "lawn", Color.WHITE])
		g.circles.append([rect.get_center() + Vector2(0, 20), 48.0, "gravel"])
	# training yard (sand) and service yard (gravel)
	g.areas.append([TR(10, 60, 28, 78), "sand", Color.WHITE])
	g.areas.append([TR(72, 60, 90, 78), "gravel", Color.WHITE])
	# the arena (radius 10 tiles) inside its walkway ring (10 to 12 tiles)
	var arena := T(50, 52)
	g.rings.append([arena, 10.0 * Geo.TILE, 12.0 * Geo.TILE, "walltop"])
	g.circles.append([arena, 10.0 * Geo.TILE, "sand"])
	# the avenue from the gate to the arena, and from the arena to the throne steps
	g.cobbles.append(TR(47, 63, 53, 82))
	g.cobbles.append(TR(47, 30, 53, 41))
	for k in [TR(46.75, 63, 47, 82), TR(53, 63, 53.25, 82), TR(46.75, 30, 47, 41), TR(53, 30, 53.25, 41)]:
		g.kerbs.append(k)
	g.carpets.append(TR(48, 64, 52, 82))
	g.carpets.append(TR(48, 30, 52, 40))
	g.steps.append(TR(46, 28, 54, 30))
	# the gate passage across the wall line, joining the bridge
	g.areas.append([TR(47, 82, 53, 86.2), "walltop", Color(0.92, 0.9, 0.86)])
	main.ground_layer.add_child(g)


# ---------------------------------------------------------------- curtain wall, towers, gate

static func _curtain_wall() -> void:
	var pieces := ["walls/wall_banners_long", "walls/wall_banner_section", "walls/wall_banner_long_b"]
	# north wall: its face looks into the courtyard; towers stand at x 5, 30, 70, 95
	var ny := T(0, 8).y
	_wall_run(T(5, 0).x, T(30, 0).x, ny, pieces)
	_wall_run(T(30, 0).x, T(70, 0).x, ny, pieces)
	_wall_run(T(70, 0).x, T(95, 0).x, ny, pieces)
	# south wall, either side of the gate towers
	var sy := T(0, 84).y
	_wall_run(T(5, 0).x, T(44, 0).x, sy, pieces)
	_wall_run(T(56, 0).x, T(95, 0).x, sy, pieces)
	# west and east walls: wall walks seen from above, filling the band to the compound
	_vwall(T(6.5, 0).x, T(0, 6).y, T(0, 84).y, 88)
	_vwall(T(93.5, 0).x, T(0, 6).y, T(0, 84).y, 88)
	# the gatehouse: an open arch, closed off at the sides
	_spr("cit_gate", T(50, 84) + Vector2(0, 1), Vector2.ZERO, Vector2.INF, false)
	for x in [45.6, 54.4]:
		_spr(A + "walls/wall_low", T(x, 84), Vector2.ZERO, Vector2.INF, false)
	_block(Rect2(T(44, 0).x, T(0, 83).y, T(47, 0).x - T(44, 0).x, 32))
	_block(Rect2(T(53, 0).x, T(0, 83).y, T(56, 0).x - T(53, 0).x, 32))
	# towers
	for p in [[5, 6.6], [95, 6.6], [5, 84.6], [95, 84.6]]:
		_put("towers/tower_round_large", p[0], p[1], Vector2(66, 26))
	for p in [[5, 45], [95, 45]]:
		_put("towers/tower_square_blue", p[0], p[1], Vector2(48, 22))
	for p in [[30, 8], [70, 8]]:
		_put("towers/tower_spire_tall", p[0], p[1], Vector2(40, 20))
	for p in [[30, 84.4], [70, 84.4]]:
		_put("towers/tower_round_window", p[0], p[1], Vector2(60, 24))
	for p in [[44, 84.6], [56, 84.6]]:
		_put("towers/tower_round_door", p[0], p[1], Vector2(60, 24))
	# lanterns on the bridge
	for x in [46.6, 53.4]:
		_put("lighting/lamp_post", x, 89.6, Vector2(8, 6))


# ---------------------------------------------------------------- throne hall

static func _throne_hall(main) -> void:
	var res := _building(main, [38, 8, 62, 28], 128, [50], Tiles.MARBLE)
	var inside = res[0]
	var b = res[1]
	var fp: Rect2 = res[2]
	b.big_door = true
	b.keep_spire = true
	b.facade = load("res://art/castle2/roofs/hall_facade.png")
	inside.tile_vars = [0, 1]
	inside.nave = Rect2(fp.position.x + 160, fp.position.y + 96, fp.size.x - 320, fp.size.y - 96)
	inside.nave_alt = [2, 3]
	inside.bands = [[Rect2(inside.nave.position.x - 32, inside.nave.position.y, 32, inside.nave.size.y), Tiles.MARBLE_BORDER_V],
			[Rect2(inside.nave.end.x, inside.nave.position.y, 32, inside.nave.size.y), Tiles.MARBLE_BORDER_V],
			[Rect2(inside.nave.position.x - 32, inside.nave.position.y, inside.nave.size.x + 64, 32), Tiles.MARBLE_BORDER]]
	inside.carpet = TR(48.75, 15, 51.25, 28)
	inside.dais = TR(44, 12, 56, 15)
	inside.rugs = [[load("res://art/dec_rug_throne.png"), T(50, 21)]]
	inside.pools = [[T(46, 12.4), 44.0], [T(54, 12.4), 44.0]]
	# the throne under its canopy, on the dais
	_spr("dec_canopy", T(50, 13.6), Vector2.ZERO, Vector2.INF, false)
	_put("royal_props/throne_red", 50, 14.6, Vector2(60, 20))
	for x in [46.5, 53.5]:
		_put("lighting/candelabra", x, 14.4, Vector2(12, 8))
	for x in [46, 54]:
		_spr("dec_sconce", T(x, 12), Vector2.ZERO, Vector2(0, -72), false, 46)
	# two rows of pillars along the nave, braziers along the carpet
	for y in [17, 20, 23, 26]:
		for x in [42.5, 57.5]:
			_put("royal_props/pillar_a", x, y, Vector2(26, 12))
	for y in [18.5, 24.5]:
		for x in [46.5, 53.5]:
			_put("lighting/brazier_large", x, y, Vector2(22, 10))
	# banners, busts and planters in the side aisles
	for side in [-1, 1]:
		var ax: float = 50 + side * 10.6
		_put("banners/banner_lion", ax, 16.2, Vector2(20, 8))
		_put("royal_props/bust_stone", ax, 19.5, Vector2(20, 10))
		_put("banners/banner_large", ax, 22.5, Vector2(24, 8))
		_put("vegetation/planter_tall", ax, 27, Vector2(16, 8))
	main._npc("guard", T(47.6, 16.4), "Royal guard", Story.GUARD_HALL)
	main._npc("guard", T(52.4, 16.4), "Royal guard", Story.GUARD_HALL)


# ---------------------------------------------------------------- west side

static func _west_side(main) -> void:
	# West Royal Wing: entrance hall with the grand stair (S1) up to the residential floor
	var w := _building(main, [10, 10, 30, 30], 112, [20], Tiles.C_WOOD)
	w[0].rugs = [[load("res://art/castle2/rugs/rug_red_a.png"), T(17, 21)], [load("res://art/castle2/rugs/rug_red_d.png"), T(17, 26)]]
	_put("furniture/sofa_red", 14, 18, Vector2(36, 10))
	_put("furniture/table_round", 17, 18.2, Vector2(24, 10))
	_put("furniture/chair_blue", 19.5, 18, Vector2(14, 8))
	_put("library_props/bookshelf", 12, 14.6, Vector2(30, 12))
	_put("library_props/bookshelf_b", 13.4, 14.6, Vector2(30, 12))
	_put("royal_props/clock_trio", 22, 14.6, Vector2(30, 10))
	_put("vegetation/urn_flowers", 28.6, 15, Vector2(18, 8))
	_put("vegetation/urn_flowers", 11.4, 29.4, Vector2(18, 8))
	_put("banners/banner_lion_b", 26, 14.8, Vector2(20, 8))
	_put("lighting/candle_stand", 22.6, 25, Vector2(10, 6))
	_put("lighting/candle_stand", 28.4, 25, Vector2(10, 6))
	main._npc("guard", T(22.6, 28.4), "Royal guard", Story.GUARD_WEST_WING)

	# Chapel and Armory open into the west gallery; the gallery opens onto the courtyard
	var ch := _building(main, [10, 32, 22, 42], 96, [], Tiles.C_LIMESTONE, [["e", 36, 38]])
	ch[0].stained = true
	ch[0].carpet = TR(15.4, 35, 16.6, 42)
	_spr("cit_altar", T(16, 36.4), Vector2(76, 14))
	for y in [38.2, 39.6, 41.0]:
		_spr("cit_pew", T(13.4, y), Vector2(64, 10))
		_spr("cit_pew", T(18.6, y), Vector2(64, 10))
	_put("lighting/candelabra_table", 12, 36.6, Vector2(14, 8))
	_put("lighting/candelabra_table", 20, 36.6, Vector2(14, 8))
	main._npc("court", T(16, 37.4), "Sister Maren", Story.PRIEST).variant = 2

	var ar := _building(main, [10, 44, 22, 56], 96, [], Tiles.C_DARKSTONE, [["e", 48, 50]])
	ar[0].rugs = [[load("res://art/castle2/rugs/rug_red_b.png"), T(15, 52)]]
	for x in [12, 14.5, 17, 19.5]:
		_put("prison_props/stand_iron", x, 47.6, Vector2(14, 8))
	_put("banners/shield_crest", 12, 50.5, Vector2(20, 8))
	_put("banners/shield_crest", 12, 53, Vector2(20, 8))
	_deco("weapon_rack", T(15.5, 55.4), Vector2(56, 14))
	_deco("armor_stand", T(19, 55.4), Vector2(26, 14))
	_put("furniture/workbench", 17.5, 51, Vector2(44, 12))
	main._npc("guard", T(19.5, 51.4), "Armourer", Story.ARMOURER)

	var ga := _building(main, [22, 32, 28, 56], 96, [], Tiles.C_LIMESTONE, [["w", 36, 38], ["w", 48, 50], ["e", 40, 42]])
	ga[0].carpet = TR(24.4, 35, 25.6, 51)
	_put("banners/banner_red_a", 25, 35.4, Vector2(16, 6))
	_put("lighting/candle_stand", 23, 44, Vector2(10, 6))
	_put("lighting/candle_stand", 27, 44, Vector2(10, 6))


# ---------------------------------------------------------------- east side

static func _east_side(main) -> void:
	# East Royal Wing: entrance hall with the private stair (S2) up
	var e := _building(main, [70, 10, 90, 30], 112, [80], Tiles.C_WOOD)
	e[0].rugs = [[load("res://art/castle2/rugs/rug_red_c.png"), T(83, 21)], [load("res://art/castle2/rugs/rug_red_e.png"), T(83, 26)]]
	_put("furniture/sofa_red", 86, 18, Vector2(36, 10))
	_put("furniture/table_round", 83, 18.2, Vector2(24, 10))
	_put("furniture/chair_blue", 80.5, 18, Vector2(14, 8))
	_put("furniture/cabinet_gold", 87.8, 14.6, Vector2(30, 12))
	_put("library_props/globe_gold", 72.6, 15, Vector2(16, 8))
	_put("vegetation/urn_flowers", 71.4, 29.4, Vector2(18, 8))
	_put("vegetation/urn_flowers", 88.6, 29.4, Vector2(18, 8))
	_put("banners/banner_lion_b", 79.4, 14.8, Vector2(20, 8))
	_put("lighting/candle_stand", 71.6, 25, Vector2(10, 6))
	_put("lighting/candle_stand", 77.4, 25, Vector2(10, 6))
	main._npc("guard", T(77.6, 28.4), "Guard", Story.GUARD_EAST_WING)

	# Library and Archives
	var li := _building(main, [72, 32, 90, 42], 96, [77], Tiles.C_WOOD_CHEVRON)
	li[0].rugs = [[load("res://art/castle2/rugs/rug_square_blue.png"), T(81, 38.4)]]
	for p in [[73.4, "bookshelf"], [74.8, "bookshelf_wide"], [76.2, "bookshelf_b"], [85.8, "bookshelf"], [87.2, "bookshelf_wide"], [88.6, "bookshelf_b"]]:
		_put("library_props/" + p[1], p[0], 35.6, Vector2(30, 12))
	_put("furniture/desk_writing", 81, 37.6, Vector2(50, 12))
	_put("library_props/globe_large", 79, 40, Vector2(18, 8))
	_put("library_props/globe_blue", 84, 40, Vector2(14, 8))
	_put("lighting/candelabra", 73.4, 41.4, Vector2(10, 6))
	_put("lighting/candelabra", 88.6, 41.4, Vector2(10, 6))
	main._npc("court", T(82.6, 38.8), "Archivist", Story.SCRIBE).variant = 2

	# Council room
	var co := _building(main, [70, 44, 82, 54], 96, [], Tiles.C_WOOD, [["w", 48, 50]])
	co[0].rugs = [[load("res://art/castle2/rugs/rug_red_a.png"), T(76.5, 51)]]
	_put("furniture/dining_table", 76.5, 51.4, Vector2(52, 16))
	for x in [75, 76.5, 78]:
		_put("furniture/chair_blue_high", x, 50, Vector2(12, 6))
	_put("royal_props/throne_wood", 76.5, 48.4, Vector2(24, 10))
	_put("banners/banner_lion", 72, 47.6, Vector2(20, 8))
	_put("banners/banner_lion", 81, 47.6, Vector2(20, 8))
	_put("library_props/treasure_map", 80.4, 53.4, Vector2(26, 8))
	main._npc("court", T(73.6, 51.6), "Councillor", Story.COUNCILLOR).variant = 0

	# Treasury entrance, with the stair down to the vaults (S4)
	_building(main, [82, 44, 90, 56], 96, [86], Tiles.C_BLUESTONE)
	_put("treasury_props/gold_pile", 83.6, 50.6, Vector2(26, 10))
	_put("treasury_props/gold_table", 84.2, 53.6, Vector2(36, 10))
	_put("treasury_props/cabinet_treasure", 89.2, 47.6, Vector2(16, 8))
	main._npc("guard", T(84.2, 55.2), "Treasury guard", Story.TREASURY_GUARD)


# ---------------------------------------------------------------- gardens and courtyard

static func _garden(x0: float, y0: float) -> void:
	# a 9 x 10 tile garden: fountain in the middle, trees, hedges, planters and benches
	var cx := x0 + 4.5
	var cy := y0 + 5
	_put("vegetation/fountain", cx, cy + 1.6, Vector2(50, 18))
	for k in [[x0 + 1, y0 + 1.6], [x0 + 8, y0 + 1.6], [x0 + 1, y0 + 9.4], [x0 + 8, y0 + 9.4]]:
		_put("vegetation/tree_round", k[0], k[1], Vector2(16, 8))
	for k in [[x0 + 3.4, y0 + 1.6], [x0 + 5.6, y0 + 1.6], [x0 + 3.4, y0 + 9.4], [x0 + 5.6, y0 + 9.4]]:
		_put("vegetation/hedge_flowers", k[0], k[1], Vector2(26, 10))
	for k in [[x0 + 1, y0 + 4.4], [x0 + 1, y0 + 7], [x0 + 8, y0 + 4.4], [x0 + 8, y0 + 7]]:
		_put("vegetation/planter_flowers", k[0], k[1], Vector2(22, 10))
	_spr("cit_bench", T(cx, cy + 3.6), Vector2(44, 10))


static func _gardens() -> void:
	for g in [[31, 30], [60, 30], [31, 62], [60, 62]]:
		_garden(g[0], g[1])


static func _courtyard() -> void:
	# a rope fence around the arena, open on four sides, so it stays a clear fighting ring
	var c := T(50, 52)
	var n := 40
	for i in n:
		if i in [9, 10, 29, 30, 19, 20, 39, 0]:
			continue
		var p0 := (c + Vector2.from_angle(TAU * i / n) * (10.0 * Geo.TILE + 6)).round()
		var p1 := (c + Vector2.from_angle(TAU * (i + 1) / n) * (10.0 * Geo.TILE + 6)).round()
		var f = Fence.new()
		f.position = p0 if p0.y > p1.y else p1
		f.a = p0 - f.position
		f.b = p1 - f.position
		layer.add_child(f)
	# statues and braziers flank the avenue at the steps, the arena and the gate
	for side in [-1, 1]:
		_spr("cit_statue", T(50 + side * 4.6, 31.6), Vector2(30, 12))
		_put("lighting/brazier_gold", 50 + side * 4.6, 64.8, Vector2(18, 8))
		_put("lighting/brazier_gold", 50 + side * 4.6, 80.6, Vector2(18, 8))
		_put("lighting/lamp_post", 50 + side * 3.6, 72, Vector2(8, 6))
		# flags at the courtyard corners
		_put("banners/flag_blue", 50 + side * 19, 29.4, Vector2(8, 6))
		_put("banners/flag_blue", 50 + side * 19, 77.6, Vector2(8, 6))


static func _yards() -> void:
	# west: the training yard
	for x in [12, 15, 18]:
		_spr("cit_dummy", T(x, 63), Vector2(16, 8))
	for x in [22, 25]:
		_spr("cit_target", T(x, 62.6), Vector2(28, 8))
	_deco("weapon_rack", T(12.5, 76.6), Vector2(56, 14))
	_deco("weapon_rack", T(16, 76.6), Vector2(56, 14))
	_deco("armor_stand", T(19.5, 76.6), Vector2(26, 14))
	_put("prison_props/stand_iron", 25.5, 76.6, Vector2(14, 8))
	main_ref._npc("guard", T(20, 70), "Drill sergeant", Story.DRILL_SERGEANT)
	# east: the service yard (S5, the stairs down to the kitchens, is in its south-east corner)
	_deco("crates", T(74, 62.6))
	_deco("crates", T(76, 63.2))
	_put("kitchen_props/barrels_pair", 79, 62.6, Vector2(30, 10))
	_put("kitchen_props/barrel", 81, 63, Vector2(16, 8))
	_deco("woodpile", T(74.5, 76.6))
	_deco("ore_cart", T(79, 76.6), Vector2(40, 14))
	_put("kitchen_props/sack", 82, 76.4, Vector2(12, 6))
	main_ref._npc("court", T(78, 70), "Servant", Story.SERVANT).variant = 3


# ---------------------------------------------------------------- stairs

static func _stairs(main) -> void:
	var down_tex: Texture2D = load("res://art/dec_stairs_down.png")
	for key in STAIRS:
		var s: Dictionary = STAIRS[key]
		var f: Array = s["foot"]
		var l: Array = s["land"]
		var foot := TR(f[0], f[1], f[2], f[3])
		var land := TR(l[0], l[1], l[2], l[3])
		var from_north: bool = l[1] < f[1]   # landing above the footprint: walk south onto it
		if s["dir"] == "up":
			# a carpeted flight of stairs climbing north, rails on both sides
			_spr(A + "stairs/stairs_red_carpet", Vector2(foot.get_center().x, foot.end.y), Vector2.ZERO, Vector2.INF, false)
			_block(Rect2(foot.position.x, foot.position.y, 14, foot.size.y))
			_block(Rect2(foot.end.x - 14, foot.position.y, 14, foot.size.y))
			_block(Rect2(foot.position.x, foot.position.y - 8, foot.size.x, 12))
			var trig := Rect2(foot.position.x + 14, foot.position.y + 4, foot.size.x - 28, 40)
			main.add_stairs(trig, Floors.UP_ARRIVE, "up", "", "Royal Residence")
		else:
			# an opening in the floor with a balustrade on three sides
			var spr := Sprite2D.new()
			spr.texture = down_tex
			spr.centered = false
			spr.flip_v = from_north
			spr.position = foot.position
			spr.scale = foot.size / down_tex.get_size()
			main.ground_layer.add_child(spr)
			_block(Rect2(foot.position.x, foot.position.y, 10, foot.size.y))
			_block(Rect2(foot.end.x - 10, foot.position.y, 10, foot.size.y))
			if from_north:
				_block(Rect2(foot.position.x, foot.end.y - 10, foot.size.x, 10))
			else:
				_block(Rect2(foot.position.x, foot.position.y, foot.size.x, 10))
			var ty: float = foot.end.y - 48 if from_north else foot.position.y + 14
			var trig := Rect2(foot.position.x + 14, ty, foot.size.x - 28, 34)
			var label := "Service Floor" if key != "S4" else "Service Floor (the vaults come next)"
			main.add_stairs(trig, Floors.DOWN_ARRIVE, "down", "", label)
		land = land   # landings are kept clear: nothing is placed on them


# ---------------------------------------------------------------- people

static func _people(main) -> void:
	main._npc("guard", T(47.6, 82.4), "Royal guard", Story.GUARD_CITADEL_GATE)
	main._npc("guard", T(52.4, 82.4), "Royal guard", Story.GUARD_CITADEL_GATE)
	main._npc("guard", T(46.4, 31.2), "Royal guard", Story.GUARD_HALL)
	main._npc("guard", T(53.6, 31.2), "Royal guard", Story.GUARD_HALL)
	main._npc("court", T(42, 36), "Gardener", Story.GARDENER).variant = 1
	main._npc("court", T(58, 66), "Lady of the court", Story.COURT_LADY).variant = 0


## Centre of a staircase's landing in world pixels (where Kael arrives from another floor).
static func landing(key: String) -> Vector2:
	var l: Array = STAIRS[key]["land"]
	return TR(l[0], l[1], l[2], l[3]).get_center()
