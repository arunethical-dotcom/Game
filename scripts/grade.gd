extends CanvasLayer
## Full-screen colour grade, between the world and the interface.

func _ready() -> void:
	layer = 5
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/grade.gdshader")
	r.material = mat
	add_child(r)
