extends CanvasLayer
## Full-screen sunlight and colour grade, between the world and the interface.

var mat: ShaderMaterial
var indoor := 0.0


func _ready() -> void:
	layer = 5
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = preload("res://scripts/grade.gdshader")
	r.material = mat
	add_child(r)


func _process(_delta: float) -> void:
	# tell the shader where the camera is, so the sun shafts stay fixed to the world
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var size := get_viewport().get_visible_rect().size / cam.zoom
	mat.set_shader_parameter("view_size", size)
	mat.set_shader_parameter("cam_pos", cam.get_screen_center_position() - size * 0.5)
	# no sky indoors: fade the sun shafts, sky glow and warm cast out under a roof
	var main = get_parent()
	var target := 1.0 if main != null and main.has_method("is_indoors") and main.is_indoors() else 0.0
	indoor = move_toward(indoor, target, _delta * 3.0)
	mat.set_shader_parameter("indoor", indoor)
