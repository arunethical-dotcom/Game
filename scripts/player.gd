extends CharacterBody2D
const Shadow = preload("res://scripts/shadow.gd")
## Kael, the main character.
## Real-time combat: quick attack, heavy slam (cracks the ground), and a dodge roll
## that makes you briefly invincible.

var main
var locked := false

const SPEED := 210.0
const DODGE_SPEED := 560.0
const DODGE_TIME := 0.24

var max_hp := 100.0
var hp := 100.0
var facing := Vector2.DOWN
var state := "move"
var state_t := 0.0
var hit_done := false
var invuln := 0.0
var dodge_cd := 0.0
var hurt_flash := 0.0
var knock := Vector2.ZERO
var dodge_dir := Vector2.DOWN
var walk_t := 0.0

var has_sword := false
var sword_damage := 0.0
const HAMMER_DAMAGE := 5.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 11.0
	cs.shape = c
	cs.position = Vector2(0, -6)
	add_child(cs)


func reset_state() -> void:
	_start("move")
	velocity = Vector2.ZERO
	invuln = 1.0


func _start(s: String) -> void:
	state = s
	state_t = 0.0
	hit_done = false


func _physics_process(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	dodge_cd = maxf(dodge_cd - delta, 0.0)
	hurt_flash = maxf(hurt_flash - delta, 0.0)
	state_t += delta

	var input := Vector2.ZERO
	if not locked:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	match state:
		"move":
			if input.length() > 0.1:
				facing = input.normalized()
				walk_t += delta * 11.0
			velocity = input * SPEED
			if not locked:
				if Input.is_action_just_pressed("attack"):
					_start("attack")
				elif Input.is_action_just_pressed("heavy") and has_sword:
					_start("heavy")
				elif Input.is_action_just_pressed("dodge"):
					_try_dodge(input)
		"attack":
			velocity = facing * 40.0
			if not hit_done and state_t >= 0.09:
				hit_done = true
				_do_hit(false)
			if state_t > 0.14 and not locked and Input.is_action_just_pressed("dodge"):
				_try_dodge(input)
			elif state_t >= 0.32:
				_start("move")
		"heavy":
			velocity = Vector2.ZERO
			if not hit_done and state_t >= 0.38:
				hit_done = true
				_do_hit(true)
			if state_t >= 0.65:
				_start("move")
		"dodge":
			velocity = dodge_dir * DODGE_SPEED * (1.0 - state_t / DODGE_TIME * 0.5)
			if state_t >= DODGE_TIME:
				_start("move")
		"hurt":
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 1400.0 * delta)
			if state_t >= 0.25:
				_start("move")

	if locked and state == "move":
		velocity = Vector2.ZERO
	move_and_slide()
	global_position = main.world.clamp_to_world(global_position)
	queue_redraw()


func _try_dodge(input: Vector2) -> void:
	if dodge_cd > 0.0:
		return
	dodge_dir = input.normalized() if input.length() > 0.1 else facing
	facing = dodge_dir
	_start("dodge")
	invuln = 0.32
	dodge_cd = 0.55
	main.spawn_fx("dust", global_position)


func _do_hit(heavy: bool) -> void:
	var base := sword_damage if has_sword else HAMMER_DAMAGE
	var dmg := base * (2.0 if heavy else 1.0)
	var slam_point := global_position + Vector2(0, -4) + facing * 44.0
	var hit_any := false
	for n in get_tree().get_nodes_in_group("hittable"):
		if not is_instance_valid(n):
			continue
		if heavy:
			if n.global_position.distance_to(slam_point) < 80.0 + float(n.get("hit_radius") if n.get("hit_radius") != null else 0.0):
				n.hit(dmg, global_position)
				hit_any = true
		else:
			var to: Vector2 = n.global_position - global_position
			var d := to.length()
			var reach: float = 56.0 + float(n.get("hit_radius") if n.get("hit_radius") != null else 10.0)
			if d < reach and (d < 20.0 or to.normalized().dot(facing) > 0.3):
				n.hit(dmg, global_position)
				hit_any = true
	if heavy:
		main.spawn_crater(slam_point)
		main.shake(10.0)
	elif hit_any:
		main.shake(3.0)


func take_damage(amount: float, from: Vector2) -> void:
	if invuln > 0.0 or state == "dodge" or locked:
		return
	hp -= amount
	hurt_flash = 0.3
	invuln = 0.7
	knock = (global_position - from).normalized() * 380.0
	_start("hurt")
	main.shake(6.0)
	main.spawn_fx("spark", global_position + Vector2(0, -16), Color(1, 0.4, 0.3))
	if hp <= 0.0:
		main.on_player_down()
	main.hud.update_hud()


# ---------------------------------------------------------------- Drawing

const SHEET = preload("res://art/char_kael.png")
const ITEMS = preload("res://art/items.png")


func _row() -> int:
	if absf(facing.x) > absf(facing.y):
		return 2
	return 1 if facing.y < 0.0 else 0


func _draw() -> void:
	var alpha := 1.0
	if invuln > 0.0 and state != "dodge" and int(invuln * 20.0) % 2 == 0:
		alpha = 0.45
	var tint := Color(1, 1, 1, alpha)
	if hurt_flash > 0.0:
		tint = Color(1, 0.45, 0.45, alpha)

	Shadow.soft(self, Vector2(1, 0), 14.0, 5.5, 0.5)

	var row := _row()
	var frame := int(walk_t * 0.75) % 4 if velocity.length() > 10.0 and state == "move" else 0
	var flip := row == 2 and facing.x < 0.0

	if state == "dodge":
		var spin := state_t / DODGE_TIME * TAU * (-1.0 if facing.x < 0.0 else 1.0)
		draw_set_transform(Vector2(0, -28), spin, Vector2(-1 if flip else 1, 1))
		draw_texture_rect_region(SHEET, Rect2(-20, -30, 40, 60), Rect2(0, row * 60, 40, 60), tint)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return

	var weapon_behind := row == 1
	if weapon_behind:
		_draw_weapon(alpha)
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect_region(SHEET, Rect2(-20, -58, 40, 60), Rect2(frame * 40, row * 60, 40, 60), tint)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if not weapon_behind:
		_draw_weapon(alpha)


func _weapon_at(hand: Vector2, angle: float, alpha: float) -> void:
	# weapon sprites point up; rotate so they point along `angle`
	draw_set_transform(hand, angle + PI * 0.5, Vector2(2, 2))
	if has_sword:
		draw_texture_rect_region(ITEMS, Rect2(-3.5, -20, 7, 23), Rect2(0, 0, 14, 46), Color(1, 1, 1, alpha))
	else:
		draw_texture_rect_region(ITEMS, Rect2(-4, -20, 8, 22), Rect2(20, 0, 16, 44), Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_weapon(alpha: float) -> void:
	var hand := Vector2(0, -24) + facing * 10.0
	var ang := facing.angle()
	if state == "attack":
		var p := clampf(state_t / 0.18, 0.0, 1.0)
		var a := ang - 1.3 + p * 2.6
		if p < 1.0:
			draw_arc(hand, 40.0, ang - 1.3, a, 14, Color(1, 1, 1, 0.5 * (1.0 - p)), 4.0)
		_weapon_at(hand, a, alpha)
	elif state == "heavy":
		var p := clampf(state_t / 0.38, 0.0, 1.0)
		var a := lerp_angle(-PI * 0.5, ang, p * p)
		_weapon_at(hand, a, alpha)
		if state_t >= 0.38 and state_t < 0.55:
			var r := (state_t - 0.38) / 0.17
			draw_arc(Vector2(0, -4) + facing * 44.0, 20 + r * 60, 0, TAU, 32, Color(1, 0.85, 0.5, 1.0 - r), 4.0)
	else:
		_weapon_at(hand + Vector2(0, 6), ang + 0.9, alpha)
