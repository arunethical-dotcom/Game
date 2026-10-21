extends Control
## Round on-screen button for phones that presses an input action. Multi-touch safe.

var action := "attack"
var label := ""
var radius := 50.0
var touch_index := -1
const BIG = preload("res://art/ui_button_32.png")
const SMALL = preload("res://art/ui_button_24.png")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var center := get_global_rect().get_center()
		if event.pressed and touch_index == -1 and event.position.distance_to(center) <= radius + 10.0:
			touch_index = event.index
			Input.action_press(action)
			queue_redraw()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			Input.action_release(action)
			queue_redraw()


func _draw() -> void:
	var r := int(radius)
	var tex: Texture2D = BIG if r > 28 else SMALL
	var pressed := touch_index != -1
	var c := size / 2.0
	draw_texture_rect_region(tex, Rect2(c - Vector2(r, r), Vector2(r * 2, r * 2)), Rect2((r * 2) if pressed else 0, 0, r * 2, r * 2))
	var font := get_theme_default_font()
	var fs := 13 if r > 28 else 10
	draw_string_outline(font, Vector2(0, c.y + fs * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 3, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(0, c.y + fs * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(1, 0.93, 0.78))
