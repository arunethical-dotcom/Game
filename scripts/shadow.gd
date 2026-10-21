extends RefCounted
## Soft ground shadows: three stacked ellipses fading outward, cast a little to the
## lower right (the sun is upper left). Tinted dark green rather than black, so they
## look like shade on grass.

const TINT := Color(0.06, 0.1, 0.04)


static func soft(ci: CanvasItem, center: Vector2, rx: float, ry: float, strength := 0.3) -> void:
	for k in 3:
		var grow := 1.0 + k * 0.16
		ci.draw_set_transform(center + Vector2(rx * 0.12, 0), 0, Vector2(1.0, ry / rx))
		ci.draw_circle(Vector2.ZERO, rx * grow, Color(TINT, strength * (0.55 - k * 0.15)))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
