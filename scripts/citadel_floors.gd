extends RefCounted
## The citadel's other floors, reached by the stairs in the Grand Throne Hall:
##
##   ROYAL RESIDENCE (up)                         SERVICE FLOOR (down)
##   +--------+--------+--------+-----------+     +-----------+---------+-----------+
##   | King & | Princes| Princess| King's    |     |  Kitchen  |Storeroom| Servants' |
##   | Queen  |        |         | sister's  |     |           |         | quarters  |
##   +--D-----+---D----+----D----+----D------+     +-----D-----+----D----+-----D-----+
##   |=stairs===== Royal corridor ==========|     |=stairs===== Service hall =======|
##   +---------------D----------------------+     +---------------------------------+
##                | Royal library |
##
## Each floor is a FloorPlan node (walls, floors, doorways and collision) placed far from
## the open world, plus furniture and people in the normal y-sorted entity layer.

const FloorPlan = preload("res://scripts/floor_plan.gd")
const Tiles = preload("res://scripts/tiles.gd")
const Spr = preload("res://scripts/cit_sprite.gd")
const Deco = preload("res://scripts/deco.gd")
const Story = preload("res://scripts/story.gd")

const UP_O := Vector2(20000, 0)       # world position of the residence floor's origin
const DOWN_O := Vector2(20000, 4000)  # and of the service floor

# where Kael arrives on each floor, and back in the throne hall
const UP_ARRIVE := UP_O + Vector2(-588, 132)
const DOWN_ARRIVE := DOWN_O + Vector2(-392, 118)
const HALL_FROM_UP := Vector2(-274, -770)
const HALL_FROM_DOWN := Vector2(274, -736)

const STRIP := FloorPlan.STRIP

static var layer: Node2D
static var main_ref
static var o := Vector2.ZERO


static func build(main) -> void:
	main_ref = main
	layer = main.entity_layer
	_residence(main)
	_service(main)


# ---------------------------------------------------------------- helpers

static func _put(name: String, p: Vector2, solid := Vector2.ZERO, shadow := true, flame := Vector2.INF) -> Node2D:
	var s = Spr.new()
	s.sprite = name
	s.flame = flame
	s.position = (o + p).round()
	s.solid = solid
	s.shadow = shadow
	layer.add_child(s)
	return s


static func _sconce(fp, p: Vector2) -> void:
	# a torch on a wall face; p = local point at the bottom of the face
	var s = Spr.new()
	s.sprite = "dec_sconce"
	s.position = (o + p).round()
	s.lift = 40
	s.flame = Vector2(0, -66)
	s.shadow = false
	layer.add_child(s)
	fp.pools.append([p + Vector2(0, 30), 46.0])


static func _deco(name: String, p: Vector2, base := Vector2.ZERO) -> void:
	var d = Deco.new()
	d.sprite = name
	d.position = (o + p).round()
	d.base = base
	layer.add_child(d)


static func _person(role: String, p: Vector2, label: String, lines: Array, variant := 0) -> void:
	var n = main_ref._npc(role, o + p, label, lines)
	if role == "court":
		n.variant = variant


static func _door(fp, r: Rect2, row: int, label: String, lines: Array) -> void:
	# a doorway cut through a wall, with a name plate you can read next to it
	fp.passages.append([r, row])
	main_ref._npc("none", o + Vector2(r.end.x + 22, r.end.y + 16), label, lines)


static func _room_windows(fp, r: Rect2, h: int, portrait := "") -> void:
	var face_top := r.position.y - h
	var win := load("res://art/cit_window_stained.png")
	for t in [0.22, 0.78]:
		var x := roundf(lerpf(r.position.x, r.end.x, t))
		fp.face_items.append([win, Vector2(x - 12, face_top + 14)])
		fp.shafts.append([x, r.position.y, minf(r.size.y * 0.6, 160.0)])
	if portrait != "":
		var t: Texture2D = load("res://art/%s.png" % portrait)
		fp.face_items.append([t, Vector2(roundf(r.get_center().x - t.get_width() / 2.0), face_top + 12)])


# ---------------------------------------------------------------- royal residence (up)

static func _residence(main) -> void:
	o = UP_O
	var fp = FloorPlan.new()
	fp.position = o
	fp.z_index = -6
	var hall: Rect2 = fp.room(Rect2(-640, 0, 1280, 160), Tiles.MARBLE, 96, [2, 3])
	var king: Rect2 = fp.room(Rect2(-640, -420, 310, 300), Tiles.C_WOOD, 96)
	var princes: Rect2 = fp.room(Rect2(-306, -420, 270, 300), Tiles.C_WOOD, 96)
	var princess: Rect2 = fp.room(Rect2(-12, -420, 220, 300), Tiles.C_WOOD_CHEVRON, 96)
	var sister: Rect2 = fp.room(Rect2(232, -420, 408, 300), Tiles.C_WOOD, 96)
	var library: Rect2 = fp.room(Rect2(-240, 264, 480, 220), Tiles.C_WOOD_CHEVRON, 80)

	# doors from the corridor (through its back wall) into each chamber
	var door_h := -king.end.y + 4
	_door(fp, Rect2(-513, -124, 56, door_h + 4), Tiles.WOOD, "King's chamber", Story.SIGN_KING)
	_door(fp, Rect2(-199, -124, 56, door_h + 4), Tiles.WOOD, "Princes' chamber", Story.SIGN_PRINCES)
	_door(fp, Rect2(70, -124, 56, door_h + 4), Tiles.WOOD, "Princess's chamber", Story.SIGN_PRINCESS)
	_door(fp, Rect2(408, -124, 56, door_h + 4), Tiles.WOOD, "The king's sister's rooms", Story.SIGN_SISTER)
	fp.passages.append([Rect2(-28, 156, 56, library.position.y - 156 + 4), Tiles.WOOD])
	main._npc("none", o + Vector2(52, 140), "Royal library", Story.SIGN_LIBRARY)

	# the corridor: runner, banners and portraits on the wall, torches, armour
	fp.runners.append(Rect2(-530, 74, 1160, 36))
	for p in [[-330, "castle/decor/portrait_king", -78], [-40, "castle/decor/banner_lion_blue", -88],
			[260, "castle/decor/portrait_lady", -86], [560, "castle/decor/painting_castle", -76],
			[-120, "castle/decor/banner_fleur_red", -88], [600, "castle/decor/banner_lion_red", -90]]:
		var t: Texture2D = load("res://art/%s.png" % p[1])
		fp.face_items.append([t, Vector2(p[0] - t.get_width() / 2, p[2])])
	for x in [-420, -250, 30, 170, 330, 520]:
		_sconce(fp, Vector2(x, 0))
	_put("castle/decor/plant_urn", Vector2(-290, 40), Vector2(24, 10))
	_put("castle/decor/plant_pot", Vector2(610, 40), Vector2(24, 10))
	_put("castle/decor/armour_a", Vector2(-80, 40), Vector2(20, 10))
	_put("castle/decor/armour_b", Vector2(120, 40), Vector2(20, 10))
	_put("castle/decor/vase_blue", Vector2(380, 40), Vector2(16, 8))
	_person("guard", Vector2(230, 130), "Royal guard", Story.RESIDENCE_GUARD)

	# stairs down to the throne hall at the west end of the corridor
	fp.floor_items.append([load("res://art/dec_stairs_down.png"), Vector2(-636, 2)])
	_block(fp, Rect2(-636, 0, 10, 96))
	_block(fp, Rect2(-550, 0, 10, 96))
	main.add_stairs(Rect2(o + Vector2(-620, 8), Vector2(64, 44)), HALL_FROM_UP, "", "up", "Grand Throne Hall")

	# King and Queen's chamber
	_room_windows(fp, king, 96, "castle/decor/portrait_lady")
	fp.rugs.append([load("res://art/castle/rugs/rug_blue_diamond.png"), Vector2(-485, -230)])
	_put("castle/furniture/bed_canopy", Vector2(-570, -300), Vector2(68, 50))
	_put("castle/furniture/chest_gold", Vector2(-570, -262), Vector2(40, 12))
	_put("castle/furniture/dresser", Vector2(-380, -380), Vector2(40, 14))
	_put("castle/furniture/desk", Vector2(-395, -190), Vector2(62, 14))
	_put("castle/furniture/chair_red", Vector2(-395, -218), Vector2(14, 8))
	_put("castle/decor/candelabra_a", Vector2(-620, -150), Vector2(12, 8))
	_put("castle/decor/plant_pot", Vector2(-350, -134), Vector2(20, 10))
	_person("court", Vector2(-470, -320), "Royal maid", Story.ROYAL_MAID, 3)
	fp.pools.append([Vector2(-620, -170), 40.0])

	# the two princes share a room
	_room_windows(fp, princes, 96, "castle/decor/painting_castle")
	_put("castle/furniture/bed_blue", Vector2(-266, -300), Vector2(48, 44))
	_put("castle/furniture/bed_blue", Vector2(-76, -300), Vector2(48, 44))
	_put("castle/furniture/chest_blue", Vector2(-266, -262), Vector2(38, 12))
	_put("castle/furniture/chest_wood", Vector2(-76, -262), Vector2(34, 12))
	_put("castle/furniture/bookshelf_a", Vector2(-171, -366), Vector2(32, 18))
	_put("castle/decor/weapon_rack", Vector2(-260, -130), Vector2(34, 10))
	_put("castle/decor/shield_stand", Vector2(-80, -130), Vector2(30, 10))
	fp.rugs.append([load("res://art/castle/rugs/runner_blue.png"), Vector2(-171, -240)])

	# the princess
	_room_windows(fp, princess, 96, "castle/decor/portrait_lady")
	fp.rugs.append([load("res://art/castle/rugs/rug_red_medallion.png"), Vector2(98, -236)])
	_put("castle/furniture/bed_canopy", Vector2(160, -300), Vector2(68, 50))
	_put("castle/furniture/dresser", Vector2(20, -380), Vector2(40, 14))
	_put("castle/furniture/chair_blue", Vector2(20, -340), Vector2(14, 8))
	_put("castle/decor/flower_planter", Vector2(170, -132), Vector2(48, 10))
	_put("castle/furniture/jewel_box", Vector2(10, -140), Vector2(28, 10))

	# the king's sister, her son and her daughter
	_room_windows(fp, sister, 96, "castle/decor/portrait_king")
	fp.rugs.append([load("res://art/castle/rugs/rug_red.png"), Vector2(436, -236)])
	_put("castle/furniture/bed_canopy", Vector2(300, -300), Vector2(68, 50))
	_put("castle/furniture/bed_blue", Vector2(540, -300), Vector2(48, 44))
	_put("castle/furniture/bed_simple", Vector2(604, -300), Vector2(34, 40))
	_put("castle/furniture/chest_blue", Vector2(540, -262), Vector2(38, 12))
	_put("castle/furniture/chest_wood", Vector2(604, -262), Vector2(34, 12))
	_put("castle/furniture/sofa_blue", Vector2(320, -168), Vector2(36, 10))
	_put("castle/furniture/side_table", Vector2(372, -170), Vector2(28, 10))
	_put("castle/decor/candelabra_b", Vector2(620, -150), Vector2(12, 8))
	_put("castle/decor/vase_blue", Vector2(254, -136), Vector2(16, 8))
	_put("castle/furniture/screen", Vector2(560, -150), Vector2(50, 10))

	# the royal library, south of the corridor
	for p in [[-200, "bookshelf_a"], [-160, "bookshelf_b"], [-110, "bookshelf_a"], [110, "bookshelf_b"], [160, "bookshelf_a"], [200, "bookshelf_b"]]:
		_put("castle/furniture/" + p[1], Vector2(p[0], 318), Vector2(32, 16))
	fp.rugs.append([load("res://art/castle/rugs/rug_blue_small.png"), Vector2(0, 400)])
	_put("castle/furniture/desk", Vector2(-120, 430), Vector2(62, 14))
	_put("castle/furniture/armchair", Vector2(-120, 404), Vector2(20, 8))
	_put("castle/furniture/desk", Vector2(120, 430), Vector2(62, 14))
	_put("castle/furniture/royal_chair", Vector2(120, 404), Vector2(30, 8))
	_put("castle/decor/candelabra_a", Vector2(-210, 470), Vector2(12, 8))
	_put("castle/decor/candelabra_b", Vector2(210, 470), Vector2(12, 8))
	_put("castle/decor/statue_saint", Vector2(0, 470), Vector2(22, 10))
	_person("court", Vector2(40, 380), "Royal scribe", Story.SCRIBE, 2)
	fp.pools.append([Vector2(-210, 450), 40.0])
	fp.pools.append([Vector2(210, 450), 40.0])

	main.add_child(fp)


# ---------------------------------------------------------------- service floor (down)

static func _service(main) -> void:
	o = DOWN_O
	var fp = FloorPlan.new()
	fp.position = o
	fp.z_index = -6
	var hall: Rect2 = fp.room(Rect2(-480, 0, 960, 160), Tiles.C_LIMESTONE, 96, [], Color(0.9, 0.88, 0.84))
	var kitchen: Rect2 = fp.room(Rect2(-480, -420, 360, 300), Tiles.C_DARKSTONE, 96)
	var store: Rect2 = fp.room(Rect2(-96, -420, 240, 300), Tiles.FLAG, 96, [], Color(0.8, 0.78, 0.74))
	var quarters: Rect2 = fp.room(Rect2(168, -420, 312, 300), Tiles.WOOD, 96)
	var door_h := -kitchen.end.y + 4
	_door(fp, Rect2(-328, -124, 56, door_h + 4), Tiles.FLAG, "Kitchen", Story.SIGN_KITCHEN)
	_door(fp, Rect2(-4, -124, 56, door_h + 4), Tiles.FLAG, "Storeroom", Story.SIGN_STORE)
	_door(fp, Rect2(296, -124, 56, door_h + 4), Tiles.WOOD, "Servants' quarters", Story.SIGN_QUARTERS)
	for x in [-230, 100, 400]:
		_sconce(fp, Vector2(x, 0))
	for r in [kitchen, store, quarters]:
		_sconce(fp, Vector2(roundf(r.get_center().x), r.position.y))

	# stairs up to the throne hall, climbing into the back wall of the service hall
	fp.floor_items.append([load("res://art/castle/walls/stairs_worn.png"), Vector2(-440, -36)])
	_block(fp, Rect2(-440, 0, 14, 78))
	_block(fp, Rect2(-358, 0, 14, 78))
	main.add_stairs(Rect2(o + Vector2(-424, 0), Vector2(64, 30)), HALL_FROM_DOWN, "", "down", "Grand Throne Hall")
	_put("castle/kitchen/barrel_small", Vector2(440, 40), Vector2(18, 8))
	_put("castle/kitchen/barrel_sack", Vector2(400, 44), Vector2(40, 12))
	_put("castle/furniture/kitchen_table", Vector2(200, 130), Vector2(84, 14))
	_person("court", Vector2(-120, 110), "Servant", Story.SERVANT_BELOW, 1)

	# kitchen: hearth, oven and stove along the back wall, tables and stores
	_put("castle/kitchen/fireplace", Vector2(-420, -386), Vector2(54, 16), true, Vector2(0, -16))
	_put("castle/kitchen/oven", Vector2(-340, -384), Vector2(34, 16))
	_put("castle/kitchen/stove", Vector2(-180, -384), Vector2(48, 16))
	_put("castle/kitchen/pans_rack", Vector2(-260, -394), Vector2(40, 8))
	_put("castle/furniture/kitchen_table", Vector2(-380, -250), Vector2(84, 14))
	_put("castle/furniture/food_shelf", Vector2(-170, -250), Vector2(60, 14))
	_put("castle/kitchen/barrels_stack", Vector2(-440, -140), Vector2(32, 12))
	_put("castle/kitchen/sack_basket", Vector2(-160, -140), Vector2(26, 10))
	_put("castle/kitchen/bread_basket", Vector2(-200, -136), Vector2(24, 10))
	_put("castle/kitchen/bucket", Vector2(-400, -186), Vector2(22, 8))
	_person("court", Vector2(-250, -300), "Cook", Story.COOK, 0)
	fp.pools.append([Vector2(-420, -370), 70.0])

	# storeroom
	_put("castle/kitchen/barrels_stack", Vector2(-60, -350), Vector2(32, 12))
	_deco("crates", Vector2(100, -350))
	_put("castle/kitchen/barrel_sack", Vector2(-60, -250), Vector2(40, 12))
	_put("castle/kitchen/barrel_small", Vector2(-76, -170), Vector2(18, 8))
	_put("castle/kitchen/jug", Vector2(-54, -170), Vector2(14, 8))
	_put("dec_hay", Vector2(110, -250), Vector2(36, 14))
	_put("castle/furniture/chest_wood", Vector2(110, -170), Vector2(34, 12))
	_put("castle/kitchen/tub", Vector2(110, -306), Vector2(22, 8))

	# servants' quarters
	for x in [204, 250, 412, 458]:
		_put("castle/furniture/bed_simple", Vector2(x, -330), Vector2(34, 40))
	_put("castle/furniture/low_table", Vector2(420, -186), Vector2(40, 10))
	_put("castle/furniture/stool", Vector2(400, -210), Vector2(14, 8))
	_put("castle/furniture/stool", Vector2(440, -210), Vector2(14, 8))
	_put("castle/furniture/washstand", Vector2(200, -160), Vector2(26, 10))
	_put("castle/furniture/screen", Vector2(250, -150), Vector2(50, 10))

	main.add_child(fp)


static func _block(fp, r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	cs.shape = s
	cs.position = o + r.get_center()
	body.add_child(cs)
	layer.add_child(body)
