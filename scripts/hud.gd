extends CanvasLayer
## On-screen interface: health, quest tracker, dialogue, forge mini-game and touch controls.

const ForgeScript = preload("res://scripts/forge_panel.gd")
const JoystickScript = preload("res://scripts/joystick.gd")
const TouchButtonScript = preload("res://scripts/touch_button.gd")
const MinimapScript = preload("res://scripts/minimap.gd")
const UI_PANEL = preload("res://art/ui_panel.png")
const UI_FRAME = preload("res://art/ui_frame.png")
const UI_SMALL = preload("res://art/ui_small.png")

var main
var root: Control
var hp_bar
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
	touch_mode = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or OS.get_environment("FORCE_TOUCH") == "1"

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Health: heart icon and a wooden-framed bar
	var top := Control.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.position = Vector2(12, 10)
	root.add_child(top)
	var heart := TextureRect.new()
	heart.texture = _region(UI_SMALL, Rect2(0, 0, 16, 16))
	heart.position = Vector2(0, 0)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(heart)
	var bar_frame := Panel.new()
	bar_frame.add_theme_stylebox_override("panel", _nine(UI_FRAME, 7))
	bar_frame.position = Vector2(18, -2)
	bar_frame.size = Vector2(150, 20)
	bar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar_frame)
	hp_bar = preload("res://scripts/hp_bar.gd").new()
	hp_bar.position = Vector2(25, 5)
	hp_bar.size = Vector2(136, 6)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(hp_bar)

	quest_label = _make_label(12, Color(1, 0.86, 0.5))
	quest_label.position = Vector2(0, 22)
	top.add_child(quest_label)
	inv_label = _make_label(10, Color(0.95, 0.93, 0.88))
	inv_label.position = Vector2(0, 38)
	top.add_child(inv_label)

	hint_label = _make_label(13, Color(1, 0.95, 0.75))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(hint_label, Vector2(0.5, 1.0), Vector2(-200, -168 if touch_mode else -48), Vector2(400, 22))
	root.add_child(hint_label)

	if not touch_mode:
		help_label = _make_label(10, Color(0.95, 0.95, 0.95, 0.85))
		help_label.text = "WASD move   J / Space attack   L slam   K / Shift dodge   E talk   F3 castle   Esc quit"
		help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place(help_label, Vector2(1.0, 1.0), Vector2(-500, -22), Vector2(488, 16))
		root.add_child(help_label)

	# Minimap in a wooden frame
	var mm_frame := Panel.new()
	mm_frame.add_theme_stylebox_override("panel", _nine(UI_FRAME, 7))
	mm_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(mm_frame, Vector2(1.0, 0.0), Vector2(-128, 8), Vector2(120, 120))
	root.add_child(mm_frame)
	var minimap = MinimapScript.new()
	minimap.main = main
	_place(minimap, Vector2(1.0, 0.0), Vector2(-121, 15), Vector2(106, 106))
	root.add_child(minimap)
	root.move_child(mm_frame, root.get_child_count() - 1)

	_build_dialog()

	forge = ForgeScript.new()
	forge.main = main
	forge.visible = false
	_place(forge, Vector2(0.5, 0.5), Vector2(-240, -125), Vector2(600, 270))
	forge.scale = Vector2(0.8, 0.8)
	root.add_child(forge)

	if touch_mode:
		_build_touch_controls()

	update_hud()


func _region(tex: Texture2D, r: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = r
	return a


func _nine(tex: Texture2D, margin: int) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	return sb


func _flat_tex(r: Rect2) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _region(UI_SMALL, r)
	sb.texture_margin_top = 2
	sb.texture_margin_bottom = 2
	return sb


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
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_dialog() -> void:
	dialog_panel = PanelContainer.new()
	var sb := _nine(UI_PANEL, 9)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 8
	dialog_panel.add_theme_stylebox_override("panel", sb)
	dialog_panel.anchor_left = 0.5
	dialog_panel.anchor_right = 0.5
	dialog_panel.anchor_top = 1.0
	dialog_panel.anchor_bottom = 1.0
	dialog_panel.offset_left = -300
	dialog_panel.offset_right = 300
	dialog_panel.offset_top = -124
	dialog_panel.offset_bottom = -12
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_panel.gui_input.connect(_on_dialog_input)
	root.add_child(dialog_panel)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.add_child(vb)
	dialog_name = _make_label(13, Color(1, 0.8, 0.4))
	vb.add_child(dialog_name)
	dialog_text = _make_label(14, Color(0.97, 0.95, 0.9))
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(dialog_text)
	dialog_more = _make_label(10, Color(0.85, 0.75, 0.55))
	dialog_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialog_more.text = "Tap to continue" if touch_mode else "E / Space to continue"
	vb.add_child(dialog_more)
	dialog_panel.visible = false


func _build_touch_controls() -> void:
	var stick = JoystickScript.new()
	_place(stick, Vector2(0.0, 1.0), Vector2(22, -142), Vector2(120, 120))
	root.add_child(stick)

	# [action, label, offset from bottom-right corner, radius]
	var buttons := [
		["attack", "Attack", Vector2(-62, -62), 32.0],
		["dodge", "Dodge", Vector2(-136, -40), 24.0],
		["heavy", "Slam", Vector2(-44, -140), 24.0],
		["interact", "Talk", Vector2(-118, -112), 24.0],
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
	quest_label.text = "Quest: " + main.objective_text()
	var weapon: String = "Sword (power %d)" % int(main.player.sword_damage) if main.player.has_sword else "Old hammer"
	inv_label.text = "Iron ore %d    Moonsteel %d    %s" % [main.inv["ore"], main.inv["moonsteel"], weapon]


func set_hint(text: String) -> void:
	if text == "":
		hint_label.text = ""
	else:
		hint_label.text = text if touch_mode else "E: " + text


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
