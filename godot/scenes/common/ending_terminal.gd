class_name EndingTerminal
extends Area2D

const C_CYAN := Color("#00f0ff")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")

@export var prompt_message: String = "[E] Akses Terminal Transmisi"
@export var available_endings: Array[int] = [1, 2, 3, 5]

var player_in_zone: bool = false
var _open: bool = false
var _prompt: Label
var _overlay: CanvasLayer
var _buttons: Array[Button] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()
	_build_overlay()

func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.text = prompt_message
	_prompt.position = Vector2(-110, -52)
	_prompt.size = Vector2(220, 14)
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
	_overlay.layer = 40
	_overlay.visible = false
	add_child(_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.05, 0.88)
	_overlay.add_child(shade)

	var title := _label("TERMINAL TRANSMISI NASIONAL", 12, C_CYAN)
	title.position = Vector2(0, 36)
	title.size = Vector2(640, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(title)

	var subtitle := _label("PILIH NASIB KOTA CONCORD", 8, C_DIM)
	subtitle.position = Vector2(0, 58)
	subtitle.size = Vector2(640, 14)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(subtitle)

	var list := VBoxContainer.new()
	list.position = Vector2(120, 92)
	list.size = Vector2(400, 220)
	list.add_theme_constant_override("separation", 8)
	_overlay.add_child(list)

	for ending_id in available_endings:
		var button := Button.new()
		button.custom_minimum_size = Vector2(400, 42)
		button.add_theme_font_size_override("font_size", 8)
		var unlocked: bool = GameManager.is_ending_available(ending_id)
		button.disabled = not unlocked
		var status := "" if unlocked else "  [TERKUNCI]"
		button.text = "%s%s" % [String(GameManager.ENDING_TITLES.get(ending_id, "Ending")), status]
		button.pressed.connect(_choose_ending.bind(ending_id))
		list.add_child(button)
		_buttons.append(button)

	var hint := _label("[ESC] BATAL", 7, C_DIM)
	hint.position = Vector2(0, 328)
	hint.size = Vector2(640, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(hint)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_zone = true
	if _prompt and not _open:
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
			close_terminal()
		return
	if not player_in_zone:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		open_terminal()

func open_terminal() -> void:
	if _open:
		return
	_open = true
	_overlay.visible = true
	_prompt.visible = false
	_set_player_movement(false)
	for i in range(_buttons.size()):
		var ending_id: int = available_endings[i]
		_buttons[i].disabled = not GameManager.is_ending_available(ending_id)
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			break

func close_terminal() -> void:
	if not _open:
		return
	_open = false
	_overlay.visible = false
	_set_player_movement(true)
	if player_in_zone:
		_prompt.visible = true

func _set_player_movement(can_move: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set("can_move", can_move)

func _choose_ending(ending_id: int) -> void:
	for button in _buttons:
		button.disabled = true
	await UIManager.play_fade_transition(true, 0.5)
	GameManager.resolve_ending(ending_id)
