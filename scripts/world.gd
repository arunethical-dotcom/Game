extends Node2D
## Seamless open world ground.
## The land is split into chunks. Chunks near the player load quietly in the background
## and far ones unload, so there are no loading screens anywhere: city, plateau or lowlands.

const Geo = preload("res://scripts/geo.gd")
const ChunkScript = preload("res://scripts/chunk.gd")
const ResourceScript = preload("res://scripts/resource_node.gd")

const TILE := 32
const CHUNK_TILES := 16
const CHUNK_PX := TILE * CHUNK_TILES
const LOAD_RADIUS := 2

var main
var noise := FastNoiseLite.new()
var chunks := {}      # Vector2i -> {"ground": Node2D, "props": Array}
var depleted := {}    # remembers which ore rocks were already mined
var _last_center := Vector2i(999999, 999999)


func _ready() -> void:
	noise.seed = 4242
	noise.frequency = 0.06


func update_chunks(player_pos: Vector2) -> void:
	var center := Vector2i(floori(player_pos.x / CHUNK_PX), floori(player_pos.y / CHUNK_PX))
	if center == _last_center:
		return
	_last_center = center
	for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var c := center + Vector2i(dx, dy)
			if not chunks.has(c):
				_load_chunk(c)
	for c in chunks.keys():
		if absi(c.x - center.x) > LOAD_RADIUS + 1 or absi(c.y - center.y) > LOAD_RADIUS + 1:
			_unload_chunk(c)


func _load_chunk(c: Vector2i) -> void:
	var origin := Vector2(c.x * CHUNK_PX, c.y * CHUNK_PX)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d,%d" % [c.x, c.y])

	var ground = ChunkScript.new()
	ground.position = origin
	# Biome of every tile, plus a 1-tile border so edges can blend
	var n := CHUNK_TILES + 2
	var grid := []
	grid.resize(n * n)
	for ty in n:
		for tx in n:
			var wp := origin + Vector2((tx - 1) * TILE + TILE * 0.5, (ty - 1) * TILE + TILE * 0.5)
			grid[ty * n + tx] = Geo.biome(wp)
	var tiles := PackedInt32Array()
	tiles.resize(CHUNK_TILES * CHUNK_TILES)
	var fringes := []
	for ty in CHUNK_TILES:
		for tx in CHUNK_TILES:
			var i := ty * CHUNK_TILES + tx
			var wp := origin + Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)
			var b: String = grid[(ty + 1) * n + tx + 1]
			tiles[i] = _tile_id(b, wp, c.x * CHUNK_TILES + tx, c.y * CHUNK_TILES + ty)
			if b in PATHLIKE:
				var nb := [grid[ty * n + tx + 1], grid[(ty + 1) * n + tx + 2], grid[(ty + 2) * n + tx + 1], grid[(ty + 1) * n + tx]]
				for side in 4:
					if nb[side] in GRASSLIKE:
						fringes.append([i, side])
	ground.tiles = tiles
	ground.fringes = fringes
	add_child(ground)

	# Trees and ore rocks, only outside the city walls
	var props := []
	for i in 12:
		var key := "%d_%d_%d" % [c.x, c.y, i]
		var wp := origin + Vector2(rng.randf_range(24, CHUNK_PX - 24), rng.randf_range(24, CHUNK_PX - 24))
		var roll := rng.randf()
		var b := Geo.biome(wp)
		var kind := ""
		match b:
			"elder":
				if roll < 0.7:
					kind = "tree"
			"plateau":
				if roll < 0.08 and wp.length() > Geo.R_WALL + 120.0:
					kind = "tree"
			"lowlands":
				if roll < 0.18:
					kind = "tree"
			"foothills":
				if roll < 0.32:
					kind = "rock"
				elif roll < 0.4:
					kind = "tree"
		if kind == "" or Geo.road_dist(wp) < 70.0 or wp.distance_to(Geo.DEN) < 160.0 or Geo.reserved(wp, 30.0):
			continue
		if kind == "rock" and depleted.has(key):
			continue
		var node = ResourceScript.new()
		node.kind = kind
		node.key = key
		node.main = main
		node.variant = _tree_variant(b, rng) if kind == "tree" else rng.randi() % 3
		node.position = wp
		main.entity_layer.add_child(node)
		props.append(node)

	chunks[c] = {"ground": ground, "props": props}


## Columns in trees.png: oak 0-1, pine 2-3, blossom 4-5, autumn 6-7, violet 8-9
static func _tree_variant(b: String, rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	match b:
		"elder":
			return rng.randi() % 10   # the Forest of Elders is full of colour
		"foothills":
			return 2 + rng.randi() % 2
		_:
			if r < 0.12:
				return 4 + rng.randi() % 4
			return rng.randi() % 4


func _unload_chunk(c: Vector2i) -> void:
	var data: Dictionary = chunks[c]
	data["ground"].queue_free()
	for p in data["props"]:
		if is_instance_valid(p):
			p.queue_free()
	chunks.erase(c)


const ROW := {"grass": 0, "grass_dark": 1, "grass_light": 2, "path": 3, "cobble": 4, "plaza": 5,
	"yard": 6, "field": 7, "rocky": 8, "cliff_top": 9, "cliff_face": 10, "water": 11, "mountain": 12}
const PATHLIKE := ["street", "road", "yard", "market"]
const GRASSLIKE := ["town", "plateau", "lowlands", "elder", "field"]


func _tile_id(b: String, wp: Vector2, gx: int, gy: int) -> int:
	var h := absi(hash(Vector2i(gx, gy))) % 20
	var v := 0 if h < 11 else (1 if h < 16 else (2 if h < 19 else 3))
	var row := "grass"
	match b:
		"mountain": row = "mountain"
		"castle": row = "cobble"
		"street", "road": row = "path"
		"yard": row = "yard"
		"market": row = "plaza"
		"field": row = "field"
		"town", "plateau": row = "grass"
		"elder": row = "grass_dark"
		"lowlands": row = "grass_light"
		"foothills": row = "rocky"
		"stream": row = "water"
		"cliff":
			row = "cliff_top" if wp.length() < Geo.R_CLIFF - 10.0 else "cliff_face"
	return ROW[row] * 4 + v


func clamp_to_world(p: Vector2) -> Vector2:
	var lim := Geo.WORLD_HALF - 300.0
	return Vector2(clampf(p.x, -lim, lim), clampf(p.y, -lim, lim))
