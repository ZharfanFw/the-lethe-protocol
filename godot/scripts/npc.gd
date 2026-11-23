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
		prompt_label.text = "[E] Bicara"
	
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
			if face_player_on_interact and player_ref:
				face_target(player_ref.global_position)
			is_talking = true
			var active_speaker: String = speaker_name
			var active_lines: Array = dialogue_lines
			if not npc_id.is_empty():
				var entry := GameManager.get_npc_dialogue(npc_id)
				if not entry.is_empty():
					active_speaker = str(entry.get("speaker", active_speaker))
					var json_lines: Variant = entry.get("lines", [])
					if json_lines is Array and not json_lines.is_empty():
						active_lines = json_lines
			dlg.start_dialogue(active_speaker, active_lines)
			get_viewport().set_input_as_handled()
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
