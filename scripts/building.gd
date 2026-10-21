extends StaticBody2D
## Village buildings drawn from pixel-art sprites.
## Houses: pick `style` (size 0-3) and `roof` (0 red, 1 brown, 2 blue, 3 teal, 4 slate).
## The forge has an animated furnace glow and chimney smoke.

const HOUSES = preload("res://art/houses.png")
const FORGE = preload("res://art/forge.png")
const HOUSE_W := [36, 42, 48, 56]
const HOUSE_H := [34, 36, 38, 38]

var kind := "house"
var style := 0
var roof := 0
var t := 0.0


func footprint() -> Vector2:
	if kind == "forge":
		return Vector2(136, 70)
	return Vector2(HOUSE_W[style] * 2 - 6, 40)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = footprint()
	cs.shape = r
	cs.position = Vector2(0, -r.size.y * 0.5)
	add_child(cs)
	t = randf() * 5.0


func _process(delta: float) -> void:
	if kind == "forge":
		t += delta
		queue_redraw()


func _draw() -> void:
	if kind == "forge":
		_draw_forge()
		return
	var w: int = HOUSE_W[style]
	draw_rect(Rect2(-w + 2, -6, w * 2 - 4, 10), Color(0, 0, 0, 0.18))
	# each cell in houses.png is 56x40, sprite bottom-centred in the cell
	draw_texture_rect_region(HOUSES, Rect2(-56, -78, 112, 80), Rect2(style * 112, roof * 80, 112, 80))


func _draw_forge() -> void:
	draw_rect(Rect2(-70, -6, 140, 10), Color(0, 0, 0, 0.2))
	# forge sprite is 72x62, drawn at 2x with its base on the origin
	draw_texture_rect_region(FORGE, Rect2(-72, -120, 144, 124), Rect2(0, 0, 144, 124))
	# anvil in front
	draw_texture_rect_region(FORGE, Rect2(-104, 0, 36, 20), Rect2(146, 100, 36, 20))
	# furnace glow (the furnace mouth in the sprite is around pixels 26-45, 41-57)
	var flicker := 0.35 + 0.25 * sin(t * 13.0) * sin(t * 7.3)
	draw_rect(Rect2(-72 + 52, -120 + 82, 40, 34), Color(1.0, 0.75, 0.3, flicker))
	# chimney smoke, as chunky pixel puffs
	for i in 5:
		var p := fmod(t * 0.3 + i * 0.2, 1.0)
		var sz := roundf((3.0 + p * 6.0)) * 2.0
		var sp := Vector2(-72 + 112 + sin(p * 6.0 + i) * 8.0, -120 - p * 90.0)
		sp = (sp / 2.0).round() * 2.0
		draw_rect(Rect2(sp - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(0.85, 0.85, 0.85, 0.5 * (1.0 - p)))
