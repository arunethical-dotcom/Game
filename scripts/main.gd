extends Node2D
## Main game controller.
## Builds Akropolis Aigidos and the land around it, places the people, and runs Mission 1:
## mine iron ore outside the walls, forge a sword, and take moonsteel from the beast pack leader.

const Geo = preload("res://scripts/geo.gd")
const City = preload("res://scripts/city.gd")
const Castle = preload("res://scripts/castle_outer.gd")
const WorldScript = preload("res://scripts/world.gd")
const PlayerScript = preload("res://scripts/player.gd")
const NpcScript = preload("res://scripts/npc.gd")
const BeastScript = preload("res://scripts/beast.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const CraterScript = preload("res://scripts/crater.gd")
const FxScript = preload("res://scripts/fx.gd")
const ArrowScript = preload("res://scripts/objective_arrow.gd")
const HudScript = preload("res://scripts/hud.gd")
const Story = preload("res://scripts/story.gd")

enum { S_START, S_GATHER, S_FORGE, S_HUNT, S_RETURN, S_DONE }

const NEED_ORE := 3

var world
var ground_layer: Node2D
var decal_layer: Node2D
var entity_layer: Node2D
var overlay_layer: Node2D
var lights                    # light_layer.gd: warm local light from flames
var env_zones := []           # [Rect2, environment name] used by the colour grade (grade.gd)
var time_of_day := "day"      # "day", "afternoon", "sunset" or "night"
const TIMES := ["day", "afternoon", "sunset", "night"]
var player
var haldor
var hud
var camera: Camera2D
var arrow
var npcs := []
var talk_target = null

var stage := S_START
var inv := {"ore": 0, "moonsteel": 0}
var leader_dead := false
var moonsteel_drop := Vector2.INF
var shake_amount := 0.0
var cam_pos := Vector2.ZERO
var camera_zones := []        # [Rect2, zoom] areas the camera stays inside (see _update_camera)
var boss_focus: Node2D = null # set during a boss fight: the camera keeps Kael and the boss in view
const INTERIOR_ZOOM := 1.5    # 1.5 x the 2x phone scale = exactly 3 screen pixels per art pixel
var current_zone := Rect2()
var zone_blend := 1.0
var look_ahead := Vector2.ZERO

# indoor floors reached by stairs (see citadel_floors.gd)
var floor_name := ""          # "" = the open world and the citadel's main floor
var stairs := []              # [trigger Rect2, destination, floor it leads to, floor it is on, place name]
var traveling := false
var _stairs_armed := true
var fade_rect: ColorRect


func _ready() -> void:
	randomize()
	_setup_input()

	ground_layer = Node2D.new()
	ground_layer.z_index = -10
	add_child(ground_layer)
	decal_layer = Node2D.new()
	decal_layer.z_index = -5
	add_child(decal_layer)
	lights = preload("res://scripts/light_layer.gd").new()
	lights.main = self
	add_child(lights)
	entity_layer = Node2D.new()
	entity_layer.y_sort_enabled = true
	add_child(entity_layer)
	overlay_layer = Node2D.new()
	overlay_layer.z_index = 20
	add_child(overlay_layer)

	world = WorldScript.new()
	world.main = self
	ground_layer.add_child(world)
	ground_layer.add_child(preload("res://scripts/paving.gd").new())

	City.build(self)
	_place_people()
	Castle.build(self)

	player = PlayerScript.new()
	player.main = self
	player.position = Geo.HALDOR_POS + Vector2(-70, 40)
	entity_layer.add_child(player)

	camera = Camera2D.new()
	# The game renders at 540 px tall and is scaled up by a whole number (2x on a
	# 1080p phone), so every art pixel stays a crisp square.
	camera.zoom = Vector2(1.0, 1.0)
	# On a computer the window opens maximised and may not be an exact multiple of
	# 540 px tall, so let it scale smoothly there (phones keep exact 2x pixels).
	if not (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()):
		get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	# The camera follows Kael smoothly but always lands on whole pixels, so walls,
	# roads and buildings never shimmer or shake while he moves.
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	cam_pos = player.global_position
	camera.global_position = cam_pos.round()

	arrow = ArrowScript.new()
	arrow.main = self
	overlay_layer.add_child(arrow)

	add_child(preload("res://scripts/grade.gd").new())

	hud = HudScript.new()
	hud.main = self
	add_child(hud)

	# a black screen used for the quick fade when taking the stairs
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 8
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)

	world.update_chunks(player.global_position)
	_refresh_hud()
	hud.show_dialog(Story.WAKE_UP)


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J, KEY_SPACE],
		"heavy": [KEY_L],
		"dodge": [KEY_K, KEY_SHIFT],
		"interact": [KEY_E, KEY_ENTER],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _npc(role: String, pos: Vector2, name := "", lines := []) -> Node2D:
	var n = NpcScript.new()
	n.role = role
	n.position = pos
	n.lines = lines
	n.npc_name = name if name != "" or lines.is_empty() else lines[0][0]
	n.main = self
	entity_layer.add_child(n)
	npcs.append(n)
	return n


func _place_people() -> void:
	haldor = _npc("haldor", Geo.HALDOR_POS, "Haldor")

	_npc("guard", Geo.GATE_IN + Vector2(-85, 30), "Guard", Story.GUARD_NORTH)
	_npc("guard", Geo.GATE_IN + Vector2(85, 30), "Guard", Story.GUARD_NORTH)
	_npc("guard", Geo.SOUTH_GATE + Vector2(0, -90), "Guard", Story.GUARD_SOUTH)

	# Kingdom A captives hauling stone near the castle, watched by a guard
	for i in 3:
		var w = _npc("worker", Vector2(-1960 * Geo.K - i * 40, 300 * Geo.K + i * 30), "Captive", Story.WORKER if i == 0 else [])
		w.patrol_b = w.position + Vector2(-60, 220)
	_npc("guard", Vector2(-1880 * Geo.K, 420 * Geo.K), "Overseer", Story.GUARD_CASTLE)

	# The inn, the watchtowers, the forest outpost and the mining settlement
	_npc("villager", Geo.INN_POS + Vector2(0, 40), "Innkeeper", Story.INNKEEPER).variant = 3
	_npc("guard", Geo.WATCHTOWERS[0] + Vector2(40, 30), "Watchman", Story.WATCH_GUARD)
	_npc("guard", Geo.WATCHTOWERS[1] + Vector2(-40, 30), "Watchman", Story.WATCH_GUARD)
	_npc("guard", Geo.OUTPOST_POS + Vector2(30, 40), "Scout", Story.OUTPOST_GUARD)
	var m := Geo.MINE_POS
	_npc("miner", m + Vector2(60, 90), "Miner", Story.MINER)
	_npc("miner", m + Vector2(-120, 150), "Foreman", Story.MINE_FOREMAN)
	var mw = _npc("miner", m + Vector2(-60, 80), "Miner")
	mw.role = "worker_miner"
	for i in 2:
		var w = _npc("worker", m + Vector2(-20 + i * 50, 110), "Captive")
		w.patrol_b = w.position + Vector2(-150, -40)

	# Townsfolk strolling along the ring road
	for i in 8:
		var a := -PI / 2.0 + PI / 8.0 + i * PI / 4.0
		_npc("villager", Vector2.from_angle(a) * Geo.RING_ROAD, "", Story.VILLAGER_LINES[i % Story.VILLAGER_LINES.size()])


func _unhandled_input(event: InputEvent) -> void:
	# Esc closes the game on a computer
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not OS.has_feature("mobile"):
		get_tree().quit()
	# F2 cycles the time of day (for checking the lighting; a day/night cycle can drive it later)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		time_of_day = TIMES[(TIMES.find(time_of_day) + 1) % TIMES.size()]
		float_text(time_of_day.capitalize(), player.global_position + Vector2(0, -90), Color(1, 0.9, 0.6))


func _process(delta: float) -> void:
	var busy: bool = hud.is_busy() or traveling
	player.locked = busy
	if floor_name == "":
		world.update_chunks(player.global_position)
	_check_stairs()

	# Find someone to talk to
	var nearest = null
	var best := 80.0
	for n in npcs:
		n.look_at_pos = Vector2.INF
		if n.talkable():
			var d: float = player.global_position.distance_to(n.global_position)
			if d < best:
				best = d
				nearest = n
	talk_target = nearest
	haldor.alert = _haldor_has_news()
	if nearest != null and not busy:
		nearest.look_at_pos = player.global_position
		hud.set_hint("Talk to " + (nearest.npc_name if nearest.npc_name != "" else "them"))
		if Input.is_action_just_pressed("interact"):
			_talk(nearest)
	else:
		hud.set_hint("")

	_update_camera(delta)


## CrossCode-style camera:
##  - follows Kael softly and leans a little ahead of where he is walking
##  - each area (a room, a hall, the castle grounds) is a camera zone: the view never shows
##    past its edges, so small rooms sit still like a framed picture and big ones scroll
##  - moving into another zone glides the camera over instead of jumping
##  - in a conversation it frames Kael and the person he is talking to
func add_camera_zone(r: Rect2, zoom := 1.0) -> void:
	camera_zones.append([r, zoom])


func _zone_at(p: Vector2) -> Array:
	var best := [Rect2(), 1.0]
	for z in camera_zones:
		var r: Rect2 = z[0]
		if r.has_point(p) and (best[0].size == Vector2.ZERO or r.get_area() < best[0].get_area()):
			best = z
	return best


func _clamp_to_zone(t: Vector2, z: Rect2, view: Vector2) -> Vector2:
	if z.size == Vector2.ZERO:
		return t
	var half := view / 2.0
	for i in 2:
		if z.size[i] <= view[i]:
			t[i] = z.get_center()[i]     # area narrower than the screen: keep it centred
		else:
			t[i] = clampf(t[i], z.position[i] + half[i], z.end[i] - half[i])
	return t


func _update_camera(delta: float) -> void:
	var p: Vector2 = player.global_position
	var zone_info := _zone_at(p)
	var zone: Rect2 = zone_info[0]
	var want_zoom: float = zone_info[1]
	# boss fight: frame Kael and the boss together inside the arena
	if boss_focus != null and is_instance_valid(boss_focus):
		want_zoom = 1.0
	# ease the zoom (rooms are viewed closer, at an exact 3x pixel scale on phones)
	var z := move_toward(camera.zoom.x, want_zoom, delta * 2.5)
	camera.zoom = Vector2(z, z)
	var view: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	# look ahead in the walking direction (eased so it never snaps)
	var ahead: Vector2 = player.velocity.limit_length(1.0) * 0.0
	if player.velocity.length() > 10.0:
		ahead = player.velocity.normalized() * 44.0
	look_ahead = look_ahead.lerp(ahead, 1.0 - exp(-2.5 * delta))
	var target := p + look_ahead
	# in a conversation, frame both speakers
	if hud.is_busy() and talk_target != null and is_instance_valid(talk_target):
		target = (p + talk_target.global_position) / 2.0 + Vector2(0, -20)
	if boss_focus != null and is_instance_valid(boss_focus):
		target = (p + boss_focus.global_position) / 2.0 + Vector2(0, -24)
	if zone != current_zone:
		current_zone = zone
		zone_blend = 0.0          # glide into the new area
	target = _clamp_to_zone(target, zone, view)
	zone_blend = minf(1.0, zone_blend + delta * 1.6)
	var speed := lerpf(3.0, 7.0, zone_blend)
	cam_pos = cam_pos.lerp(target, 1.0 - exp(-speed * delta))
	if cam_pos.distance_to(target) > 700.0:
		cam_pos = target   # teleports (stairs, waking at the forge)
	var shake := Vector2.ZERO
	if shake_amount > 0.0:
		shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
		shake_amount = move_toward(shake_amount, 0.0, 40.0 * delta)
	# always land on whole pixels so nothing shimmers
	camera.global_position = (cam_pos + shake).round()
	camera.offset = Vector2.ZERO


# ---------------------------------------------------------------- Stairs between floors

func add_stairs(trigger: Rect2, dest: Vector2, to_floor: String, on_floor: String, place: String) -> void:
	stairs.append([trigger, dest, to_floor, on_floor, place])


func _check_stairs() -> void:
	if traveling:
		return
	var p: Vector2 = player.global_position
	for s in stairs:
		if s[0].has_point(p):
			if _stairs_armed:
				if s[1] == Vector2.INF:
					# a staircase whose floor isn't built yet: it is sealed
					_stairs_armed = false
					hud.show_dialog([["", s[4]]])
				else:
					travel(s[1], s[2], s[4])
			return
	# Kael must step off the stairs before they work again
	_stairs_armed = true


## Move Kael to another floor behind a quick fade (no loading screen: every floor is
## already built, just far apart in the world).
func travel(dest: Vector2, to_floor: String, place: String) -> void:
	traveling = true
	_stairs_armed = false
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.16)
	tw.tween_callback(func():
		floor_name = to_floor
		player.global_position = dest
		player.reset_state()
		cam_pos = dest
		camera.global_position = dest.round()
		if to_floor == "":
			world.update_chunks(dest)
		float_text(place, dest + Vector2(0, -80), Color(1.0, 0.9, 0.6)))
	tw.tween_interval(0.06)
	tw.tween_property(fade_rect, "color:a", 0.0, 0.22)
	tw.tween_callback(func(): traveling = false)


## Register a room for the colour grade: "throne", "bedroom", "library", "kitchen", "stone", "chapel".
func add_env_zone(r: Rect2, env: String) -> void:
	env_zones.append([r, env])


## Which grading profile applies where Kael stands ("outdoor" when no room contains him).
func environment() -> String:
	var p: Vector2 = player.global_position
	var best := "outdoor"
	var area := INF
	for z in env_zones:
		var r: Rect2 = z[0]
		if r.has_point(p) and r.get_area() < area:
			area = r.get_area()
			best = z[1]
	if best == "outdoor" and floor_name != "":
		best = "bedroom" if floor_name == "up" else "kitchen"
	return best


## True when Kael is under a roof: inside a citadel building or on another floor.
func is_indoors() -> bool:
	return environment() != "outdoor"


func is_world_paused() -> bool:
	return hud != null and hud.is_busy()


# ---------------------------------------------------------------- Mission flow

func _haldor_has_news() -> bool:
	match stage:
		S_START, S_RETURN:
			return true
		S_GATHER:
			return inv["ore"] >= NEED_ORE
	return false


func _talk(n) -> void:
	if n == haldor:
		_talk_to_haldor()
	else:
		hud.show_dialog(n.lines)


func _talk_to_haldor() -> void:
	match stage:
		S_START:
			hud.show_dialog(Story.FIRST_JOB, func(): _set_stage(S_GATHER))
		S_GATHER:
			if inv["ore"] >= NEED_ORE:
				hud.show_dialog(Story.READY_TO_FORGE, func():
					_set_stage(S_FORGE)
					hud.open_forge(_on_forge_done))
			else:
				hud.show_dialog(Story.NOT_ENOUGH)
		S_FORGE:
			hud.open_forge(_on_forge_done)
		S_HUNT:
			hud.show_dialog(Story.HUNT_REMINDER)
		S_RETURN:
			inv["moonsteel"] = 0
			hud.show_dialog(Story.ENDING, func(): _set_stage(S_DONE))
		S_DONE:
			hud.show_dialog([Story.IDLE_LINES[randi() % Story.IDLE_LINES.size()]])


func _on_forge_done(quality: float) -> void:
	inv["ore"] -= NEED_ORE
	player.has_sword = true
	player.sword_damage = 12.0 + 22.0 * quality
	var lines: Array
	if quality >= 0.75:
		lines = Story.FORGE_GREAT.duplicate()
	elif quality >= 0.4:
		lines = Story.FORGE_OK.duplicate()
	else:
		lines = Story.FORGE_ROUGH.duplicate()
	lines.append_array(Story.HUNT_BRIEFING)
	hud.show_dialog(lines, func(): _set_stage(S_HUNT))


func _set_stage(s: int) -> void:
	stage = s
	if s == S_HUNT:
		_spawn_pack()
	_refresh_hud()


func _spawn_pack() -> void:
	var offsets := [Vector2(-150, -60), Vector2(140, -30), Vector2(-40, 150)]
	for o in offsets:
		var b = BeastScript.new()
		b.main = self
		b.position = Geo.DEN + o
		entity_layer.add_child(b)
	var lead = BeastScript.new()
	lead.main = self
	lead.leader = true
	lead.position = Geo.DEN
	entity_layer.add_child(lead)


func on_beast_killed(b) -> void:
	spawn_fx("dust", b.global_position)
	if b.leader:
		leader_dead = true
		moonsteel_drop = b.global_position
		var p = PickupScript.new()
		p.main = self
		p.kind = "moonsteel"
		p.position = b.global_position
		entity_layer.add_child(p)
		float_text("The leader dropped its moonsteel", b.global_position + Vector2(0, -60), Color(0.8, 0.9, 1.0))
	_refresh_hud()


func collect(kind: String, pos: Vector2) -> void:
	inv[kind] += 1
	float_text("+1 Moonsteel", pos + Vector2(0, -40), Color(0.8, 0.9, 1.0))
	spawn_fx("spark", pos + Vector2(0, -16), Color(0.7, 0.85, 1.0))
	if kind == "moonsteel" and stage == S_HUNT:
		_set_stage(S_RETURN)
	_refresh_hud()


func add_item(kind: String, pos: Vector2) -> void:
	inv[kind] += 1
	float_text("+1 Iron ore", pos + Vector2(0, -40), Color(1, 0.95, 0.8))
	if stage == S_GATHER and inv["ore"] == NEED_ORE:
		float_text("Return to Haldor", player.global_position + Vector2(0, -70), Color(1, 0.8, 0.4))
	_refresh_hud()


func objective_text() -> String:
	match stage:
		S_START:
			return "Talk to Old Haldor at the forge"
		S_GATHER:
			if inv["ore"] >= NEED_ORE:
				return "Bring the iron ore back to Haldor"
			return "Mine iron ore at the foot of the cliffs  %d/%d" % [inv["ore"], NEED_ORE]
		S_FORGE:
			return "Forge your first sword"
		S_HUNT:
			if leader_dead:
				return "Pick up the moonsteel"
			return "Defeat the Terrak leader in the Forest of Elders"
		S_RETURN:
			return "Bring the moonsteel to Haldor"
		S_DONE:
			return "Mission complete. Explore freely."
	return ""


## The final place the player needs to reach.
func objective_goal() -> Vector2:
	match stage:
		S_START, S_FORGE, S_RETURN:
			return Geo.HALDOR_POS
		S_GATHER:
			if inv["ore"] >= NEED_ORE:
				return Geo.HALDOR_POS
			return _nearest_rock()
		S_HUNT:
			if leader_dead:
				return moonsteel_drop
			for b in get_tree().get_nodes_in_group("beasts"):
				if b.leader:
					return b.global_position
			return Geo.DEN
	return Vector2.INF


## Where the guide arrow points right now (follows the gate and the Serpent's Way).
func objective_target() -> Vector2:
	var goal := objective_goal()
	if goal == Vector2.INF:
		return goal
	if floor_name != "":
		# indoors on another floor: point back to the stairs
		for s in stairs:
			if s[3] == floor_name and s[2] == "":
				return s[0].get_center()
	return Geo.next_waypoint(player.global_position, goal)


func _nearest_rock() -> Vector2:
	var best := Geo.QUARRY
	var best_d := 1000.0
	for n in get_tree().get_nodes_in_group("hittable"):
		if n.get("kind") == "rock":
			var d: float = player.global_position.distance_to(n.global_position)
			if d < best_d:
				best_d = d
				best = n.global_position
	return best


func on_player_down() -> void:
	floor_name = ""
	player.hp = player.max_hp
	player.global_position = Geo.HALDOR_POS + Vector2(-60, 50)
	player.reset_state()
	hud.show_dialog(Story.KNOCKED_OUT)
	_refresh_hud()


func _refresh_hud() -> void:
	if hud:
		hud.update_hud()


# ---------------------------------------------------------------- Effects

func shake(amount: float) -> void:
	shake_amount = maxf(shake_amount, amount)


func spawn_crater(pos: Vector2) -> void:
	var c = CraterScript.new()
	c.position = pos
	decal_layer.add_child(c)
	spawn_fx("dust", pos)


func spawn_fx(kind: String, pos: Vector2, color := Color.WHITE) -> void:
	var f = FxScript.new()
	f.kind = kind
	f.color = color
	f.position = pos
	overlay_layer.add_child(f)


func float_text(text: String, pos: Vector2, color := Color.WHITE) -> void:
	var f = FxScript.new()
	f.kind = "text"
	f.text = text
	f.color = color
	f.position = pos
	overlay_layer.add_child(f)
