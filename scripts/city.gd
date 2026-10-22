extends RefCounted
## Builds Akropolis Aigidos: the round outer wall with its gates, the districts of houses
## around the Royal Citadel, Haldor's yard, the market, the fields, and the cliff edge.
## The citadel itself is built by citadel.gd.

const Geo = preload("res://scripts/geo.gd")
const WallScript = preload("res://scripts/wall_segment.gd")
const TowerScript = preload("res://scripts/tower.gd")
const BuildingScript = preload("res://scripts/building.gd")
const FenceScript = preload("res://scripts/fence.gd")
const ResourceScript = preload("res://scripts/resource_node.gd")
const PropScript = preload("res://scripts/prop.gd")
const DecoScript = preload("res://scripts/deco.gd")

const WALL_SEGMENTS := 216
const SLATE := 4   # roof index for wealthy houses near the castle


static func build(main) -> void:
	var layer: Node2D = main.entity_layer
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_outer_wall(layer)
	_cliff_edge(main)
	_yard(layer, main)
	_fields(layer)
	_market(layer)
	_places(layer)
	_houses(layer, main, rng)


static func _wall(layer: Node2D, pa: Vector2, pb: Vector2, gate := false, height := 58.0) -> void:
	var w = WallScript.new()
	w.position = (pa + pb) * 0.5
	w.a = pa - w.position
	w.b = pb - w.position
	w.gate = gate
	w.height = height
	layer.add_child(w)


static func _tower(layer: Node2D, p: Vector2, cone := false, radius := 32.0, height := 88.0) -> void:
	var t = TowerScript.new()
	t.position = p
	t.cone = cone
	t.radius = radius
	t.height = height
	layer.add_child(t)


static func _outer_wall(layer: Node2D) -> void:
	var step := TAU / WALL_SEGMENTS
	var half := WALL_SEGMENTS / 2
	for i in WALL_SEGMENTS:
		if i == 0 or i == 1 or i == WALL_SEGMENTS - 1:
			continue  # north gate: open
		var c := -PI / 2.0 + i * step
		var pa := Vector2.from_angle(c - step * 0.5) * Geo.R_WALL
		var pb := Vector2.from_angle(c + step * 0.5) * Geo.R_WALL
		_wall(layer, pa, pb, i == half)  # south gate: sealed
	var towers := [WALL_SEGMENTS - 1, 2, half, half + 1]
	for k in range(6, WALL_SEGMENTS, 12):
		towers.append(k)
	for k in towers:
		var ang: float = -PI / 2.0 + (k - 0.5) * step
		_tower(layer, (Vector2.from_angle(ang) * Geo.R_WALL).round(), false, 34.0, 92.0)


static func _cliff_edge(main) -> void:
	# Invisible barrier along the plateau edge, open only where the Serpent's Way goes down
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var n := 360
	var r := Geo.R_CLIFF + 20.0
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var pa := Vector2.from_angle(a0) * r
		var pb := Vector2.from_angle(a1) * r
		var mid := (pa + pb) * 0.5
		if Geo.dist_to_path(mid, Geo.SERPENT_WAY) < 75.0:
			continue
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(pa.distance_to(pb) + 4.0, 40.0)
		cs.shape = rect
		cs.position = mid
		cs.rotation = (pb - pa).angle()
		body.add_child(cs)
	main.add_child(body)


static func _fence(layer: Node2D, pa: Vector2, pb: Vector2) -> void:
	var f = FenceScript.new()
	f.position = (pa + pb) * 0.5
	f.a = pa - f.position
	f.b = pb - f.position
	layer.add_child(f)


static func _yard(layer: Node2D, main) -> void:
	var r := Geo.YARD_RECT
	var tl := r.position
	var tr := Vector2(r.end.x, r.position.y)
	var bl := Vector2(r.position.x, r.end.y)
	var br := r.end
	_fence(layer, tl, tr)
	_fence(layer, tl, bl)
	_fence(layer, bl, br)
	_fence(layer, tr, Vector2(tr.x, Geo.YARD_DOOR.y - 45.0))     # gap toward the north road
	_fence(layer, Vector2(tr.x, Geo.YARD_DOOR.y + 45.0), br)

	var forge = BuildingScript.new()
	forge.kind = "forge"
	forge.position = Geo.FORGE_POS
	layer.add_child(forge)

	# Haldor's house, and the neighbours
	var o := Geo.YARD_RECT.position - Vector2(-520, -1210)   # yard layout was designed at (-520, -1210)
	for h in [[Vector2(-440, -1100) + o, 1, 0], [Vector2(-450, -935) + o, 0, 1], [Vector2(-340, -935) + o, 0, 0]]:
		var b = BuildingScript.new()
		b.position = h[0]
		b.style = h[1]
		b.roof = h[2]
		layer.add_child(b)
	var g = PropScript.new()
	g.kind = "garden"
	g.variant = 1
	g.position = Vector2(-470, -1010) + o
	layer.add_child(g)


static func _fields(layer: Node2D) -> void:
	# Fence pieces around the farm fields, with gaps to walk through
	var a0 := -1.24
	var a1 := -1.04
	var steps := 10
	for i in steps:
		if i % 3 == 1:
			continue
		var t0 := lerpf(a0, a1, float(i) / steps)
		var t1 := lerpf(a0, a1, float(i + 1) / steps)
		_fence(layer, (Vector2.from_angle(t0) * (Geo.MARKET_R.x + 10.0)).round(), (Vector2.from_angle(t1) * (Geo.MARKET_R.x + 10.0)).round())


static func _market(layer: Node2D) -> void:
	# Market square inside the north gate: rows of striped stalls around a well
	var well = PropScript.new()
	well.kind = "well"
	well.position = (Vector2.from_angle(-1.37) * 2270.0).round()
	layer.add_child(well)
	var i := 0
	for r in [2090.0, 2270.0, 2450.0]:
		var a: float = -1.47
		while a < -1.27:
			var pos: Vector2 = (Vector2.from_angle(a) * r).round()
			a += 64.0 / r
			if pos.distance_to(well.position) < 70.0:
				continue
			var s = PropScript.new()
			s.kind = "stall"
			s.variant = i % 4
			s.position = pos
			layer.add_child(s)
			i += 1


static func _deco(layer: Node2D, sprite: String, p: Vector2, solid := true, base := Vector2.ZERO) -> void:
	var d = DecoScript.new()
	d.sprite = sprite
	d.position = p
	d.solid = solid
	d.base = base
	layer.add_child(d)


static func _places(layer: Node2D) -> void:
	# Blacksmith compound: weapons and armour on display, firewood, storage
	var o := Geo.YARD_RECT.position - Vector2(-520, -1210)
	_deco(layer, "weapon_rack", Vector2(-110, -1150) + o)
	_deco(layer, "armor_stand", Vector2(-322, -1150) + o, true, Vector2(26, 14))
	_deco(layer, "woodpile", Vector2(-470, -1172) + o)
	_deco(layer, "barrel", Vector2(-96, -940) + o, true, Vector2(22, 14))
	_deco(layer, "barrel", Vector2(-124, -930) + o, true, Vector2(22, 14))
	_deco(layer, "crates", Vector2(-190, -925) + o)
	# The inn on the ring road
	_deco(layer, "inn", Geo.INN_POS, true, Vector2(120, 40))
	_deco(layer, "barrel", Geo.INN_POS + Vector2(-80, 6), true, Vector2(22, 14))
	_deco(layer, "crates", Geo.INN_POS + Vector2(84, 8))
	# Watchtowers on the plateau, guarding the approach
	for w in Geo.WATCHTOWERS:
		_deco(layer, "watchtower", w, true, Vector2(46, 18))
	# Outpost on the edge of the Forest of Elders
	_deco(layer, "outpost", Geo.OUTPOST_POS, true, Vector2(60, 30))
	_deco(layer, "barrel", Geo.OUTPOST_POS + Vector2(54, 10), true, Vector2(22, 14))
	_deco(layer, "crates", Geo.OUTPOST_POS + Vector2(-70, 14))
	# East quarry mining settlement
	var m := Geo.MINE_POS
	_deco(layer, "mine_entrance", m, true, Vector2(90, 30))
	_deco(layer, "headframe", m + Vector2(-210, -10), true, Vector2(70, 16))
	_deco(layer, "bunkhouse", m + Vector2(100, 190), true, Vector2(120, 40))
	_deco(layer, "shed", m + Vector2(-60, 200), true, Vector2(80, 36))
	_deco(layer, "ore_cart", m + Vector2(-2, 46), true, Vector2(40, 14))
	_deco(layer, "ore_cart", m + Vector2(-110, 70), true, Vector2(40, 14))
	_deco(layer, "ore_pile", m + Vector2(80, 40), true, Vector2(46, 14))
	_deco(layer, "ore_pile", m + Vector2(-160, 120), true, Vector2(46, 14))
	_deco(layer, "crates", m + Vector2(150, 70))
	_deco(layer, "barrel", m + Vector2(186, 80), true, Vector2(22, 14))


static func _houses(layer: Node2D, main, rng: RandomNumberGenerator) -> void:
	var yard := Geo.YARD_RECT.grow(70)
	var step := 115.0
	var y := -Geo.R_WALL
	while y < Geo.R_WALL:
		var x := -Geo.R_WALL
		while x < Geo.R_WALL:
			var p := (Vector2(x, y) + Vector2(rng.randf_range(-22, 22), rng.randf_range(-18, 18))).round()
			x += step
			var r := p.length()
			if Geo.in_citadel(p, 120.0) or r > Geo.R_WALL - 115.0:
				continue
			if (Geo.spoke_dist(p) < 88.0 and r > Geo.RING_ROAD - 60.0) or absf(p.x) < 100.0 and p.y > 0.0 or absf(r - Geo.RING_ROAD) < 96.0:
				continue
			if yard.has_point(p) or p.distance_to(Geo.GATE_IN) < 200.0 or p.distance_to(Geo.SOUTH_GATE) < 170.0 or Geo.reserved(p, 60.0):
				continue
			var a := p.angle()
			if r > Geo.MARKET_R.x - 40.0 and a > -1.55 and a < -0.98:
				continue  # farm fields
			var roll := rng.randf()
			if roll < 0.2:
				continue
			if roll < 0.3:
				var tree = ResourceScript.new()
				tree.kind = "tree"
				tree.main = main
				tree.variant = [0, 1, 4, 5, 6][rng.randi() % 5]
				tree.position = p
				layer.add_child(tree)
				continue
			if roll < 0.38:
				var g = PropScript.new()
				g.kind = "garden"
				g.variant = rng.randi() % 4
				g.position = p
				layer.add_child(g)
				continue
			var b = BuildingScript.new()
			b.position = p
			b.style = rng.randi() % 3
			b.roof = SLATE if (r < Geo.RING_ROAD and rng.randf() < 0.5) else rng.randi() % 4
			layer.add_child(b)
		y += step
