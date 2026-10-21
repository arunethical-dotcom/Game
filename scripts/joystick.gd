extends Control
## Virtual joystick for phones. Supports multi-touch, so you can move and attack at once.

var touch_index := -1
var knob := Vector2.ZERO
const MAX_R := 40.0
const TEX = preload("res://art/ui_joystick.png")


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
	draw_texture_rect_region(TEX, Rect2(c - Vector2(48, 48), Vector2(96, 96)), Rect2(0, 0, 96, 96))
	var k := (c + knob).round()
	draw_texture_rect_region(TEX, Rect2(k - Vector2(18, 18), Vector2(36, 36)), Rect2(98, 0, 36, 36), Color(1, 1, 1, 1.0 if touch_index != -1 else 0.8))
