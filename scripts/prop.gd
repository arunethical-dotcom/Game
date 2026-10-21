extends StaticBody2D
const Shadow = preload("res://scripts/shadow.gd")
## A sprite prop: market stall, well, or garden plot (from market.png).
## Stalls and wells block movement, gardens don't.

const MARKET = preload("res://art/market.png")

var kind := "stall"
var variant := 0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if kind == "garden":
		return
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(52, 22) if kind == "stall" else Vector2(38, 20)
	cs.shape = r
	cs.position = Vector2(0, -10)
	add_child(cs)


func _draw() -> void:
	match kind:
		"stall":
			Shadow.soft(self, Vector2(3, -1), 30.0, 8.0, 0.38)
			draw_texture_rect_region(MARKET, Rect2(-30, -58, 60, 60), Rect2(variant * 60, 0, 60, 60))
		"well":
			draw_texture_rect_region(MARKET, Rect2(-22, -54, 44, 56), Rect2(240, 4, 44, 56))
		"garden":
			draw_texture_rect_region(MARKET, Rect2(-28, -36, 56, 36), Rect2(284 + variant * 56, 24, 56, 36))
