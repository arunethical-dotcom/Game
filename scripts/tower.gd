extends StaticBody2D
const Shadow = preload("res://scripts/shadow.gd")
## Round stone tower: city wall style, or castle style with a pointed blue roof.

const TOWERS = preload("res://art/towers.png")

var radius := 30.0
var height := 84.0   # kept for compatibility, size comes from the sprite
var cone := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 26.0 if cone else 30.0
	cs.shape = c
	add_child(cs)


func _draw() -> void:
	Shadow.soft(self, Vector2(4, 0), 38.0, 12.0, 0.42)
	if cone:
		draw_texture_rect_region(TOWERS, Rect2(-26, -152, 52, 156), Rect2(60, 0, 52, 156))
	else:
		draw_texture_rect_region(TOWERS, Rect2(-30, -108, 60, 112), Rect2(0, 44, 60, 112))
