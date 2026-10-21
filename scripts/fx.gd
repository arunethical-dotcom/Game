extends Node2D
## Short-lived visual effects: sparks, wood/stone chips, dust puffs, floating text.

var kind := "spark"
var color := Color.WHITE
var text := ""
var age := 0.0
var life := 0.35
var bits := []


func _ready() -> void:
	match kind:
		"text":
			life = 1.1
		"dust":
			life = 0.5
	var n := 8 if kind != "dust" else 6
	for i in n:
		var a := randf() * TAU
		bits.append([Vector2.from_angle(a) * randf_range(60, 180), Vector2.ZERO])


func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	for b in bits:
		b[1] += b[0] * delta
		b[0] *= 0.88
	if kind == "text":
		position.y -= 30.0 * delta
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - age / life
	match kind:
		"spark":
			for b in bits:
				draw_line(b[1], b[1] + b[0].normalized() * 6.0, Color(1, 0.85, 0.4, a) if color == Color.WHITE else Color(color, a), 2.0)
		"chip":
			for b in bits:
				draw_rect(Rect2(b[1] - Vector2(2, 2), Vector2(4, 4)), Color(color, a))
		"dust":
			for b in bits:
				draw_circle(b[1] * 0.35, 6.0 + age * 20.0, Color(0.75, 0.68, 0.55, 0.45 * a))
		"text":
			var font := ThemeDB.fallback_font
			draw_string_outline(font, Vector2(-100, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 200, 16, 4, Color(0, 0, 0, a))
			draw_string(font, Vector2(-100, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 200, 16, Color(color, a))
