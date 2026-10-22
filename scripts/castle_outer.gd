extends RefCounted
## The Royal Castle, drawn from the reference painting itself so it matches it exactly:
## every tower, wall, roof, building, garden and tree is where the painting has it.
##
## source_art/castle3/reference_map.png is shown at 3x (nearest neighbour, crisp pixels;
## the castle kit is drawn at the same scale). tools/castle_mask.py works out from the
## painting which pixels are walkable ground, water, or upright things (walls, towers,
## trees, statues) and where each upright thing stands (art/castle3/ref_depth.png), plus
## the collision boxes (art/castle3/ref_collision.json).
##
## In game:
##  - the painting is the ground layer (water pixels shimmer gently);
##  - an occluder copy of the painting is drawn above the characters, showing only the
##    upright pixels whose base is south of Kael's feet, near Kael, so he walks behind
##    towers, trees and statues and in front of them;
##  - the collision boxes keep him on the paths, courtyards, terraces, stairs and causeway.

const Geo = preload("res://scripts/geo.gd")
const Spr = preload("res://scripts/cit_sprite.gd")
const Story = preload("res://scripts/story.gd")
const REF = preload("res://art/castle3/castle_painting.png")
const DEPTH = preload("res://art/castle3/ref_depth.png")
const S := 3.0

const SHADER := """
shader_type canvas_item;
uniform sampler2D depth_tex : filter_nearest;
uniform int mode = 0;               // 0 = ground layer, 1 = occluder above the characters
uniform vec2 player = vec2(0.0);    // Kael's feet in painting px
uniform float reach = 30.0;         // occluder radius around Kael in painting px
varying vec2 px;
void vertex() { px = VERTEX; }
void fragment() {
	vec4 d = texture(depth_tex, UV);
	float kind = d.b;
	vec4 c = texture(TEXTURE, UV);
	if (mode == 0) {
		if (kind > 0.4 && kind < 0.6) {
			// water: a slow shimmer
			float w = sin(TIME * 1.3 + px.x * 0.09 + px.y * 0.05) * sin(TIME * 0.9 - px.y * 0.07);
			c.rgb += vec3(0.02, 0.035, 0.05) * w;
		}
		COLOR = c;
	} else {
		float base = floor(d.r * 255.0 + 0.5) * 256.0 + floor(d.g * 255.0 + 0.5);
		vec2 p = UV * vec2(textureSize(TEXTURE, 0));
		vec2 rel = p - (player + vec2(0.0, -10.0));
		bool near = abs(rel.x) < reach && rel.y > -reach * 1.2 && rel.y < reach * 0.6;
		if (kind < 0.9 || base <= player.y + 0.5 || !near) {
			discard;
		}
		COLOR = c;
	}
}
"""

static var main_ref
static var layer: Node2D
static var occluder: Sprite2D


static func build(main) -> void:
	main_ref = main
	layer = main.entity_layer
	_town_square()
	var sh := Shader.new()
	sh.code = SHADER
	# the painting as the ground
	var ground := _sprite(sh, 0)
	main.ground_layer.add_child(ground)
	# the occluder above the characters (redraws towers, trees, statues in front of Kael)
	occluder = _sprite(sh, 1)
	occluder.z_index = 12
	occluder.z_as_relative = false
	main.add_child(occluder)
	var follow := _Follow.new()
	follow.main = main
	follow.sprite = occluder
	main.add_child(follow)
	_collision()
	# the camera never looks past the edge of the painting
	main.add_camera_zone(Rect2(Geo.CASTLE_O, Vector2(1536, 1024) * S))
	_lights(main)
	_people(main)


static func _sprite(sh: Shader, mode: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = REF
	s.centered = false
	s.position = Geo.CASTLE_O
	s.scale = Vector2(S, S)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("depth_tex", DEPTH)
	mat.set_shader_parameter("mode", mode)
	s.material = mat
	return s


static func _collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var boxes = JSON.parse_string(FileAccess.get_file_as_string("res://art/castle3/ref_collision.json"))
	for b in boxes:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(b[2], b[3]) * S
		cs.shape = r
		cs.position = Geo.CASTLE_O + (Vector2(b[0], b[1]) + Vector2(b[2], b[3]) / 2.0) * S
		body.add_child(cs)
	layer.add_child(body)


static func _lights(main) -> void:
	# torches along the causeway and lamps in the gardens, where the painting has them
	for y in [744, 813, 871, 967]:
		for x in [722, 814]:
			main.lights.add(Geo.rp(x, y) - Vector2(0, 24), "torch")
	for p in [[702, 452], [834, 452], [722, 262], [814, 262], [756, 196], [780, 196]]:
		main.lights.add(Geo.rp(p[0], p[1]), "candle")


static func _people(main) -> void:
	main._npc("guard", Geo.rp(750, 985), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.rp(786, 985), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.rp(752, 218), "Palace guard", Story.CASTLE_NORTH_GUARD)
	main._npc("guard", Geo.rp(784, 218), "Palace guard", Story.CASTLE_NORTH_GUARD)


static func _town_square() -> void:
	# the old citadel ground in the middle of the city is an open square
	for item in [["castle2/vegetation/fountain", Vector2(0, 40), Vector2(50, 18)], ["cit_bench", Vector2(-90, 110), Vector2(44, 10)],
			["cit_bench", Vector2(90, 110), Vector2(44, 10)], ["cit_lamp", Vector2(-200, -200), Vector2(10, 6)],
			["cit_lamp", Vector2(200, -200), Vector2(10, 6)], ["cit_lamp", Vector2(-200, 240), Vector2(10, 6)],
			["cit_lamp", Vector2(200, 240), Vector2(10, 6)]]:
		var s = Spr.new()
		s.sprite = item[0]
		s.position = item[1]
		s.solid = item[2]
		layer.add_child(s)


## Keeps the occluder's shader told where Kael's feet are.
class _Follow extends Node:
	const Geo = preload("res://scripts/geo.gd")
	const S := 3.0
	var main
	var sprite: Sprite2D

	func _process(_delta: float) -> void:
		if main == null or main.player == null:
			return
		var p: Vector2 = (main.player.global_position - Geo.CASTLE_O) / S
		(sprite.material as ShaderMaterial).set_shader_parameter("player", p)
