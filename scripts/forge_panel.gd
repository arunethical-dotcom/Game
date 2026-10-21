extends Control
## Forging mini-game. A needle swings across the heat bar.
## Strike three times while it is in the bright zone. Better timing makes a stronger sword.

var main
var active := false
var needle := 0.0
var dir := 1.0
var speed := 0.85
var strikes := []
var done_cb = null
var result_t := -1.0
var flash := 0.0
var opened_frame := -1
var sparks := []

const ZONE_C := 0.62
const ZONE_HALF := 0.06
const STRIKES := 3


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(cb: Callable) -> void:
	active = true
	visible = true
	strikes = []
	needle = 0.0
	dir = 1.0
	speed = 0.85
	done_cb = cb
	result_t = -1.0
	opened_frame = Engine.get_process_frames()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_strike()


func _process(delta: float) -> void:
	if not active:
		return
	flash = maxf(flash - delta, 0.0)
	for s in sparks:
		s[1] += s[0] * delta
		s[0].y += 500.0 * delta
		s[2] -= delta
	sparks = sparks.filter(func(s): return s[2] > 0.0)

	if result_t >= 0.0:
		result_t += delta
		if result_t > 1.8:
			_finish()
	else:
		needle += dir * speed * delta
		if needle > 1.0:
			needle = 1.0
			dir = -1.0
		elif needle < 0.0:
			needle = 0.0
			dir = 1.0
		if Engine.get_process_frames() != opened_frame:
			if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact"):
				_strike()
	queue_redraw()


func _strike() -> void:
	if not active or result_t >= 0.0 or Engine.get_process_frames() == opened_frame:
		return
	var off := absf(needle - ZONE_C)
	var q := 1.0 if off <= ZONE_HALF else clampf(1.0 - (off - ZONE_HALF) / 0.35, 0.0, 1.0)
	strikes.append(q)
	speed += 0.4
	flash = 0.18
	if main:
		main.shake(4.0 + q * 4.0)
	var bar := _bar_rect()
	var hit_pos := Vector2(bar.position.x + needle * bar.size.x, bar.position.y)
	for i in int(6 + q * 14):
		sparks.append([Vector2(randf_range(-220, 220), randf_range(-320, -80)), hit_pos, randf_range(0.3, 0.7)])
	if strikes.size() >= STRIKES:
		result_t = 0.0


func quality() -> float:
	if strikes.is_empty():
		return 0.0
	var total := 0.0
	for q in strikes:
		total += q
	return total / strikes.size()


func _finish() -> void:
	active = false
	visible = false
	var cb = done_cb
	done_cb = null
	if cb is Callable and cb.is_valid():
		cb.call(quality())


func _bar_rect() -> Rect2:
	return Rect2(50, 120, size.x - 100, 34)


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.06, 0.04, 0.95))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.72, 0.52, 0.28), false, 3.0)
	draw_string(font, Vector2(0, 44), "Forge the blade", HORIZONTAL_ALIGNMENT_CENTER, w, 28, Color(1, 0.82, 0.5))
	var tip := "Strike when the needle is in the bright zone"
	draw_string(font, Vector2(0, 80), tip, HORIZONTAL_ALIGNMENT_CENTER, w, 16, Color(0.9, 0.86, 0.8))

	var bar := _bar_rect()
	# heat gradient
	var steps := 40
	for i in steps:
		var f := float(i) / steps
		var heat := clampf(1.0 - absf(f - ZONE_C) / 0.6, 0.0, 1.0)
		var col := Color(0.25, 0.08, 0.04).lerp(Color(1.0, 0.55, 0.15), heat)
		draw_rect(Rect2(bar.position.x + f * bar.size.x, bar.position.y, bar.size.x / steps + 1, bar.size.y), col)
	var zx := bar.position.x + (ZONE_C - ZONE_HALF) * bar.size.x
	draw_rect(Rect2(zx, bar.position.y - 4, ZONE_HALF * 2.0 * bar.size.x, bar.size.y + 8), Color(1, 0.95, 0.6, 0.85))
	draw_rect(bar, Color(0, 0, 0, 0.8), false, 2.0)

	# needle (the hammer)
	var nx := bar.position.x + needle * bar.size.x
	draw_line(Vector2(nx, bar.position.y - 18), Vector2(nx, bar.end.y + 10), Color(0.95, 0.95, 1.0), 4.0)
	draw_rect(Rect2(nx - 12, bar.position.y - 30, 24, 14), Color(0.4, 0.4, 0.44))

	# strike results
	for i in STRIKES:
		var c := Vector2(w / 2 + (i - 1) * 50, 200)
		draw_circle(c, 15, Color(0.2, 0.15, 0.1))
		if i < strikes.size():
			var q: float = strikes[i]
			draw_circle(c, 12, Color(0.6, 0.2, 0.1).lerp(Color(1, 0.9, 0.4), q))

	if result_t >= 0.0:
		var q := quality()
		var verdict := "Fine blade" if q >= 0.75 else ("Solid blade" if q >= 0.4 else "Rough blade")
		draw_string(font, Vector2(0, 252), verdict, HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color(1, 0.9, 0.55))
	else:
		var hint := "Tap here to strike" if DisplayServer.is_touchscreen_available() else "J / Space to strike"
		draw_string(font, Vector2(0, 252), hint, HORIZONTAL_ALIGNMENT_CENTER, w, 16, Color(0.8, 0.75, 0.65))

	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.8, 0.4, flash))
	for s in sparks:
		draw_circle(s[1], 2.5, Color(1, 0.8, 0.3, clampf(s[2] * 2.0, 0.0, 1.0)))
