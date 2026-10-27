extends RefCounted
## The Royal Castle (stage 18): one seamless picture built by tools/castle8_build.py from the
## coworkers' assets, laid out on the castle reference (source_art/castle8/castle_ref.png).
##
## art/castle8/out/ holds it in chunks (meta.json gives the grid):
##   col_R_C.png  the picture (castle pieces drawn at whole-number scales, never resampled)
##   dep_R_C.png  per pixel: R,G = the y where the thing drawn there stands (its base line,
##                in castle px), B = what it is (0 ground, 32 flat floor, 128 water, 255 upright)
##   collision.json  solid boxes (castle px) around everything Kael cannot walk on
##   lights.json     torches and braziers found in the picture
##
## In game:
##  - the picture is the ground layer (water pixels shimmer gently);
##  - an occluder copy is drawn above the characters, showing only the upright pixels near
##    Kael that stand south of his feet, so he walks behind towers, walls, statues and trees
##    and in front of them;
##  - the collision boxes keep him on the paving, lawns, causeway and stairs.

const Geo = preload("res://scripts/geo.gd")
const Spr = preload("res://scripts/cit_sprite.gd")
const Story = preload("res://scripts/story.gd")
const DIR := "res://art/castle8/out/"

const SHADER := """
shader_type canvas_item;
uniform sampler2D depth_tex : filter_nearest;
uniform int mode = 0;               // 0 = ground layer, 1 = occluder above the characters
uniform vec2 player = vec2(-9999.0);   // Kael's feet in castle px
uniform vec2 origin = vec2(0.0);    // this chunk's top-left in castle px
uniform vec2 reach = vec2(46.0, 100.0);
void fragment() {
	vec4 d = texture(depth_tex, UV);
	float kind = d.b;
	vec4 c = texture(TEXTURE, UV);
	vec2 p = origin + UV * vec2(textureSize(TEXTURE, 0));
	if (mode == 0) {
		if (kind > 0.4 && kind < 0.6) {
			float w = sin(TIME * 1.3 + p.x * 0.035 + p.y * 0.02) * sin(TIME * 0.9 - p.y * 0.028);
			c.rgb += vec3(0.02, 0.035, 0.05) * w;
		}
		COLOR = c;
	} else {
		float base = floor(d.r * 255.0 + 0.5) * 256.0 + floor(d.g * 255.0 + 0.5);
		vec2 rel = p - player;
		bool near = abs(rel.x) < reach.x && rel.y > -reach.y && rel.y < 10.0;
		if (kind < 0.9 || base <= player.y + 0.5 || !near) {
			discard;
		}
		COLOR = c;
	}
}
"""

static var main_ref
static var layer: Node2D
static var occluders := []


static func build(main) -> void:
	main_ref = main
	layer = main.entity_layer
	occluders = []
	_town_square()
	var sh := Shader.new()
	sh.code = SHADER
	var meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "meta.json"))
	var CHUNK: int = int(meta["chunk"])
	for r in int(meta["rows"]):
		for c in int(meta["cols"]):
			var col: Texture2D = load(DIR + "col_%d_%d.png" % [r, c])
			var dep: Texture2D = load(DIR + "dep_%d_%d.png" % [r, c])
			var origin := Vector2(c * CHUNK, r * CHUNK)
			main.ground_layer.add_child(_chunk(sh, col, dep, origin, 0))
			var occ := _chunk(sh, col, dep, origin, 1)
			occ.z_index = 12
			occ.z_as_relative = false
			main.add_child(occ)
			occluders.append(occ)
	var follow := _Follow.new()
	follow.main = main
	follow.occ = occluders
	main.add_child(follow)
	_collision()
	# the camera never looks past the edge of the castle
	main.add_camera_zone(Geo.CASTLE_AREA)
	_lights(main)
	_people(main)


static func _chunk(sh: Shader, col: Texture2D, dep: Texture2D, origin: Vector2, mode: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = col
	s.centered = false
	s.position = Geo.CASTLE_O + origin
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("depth_tex", dep)
	mat.set_shader_parameter("mode", mode)
	mat.set_shader_parameter("origin", origin)
	s.material = mat
	return s


static func _collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var boxes = JSON.parse_string(FileAccess.get_file_as_string(DIR + "collision.json"))
	for b in boxes:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(b[2], b[3])
		cs.shape = r
		cs.position = Geo.CASTLE_O + Vector2(b[0], b[1]) + Vector2(b[2], b[3]) / 2.0
		body.add_child(cs)
	layer.add_child(body)


static func _lights(main) -> void:
	var list = JSON.parse_string(FileAccess.get_file_as_string(DIR + "lights.json"))
	for l in list:
		main.lights.add(Geo.CASTLE_O + Vector2(l[0], l[1]) + Vector2(0, 20), l[2])


static func _people(main) -> void:
	main._npc("guard", Geo.rp(755, 1018), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.rp(781, 1018), "Castle guard", Story.CASTLE_GATE_GUARD)
	main._npc("guard", Geo.rp(755, 628), "Castle guard", Story.CASTLE_NORTH_GUARD)
	main._npc("guard", Geo.rp(781, 628), "Castle guard", Story.CASTLE_NORTH_GUARD)


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


## Keeps the occluders told where Kael's feet are.
class _Follow extends Node:
	const Geo = preload("res://scripts/geo.gd")
	var main
	var occ := []

	func _process(_delta: float) -> void:
		if main == null or main.player == null:
			return
		var p: Vector2 = main.player.global_position - Geo.CASTLE_O
		for o in occ:
			(o.material as ShaderMaterial).set_shader_parameter("player", p)
