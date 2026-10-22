extends CanvasLayer
## Full-screen sunlight and colour grade, between the world and the interface.

var mat: ShaderMaterial


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
	# no sky indoors: turn the sun shafts and dust off on the citadel's other floors
	var main = get_parent()
	var indoors: bool = main != null and main.get("floor_name") != null and main.floor_name != ""
	mat.set_shader_parameter("shaft_strength", 0.0 if indoors else 0.30)
