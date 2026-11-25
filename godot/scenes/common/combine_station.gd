class_name CombineStation
extends Area2D

@export var prompt_message: String = "[E] Meja Sintesis Bukti"

var player_in_zone: bool = false
var _prompt: Label

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()

func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.text = "E"
	_prompt.position = Vector2(-8, -36)
	_prompt.size = Vector2(16, 16)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 9)
	_prompt.add_theme_color_override("font_color", Color("#00f0ff"))
	_prompt.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.07, 0.95))
	_prompt.add_theme_constant_override("outline_size", 2)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.22, 0.92)
	style.set_border_width_all(1)
	style.border_color = Color("#00f0ff")
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.0, 0.94, 1.0, 0.35)
	style.shadow_size = 2
	_prompt.add_theme_stylebox_override("normal", style)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	add_child(_prompt)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_zone = true
	if _prompt:
		_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_zone = false
	if _prompt:
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_zone:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_E or event.keycode == KEY_C)):
		get_viewport().set_input_as_handled()
		open_combiner()

func open_combiner() -> void:
	if not is_inside_tree() or not get_tree().current_scene:
		return
	var matches := get_tree().current_scene.find_children("ItemCombiner", "CanvasLayer", true, false)
	if not matches.is_empty():
		var combiner = matches[0]
		if combiner.has_signal("open_requested"):
			combiner.open_requested.emit()
		elif combiner.has_method("open_combiner"):
			combiner.open_combiner()
