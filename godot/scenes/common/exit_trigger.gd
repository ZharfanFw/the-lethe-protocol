class_name ExitTrigger
extends Area2D

signal transition_requested(target_chapter: int)

@export var target_next_chapter: int = 2
@export var required_flags: Array[String] = []
@export var prompt_message: String = "[E] Lanjut ke chapter berikutnya"

var player_in_zone: bool = false
var transitioning: bool = false
var _prompt: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()

func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.text = prompt_message
	_prompt.position = Vector2(-90, -52)
	_prompt.size = Vector2(180, 14)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 7)
	_prompt.add_theme_color_override("font_color", Color("#00ff88"))
	_prompt.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.07, 0.95))
	_prompt.add_theme_constant_override("outline_size", 4)
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
	if not player_in_zone or transitioning:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		try_transition()

func try_transition() -> void:
	if transitioning:
		return
	var missing: Array[String] = []
	for flag in required_flags:
		if not GameManager.has_flag(flag):
			missing.append(flag)
	if not missing.is_empty():
		UIManager.say("Arthur Vance", ["Saya belum bisa meninggalkan area ini. Masih ada petunjuk kunci yang harus diselesaikan."])
		return

	transitioning = true
	if _prompt:
		_prompt.visible = false
	GameManager.set_flag("chapter_%d_completed" % (target_next_chapter - 1), true)
	transition_requested.emit(target_next_chapter)
	await UIManager.play_fade_transition(true, 0.4)
	GameManager.advance_to_chapter(target_next_chapter)
