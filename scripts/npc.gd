extends Node2D
const Shadow = preload("res://scripts/shadow.gd")
## A person in the world. Roles:
##   haldor   - the old blacksmith
##   guard    - Kingdom B soldier with a spear
##   villager - townsfolk who stroll around
##   worker   - Kingdom A captive, in chains, hauling stone

var role := "villager"
var npc_name := ""
var lines := []          # dialogue: array of [speaker, text]
var alert := false
var look_at_pos := Vector2.INF
var t := 0.0
var home := Vector2.ZERO
var target := Vector2.ZERO
var wait := 0.0
var walk := 0.0
var tint := Color(0.6, 0.4, 0.3)
var patrol_b := Vector2.ZERO
var main
var look_dir := Vector2.DOWN
var moving := false
var variant := 0

const SHEETS := {
	"haldor": preload("res://art/char_haldor.png"),
	"guard": preload("res://art/char_guard.png"),
	"worker": preload("res://art/char_worker.png"),
	"miner": preload("res://art/char_miner.png"),
	"worker_miner": preload("res://art/char_miner.png"),
	"villager0": preload("res://art/char_villager0.png"),
	"villager1": preload("res://art/char_villager1.png"),
	"villager2": preload("res://art/char_villager2.png"),
	"villager3": preload("res://art/char_villager3.png"),
}


func _ready() -> void:
	home = position
	target = position
	t = randf() * 10.0
	var palette := [Color(0.62, 0.38, 0.3), Color(0.38, 0.5, 0.35), Color(0.55, 0.5, 0.3), Color(0.45, 0.4, 0.55), Color(0.6, 0.55, 0.45)]
	tint = palette[randi() % palette.size()]
	variant = randi() % 4


func talkable() -> bool:
	return role == "haldor" or not lines.is_empty()


func _process(delta: float) -> void:
	t += delta
	moving = false
	var paused: bool = main != null and main.is_world_paused()
	var talking_range := look_at_pos != Vector2.INF
	if not paused and not talking_range:
		match role:
			"villager":
				_stroll(delta, 38.0, 90.0)
			"worker_miner":
				_stroll(delta, 30.0, 70.0)
			"worker":
				# haul stone back and forth, slowly
				var dest := patrol_b if int(t / 9.0) % 2 == 0 else home
				_move_to(dest, delta, 22.0)
	queue_redraw()


func _stroll(delta: float, speed: float, radius: float) -> void:
	if wait > 0.0:
		wait -= delta
		return
	if position.distance_to(target) < 6.0:
		target = home + Vector2(randf_range(-radius, radius), randf_range(-radius * 0.5, radius * 0.5))
		wait = randf_range(1.0, 4.0)
		return
	_move_to(target, delta, speed)


func _move_to(dest: Vector2, delta: float, speed: float) -> void:
	var d := dest - position
	if d.length() > 4.0:
		position += d.normalized() * minf(speed * delta, d.length())
		walk += delta * 9.0
		look_dir = d.normalized()
		moving = true


func _draw() -> void:
	Shadow.soft(self, Vector2(1, 0), 14.0, 5.5, 0.5)
	var dir := look_dir
	if look_at_pos != Vector2.INF:
		dir = (look_at_pos - global_position).normalized()
	elif not moving and role != "villager":
		dir = Vector2.DOWN
	var row := 2 if absf(dir.x) > absf(dir.y) else (1 if dir.y < 0.0 else 0)
	var flip := row == 2 and dir.x < 0.0
	var frame := int(walk * 0.75) % 4 if moving else 0
	var key := role if role != "villager" else "villager%d" % variant
	var sheet: Texture2D = SHEETS.get(key, SHEETS["villager0"])
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect_region(sheet, Rect2(-20, -58, 40, 60), Rect2(frame * 40, row * 60, 40, 60))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if alert:
		var y := roundf((-74 + sin(t * 4.0) * 3.0) / 2.0) * 2.0
		draw_rect(Rect2(-8, y - 10, 16, 20), Color(0.25, 0.15, 0.05))
		draw_rect(Rect2(-6, y - 8, 12, 16), Color(1, 0.82, 0.3))
		draw_rect(Rect2(-2, y - 6, 4, 8), Color(0.25, 0.15, 0.05))
		draw_rect(Rect2(-2, y + 4, 4, 2), Color(0.25, 0.15, 0.05))
