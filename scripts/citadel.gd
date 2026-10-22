extends RefCounted
## Builds the Royal Citadel at the centre of Akropolis Aigidos — main floor.
##
##                         north curtain wall
##   +------------------+---------------------+---------------------+
##   |   WEST GARDEN    |  GRAND THRONE HALL  |  EAST GARDEN |CHAPEL|
##   |    (fountain)    |   (central keep)    |  (fountain)  |      |
##   +------------------+----steps / carpet---+---------------------+
##   |    WEST WING     |   ROYAL COURTYARD   |      EAST WING      |
##   |  military yard   |   (battle arena)    |    service yard     |
##   +------------------+-----MAIN GATE-------+---------------------+
##                          bridge over moat
##
## All coordinates are whole pixels, centred on the city centre (0, 0).

const Geo = preload("res://scripts/geo.gd")
const Story = preload("res://scripts/story.gd")
const Wall = preload("res://scripts/cit_wall.gd")
const Spr = preload("res://scripts/cit_sprite.gd")
const Hedge = preload("res://scripts/cit_hedge.gd")
const Building = preload("res://scripts/cit_building.gd")
const Interior = preload("res://scripts/cit_interior.gd")
const Ground = preload("res://scripts/cit_ground.gd")
const Moat = preload("res://scripts/cit_moat.gd")
const Deco = preload("res://scripts/deco.gd")
const Tiles = preload("res://scripts/tiles.gd")
const Fence = preload("res://scripts/cit_fence.gd")
const Floors = preload("res://scripts/citadel_floors.gd")

const PIECE := 32   # vertical walls are built from pieces this long

static var main_ref
static var layer: Node2D


static func build(main) -> void:
	main_ref = main
	layer = main.entity_layer
	_grounds(main)
	_curtain_wall()
	_throne_hall(main)
	_chapel(main)
	_wings(main)
	_gardens()
	_courtyard()
	_yards()
	_people(main)
	Floors.build(main)
	# the castle grounds: inside the moat the camera stops at the castle's edge
	main.add_camera_zone(Geo.CIT_MOAT.grow_individual(0, 120, 0, 260))


# ---------------------------------------------------------------- helpers

static func _spr(name: String, p: Vector2, solid := Vector2.ZERO, flame := Vector2.INF, shadow := true, lift := 0) -> Node2D:
	var s = Spr.new()
	s.lift = lift
	s.sprite = name
	s.position = p.round()
	s.solid = solid
	s.flame = flame
	s.shadow = shadow
	layer.add_child(s)
	return s


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


static func _hwall(x0: float, x1: float, y: float, front := true) -> void:
	var w = Wall.new()
	w.length = int(x1 - x0)
	w.position = Vector2(roundf((x0 + x1) / 2.0), y)
	w.front_battlements = front
	layer.add_child(w)


static func _vwall(x: float, y0: float, y1: float) -> void:
	var y := y0
	while y < y1:
		var w = Wall.new()
		w.vertical = true
		w.length = int(minf(PIECE, y1 - y))
		w.position = Vector2(x, y + w.length)
		layer.add_child(w)
		y += PIECE


static func _hedge(x0: float, x1: float, y: float) -> void:
	var h = Hedge.new()
	h.length = int(x1 - x0)
	h.position = Vector2(roundf((x0 + x1) / 2.0), y)
	layer.add_child(h)


static func _sign(main, p: Vector2, label: String, lines: Array) -> void:
	main._npc("none", p, label, lines)


# ---------------------------------------------------------------- grounds

static func _grounds(main) -> void:
	var moat = Moat.new()
	main.ground_layer.add_child(moat)
	main.ground_layer.add_child(Moat.Edges.new())
	var g = Ground.new()
	# gardens: lawns, gravel paths and round plazas around the fountains
	g.areas.append([Rect2(-1060, -950, 620, 860), "lawn", Color.WHITE])
	g.areas.append([Rect2(440, -950, 400, 860), "lawn", Color.WHITE])
	g.areas.append([Rect2(-1060, -540, 620, 40), "gravel", Color.WHITE])
	g.areas.append([Rect2(-770, -950, 40, 860), "gravel", Color.WHITE])
	g.areas.append([Rect2(440, -540, 400, 40), "gravel", Color.WHITE])
	g.areas.append([Rect2(620, -950, 40, 860), "gravel", Color.WHITE])
	g.circles.append([Vector2(-750, -520), 116, "gravel"])
	g.circles.append([Vector2(640, -520), 108, "gravel"])
	# military training yard
	g.areas.append([Rect2(-1060, 620, 600, 280), "sand", Color.WHITE])
	# royal courtyard: the battle arena
	g.circles.append([Vector2(0, 560), 210, "sand"])
	g.rings.append([Vector2(0, 560), 210, 228, "walltop"])
	# grand steps and the red carpet up to the throne hall
	g.steps.append(Rect2(-130, 100, 260, 60))
	g.carpets.append(Rect2(-36, 100, 72, 232))
	# cobbled avenue from the gate to the arena and from the arena to the steps
	g.cobbles.append(Rect2(-56, 788, 112, 132))
	g.cobbles.append(Rect2(-56, 160, 112, 172))
	for r in [Rect2(-64, 788, 8, 132), Rect2(56, 788, 8, 132), Rect2(-64, 160, 8, 172), Rect2(56, 160, 8, 172),
			# plinths along the fronts of the wings and the throne hall
			Rect2(-1060, 560, 600, 10), Rect2(460, 560, 600, 10), Rect2(-340, 100, 210, 10), Rect2(130, 100, 210, 10)]:
		g.kerbs.append(r)
	# irregular planting beds in the courtyard
	for side in [-1, 1]:
		g.beds.append([Vector2(side * 420, 470), Vector2(34, 84)])
		g.beds.append([Vector2(side * 190, 852), Vector2(64, 24)])
	main.ground_layer.add_child(g)


# ---------------------------------------------------------------- walls and gate

static func _curtain_wall() -> void:
	var w := Geo.CIT_WALL
	var x0 := w.position.x
	var x1 := w.end.x
	var y0 := w.position.y
	var y1 := w.end.y
	_hwall(x0, x1, y0, false)
	_hwall(x0, -66, y1)
	_hwall(66, x1, y1)
	_vwall(x0 + 14, y0, y1)
	_vwall(x1 - 14, y0, y1)
	# the gatehouse: an arch through the wall between two towers
	_spr("cit_gate", Vector2(0, y1 + 1), Vector2.ZERO, Vector2.INF, false)
	_block(Rect2(-66, y1 - 24, 30, 24))
	_block(Rect2(36, y1 - 24, 30, 24))
	for x in [-100, 100]:
		_spr("cit_tower_small", Vector2(x, y1 + 14), Vector2(48, 20))
	# corner towers and towers along the walls
	for p in [Vector2(x0, y0 + 4), Vector2(x1, y0 + 4), Vector2(x0, y1 + 6), Vector2(x1, y1 + 6)]:
		_spr("cit_tower", p, Vector2(70, 24))
	for p in [Vector2(x0, -40), Vector2(x1, -40), Vector2(-560, y0 + 4), Vector2(560, y0 + 4), Vector2(-560, y1 + 6), Vector2(560, y1 + 6)]:
		_spr("cit_tower_small", p, Vector2(50, 20))
	# lanterns on the bridge
	for x in [-56, 56]:
		_spr("cit_lamp", Vector2(x, Geo.CIT_BRIDGE.end.y - 6))


# ---------------------------------------------------------------- buildings

static func _building(main, fp: Rect2, wall_h: int, doors: Array, enterable: bool) -> Node2D:
	var b = Building.new()
	b.main = main
	b.footprint = fp
	b.wall_h = wall_h
	b.doors = doors
	b.enterable = enterable
	b.position = Vector2(roundf(fp.get_center().x), fp.end.y)
	return b


static func _throne_hall(main) -> void:
	var fp := Rect2(-340, -880, 680, 980)
	var inside = Interior.new()
	inside.footprint = fp
	inside.wall_h = 128
	inside.floor_tex = load("res://art/cit_tex_marble.png")
	# cream marble, a checkered nave between the pillars, inlaid borders along it
	inside.tile_row = Tiles.MARBLE
	inside.tile_vars = [0, 1]
	inside.nave = Rect2(-204, -752, 408, 852)
	inside.nave_alt = [2, 3]
	inside.bands = [[Rect2(-236, -752, 32, 852), Tiles.MARBLE_BORDER_V], [Rect2(204, -752, 32, 852), Tiles.MARBLE_BORDER_V],
			[Rect2(-236, -752, 472, 32), Tiles.MARBLE_BORDER]]
	inside.rugs = [[load("res://art/dec_rug_throne.png"), Vector2(0, -430)], [load("res://art/dec_rug_blue.png"), Vector2(0, -110)]]
	inside.pools = [[Vector2(-113, -860), 44.0], [Vector2(113, -860), 44.0]]
	inside.carpet = Rect2(-40, -764, 80, 864)
	inside.dais = Rect2(-180, -862, 360, 96)
	inside.stairs = [[Vector2(-318, -902), load("res://art/castle/walls/stairs_grand.png")], [Vector2(226, -876), load("res://art/dec_stairs_down.png")]]
	main.ground_layer.add_child(inside)
	main.add_camera_zone(Rect2(fp.position.x - 40, fp.position.y - 150, fp.size.x + 80, fp.size.y + 170))
	var b = _building(main, fp, 128, [0], true)
	b.big_door = true
	b.keep_spire = true
	layer.add_child(b)
	# turrets at the front corners of the hall
	for x in [-344, 344]:
		_spr("cit_tower_small", Vector2(x, 106), Vector2(46, 18))
	# the throne on its dais, under a velvet canopy, between candelabras
	_spr("dec_canopy", Vector2(0, -840), Vector2.ZERO, Vector2.INF, false)
	_spr("castle/decor/throne_dais", Vector2(0, -776), Vector2(84, 30))
	for x in [-150, 150]:
		_spr("castle/decor/candelabra_b", Vector2(x, -800), Vector2(12, 8))
	# torches on the back wall
	for x in [-113, 113]:
		_spr("dec_sconce", Vector2(x, -880), Vector2.ZERO, Vector2(0, -72), false, 46)
	# rows of pillars and fire bowls along the carpet
	for y in [-700, -520, -340, -160, 20]:
		for x in [-220, 220]:
			_spr("cit_pillar", Vector2(x, y), Vector2(26, 14))
	for y in [-620, -300, 20]:
		for x in [-110, 110]:
			_spr("cit_brazier", Vector2(x, y), Vector2(20, 10), Vector2(0, -37))
	# statues and suits of armour in the side aisles, keeping the aisles walkable
	for side in [-1, 1]:
		_spr("castle/decor/statue_queen" if side < 0 else "castle/decor/statue_saint", Vector2(side * 296, -610), Vector2(26, 12))
		_spr("castle/decor/armour_a", Vector2(side * 298, -430), Vector2(20, 10))
		_spr("castle/decor/statue_saint" if side < 0 else "castle/decor/statue_queen", Vector2(side * 296, -250), Vector2(26, 12))
		_spr("castle/decor/armour_b", Vector2(side * 298, -70), Vector2(20, 10))
		_spr("castle/decor/plant_urn", Vector2(side * 296, 60), Vector2(24, 10))
	# the stairs: up to the Royal Residence, down to the Service Floor
	_block(Rect2(-318, -880, 12, 74))
	_block(Rect2(-242, -880, 12, 74))
	_block(Rect2(226, -876, 10, 96))
	_block(Rect2(312, -876, 10, 96))
	main.add_stairs(Rect2(-306, -880, 64, 36), Floors.UP_ARRIVE, "up", "", "Royal Residence")
	main.add_stairs(Rect2(244, -866, 60, 44), Floors.DOWN_ARRIVE, "down", "", "Service Floor")


static func _chapel(main) -> void:
	var fp := Rect2(860, -820, 200, 340)
	var inside = Interior.new()
	inside.footprint = fp
	inside.wall_h = 96
	inside.floor_tex = load("res://art/cit_tex_wood.png")
	inside.carpet = Rect2(946, -760, 28, 280)
	inside.stained = true
	main.ground_layer.add_child(inside)
	main.add_camera_zone(Rect2(fp.position.x - 40, fp.position.y - 120, fp.size.x + 80, fp.size.y + 140))
	var b = _building(main, fp, 96, [960], true)
	b.banners = false
	layer.add_child(b)
	_spr("cit_altar", Vector2(960, -770), Vector2(76, 14))
	for y in [-700, -648, -596, -544]:
		_spr("cit_pew", Vector2(906, y), Vector2(72, 10))
		_spr("cit_pew", Vector2(1014, y), Vector2(72, 10))


static func _wing(main, fp: Rect2, door: float, row: int) -> void:
	var inside = Interior.new()
	inside.footprint = fp
	inside.wall_h = 112
	inside.tile_row = row
	main.ground_layer.add_child(inside)
	main.add_camera_zone(Rect2(fp.position.x - 40, fp.position.y - 136, fp.size.x + 80, fp.size.y + 156))
	layer.add_child(_building(main, fp, 112, [door], true))


static func _wings(main) -> void:
	# west: barracks and armory
	_wing(main, Rect2(-1060, 230, 600, 330), -760, Tiles.FLAG)
	for x in [-1010, -960, -910, -610, -560, -510]:
		_spr("castle/furniture/bed_simple", Vector2(x, 316), Vector2(34, 40))
		_spr("castle/furniture/chest_wood", Vector2(x, 352), Vector2(34, 12))
	_spr("castle/furniture/kitchen_table", Vector2(-900, 470), Vector2(84, 14))
	_spr("castle/furniture/stool", Vector2(-924, 444), Vector2(14, 8))
	_spr("castle/furniture/stool", Vector2(-876, 444), Vector2(14, 8))
	_spr("castle/decor/weapon_rack", Vector2(-1010, 538), Vector2(34, 10))
	_spr("castle/decor/halberd_stand", Vector2(-960, 538), Vector2(16, 8))
	_spr("castle/decor/weapon_rack", Vector2(-910, 538), Vector2(34, 10))
	_spr("castle/decor/shield_stand", Vector2(-620, 538), Vector2(30, 10))
	_spr("castle/decor/armour_a", Vector2(-560, 538), Vector2(20, 10))
	_spr("castle/decor/armour_b", Vector2(-510, 538), Vector2(20, 10))
	main._npc("guard", Vector2(-660, 430), "Soldier", Story.BARRACKS_GUARD)
	# east: the royal banquet hall
	_wing(main, Rect2(460, 230, 600, 330), 760, Tiles.WOOD)
	for x in [500, 540, 980, 1020]:
		_spr("castle/furniture/bookshelf_a" if x % 40 == 20 else "castle/furniture/bookshelf_b", Vector2(x, 292), Vector2(32, 16))
	for x in [600, 920]:
		_spr("castle/furniture/dining_table", Vector2(x, 440), Vector2(100, 20))
		for dx in [-30, 0, 30]:
			_spr("castle/furniture/chair_blue" if dx != 0 else "castle/furniture/chair_red", Vector2(x + dx, 388), Vector2(14, 8))
	for x in [690, 830]:
		_spr("castle/decor/candelabra_a", Vector2(x, 292), Vector2(12, 8))
	for x in [500, 1020]:
		_spr("castle/decor/plant_urn", Vector2(x, 536), Vector2(24, 10))
	_spr("castle/decor/vase_blue", Vector2(640, 288), Vector2(16, 8))
	_spr("castle/decor/vase_blue", Vector2(880, 288), Vector2(16, 8))
	main._npc("court", Vector2(840, 330), "Steward", Story.STEWARD).variant = 2


# ---------------------------------------------------------------- gardens and courtyard

static func _garden(cx: float, x0: float, x1: float, fountain_y: float) -> void:
	_spr("cit_fountain", Vector2(cx, fountain_y + 44), Vector2(112, 34))
	# hedges framing the lawn, open where the paths cross
	for y in [-930, -110]:
		_hedge(x0 + 10, cx - 40, y)
		_hedge(cx + 40, x1 - 10, y)
	# flower beds in the four lawn quarters
	for qx in [lerpf(x0, cx, 0.5), lerpf(cx, x1, 0.5)]:
		for qy in [-760, -300]:
			_spr("cit_flowerbed", Vector2(qx, qy), Vector2(68, 14))
			_spr("cit_topiary", Vector2(qx - 70, qy - 40), Vector2(30, 12))
			_spr("cit_topiary", Vector2(qx + 70, qy + 40), Vector2(30, 12))
	# cypress trees lining the north-south path
	for y in [-880, -780, -680, -360, -260, -160]:
		for side in [-1, 1]:
			_spr("cit_cypress", Vector2(cx + side * 46, y), Vector2(20, 10))
	# benches and lamps around the fountain
	for side in [-1, 1]:
		_spr("cit_bench", Vector2(cx + side * 90, -640), Vector2(52, 12))
		_spr("cit_lamp", Vector2(cx + side * 130, -560), Vector2(10, 6))
		_spr("cit_lamp", Vector2(cx + side * 130, -470), Vector2(10, 6))


static func _gardens() -> void:
	_garden(-750, -1060, -440, -520)
	_garden(640, 440, 840, -520)
	for p in [Vector2(-1030, -900), Vector2(-470, -900), Vector2(-1030, -130), Vector2(-470, -130)]:
		_spr("cit_statue", p, Vector2(34, 14))


static func _courtyard() -> void:
	# a rope fence around the arena, open towards the hall, the gate and both wings
	var c := Vector2(0, 560)
	var n := 32
	for i in n:
		if i in [7, 8, 23, 24, 15, 16, 31, 0]:
			continue
		var p0 := (c + Vector2.from_angle(TAU * i / n) * 238.0).round()
		var p1 := (c + Vector2.from_angle(TAU * (i + 1) / n) * 238.0).round()
		var f = Fence.new()
		f.position = p0 if p0.y > p1.y else p1
		f.a = p0 - f.position
		f.b = p1 - f.position
		layer.add_child(f)
	# planting beds: roses, lavender, shrubs and wildflowers
	for side in [-1, 1]:
		var x: float = side * 420
		_spr("dec_roses", Vector2(x, 418), Vector2(24, 8))
		_spr("dec_shrub", Vector2(x - side * 6, 466), Vector2(22, 8))
		_spr("dec_lavender", Vector2(x + side * 8, 506), Vector2(18, 6))
		_spr("dec_roses", Vector2(x - side * 4, 546), Vector2(24, 8))
		_spr("dec_flowers", Vector2(x + 12, 440), Vector2.ZERO, Vector2.INF, false)
		_spr("dec_flowers", Vector2(x - 14, 490), Vector2.ZERO, Vector2.INF, false)
		_spr("dec_flowers", Vector2(x + 10, 528), Vector2.ZERO, Vector2.INF, false)
		var bx: float = side * 190
		_spr("dec_lavender", Vector2(bx - 36, 852), Vector2(18, 6))
		_spr("dec_shrub", Vector2(bx, 858), Vector2(22, 8))
		_spr("dec_lavender", Vector2(bx + 36, 852), Vector2(18, 6))
		_spr("dec_flowers", Vector2(bx - 14, 842), Vector2.ZERO, Vector2.INF, false)
		_spr("dec_flowers", Vector2(bx + 20, 866), Vector2.ZERO, Vector2.INF, false)
	# statues and fire bowls at the foot of the grand steps
	for side in [-1, 1]:
		_spr("cit_statue", Vector2(side * 200, 176), Vector2(34, 14))
		_spr("cit_brazier", Vector2(side * 150, 176), Vector2(20, 10), Vector2(0, -37))
	# lamps around the arena and along the avenue to the gate
	for p in [Vector2(-260, 380), Vector2(260, 380), Vector2(-260, 740), Vector2(260, 740),
			Vector2(-70, 860), Vector2(70, 860)]:
		_spr("cit_lamp", p, Vector2(10, 6))
	# banners on poles at the four corners of the courtyard
	for p in [Vector2(-380, 230), Vector2(380, 230), Vector2(-380, 880), Vector2(380, 880)]:
		_spr("cit_banner_blue", p, Vector2(10, 6), Vector2.INF, false)


static func _yards() -> void:
	# west: the military wing's training yard
	for x in [-1000, -920, -840]:
		_spr("cit_dummy", Vector2(x, 700), Vector2(16, 8))
	for x in [-660, -580]:
		_spr("cit_target", Vector2(x, 690), Vector2(28, 8))
	_deco("weapon_rack", Vector2(-990, 860))
	_deco("weapon_rack", Vector2(-880, 860))
	_deco("armor_stand", Vector2(-770, 860), Vector2(26, 14))
	# east: the service yard
	_deco("crates", Vector2(560, 700))
	_deco("crates", Vector2(630, 724))
	_deco("barrel", Vector2(700, 690), Vector2(22, 14))
	_deco("barrel", Vector2(726, 702), Vector2(22, 14))
	_deco("woodpile", Vector2(900, 700))
	_deco("ore_cart", Vector2(1000, 860), Vector2(40, 14))
	_deco("barrel", Vector2(560, 860), Vector2(22, 14))


static func _people(main) -> void:
	main._npc("guard", Vector2(-44, 990), "Royal guard", Story.GUARD_CITADEL_GATE)
	main._npc("guard", Vector2(44, 990), "Royal guard", Story.GUARD_CITADEL_GATE)
	main._npc("guard", Vector2(-80, 186), "Royal guard", Story.GUARD_HALL)
	main._npc("guard", Vector2(80, 186), "Royal guard", Story.GUARD_HALL)
	main._npc("guard", Vector2(-90, -700), "Royal guard", Story.GUARD_HALL)
	main._npc("guard", Vector2(90, -700), "Royal guard", Story.GUARD_HALL)
	main._npc("guard", Vector2(-700, 596), "Guard", Story.GUARD_WEST_WING)
	main._npc("guard", Vector2(700, 596), "Guard", Story.GUARD_EAST_WING)
	for p in [[Vector2(960, -735), "Sister Maren", Story.PRIEST, 2], [Vector2(-600, -200), "Gardener", Story.GARDENER, 1],
			[Vector2(560, -300), "Lady of the court", Story.COURT_LADY, 0], [Vector2(820, 780), "Servant", Story.SERVANT, 3]]:
		var n = main._npc("court", p[0], p[1], p[2])
		n.variant = p[3]
