extends CanvasLayer
## On-screen interface: health, quest tracker, dialogue, forge mini-game and touch controls.

const ForgeScript = preload("res://scripts/forge_panel.gd")
const JoystickScript = preload("res://scripts/joystick.gd")
const TouchButtonScript = preload("res://scripts/touch_button.gd")
const MinimapScript = preload("res://scripts/minimap.gd")

var main
var root: Control
var hp_bar: ProgressBar
var quest_label: Label
var inv_label: Label
var hint_label: Label
var help_label: Label

var dialog_panel: PanelContainer
var dialog_name: Label
var dialog_text: Label
var dialog_more: Label
var dialog_lines := []
var dialog_index := 0
var dialog_cb = null
var dialog_frame := -1
var reveal := 0.0

var forge
var touch_mode := false


func _ready() -> void:
	layer = 10
	touch_mode = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Health
	var hp_box := VBoxContainer.new()
	hp_box.position = Vector2(24, 20)
	hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_box)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(260, 20)
	hp_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.06, 0.05, 0.85)
	bg.set_corner_radius_all(4)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.85, 0.7, 0.45)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.78, 0.2, 0.18)
	fill.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("background", bg)
	hp_bar.add_theme_stylebox_override("fill", fill)
	hp_box.add_child(hp_bar)

	quest_label = _make_label(19, Color(1, 0.88, 0.6))
	hp_box.add_child(quest_label)
	inv_label = _make_label(16, Color(0.92, 0.9, 0.85))
	hp_box.add_child(inv_label)

	hint_label = _make_label(20, Color(1, 0.95, 0.75))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(hint_label, Vector2(0.5, 1.0), Vector2(-250, -250 if touch_mode else -90), Vector2(500, 30))
	root.add_child(hint_label)

	if not touch_mode:
		help_label = _make_label(14, Color(0.9, 0.9, 0.9, 0.8))
		help_label.text = "WASD move   J / Space attack   L heavy slam   K / Shift dodge   E talk"
		help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place(help_label, Vector2(1.0, 0.0), Vector2(-680, 20), Vector2(660, 24))
		root.add_child(help_label)

	var minimap = MinimapScript.new()
	minimap.main = main
	_place(minimap, Vector2(1.0, 0.0), Vector2(-206, 52 if not touch_mode else 20), Vector2(186, 186))
	root.add_child(minimap)

	_build_dialog()

	forge = ForgeScript.new()
	forge.main = main
	forge.visible = false
	_place(forge, Vector2(0.5, 0.5), Vector2(-300, -170), Vector2(600, 270))
	root.add_child(forge)

	if touch_mode:
		_build_touch_controls()

	update_hud()


func _place(c: Control, anchor: Vector2, pos: Vector2, sz: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = pos.x
	c.offset_top = pos.y
	c.offset_right = pos.x + sz.x
	c.offset_bottom = pos.y + sz.y


func _make_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_dialog() -> void:
	dialog_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.05, 0.92)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.72, 0.52, 0.28)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(18)
	dialog_panel.add_theme_stylebox_override("panel", sb)
	dialog_panel.anchor_left = 0.12
	dialog_panel.anchor_right = 0.88
	dialog_panel.anchor_top = 1.0
	dialog_panel.anchor_bottom = 1.0
	dialog_panel.offset_top = -200
	dialog_panel.offset_bottom = -28
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_panel.gui_input.connect(_on_dialog_input)
	root.add_child(dialog_panel)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.add_child(vb)
	dialog_name = _make_label(20, Color(1, 0.78, 0.4))
	vb.add_child(dialog_name)
	dialog_text = _make_label(21, Color(0.97, 0.95, 0.9))
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(dialog_text)
	dialog_more = _make_label(14, Color(0.8, 0.75, 0.65))
	dialog_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialog_more.text = "Tap to continue" if touch_mode else "E / Space to continue"
	vb.add_child(dialog_more)
	dialog_panel.visible = false


func _build_touch_controls() -> void:
	var stick = JoystickScript.new()
	_place(stick, Vector2(0.0, 1.0), Vector2(40, -270), Vector2(230, 230))
	root.add_child(stick)

	# [action, label, offset from bottom-right corner, radius]
	var buttons := [
		["attack", "Attack", Vector2(-150, -150), 66.0],
		["dodge", "Dodge", Vector2(-290, -90), 48.0],
		["heavy", "Slam", Vector2(-120, -300), 48.0],
		["interact", "Talk", Vector2(-260, -230), 42.0],
	]
	for b in buttons:
		var tb = TouchButtonScript.new()
		tb.action = b[0]
		tb.label = b[1]
		tb.radius = b[3]
		_place(tb, Vector2(1.0, 1.0), b[2] - Vector2(b[3], b[3]), Vector2(b[3] * 2.0, b[3] * 2.0))
		root.add_child(tb)


# ---------------------------------------------------------------- Public API

func is_busy() -> bool:
	return dialog_panel.visible or forge.active


func update_hud() -> void:
	if main == null or main.player == null:
		return
	hp_bar.max_value = main.player.max_hp
	hp_bar.value = main.player.hp
	quest_label.text = main.objective_text()
	var weapon: String = "Sword (power %d)" % int(main.player.sword_damage) if main.player.has_sword else "Old hammer"
	inv_label.text = "Iron ore %d    Moonsteel %d    %s" % [main.inv["ore"], main.inv["moonsteel"], weapon]


func set_hint(text: String) -> void:
	if text == "":
		hint_label.text = ""
	else:
		hint_label.text = ("Tap Talk: " if touch_mode else "E: ") + text


func show_dialog(lines: Array, on_done = null) -> void:
	dialog_lines = lines
	dialog_index = 0
	dialog_cb = on_done
	dialog_frame = Engine.get_process_frames()
	dialog_panel.visible = true
	_show_line()


func open_forge(on_done: Callable) -> void:
	forge.open(on_done)


# ---------------------------------------------------------------- Dialogue

func _show_line() -> void:
	var line: Array = dialog_lines[dialog_index]
	dialog_name.text = line[0]
	dialog_name.visible = line[0] != ""
	dialog_text.text = line[1]
	dialog_text.visible_ratio = 0.0
	reveal = 0.0


func _advance() -> void:
	if Engine.get_process_frames() == dialog_frame:
		return
	if dialog_text.visible_ratio < 1.0:
		dialog_text.visible_ratio = 1.0
		reveal = float(dialog_text.text.length())
		return
	dialog_index += 1
	if dialog_index >= dialog_lines.size():
		dialog_panel.visible = false
		var cb = dialog_cb
		dialog_cb = null
		update_hud()
		if cb is Callable and cb.is_valid():
			cb.call()
	else:
		_show_line()


func _on_dialog_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _process(delta: float) -> void:
	if dialog_panel.visible:
		var total := dialog_text.text.length()
		if total > 0 and dialog_text.visible_ratio < 1.0:
			reveal += delta * 55.0
			dialog_text.visible_ratio = minf(reveal / total, 1.0)
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
			_advance()
