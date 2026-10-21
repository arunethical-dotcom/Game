extends Control
## Virtual joystick for phones. Supports multi-touch, so you can move and attack at once.

var touch_index := -1
var knob := Vector2.ZERO
const MAX_R := 80.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _center() -> Vector2:
	return size / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1 and get_global_rect().grow(40).has_point(event.position):
			touch_index = event.index
			_update(event.position)
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			knob = Vector2.ZERO
			_apply()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update(event.position)


func _update(screen_pos: Vector2) -> void:
	var local := screen_pos - get_global_rect().position - _center()
	knob = local.limit_length(MAX_R)
	_apply()


func _apply() -> void:
	var v := knob / MAX_R
	_set_axis("move_left", "move_right", v.x)
	_set_axis("move_up", "move_down", v.y)
	queue_redraw()


func _set_axis(neg: String, pos: String, value: float) -> void:
	if value < -0.15:
		Input.action_press(neg, -value)
		Input.action_release(pos)
	elif value > 0.15:
		Input.action_press(pos, value)
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos)


func _draw() -> void:
	var c := _center()
	draw_circle(c, MAX_R + 20, Color(0, 0, 0, 0.25))
	draw_arc(c, MAX_R + 20, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(c + knob, 38, Color(1, 0.9, 0.7, 0.5 if touch_index != -1 else 0.3))
