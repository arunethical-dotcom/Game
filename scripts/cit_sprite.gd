extends StaticBody2D
## One citadel object drawn from art/cit_<name>.png (or another sprite), feet on this
## node's position. Optional collision, flickering flame, and gentle animation.

const Shadow = preload("res://scripts/shadow.gd")

var sprite := "cit_bench"
var solid := Vector2.ZERO     # collision box at the base; zero = walk-through
var flame := Vector2.INF      # where a fire burns, relative to the feet
var shadow := true
var flip := false
var water := false            # fountain: sparkle on the water
var lift := 0                 # draw this many pixels above the feet (things hung on a wall)
var tex: Texture2D
var t := 0.0


func _ready() -> void:
	tex = load("res://art/%s.png" % sprite)
	t = randf() * 10.0
	collision_layer = 1
	collision_mask = 0
	if solid != Vector2.ZERO:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = solid
		cs.shape = r
		cs.position = Vector2(0, -solid.y / 2.0)
		add_child(cs)
	set_process(flame != Vector2.INF or water)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var w := tex.get_width()
	var h := tex.get_height()
	if shadow:
		Shadow.soft(self, Vector2(2, 0), maxf(8.0, w * 0.45), maxf(4.0, w * 0.12), 0.38)
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if flip else 1, 1))
	draw_texture(tex, Vector2(-(w / 2), -h + 1 - lift))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if flame != Vector2.INF:
		_draw_flame(flame)
	if water:
		for i in 6:
			var a := t * 0.9 + i * 1.7
			var p := Vector2(cos(a) * (w * 0.3), sin(a * 1.3) * 10.0 - h * 0.28).round()
			draw_rect(Rect2(p, Vector2(2, 1)), Color(0.85, 0.95, 1.0, 0.5 + 0.5 * sin(t * 3.0 + i)))


func _draw_flame(at: Vector2) -> void:
	var f := 0.75 + 0.25 * sin(t * 13.0) * sin(t * 7.1 + 1.3)
	draw_circle(at + Vector2(0, -4), 20.0 * f, Color(1.0, 0.7, 0.3, 0.10))
	draw_circle(at + Vector2(0, -4), 12.0 * f, Color(1.0, 0.75, 0.35, 0.14))
	var h := roundf(10.0 * f)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(6, 0), at + Vector2(0, -h - 4)]), Color(1.0, 0.45, 0.12))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-3, 0), at + Vector2(3, 0), at + Vector2(0, -h)]), Color(1.0, 0.85, 0.35))
