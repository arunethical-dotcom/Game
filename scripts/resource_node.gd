extends StaticBody2D
const Shadow = preload("res://scripts/shadow.gd")
## An iron ore rock (hit it three times to mine it) or a tree (scenery that blocks the way).

const TREES = preload("res://art/trees.png")
const ROCKS = preload("res://art/rocks.png")

var main
var kind := "tree"
var key := ""
var variant := 0
var hp := 3
var shake_t := 0.0
var hit_radius := 14.0


func _ready() -> void:
	if kind == "rock":
		add_to_group("hittable")
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0 if kind == "tree" else 18.0
	cs.shape = c
	cs.position = Vector2(0, -4)
	add_child(cs)


func hit(_damage: float, _from: Vector2) -> void:
	hp -= 1
	shake_t = 0.18
	main.spawn_fx("chip", global_position + Vector2(0, -14), Color(0.75, 0.7, 0.62))
	if hp <= 0:
		main.world.depleted[key] = true
		main.add_item("ore", global_position)
		main.spawn_fx("dust", global_position)
		queue_free()
	queue_redraw()


func _process(delta: float) -> void:
	if shake_t > 0.0:
		shake_t -= delta
		queue_redraw()


func _draw() -> void:
	var off := Vector2(roundf(sin(shake_t * 70.0) * 2.0) * 2.0, 0) if shake_t > 0.0 else Vector2.ZERO
	if kind == "tree":
		Shadow.soft(self, Vector2(4, 0), 30.0, 11.0, 0.42)
	else:
		Shadow.soft(self, Vector2(2, 0), 24.0, 8.0, 0.35)
	if kind == "tree":
		draw_texture_rect_region(TREES, Rect2(off + Vector2(-32, -84), Vector2(64, 88)), Rect2(variant * 64, 0, 64, 88))
	else:
		draw_texture_rect_region(ROCKS, Rect2(off + Vector2(-24, -36), Vector2(48, 40)), Rect2(variant * 48, 0, 48, 40))
