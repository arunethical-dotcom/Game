extends Node2D
## The front wall of an enterable citadel building, cut down to a low ledge. It appears
## when Kael is inside and the roof fades away, so the room still has a solid front wall
## with real thickness. It is y-sorted at the wall's base, so Kael is drawn behind it
## when he stands against the inside of the front wall. (Collision lives on the building.)

const T_STONE = preload("res://art/cit_tex_stone.png")
const T_TOP = preload("res://art/cit_tex_walltop.png")

var x0 := 0.0         # local x of the wall ends
var x1 := 0.0
var gaps := []        # [left, right] local x of each doorway
const H := 22         # visible height of the cut wall
const TOP := 12       # thickness of its top


func _tile(tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	var s := tex.get_size()
	var w := rect.position + position
	draw_texture_rect_region(tex, rect, Rect2(Vector2(fposmod(w.x, s.x), fposmod(w.y, s.y)), rect.size), tint)


func _draw() -> void:
	var xs := [x0]
	for g in gaps:
		xs.append(g[0])
		xs.append(g[1])
	xs.append(x1)
	for i in range(0, xs.size(), 2):
		var a: float = xs[i]
		var b: float = xs[i + 1]
		if b <= a:
			continue
		_tile(T_STONE, Rect2(a, -H, b - a, H), Color(0.8, 0.78, 0.74))
		draw_rect(Rect2(a, -6, b - a, 6), Color(0, 0, 0, 0.2))
		_tile(T_TOP, Rect2(a, -H - TOP, b - a, TOP))
		draw_rect(Rect2(a, -H - TOP, b - a, TOP + H), Color(0.12, 0.1, 0.08), false, 1.0)
		draw_rect(Rect2(a + 1, -H - TOP + 1, b - a - 2, 1), Color(1, 0.96, 0.88, 0.5))
	# door posts with gold caps
	for g in gaps:
		for x in [g[0] - 4, g[1] - 4]:
			draw_rect(Rect2(x, -H - TOP - 8, 8, H + TOP + 8), Color(0.62, 0.58, 0.52))
			draw_rect(Rect2(x, -H - TOP - 8, 8, H + TOP + 8), Color(0.12, 0.1, 0.08), false, 1.0)
			draw_rect(Rect2(x + 1, -H - TOP - 10, 6, 3), Color(0.85, 0.66, 0.3))
