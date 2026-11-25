class_name ApartmentDoor
extends Area2D

signal door_entered(target_map: String, spawn_position: Vector2)

@export var target_map: String = "ch1_subsector4"
@export var spawn_position: Vector2 = Vector2(480, 320)

var player_in_zone: bool = false
var is_transitioning: bool = false
var _prompt: Label

func _ready() -> void:
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
	if _prompt and not is_transitioning:
		_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_zone = false
	if _prompt:
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_zone or is_transitioning:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		_attempt_exit()

func _attempt_exit() -> void:
	if is_transitioning:
		return
	var tonic_done: bool = GameManager.has_flag("tonic_taken_ch1") or GameManager.has_flag("tonic_skipped_ch1")
	var equipped_done: bool = GameManager.has_flag("vance_equipped_ch1")
	
	if not tonic_done or not equipped_done:
		var missing_msg: String = ""
		if not tonic_done and not equipped_done:
			missing_msg = "Aku belum siap bertugas. Aku harus memeriksa Cermin Biometrik di dinding dan mengambil perlengkapan dinasku di meja terlebih dahulu."
		elif not tonic_done:
			missing_msg = "Detak jantungku masih tidak stabil. Aku harus menyelesaikan pemeriksaan di Cermin Biometrik sebelum keluar."
		else:
			missing_msg = "Aku belum mengambil mantel dinas dan lencana Unit V-09 di meja kerja."
		UIManager.say("Arthur Vance", [missing_msg])
		return
	
	is_transitioning = true
	if _prompt:
		_prompt.visible = false
	
	# Transition narrative to Sub-Sector 4
	UIManager.say("Arthur Vance", [
		"Pintu kabin apartemen terbuka dengan desisan hidrolik dingin.",
		"Mobil dinas Unit V-09 meluncur membelah kabut malam dan guyuran hujan asam Kota Concord menuju Sub-Sektor 4..."
	])
	
	var box := UIManager.get_dialogue_box()
	if box and is_instance_valid(box):
		await box.dialogue_ended
	
	door_entered.emit(target_map, spawn_position)
