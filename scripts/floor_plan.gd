extends Node2D
## An indoor floor of the citadel (the Royal Residence upstairs, the Service Floor below),
## seen in the same 3/4 view as the rest of the game.
##
## Each room is a walkable rectangle. Above it stands its back wall (a tall face with a
## stone cap), and thin stone wall tops run down its sides and along its front. Doorways
## are passages cut through those walls. Everything here is drawn flat, under the people
## and furniture, so the y-sorted world draws correctly on top. Collision is built from the
## same walls, separately from the decoration.
##
## The floor sits far away from the open world in world space, over a dark backdrop; the
## stairs move Kael here behind a quick fade, so there is no loading screen.

const Tiles = preload("res://scripts/tiles.gd")
const T_STONE = preload("res://art/cit_tex_stone.png")
const T_TOP = preload("res://art/cit_tex_walltop.png")
const T_CARPET = preload("res://art/cit_tex_carpet.png")

const STRIP := 12   # thickness of a wall top seen from above

var rooms := []         # {rect: Rect2, row: int, alt: Array, h: int, tint: Color}
var passages := []      # Rect2 cut through walls, with the floor row to show: [Rect2, row]
var runners := []       # Rect2: red carpet with gold edges
var rugs := []          # [Texture2D, centre]
var face_items := []    # [Texture2D, top-left]   windows, portraits, banners on wall faces
var floor_items := []   # [Texture2D, top-left]   stairs drawn into the floor and wall
var pools := []         # [centre, radius]        warm light from sconces and fires
var shafts := []        # [x, y, length]          daylight falling from a window


func room(r: Rect2, row: int, h := 96, alt := [], tint := Color.WHITE) -> Rect2:
	rooms.append({"rect": r, "row": row, "h": h, "alt": alt, "tint": tint})
	return r


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for rm in rooms:
		for w in _walls(rm):
			var parts := [w]
			for p in passages:
				var next := []
				for a in parts:
					next.append_array(_sub(a, p[0]))
				parts = next
			for a in parts:
				var cs := CollisionShape2D.new()
				var s := RectangleShape2D.new()
				s.size = a.size
				cs.shape = s
				cs.position = a.get_center()
				body.add_child(cs)


func _walls(rm: Dictionary) -> Array:
	var r: Rect2 = rm["rect"]
	var h: float = rm["h"]
	return [
		Rect2(r.position.x - STRIP, r.position.y - h - STRIP, r.size.x + STRIP * 2, h + STRIP),
		Rect2(r.position.x - STRIP, r.position.y, STRIP, r.size.y + STRIP),
		Rect2(r.end.x, r.position.y, STRIP, r.size.y + STRIP),
		Rect2(r.position.x - STRIP, r.end.y, r.size.x + STRIP * 2, STRIP),
	]


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


func _tile(tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	var s := tex.get_size()
	var w := rect.position + position
	draw_texture_rect_region(tex, rect, Rect2(Vector2(fposmod(w.x, s.x), fposmod(w.y, s.y)), rect.size), tint)


func _draw() -> void:
	var bounds := Rect2()
	for rm in rooms:
		var r: Rect2 = rm["rect"]
		bounds = r if bounds.size == Vector2.ZERO else bounds.merge(r)
	draw_rect(bounds.grow(1400), Color(0.05, 0.04, 0.04))

	# floors
	for rm in rooms:
		Tiles.fill(self, rm["rect"], rm["row"], [0, 1, 2, 3] if rm["alt"].is_empty() else [0, 1], rm["alt"], position, rm["tint"])
	for p in passages:
		Tiles.fill(self, p[0], p[1], [0, 1], [], position)
	for c in runners:
		_tile(T_CARPET, c)
		if c.size.x > c.size.y:
			draw_rect(Rect2(c.position.x, c.position.y, c.size.x, 3), Color(0.85, 0.66, 0.3))
			draw_rect(Rect2(c.position.x, c.end.y - 3, c.size.x, 3), Color(0.85, 0.66, 0.3))
		else:
			draw_rect(Rect2(c.position.x, c.position.y, 3, c.size.y), Color(0.85, 0.66, 0.3))
			draw_rect(Rect2(c.end.x - 3, c.position.y, 3, c.size.y), Color(0.85, 0.66, 0.3))
	for g in rugs:
		var t: Texture2D = g[0]
		draw_texture(t, (g[1] - t.get_size() / 2).round())
	# daylight from the windows
	for s in shafts:
		var x: float = s[0]
		var y: float = s[1]
		var l: float = s[2]
		draw_colored_polygon(PackedVector2Array([Vector2(x - 12, y), Vector2(x + 12, y), Vector2(x + 12 + l * 0.35, y + l), Vector2(x - 12 + l * 0.35, y + l)]), Color(1.0, 0.92, 0.7, 0.07))
	# soft shadow where floors meet the walls
	for rm in rooms:
		var r: Rect2 = rm["rect"]
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 10), Color(0, 0, 0, 0.18))
		draw_rect(Rect2(r.position.x, r.position.y, 8, r.size.y), Color(0, 0, 0, 0.14))
		draw_rect(Rect2(r.end.x - 4, r.position.y, 4, r.size.y), Color(0, 0, 0, 0.1))

	# walls: back faces, then the wall tops
	for rm in rooms:
		var r: Rect2 = rm["rect"]
		var h: float = rm["h"]
		var face := Rect2(r.position.x - STRIP, r.position.y - h, r.size.x + STRIP * 2, h)
		_tile(T_STONE, face, Color(0.86, 0.84, 0.8))
		# wainscot: a walnut panel along the bottom of the wall, with a gold rail
		draw_rect(Rect2(face.position.x, face.end.y - 26, face.size.x, 26), Color(0.33, 0.22, 0.13))
		draw_rect(Rect2(face.position.x, face.end.y - 26, face.size.x, 2), Color(0.85, 0.66, 0.3))
		var x := face.position.x + 8
		while x < face.end.x - 12:
			draw_rect(Rect2(x, face.end.y - 21, 18, 16), Color(0.27, 0.17, 0.1))
			draw_rect(Rect2(x, face.end.y - 6, 18, 1), Color(0.45, 0.31, 0.19))
			x += 24
		draw_rect(Rect2(face.position.x, face.position.y, face.size.x, 3), Color(0, 0, 0, 0.25))
	for rm in rooms:
		for w in _walls(rm):
			var cap: Rect2 = w
			if cap == _walls(rm)[0]:
				cap = Rect2(w.position.x, w.position.y, w.size.x, STRIP)
			for part in _cut(cap):
				_tile(T_TOP, part, Color(0.92, 0.9, 0.86))
				draw_rect(part, Color(0.12, 0.1, 0.08), false, 1.0)

	# doorways: cut the face away and frame the opening
	for p in passages:
		var r: Rect2 = p[0]
		Tiles.fill(self, r, p[1], [0, 1], [], position)
		if r.size.y > r.size.x:   # a door through a back wall
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y), Color(0, 0, 0, 0.16))
			draw_rect(Rect2(r.position.x, r.position.y, 4, r.size.y), Color(0.2, 0.15, 0.12))
			draw_rect(Rect2(r.end.x - 4, r.position.y, 4, r.size.y), Color(0.2, 0.15, 0.12))
			draw_rect(Rect2(r.position.x + 4, r.position.y, 2, r.size.y), Color(0.75, 0.7, 0.62))
			draw_rect(Rect2(r.position.x, r.end.y - 4, r.size.x, 4), Color(0.85, 0.66, 0.3))
		else:
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 4), Color(0.2, 0.15, 0.12))
			draw_rect(Rect2(r.position.x, r.end.y - 4, r.size.x, 4), Color(0.2, 0.15, 0.12))

	for f in face_items:
		draw_texture(f[0], f[1])
	for f in floor_items:
		draw_texture(f[0], f[1])
	for l in pools:
		draw_circle(l[0], l[1], Color(1.0, 0.72, 0.35, 0.06))
		draw_circle(l[0], l[1] * 0.6, Color(1.0, 0.75, 0.4, 0.07))


## The parts of a wall top that are not cut by a doorway.
func _cut(r: Rect2) -> Array:
	var parts := [r]
	for p in passages:
		var next := []
		for a in parts:
			next.append_array(_sub(a, p[0]))
		parts = next
	return parts
