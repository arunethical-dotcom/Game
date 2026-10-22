extends StaticBody2D
## One section of a low post-and-rope fence (the arena ring). The node sits at the lower
## end of the section so y-sorting puts Kael correctly in front of or behind it.

var a := Vector2.ZERO    # section ends, relative to this node
var b := Vector2.ZERO
var solid := true

const POST := Color(0.35, 0.23, 0.13)
const POST_LIT := Color(0.54, 0.36, 0.22)
const GOLD := Color(0.85, 0.66, 0.3)
const ROPE := Color(0.67, 0.18, 0.19)
const ROPE_DARK := Color(0.43, 0.08, 0.1)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if solid:
		var cs := CollisionShape2D.new()
		var s := SegmentShape2D.new()
		s.a = a
		s.b = b
		cs.shape = s
		add_child(cs)


func _post(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-3, -20), Vector2(6, 20)), POST)
	draw_rect(Rect2(p + Vector2(-3, -20), Vector2(2, 20)), POST_LIT)
	draw_rect(Rect2(p + Vector2(-3, -23), Vector2(6, 4)), GOLD)
	draw_rect(Rect2(p + Vector2(-4, -1), Vector2(8, 2)), Color(0, 0, 0, 0.25))


func _draw() -> void:
	# the rope sags a little between the posts
	var pts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		pts.append((a.lerp(b, t) + Vector2(0, -15 + 3.0 * sin(t * PI))).round())
	draw_polyline(pts, ROPE, 2.0)
	var low := PackedVector2Array()
	for p in pts:
		low.append(p + Vector2(0, 1))
	draw_polyline(low, ROPE_DARK, 1.0)
	_post(a)
	_post(b)
