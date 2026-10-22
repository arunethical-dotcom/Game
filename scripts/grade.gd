extends CanvasLayer
## Full-screen sunlight and colour grade, between the world and the interface.
##
## Each place has its own grading profile (see PROFILES). main.environment() says which
## one Kael is in; the shader parameters ease toward it, so walking through a door blends
## smoothly from sunlit courtyard to candle-lit room. Outdoors, the time of day (main.
## time_of_day) tints the light: day, afternoon, sunset, night.

var mat: ShaderMaterial
var cur := {}

# exposure: ambient brightness; ambient: its colour; hi/lo: tints added to highlights and
# shadows; sat/con: saturation and contrast; vig: vignette; sky: 1 = sun beams outdoors
const PROFILES := {
	"outdoor": {"exposure": 1.04, "ambient": Color(1.0, 1.0, 0.98), "hi": Color(0.03, 0.018, -0.01), "lo": Color(0.0, 0.004, 0.012),
			"sat": 1.08, "con": 1.04, "vig": 0.14, "sky": 1.0},
	"throne": {"exposure": 0.9, "ambient": Color(1.0, 0.96, 0.9), "hi": Color(0.03, 0.02, 0.0), "lo": Color(0.01, 0.0, 0.02),
			"sat": 1.05, "con": 1.05, "vig": 0.22, "sky": 0.0},
	"bedroom": {"exposure": 0.93, "ambient": Color(1.0, 0.94, 0.86), "hi": Color(0.035, 0.02, -0.005), "lo": Color(0.012, 0.0, 0.01),
			"sat": 1.05, "con": 1.05, "vig": 0.26, "sky": 0.0},
	"library": {"exposure": 0.9, "ambient": Color(1.0, 0.93, 0.82), "hi": Color(0.04, 0.025, 0.0), "lo": Color(-0.005, 0.005, 0.03),
			"sat": 1.0, "con": 1.06, "vig": 0.3, "sky": 0.0},
	"kitchen": {"exposure": 0.94, "ambient": Color(1.0, 0.92, 0.8), "hi": Color(0.045, 0.02, -0.01), "lo": Color(0.015, 0.0, 0.0),
			"sat": 1.04, "con": 1.05, "vig": 0.26, "sky": 0.0},
	"stone": {"exposure": 0.88, "ambient": Color(0.92, 0.94, 1.0), "hi": Color(0.03, 0.015, 0.0), "lo": Color(-0.01, 0.0, 0.035),
			"sat": 0.95, "con": 1.06, "vig": 0.32, "sky": 0.0},
	"chapel": {"exposure": 0.95, "ambient": Color(0.98, 0.96, 1.0), "hi": Color(0.03, 0.02, 0.01), "lo": Color(0.005, 0.0, 0.03),
			"sat": 1.04, "con": 1.04, "vig": 0.24, "sky": 0.0},
}

# outdoor light by time of day: ambient colour, exposure, sun colour, beam strength
const TIMES := {
	"day": {"ambient": Color(1.0, 1.0, 0.98), "exposure": 1.04, "sun": Color(1.0, 0.9, 0.66), "beams": 1.0},
	"afternoon": {"ambient": Color(1.0, 0.95, 0.86), "exposure": 1.0, "sun": Color(1.0, 0.82, 0.52), "beams": 1.1},
	"sunset": {"ambient": Color(1.0, 0.87, 0.76), "exposure": 0.9, "sun": Color(1.0, 0.6, 0.38), "beams": 0.9},
	"night": {"ambient": Color(0.52, 0.6, 0.86), "exposure": 0.78, "sun": Color(0.6, 0.7, 1.0), "beams": 0.0},
}


func _ready() -> void:
	layer = 5
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = preload("res://scripts/grade.gdshader")
	r.material = mat
	add_child(r)
	cur = _target("outdoor", "day")


func _target(env: String, time: String) -> Dictionary:
	var p: Dictionary = PROFILES.get(env, PROFILES["outdoor"]).duplicate()
	var t: Dictionary = TIMES.get(time, TIMES["day"])
	p["sun"] = t["sun"]
	p["beams"] = t["beams"]
	if env == "outdoor":
		p["ambient"] = t["ambient"]
		p["exposure"] = t["exposure"]
	elif time == "night":
		# indoors at night the rooms rely on their candles and torches
		p["exposure"] = p["exposure"] * 0.8
		p["ambient"] = (p["ambient"] as Color) * Color(0.85, 0.88, 1.0)
	return p


func _process(delta: float) -> void:
	# tell the shader where the camera is, so the sun shafts stay fixed to the world
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var size := get_viewport().get_visible_rect().size / cam.zoom
	mat.set_shader_parameter("view_size", size)
	mat.set_shader_parameter("cam_pos", cam.get_screen_center_position() - size * 0.5)
	var main = get_parent()
	var env := "outdoor"
	var time := "day"
	if main != null and main.has_method("environment"):
		env = main.environment()
		time = main.time_of_day
	var want := _target(env, time)
	var k := 1.0 - exp(-4.0 * delta)
	for key in want:
		cur[key] = lerp(cur[key], want[key], k)
	mat.set_shader_parameter("exposure", cur["exposure"])
	mat.set_shader_parameter("ambient", cur["ambient"])
	mat.set_shader_parameter("hi_tint", Vector3(cur["hi"].r, cur["hi"].g, cur["hi"].b))
	mat.set_shader_parameter("lo_tint", Vector3(cur["lo"].r, cur["lo"].g, cur["lo"].b))
	mat.set_shader_parameter("saturation", cur["sat"])
	mat.set_shader_parameter("contrast", cur["con"])
	mat.set_shader_parameter("vignette", cur["vig"])
	mat.set_shader_parameter("indoor", 1.0 - cur["sky"])
	mat.set_shader_parameter("sun_color", cur["sun"])
	mat.set_shader_parameter("shaft_strength", 0.22 * cur["beams"])
	mat.set_shader_parameter("glow_strength", 0.16 * cur["beams"])
