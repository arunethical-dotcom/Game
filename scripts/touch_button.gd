extends Control
## Round on-screen button for phones that presses an input action. Multi-touch safe.

var action := "attack"
var label := ""
var radius := 50.0
var touch_index := -1


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
	var c := size / 2.0
	var pressed := touch_index != -1
	draw_circle(c, radius, Color(0.1, 0.06, 0.04, 0.7 if pressed else 0.45))
	draw_arc(c, radius, 0, TAU, 48, Color(1, 0.82, 0.5, 0.9 if pressed else 0.6), 3.0)
	var font := get_theme_default_font()
	draw_string(font, Vector2(0, c.y + 7), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color(1, 0.95, 0.85))
