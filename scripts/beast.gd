extends CharacterBody2D
const Shadow = preload("res://scripts/shadow.gd")
## Terrak, the ancient beast. Wanders, chases the player, roars (telegraph), then lunges.
## The roar is the player's cue to dodge.

var main
var max_hp := 45.0
var hp := 45.0
var state := "wander"
var t := 0.0
var home := Vector2.ZERO
var wander_target := Vector2.ZERO
var facing := Vector2.RIGHT
var lunge_dir := Vector2.RIGHT
var dealt := false
var flash := 0.0
var knock := Vector2.ZERO
var anim_t := 0.0
var leader := false
var damage := 14.0
var hit_radius := 26.0
const LEADER = preload("res://art/terrak_leader.png")
const YOUNG = preload("res://art/terrak_young.png")


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	add_to_group("hittable")
	add_to_group("beasts")
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 30.0 if leader else 20.0
	cs.shape = c
	cs.position = Vector2(0, -6)
	add_child(cs)
	if leader:
		max_hp = 120.0
		hp = max_hp
		damage = 20.0
		hit_radius = 44.0
	home = global_position
	_pick_wander()
	t = randf() * 1.0


func _go(s: String) -> void:
	state = s
	t = 0.0


func _pick_wander() -> void:
	wander_target = home + Vector2(randf_range(-140, 140), randf_range(-100, 100))


func _physics_process(delta: float) -> void:
	if main.is_world_paused():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	t += delta
	anim_t += delta
	flash = maxf(flash - delta, 0.0)

	var p = main.player
	var to_p: Vector2 = p.global_position - global_position
	var dist := to_p.length()

	match state:
		"wander":
			var to_w := wander_target - global_position
			if to_w.length() > 8.0:
				facing = to_w.normalized()
				velocity = facing * 60.0
			else:
				velocity = Vector2.ZERO
				if t > 1.5:
					_pick_wander()
					t = 0.0
			if dist < 330.0:
				_go("chase")
		"chase":
			facing = to_p.normalized()
			velocity = facing * 125.0
			if dist < (180.0 if leader else 140.0) and t > 0.35:
				lunge_dir = facing
				_go("windup")
			elif dist > 560.0:
				_go("wander")
		"windup":
			facing = lunge_dir
			velocity = -lunge_dir * 18.0
			if t >= 0.55:
				dealt = false
				_go("lunge")
		"lunge":
			velocity = lunge_dir * 470.0
			if not dealt and dist < hit_radius + 14.0:
				p.take_damage(damage, global_position)
				dealt = true
			if t >= 0.32:
				_go("recover")
		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 1600.0 * delta)
			if t >= 0.7:
				_go("chase")
		"hurt":
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 1500.0 * delta)
			if t >= 0.22:
				_go("chase")

	# Keep beasts from stacking on top of each other
	for other in get_tree().get_nodes_in_group("beasts"):
		if other != self:
			var away: Vector2 = global_position - other.global_position
			if away.length() < 70.0 and away.length() > 0.01:
				velocity += away.normalized() * 90.0

	move_and_slide()
	queue_redraw()


func hit(damage: float, from: Vector2) -> void:
	hp -= damage
	flash = 0.15
	main.spawn_fx("spark", global_position + Vector2(0, -12))
	main.float_text(str(int(round(damage))), global_position + Vector2(0, -40), Color(1, 0.9, 0.6))
	if hp <= 0.0:
		remove_from_group("hittable")
		remove_from_group("beasts")
		main.on_beast_killed(self)
		queue_free()
		return
	# Crouching or lunging beasts don't flinch: the player has to dodge instead
	if state != "windup" and state != "lunge":
		knock = (global_position - from).normalized() * 300.0
		_go("hurt")


func _draw() -> void:
	var tex: Texture2D = LEADER if leader else YOUNG
	var fw := tex.get_width() / 7
	var fh := tex.get_height()
	Shadow.soft(self, Vector2(2, 0), fw * 0.38, fw * 0.11, 0.5)

	var frame := 0
	match state:
		"windup":
			frame = 4 + int(t * 8.0) % 2
			var pulse := 0.5 + 0.5 * sin(t * 30.0)
			draw_line(Vector2(0, -16), Vector2(0, -16) + lunge_dir * (220.0 if leader else 170.0), Color(1, 0.25, 0.2, 0.25 + 0.2 * pulse), 12.0)
		"lunge":
			frame = 6
		"hurt", "recover":
			frame = 0
		_:
			frame = int(anim_t * 8.0) % 4 if velocity.length() > 20.0 else 0
	var tint := Color(1, 1, 1)
	if state == "windup":
		var pulse := 0.5 + 0.5 * sin(t * 30.0)
		tint = Color(1, 1, 1).lerp(Color(1.6, 0.6, 0.5), pulse * 0.6)
	if flash > 0.0:
		tint = Color(3, 3, 3)
	var flip := facing.x < 0.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if flip else 1, 1))
	# sprite is drawn at 2x; its feet sit near the bottom of the frame
	draw_texture_rect_region(tex, Rect2(-fw / 2, -fh + 6, fw, fh), Rect2(frame * fw, 0, fw, fh), tint)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	if hp < max_hp:
		var bw := 60.0 if leader else 44.0
		var y := -fh - 4.0
		draw_rect(Rect2(-bw / 2, y, bw, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-bw / 2, y, bw * maxf(hp, 0.0) / max_hp, 6), Color(0.85, 0.25, 0.2))
