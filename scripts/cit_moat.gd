extends Node2D
## The moat around the citadel: slowly moving water, with a stone embankment
## along its outer edge.

const Geo = preload("res://scripts/geo.gd")
const WATER = preload("res://art/cit_tex_water.png")
const EMBANK = preload("res://art/cit_tex_embank.png")
const TOP = preload("res://art/cit_tex_walltop.png")

const SHADER := """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV + vec2(TIME * 0.012, TIME * 0.006);
	vec4 c = texture(TEXTURE, uv);
	c.rgb += 0.03 * sin(TIME * 1.5 + (UV.x + UV.y) * 6.0);
	COLOR = c;
}
"""

var water_node: Node2D


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# the water lives in its own child so only it gets the moving-water shader
	water_node = Node2D.new()
	water_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var sh := Shader.new()
	sh.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	water_node.material = mat
	water_node.draw.connect(_draw_water)
	add_child(water_node)
	_collision()


func _draw_water() -> void:
	var m := Geo.CIT_MOAT
	water_node.draw_texture_rect_region(WATER, m, Rect2(m.position, m.size))


func _tile(t: Texture2D, rect: Rect2) -> void:
	var s := t.get_size()
	draw_texture_rect_region(t, rect, Rect2(Vector2(fposmod(rect.position.x, s.x), fposmod(rect.position.y, s.y)), rect.size))


func _draw() -> void:
	pass


## Embankment edges drawn after the water (as a separate node above it).
class Edges extends Node2D:
	const Geo = preload("res://scripts/geo.gd")
	const EMBANK = preload("res://art/cit_tex_embank.png")
	const TOP = preload("res://art/cit_tex_walltop.png")

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _tile(t: Texture2D, rect: Rect2) -> void:
		var s := t.get_size()
		draw_texture_rect_region(t, rect, Rect2(Vector2(fposmod(rect.position.x, s.x), fposmod(rect.position.y, s.y)), rect.size))

	func _draw() -> void:
		var m := Geo.CIT_MOAT
		# far (north) bank: you see its stone face
		_tile(EMBANK, Rect2(m.position.x, m.position.y, m.size.x, 24))
		# near banks: a pale stone lip
		_tile(TOP, Rect2(m.position.x - 8, m.end.y, m.size.x + 16, 8))
		_tile(TOP, Rect2(m.position.x - 8, m.position.y - 8, 8, m.size.y + 16))
		_tile(TOP, Rect2(m.end.x, m.position.y - 8, 8, m.size.y + 16))
		_tile(TOP, Rect2(m.position.x - 8, m.position.y - 8, m.size.x + 16, 8))
		draw_rect(Rect2(m.position.x, m.end.y, m.size.x, 1), Color(0.1, 0.15, 0.2, 0.8))


func _collision() -> void:
	var m := Geo.CIT_MOAT
	var w := Geo.CIT_WALL
	var b := Geo.CIT_BRIDGE
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var boxes := [
		Rect2(m.position.x, m.position.y, m.size.x, w.position.y - m.position.y - 28),          # north
		Rect2(m.position.x, m.position.y, w.position.x - m.position.x, m.size.y),               # west
		Rect2(w.end.x, m.position.y, m.end.x - w.end.x, m.size.y),                              # east
		Rect2(m.position.x, w.end.y, b.position.x - m.position.x - 2, m.end.y - w.end.y),       # south, left of bridge
		Rect2(b.end.x + 2, w.end.y, m.end.x - b.end.x - 2, m.end.y - w.end.y),                  # south, right of bridge
	]
	for r in boxes:
		var cs := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = r.size
		cs.shape = s
		cs.position = r.get_center()
		body.add_child(cs)
	add_child(body)
