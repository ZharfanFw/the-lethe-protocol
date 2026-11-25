extends StaticBody2D

@export var npc_id: String = ""
@export var speaker_name: String = "Direktur Lucian Graves"
@export var dialogue_lines: Array[String] = [
	"Semalam ada pergerakan mencurigakan di dekat terowongan rel tua Sub-Sektor 4.",
	"Mereka membawa peti bertanda 'Jayabaya'... Hati-hati, Inspektur. Di sini, dinding pun punya telinga."
]
@export var sprite_frames: SpriteFrames = null
@export var default_animation: String = "idle"
@export var sprite_scale: Vector2 = Vector2(0.12, 0.12)
@export var face_player_on_interact: bool = true
@export var quest_dialogue_id: String = ""
@export var quest_evidence_id: String = ""
@export var quest_flag: String = ""
@export var quest_memory_bonus: int = 0
@export var quest_required_evidence: Array[String] = []
@export var quest_missing_req_lines: Array[String] = []

@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D")

var player_in_range: bool = false
var dialogue_box: CanvasLayer = null
var player_ref: Node2D = null
var is_talking: bool = false

func _ready() -> void:
	if not prompt_label:
		prompt_label = get_node_or_null("PromptLabel")
	if prompt_label:
		prompt_label.visible = false
		_style_keycap(prompt_label)
	
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		if sprite_frames:
			animated_sprite.sprite_frames = sprite_frames
		animated_sprite.scale = sprite_scale
		if animated_sprite.sprite_frames:
			if animated_sprite.sprite_frames.has_animation(StringName(default_animation)):
				animated_sprite.play(StringName(default_animation))
			elif animated_sprite.sprite_frames.has_animation(&"idle_down"):
				animated_sprite.play(&"idle_down")
			elif animated_sprite.sprite_frames.has_animation(&"idle"):
				animated_sprite.play(&"idle")
	
	if not interaction_area:
		interaction_area = get_node_or_null("InteractionArea")
	if interaction_area:
		if not interaction_area.body_entered.is_connected(_on_body_entered):
			interaction_area.body_entered.connect(_on_body_entered)
		if not interaction_area.body_exited.is_connected(_on_body_exited):
			interaction_area.body_exited.connect(_on_body_exited)
	
	_get_dialogue_box()

func _get_dialogue_box() -> CanvasLayer:
	if dialogue_box and is_instance_valid(dialogue_box):
		return dialogue_box
	if is_inside_tree():
		dialogue_box = get_tree().get_first_node_in_group("dialogue_box") as CanvasLayer
		if not dialogue_box:
			dialogue_box = UIManager.get_dialogue_box()
	if dialogue_box and not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)
	return dialogue_box

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	
	var is_interact := event.is_action_pressed("interact")
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E:
			is_interact = true

	if is_interact:
		var dlg := _get_dialogue_box()
		if dlg and not dlg.is_active:
			if prompt_label:
				prompt_label.visible = false
			var quest_done: bool = not quest_flag.is_empty() and GameManager.has_flag(quest_flag)
			if face_player_on_interact and player_ref and not (quest_done and npc_id == "colin"):
				face_target(player_ref.global_position)
			is_talking = true
			var active_speaker: String = speaker_name
			var active_lines: Array = dialogue_lines
			var handled_quest := false

			if not quest_flag.is_empty() and not quest_done:
				var reqs_ok := true
				for req_id in quest_required_evidence:
					if not GameManager.has_evidence(req_id):
						reqs_ok = false
						break
				if not reqs_ok:
					handled_quest = true
					if not quest_missing_req_lines.is_empty():
						active_lines = quest_missing_req_lines
					else:
						active_lines = ["Periksa petunjuk di sekitarmu terlebih dahulu sebelum melapor kembali padaku."]
				else:
					var q_id: String = quest_dialogue_id if not quest_dialogue_id.is_empty() else quest_evidence_id
					var q_entry := GameManager.get_interactable_dialogue(q_id) if not q_id.is_empty() else {}
					if not q_entry.is_empty():
						handled_quest = true
						active_speaker = str(q_entry.get("speaker", active_speaker))
						var q_note: String = str(q_entry.get("note", ""))
						if not q_note.is_empty():
							GameManager.unlock_note(q_note)
						var q_lines: Variant = q_entry.get("lines", [])
						if q_lines is Array and not q_lines.is_empty():
							active_lines = q_lines
					if not quest_evidence_id.is_empty():
						GameManager.add_evidence(quest_evidence_id)
					if quest_memory_bonus != 0:
						GameManager.add_memory(quest_memory_bonus)
					if not _lines_have_choices(active_lines):
						GameManager.set_flag(quest_flag, true)

			if not handled_quest and not npc_id.is_empty():
				var entry := GameManager.get_npc_dialogue(npc_id)
				if not entry.is_empty():
					active_speaker = str(entry.get("speaker", active_speaker))
					var json_lines: Variant = entry.get("lines", [])
					if json_lines is Array and not json_lines.is_empty():
						active_lines = json_lines
			GameManager.unlock_profile_by_name(active_speaker)
			dlg.start_dialogue(active_speaker, active_lines)
			get_viewport().set_input_as_handled()

func _lines_have_choices(check_lines: Array) -> bool:
	for item in check_lines:
		if item is Dictionary and item.has("choices"):
			return true
	return false
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_ref = body
		player_in_range = true
		var dlg := _get_dialogue_box()
		if prompt_label and (dlg == null or not dlg.is_active):
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		player_ref = null
		if prompt_label:
			prompt_label.visible = false

func _on_dialogue_ended() -> void:
	if is_talking:
		is_talking = false
		_face_front()
	if player_in_range and prompt_label:
		prompt_label.visible = true

func _face_front() -> void:
	_play_direction(&"idle_down", &"walk_down")

func face_target(target_pos: Vector2) -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	var diff: Vector2 = target_pos - global_position
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			_play_direction(&"idle_right", &"walk_right")
		else:
			_play_direction(&"idle_left", &"walk_left")
	else:
		if diff.y > 0:
			_play_direction(&"idle_down", &"walk_down")
		else:
			_play_direction(&"idle_up", &"walk_up")

func _play_direction(primary_anim: StringName, fallback_anim: StringName) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	if animated_sprite.sprite_frames.has_animation(primary_anim):
		animated_sprite.play(primary_anim)
	elif animated_sprite.sprite_frames.has_animation(fallback_anim):
		animated_sprite.play(fallback_anim)
	elif animated_sprite.sprite_frames.has_animation(&"idle"):
		animated_sprite.play(&"idle")

func _style_keycap(lbl: Label) -> void:
	lbl.text = "E"
	lbl.size = Vector2(16, 16)
	lbl.position = Vector2(-8, -42)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#00f0ff"))
	lbl.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.07, 0.95))
	lbl.add_theme_constant_override("outline_size", 2)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.22, 0.92)
	style.set_border_width_all(1)
	style.border_color = Color("#00f0ff")
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.0, 0.94, 1.0, 0.35)
	style.shadow_size = 2
	lbl.add_theme_stylebox_override("normal", style)

