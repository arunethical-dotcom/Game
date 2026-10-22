extends Node2D
## Local warm light from torches, candles, braziers and fireplaces.
##
## Each light is drawn twice:
##  - a pool on the floor (under people and furniture), in a few hard-edged rings so it
##    stays pixel-art rather than a smooth gradient;
##  - a faint additive glow above everything nearby, so walls, furniture and Kael pick up
##    the warm colour when they stand close to a flame.
## Lights flicker gently. Only lights near the camera are drawn.

var lights := []   # [world position, radius, colour, flicker seed]
var glow: Node2D
var t := 0.0
var main


func _ready() -> void:
	z_index = -4                     # above the ground, below the y-sorted world
	glow = Node2D.new()
	glow.z_index = 15                # above the world, below effects and the HUD
	glow.z_as_relative = false
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.draw.connect(_draw_glow)
	add_child(glow)


## Add a light. `kind`: "torch", "candle", "brazier", "fire" (fireplace / kitchen hearth).
func add(pos: Vector2, kind := "candle") -> void:
	var r := 52.0
	var c := Color(1.0, 0.68, 0.3)
	match kind:
		"torch":
			r = 72.0
		"brazier":
			r = 64.0
			c = Color(1.0, 0.62, 0.26)
		"fire":
			r = 110.0
			c = Color(1.0, 0.56, 0.22)
	lights.append([pos.round(), r, c, randf() * 10.0])


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	glow.queue_redraw()


func _visible_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return Rect2()
	var size := get_viewport().get_visible_rect().size / cam.zoom
	return Rect2(cam.get_screen_center_position() - size / 2.0, size).grow(140)


func _flick(seed: float) -> float:
	return 0.9 + 0.1 * sin(t * 9.0 + seed) * sin(t * 5.3 + seed * 1.7)


## Flames read stronger when the ambient light is low (sunset, night).
func _boost() -> float:
	if main == null:
		return 1.0
	match main.time_of_day:
		"sunset":
			return 1.35
		"night":
			return 1.8
	return 1.0


func _draw() -> void:
	var view := _visible_rect()
	for l in lights:
		if not view.has_point(l[0]):
			continue
		var f := _flick(l[3])
		var r: float = l[1] * f
		var c: Color = l[2]
		# three stepped rings: brightest at the centre
		for k in 3:
			var rr := roundf(r * (1.0 - k * 0.3))
			draw_circle(l[0] + Vector2(0, 8), rr, Color(c.r, c.g, c.b, (0.045 + k * 0.02) * _boost()))


func _draw_glow() -> void:
	var view := _visible_rect()
	for l in lights:
		if not view.has_point(l[0]):
			continue
		var f := _flick(l[3])
		var b := _boost()
		var c: Color = l[2]
		glow.draw_circle(l[0] + Vector2(0, -10), roundf(l[1] * 0.75 * f), Color(c.r * 0.05 * b, c.g * 0.032 * b, c.b * 0.012 * b))
		glow.draw_circle(l[0] + Vector2(0, -10), roundf(l[1] * 0.4 * f), Color(c.r * 0.045 * b, c.g * 0.028 * b, c.b * 0.01 * b))
