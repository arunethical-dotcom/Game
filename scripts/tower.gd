extends StaticBody2D
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
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 36, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if cone:
		draw_texture_rect_region(TOWERS, Rect2(-26, -152, 52, 156), Rect2(60, 0, 52, 156))
	else:
		draw_texture_rect_region(TOWERS, Rect2(-30, -108, 60, 112), Rect2(0, 44, 60, 112))
