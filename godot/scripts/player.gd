extends CharacterBody2D

@export var speed: float = 120.0
@export var camera_zoom: Vector2 = Vector2(0.85, 0.85)
@export var sprite_scale: Vector2 = Vector2(0.12, 0.12)
@export var map_size: Vector2 = Vector2(1280, 960)
@export var follow_player: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var last_direction: Vector2 = Vector2.DOWN
var can_move: bool = true

func _ready() -> void:
	add_to_group("player")
	
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.scale = sprite_scale
		_play_idle_animation()
	
	set_map_bounds(map_size, follow_player, camera_zoom)
	
	# Connect to DialogueBox and DetectiveNotebook if available in the scene
	if get_parent():
		_connect_ui_signals(get_parent())
	if is_inside_tree() and get_tree():
		await get_tree().process_frame
		if get_tree().current_scene:
			_connect_ui_signals(get_tree().current_scene)

func set_map_bounds(size: Vector2, follow: bool = true, zoom: Vector2 = Vector2.ONE) -> void:
	map_size = size
	follow_player = follow
	camera_zoom = zoom
	
	if not camera:
		camera = get_node_or_null("Camera2D")
	if not camera:
		return
	
	camera.zoom = camera_zoom
	if follow_player:
		camera.top_level = false
		camera.position = Vector2.ZERO
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(size.x)
		camera.limit_bottom = int(size.y)
		camera.position_smoothing_enabled = true
		camera.reset_smoothing()
	else:
		camera.position_smoothing_enabled = false
		camera.top_level = true
		camera.global_position = size * 0.5
		camera.limit_left = -100000
		camera.limit_top = -100000
		camera.limit_right = 100000
		camera.limit_bottom = 100000

func _connect_ui_signals(scene_node: Node) -> void:
	if not scene_node:
		return
	var dlg: CanvasLayer = get_tree().get_first_node_in_group("dialogue_box") as CanvasLayer if is_inside_tree() else null
	if not dlg:
		dlg = scene_node.get_node_or_null("DialogueBox")
	if not dlg and is_inside_tree() and get_tree().current_scene:
		var matches := get_tree().current_scene.find_children("DialogueBox", "CanvasLayer", true, false)
		if not matches.is_empty():
			dlg = matches[0] as CanvasLayer
	if dlg:
		if not dlg.dialogue_started.is_connected(_on_dialogue_started):
			dlg.dialogue_started.connect(_on_dialogue_started)
		if not dlg.dialogue_ended.is_connected(_on_dialogue_ended):
			dlg.dialogue_ended.connect(_on_dialogue_ended)
	var nb: Control = null
	if is_inside_tree() and get_tree().current_scene:
		var nb_matches := get_tree().current_scene.find_children("DetectiveNotebook", "Control", true, false)
		if not nb_matches.is_empty():
			nb = nb_matches[0] as Control
	if not nb:
		nb = scene_node.get_node_or_null("DetectiveNotebook")
	if nb:
		if not nb.notebook_opened.is_connected(_on_dialogue_started):
			nb.notebook_opened.connect(_on_dialogue_started)
		if not nb.notebook_closed.is_connected(_on_dialogue_ended):
			nb.notebook_closed.connect(_on_dialogue_ended)

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
		
	var input_vector := Vector2.ZERO
	
	# Support move actions, ui actions, and raw key checks for 100% reliability
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
		_play_walk_animation(input_vector)
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()
	
	move_and_slide()

func _play_walk_animation(dir: Vector2) -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		return
		
	# 4-directional animation switching prioritizing the dominant axis
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			last_direction = Vector2.RIGHT
			_safe_play("walk_right")
		else:
			last_direction = Vector2.LEFT
			_safe_play("walk_left")
	else:
		if dir.y > 0:
			last_direction = Vector2.DOWN
			_safe_play("walk_down")
		else:
			last_direction = Vector2.UP
			_safe_play("walk_up")

func _play_idle_animation() -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		return
		
	if last_direction == Vector2.UP:
		_safe_play("idle_up")
	elif last_direction == Vector2.LEFT:
		_safe_play("idle_left")
	elif last_direction == Vector2.RIGHT:
		_safe_play("idle_right")
	else:
		_safe_play("idle_down")

func _safe_play(anim_name: String) -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
		
	var s_name := StringName(anim_name)
	if animated_sprite.sprite_frames.has_animation(s_name):
		if animated_sprite.animation != s_name or not animated_sprite.is_playing():
			animated_sprite.play(s_name)
	elif animated_sprite.sprite_frames.has_animation(&"idle"):
		if animated_sprite.animation != &"idle" or not animated_sprite.is_playing():
			animated_sprite.play(&"idle")

func _on_dialogue_started() -> void:
	can_move = false
	_play_idle_animation()

func _on_dialogue_ended() -> void:
	if _blocking_ui_visible():
		return
	can_move = true

func _blocking_ui_visible() -> bool:
	var scene := get_tree().current_scene
	if not scene:
		return false
	if scene.has_method("is_ui_blocking") and scene.is_ui_blocking():
		return true
	for ui_name in ["DetectiveNotebook", "ItemCombiner"]:
		var ui = scene.get_node_or_null(ui_name)
		if ui and ui is CanvasLayer and ui.visible:
			return true
	return false
