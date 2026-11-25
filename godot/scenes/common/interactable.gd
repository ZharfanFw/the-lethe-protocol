class_name Interactable
extends Area2D

signal collected(evidence_id: String)

@export var evidence_id: String = ""
@export var dialogue_id: String = ""
@export var flag_to_set: String = ""
@export var speaker_name: String = "Arthur Vance"
@export var lines: Array[String] = []
@export var prompt_text: String = "[E] Periksa"
@export var one_shot: bool = true
@export var memory_bonus: int = 0
@export var suspicion_bonus: int = 0
@export var required_evidence: Array[String] = []

var player_in_zone: bool = false
var consumed: bool = false
var _prompt: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()
	if one_shot and not flag_to_set.is_empty() and GameManager.has_flag(flag_to_set):
		consumed = true
		queue_free()

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
	if _prompt and not consumed:
		_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_zone = false
	if _prompt:
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_zone or consumed:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	if consumed:
		return
	if not _requirements_met():
		UIManager.say(speaker_name, ["Aku belum punya cukup petunjuk untuk memeriksa ini."])
		return

	if not evidence_id.is_empty():
		GameManager.add_evidence(evidence_id)
	if not flag_to_set.is_empty():
		GameManager.set_flag(flag_to_set, true)
	if memory_bonus != 0:
		GameManager.add_memory(memory_bonus)
	if suspicion_bonus != 0:
		GameManager.add_suspicion(suspicion_bonus)
	var active_speaker: String = speaker_name
	var active_lines: Array = lines
	var lookup_id: String = dialogue_id if not dialogue_id.is_empty() else evidence_id

	if lookup_id == "CH1_TONIC":
		if GameManager.has_flag("tonic_taken_ch1"):
			UIManager.say("HUD-Mirror Biometrik", [
				"Denyut nadi terpantau stabil [BPM: 72]. Log biometrik mencatat suplemen The Tonic telah diserap tubuh."
			])
			return
		elif GameManager.has_flag("tonic_skipped_ch1"):
			UIManager.say("HUD-Mirror Biometrik", [
				"Denyut nadi masih fluktuatif [BPM: 94]. Ampul The Tonic masih tergeletak di atas meja, belum diminum."
			])
			return
	elif lookup_id == "CH1_WARDROBE":
		if GameManager.has_flag("vance_equipped_ch1"):
			UIManager.say("Arthur Vance", [
				"Mantel dinas dan lencana Unit V-09 sudah kupakai. Aku siap menuju pos pemeriksaan Sub-Sektor 4."
			])
			return
	if not lookup_id.is_empty():
		var entry := GameManager.get_interactable_dialogue(lookup_id)
		if not entry.is_empty():
			active_speaker = str(entry.get("speaker", active_speaker))
			var json_lines: Variant = entry.get("lines", [])
			if json_lines is Array and not json_lines.is_empty():
				active_lines = json_lines
	if not active_lines.is_empty():
		GameManager.unlock_profile_by_name(active_speaker)
		UIManager.say(active_speaker, active_lines)
	collected.emit(evidence_id)
	if one_shot:
		consumed = true
		if _prompt:
			_prompt.visible = false
		set_deferred("monitoring", false)

func _requirements_met() -> bool:
	for id in required_evidence:
		if not GameManager.has_evidence(id):
			return false
	return true
