class_name AffinePuzzle
extends Area2D

signal solved

const C_CYAN := Color("#00f0ff")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")
const C_OK := Color("#00ff88")
const C_FAIL := Color("#ff3366")
const PREVIEW_CENTER := Vector2(320, 152)
const TOLERANCE_OFFSET := 8.0
const TOLERANCE_ROTATION := 8.0
const TOLERANCE_SCALE := 0.08

@export var target_offset: Vector2 = Vector2(24, -12)
@export var target_rotation_deg: float = 30.0
@export var target_scale: float = 1.2
@export var reward_deduction: String = "DEDUKSI-101"
@export var prompt_message: String = "[Spasi / E] Terminal Dekripsi Aksara (Puzzle)"

var player_in_zone: bool = false
var _open: bool = false
var _solved: bool = false
var _prompt: Label
var _overlay: CanvasLayer
var _glyph_holder: Control
var _status: Label
var _offset_x: HSlider
var _offset_y: HSlider
var _rotation: HSlider
var _scale: HSlider

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()
	_build_overlay()
	if GameManager.has_flag("puzzle_ja_completed"):
		_solved = true
		queue_free()

func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.text = prompt_message
	_prompt.position = Vector2(-150, -54)
	_prompt.size = Vector2(300, 14)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 7)
	_prompt.add_theme_color_override("font_color", C_CYAN)
	_prompt.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.07, 0.95))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	add_child(_prompt)

func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 35
	_overlay.visible = false
	add_child(_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.05, 0.9)
	_overlay.add_child(shade)

	_overlay.add_child(_label("KALIBRASI AFFINE // AKSARA NUSANTARA", 11, C_CYAN, Vector2(0, 22), Vector2(640, 18), HORIZONTAL_ALIGNMENT_CENTER))
	_overlay.add_child(_label("Samakan translasi, rotasi, dan skala aksara terhadap target.", 7, C_DIM, Vector2(0, 44), Vector2(640, 14), HORIZONTAL_ALIGNMENT_CENTER))

	_glyph_holder = Control.new()
	_glyph_holder.size = Vector2(56, 56)
	_glyph_holder.pivot_offset = Vector2(28, 28)
	_glyph_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_glyph_holder)

	var glyph := Label.new()
	glyph.text = "ꦲ"
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 34)
	glyph.add_theme_color_override("font_color", C_CYAN)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph_holder.add_child(glyph)

	var target_ring := ColorRect.new()
	target_ring.position = PREVIEW_CENTER - Vector2(46, 46)
	target_ring.size = Vector2(92, 92)
	target_ring.color = Color(C_CYAN, 0.12)
	target_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(target_ring)

	_offset_x = _add_slider("TRANSLASI X", -60, 60, 0, 216)
	_offset_y = _add_slider("TRANSLASI Y", -60, 60, 0, 242)
	_rotation = _add_slider("ROTASI", -180, 180, 0, 268)
	_scale = _add_slider("SKALA %", 60, 160, 100, 294)

	_status = _label("", 8, C_TEXT, Vector2(0, 306), Vector2(640, 14), HORIZONTAL_ALIGNMENT_CENTER)
	_overlay.add_child(_status)

	var check := Button.new()
	check.position = Vector2(240, 320)
	check.size = Vector2(160, 30)
	check.add_theme_font_size_override("font_size", 8)
	check.text = "UJI KALIBRASI"
	check.pressed.connect(_check_solution)
	_overlay.add_child(check)

	_apply_transform()

func _add_slider(label_text: String, min_value: float, max_value: float, value: float, y: float) -> HSlider:
	var label := _label(label_text, 7, C_DIM, Vector2(90, y), Vector2(120, 14), HORIZONTAL_ALIGNMENT_RIGHT)
	_overlay.add_child(label)
	var slider := HSlider.new()
	slider.position = Vector2(224, y)
	slider.size = Vector2(320, 16)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 1.0
	slider.value = value
	slider.value_changed.connect(func(_value: float): _apply_transform())
	_overlay.add_child(slider)
	return slider

func _label(text: String, font_size: int, color: Color, pos: Vector2, size: Vector2, align: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _apply_transform() -> void:
	if _glyph_holder == null:
		return
	var offset := Vector2(_offset_x.value, _offset_y.value)
	_glyph_holder.position = PREVIEW_CENTER + offset - _glyph_holder.size * 0.5
	_glyph_holder.rotation_degrees = _rotation.value
	var scale_factor: float = _scale.value / 100.0
	_glyph_holder.scale = Vector2(scale_factor, scale_factor)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_zone = true
	if _prompt and not _open and not _solved:
		_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_zone = false
	if _prompt:
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _open:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close_puzzle()
		return
	if not player_in_zone or _solved:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_E or event.keycode == KEY_SPACE)):
		get_viewport().set_input_as_handled()
		open_puzzle()

func open_puzzle() -> void:
	if _open or _solved:
		return
	_open = true
	_overlay.visible = true
	_prompt.visible = false
	_set_player_movement(false)

func close_puzzle() -> void:
	if not _open:
		return
	_open = false
	_overlay.visible = false
	_set_player_movement(true)
	if player_in_zone and not _solved:
		_prompt.visible = true

func _set_player_movement(can_move: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set("can_move", can_move)

func _check_solution() -> void:
	if _solved:
		return
	var current_offset := Vector2(_offset_x.value, _offset_y.value)
	var current_scale: float = _scale.value / 100.0
	var offset_ok: bool = current_offset.distance_to(target_offset) <= TOLERANCE_OFFSET
	var rotation_ok: bool = abs(_rotation.value - target_rotation_deg) <= TOLERANCE_ROTATION
	var scale_ok: bool = abs(current_scale - target_scale) <= TOLERANCE_SCALE
	if offset_ok and rotation_ok and scale_ok:
		_solved = true
		_status.text = "KALIBRASI BERHASIL // AKSARA TERSINKRON"
		_status.add_theme_color_override("font_color", C_OK)
		GameManager.set_flag("puzzle_ja_completed", true)
		if not reward_deduction.is_empty():
			GameManager.unlock_deduction(reward_deduction, 10)
		solved.emit()
		await get_tree().create_timer(0.8).timeout
		close_puzzle()
	else:
		_status.text = "KALIBRASI GAGAL // PERIKSA TRANSLASI, ROTASI, DAN SKALA"
		_status.add_theme_color_override("font_color", C_FAIL)
