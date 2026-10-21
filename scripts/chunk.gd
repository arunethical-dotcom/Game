extends Node2D
## One square piece of the ground, drawn from the pixel-art tileset. Cached by the engine.

const TILESET = preload("res://art/tiles.png")
const FLORA = preload("res://art/flora.png")
const TILE := 32        # world size of one tile
const SRC := 32         # pixel size of one tile in the tileset
const CHUNK_TILES := 16
const FRINGE_ROW := 13
const KERB_ROW := 15

var tiles := PackedInt32Array()   # row * 4 + variant for each tile
var fringes := []                 # [tile_index, side] grass hanging over paths
var kerbs := []                   # [tile_index, side] kerb stones along brick streets
var tints := PackedColorArray()   # per-tile light variation
var flora := []                   # [local position, cell] small flat plants


func _draw() -> void:
	for i in tiles.size():
		var id := tiles[i]
		var tx := i % CHUNK_TILES
		var ty := i / CHUNK_TILES
		draw_texture_rect_region(TILESET, Rect2(tx * TILE, ty * TILE, TILE, TILE),
			Rect2((id % 4) * SRC, (id / 4) * SRC, SRC, SRC), tints[i] if i < tints.size() else Color.WHITE)
	for k in kerbs:
		var i: int = k[0]
		var c := Vector2((i % CHUNK_TILES) * TILE + TILE * 0.5, (i / CHUNK_TILES) * TILE + TILE * 0.5)
		draw_set_transform(c, k[1] * PI * 0.5, Vector2.ONE)
		draw_texture_rect_region(TILESET, Rect2(-TILE * 0.5, -TILE * 0.5, TILE, TILE),
			Rect2((i % 4) * SRC, KERB_ROW * SRC, SRC, SRC))
	for f in fringes:
		var i: int = f[0]
		var side: int = f[1]   # 0 top, 1 right, 2 bottom, 3 left
		var c := Vector2((i % CHUNK_TILES) * TILE + TILE * 0.5, (i / CHUNK_TILES) * TILE + TILE * 0.5)
		draw_set_transform(c, side * PI * 0.5, Vector2.ONE)
		draw_texture_rect_region(TILESET, Rect2(-TILE * 0.5, -TILE * 0.5, TILE, TILE),
			Rect2((i % 4) * SRC, FRINGE_ROW * SRC, SRC, SRC))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for fl in flora:
		var p: Vector2 = fl[0]
		draw_texture_rect_region(FLORA, Rect2(p.x - 16, p.y - 28, 32, 32), Rect2(fl[1] * 32, 0, 32, 32))
