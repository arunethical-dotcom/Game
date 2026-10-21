extends CharacterBody2D
const Shadow = preload("res://scripts/shadow.gd")
## Kael, the main character.
## Real-time combat: quick attack, heavy slam (cracks the ground), and a dodge roll
## that makes you briefly invincible.

var main
var locked := false

const SPEED := 210.0
const DODGE_SPEED := 420.0
const DODGE_TIME := 0.36
const ATTACK_TIME := 0.36      # 6 frames
const ATTACK_HIT := 0.13       # the swing frame, when the blade connects
const DOWN_TIME := 1.7         # knocked down: fall, lie, get up

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
			if not hit_done and state_t >= ATTACK_HIT:
				hit_done = true
				_do_hit(false)
			if state_t > ATTACK_HIT + 0.05 and not locked and Input.is_action_just_pressed("dodge"):
				_try_dodge(input)
			elif state_t >= ATTACK_TIME:
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
		"down":
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t >= DOWN_TIME:
				main.on_player_down()

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
	invuln = DODGE_TIME + 0.06
	dodge_cd = 0.6
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
	if invuln > 0.0 or state == "dodge" or state == "down" or locked:
		return
	hp -= amount
	hurt_flash = 0.3
	invuln = 0.7
	knock = (global_position - from).normalized() * 380.0
	main.shake(6.0)
	main.spawn_fx("spark", global_position + Vector2(0, -16), Color(1, 0.4, 0.3))
	if absf(knock.x) > 1.0:
		facing = Vector2(-signf(knock.x), 0)   # turn toward whatever hit us
	if hp <= 0.0:
		hp = 0.0
		_start("down")
	else:
		_start("hurt")
	main.hud.update_hud()


# ---------------------------------------------------------------- Drawing
# Kael's sheets (art/kael_*.png): 96x96 frames, feet at y = 88.
# Rows: 0 facing down, 1 facing up, 2 facing right (left = flipped).

const FW := 96
const FEET := 88
const ANIM := {
	"idle": preload("res://art/kael_idle.png"),
	"walk": preload("res://art/kael_walk.png"),
	"attack": preload("res://art/kael_attack.png"),
	"roll": preload("res://art/kael_roll.png"),
	"hurt": preload("res://art/kael_hurt.png"),
}
var idle_t := 0.0


func _row() -> int:
	if absf(facing.x) > absf(facing.y):
		return 2
	return 1 if facing.y < 0.0 else 0


## Which sheet and frame to show right now.
func _pick() -> Array:
	match state:
		"attack":
			return ["attack", _row(), mini(int(state_t / ATTACK_TIME * 6.0), 5)]
		"heavy":
			# wind up and hold, then a fast swing that lands with the slam
			var f := 1
			if state_t >= 0.30:
				f = mini(2 + int((state_t - 0.30) / 0.05), 4)
			if state_t >= 0.5:
				f = 5
			return ["attack", _row(), f]
		"dodge":
			return ["roll", _row(), mini(int(state_t / DODGE_TIME * 6.0), 5)]
		"hurt":
			return ["hurt", 0, mini(int(state_t / 0.125), 1)]
		"down":
			# fall, lie still, get up, crouch, stand
			var seq := [2, 3, 3, 3, 3, 4, 5, 6]
			return ["hurt", 0, seq[mini(int(state_t / DOWN_TIME * seq.size()), seq.size() - 1)]]
	if velocity.length() > 10.0:
		return ["walk", _row(), int(walk_t * 0.8) % 6]
	return ["idle", _row(), int(idle_t * 5.0) % 4]


func _process(delta: float) -> void:
	idle_t += delta


func _draw() -> void:
	var alpha := 1.0
	if invuln > 0.0 and state != "dodge" and state != "down" and int(invuln * 20.0) % 2 == 0:
		alpha = 0.5
	var tint := Color(1, 1, 1, alpha)
	if hurt_flash > 0.0:
		tint = Color(1.4, 0.6, 0.6, alpha)

	var pick := _pick()
	var sheet_name: String = pick[0]
	var shadow_w := 22.0 if state == "down" or state == "dodge" else 15.0
	Shadow.soft(self, Vector2(1, 0), shadow_w, 5.5, 0.5)

	var tex: Texture2D = ANIM[sheet_name]
	var flip: bool = facing.x < 0.0 and (pick[1] == 2 or sheet_name == "hurt")
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect_region(tex, Rect2(-FW / 2, -FEET, FW, FW), Rect2(pick[2] * FW, pick[1] * FW, FW, FW), tint)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# heavy slam: a ring of force where the blade hits the ground
	if state == "heavy" and state_t >= 0.38 and state_t < 0.55:
		var r := (state_t - 0.38) / 0.17
		draw_arc(Vector2(0, -4) + facing * 44.0, 20 + r * 60, 0, TAU, 32, Color(1, 0.85, 0.5, 1.0 - r), 3.0)
