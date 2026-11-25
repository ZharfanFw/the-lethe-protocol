extends Node

const PLAYER_SCENE := preload("res://scenes/common/player.tscn")

const MAPS := {
	"outdoor": {
		"scene": preload("res://scenes/maps/outdoor_city.tscn"),
		"size": Vector2(1280, 960),
		"zoom": Vector2(0.85, 0.85),
		"follow": true,
	},
	"indoor": {
		"scene": preload("res://scenes/maps/indoor_office.tscn"),
		"size": Vector2(640, 340),
		"zoom": Vector2(0.85, 0.85),
		"follow": false,
	},
	"ch1_apartment": {
		"scene": preload("res://scenes/maps/apartment_vance.tscn"),
		"size": Vector2(640, 340),
		"zoom": Vector2(0.85, 0.85),
		"follow": false,
	},
	"ch1_subsector4": {
		"scene": preload("res://scenes/maps/sub_sector_4.tscn"),
		"size": Vector2(1408, 960),
		"zoom": Vector2(0.85, 0.85),
		"follow": true,
	},
	"ch2_dock": {
		"scene": preload("res://scenes/maps/outdoor_city.tscn"),
		"size": Vector2(1280, 960),
		"zoom": Vector2(0.85, 0.85),
		"follow": true,
	},
	"ch3_sector0": {
		"scene": preload("res://scenes/maps/indoor_office.tscn"),
		"size": Vector2(640, 340),
		"zoom": Vector2(0.85, 0.85),
		"follow": false,
	},
	"ch3_undercity": {
		"scene": preload("res://scenes/maps/outdoor_city.tscn"),
		"size": Vector2(1280, 960),
		"zoom": Vector2(0.85, 0.85),
		"follow": true,
	},
	"ch4_office_top": {
		"scene": preload("res://scenes/maps/indoor_office.tscn"),
		"size": Vector2(640, 340),
		"zoom": Vector2(0.85, 0.85),
		"follow": false,
	},
}

@export var start_map: String = "outdoor"
@export var start_spawn: Vector2 = Vector2(952, 220)

@onready var map_root: Node2D = $MapRoot
@onready var fade: ColorRect = $FadeLayer/Fade

var player: CharacterBody2D
var current_map: Node2D
var current_map_id: String = ""
var transitioning: bool = false
var ui_transitioning: bool = false

func _ready() -> void:
	add_to_group("world")
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.add_to_group("player")
	var combiner := get_node_or_null("ItemCombiner")
	if combiner:
		combiner.open_requested.connect(_request_open_combiner)
		combiner.combiner_opened.connect(_on_combiner_opened)
		combiner.combiner_closed.connect(_on_combiner_closed)
	var notebook := get_node_or_null("DetectiveNotebook")
	if notebook:
		notebook.open_requested.connect(_request_open_notebook)
		notebook.notebook_opened.connect(_on_notebook_opened)
		notebook.notebook_closed.connect(_on_notebook_closed)

	var target_map := start_map
	var target_spawn := start_spawn
	if GameManager.has_saved_position:
		target_spawn = GameManager.saved_player_position
		if not GameManager.saved_map_id.is_empty() and MAPS.has(GameManager.saved_map_id):
			target_map = GameManager.saved_map_id
		GameManager.has_saved_position = false

	_load_map(target_map, target_spawn)
	_set_fade(0.0, 0.25)

func _request_open_combiner() -> void:
	if ui_transitioning:
		return
	var combiner = get_node_or_null("ItemCombiner")
	var notebook = get_node_or_null("DetectiveNotebook")
	if not combiner or combiner.visible:
		return
	ui_transitioning = true
	player.can_move = false
	if notebook and notebook.visible:
		notebook.close_notebook()
		await notebook.notebook_closed
	combiner.open_combiner()
	ui_transitioning = false

func _request_open_notebook() -> void:
	if ui_transitioning:
		return
	var combiner = get_node_or_null("ItemCombiner")
	var notebook = get_node_or_null("DetectiveNotebook")
	if not notebook or notebook.visible:
		return
	ui_transitioning = true
	player.can_move = false
	if combiner and combiner.visible:
		combiner.close_combiner()
		await combiner.combiner_closed
	notebook.open_notebook()
	ui_transitioning = false

func is_ui_blocking() -> bool:
	if ui_transitioning:
		return true
	var combiner = get_node_or_null("ItemCombiner")
	if combiner and combiner.visible:
		return true
	var notebook = get_node_or_null("DetectiveNotebook")
	if notebook and notebook.visible:
		return true
	return false

func _on_combiner_opened() -> void:
	player.can_move = false

func _on_combiner_closed() -> void:
	player.can_move = not is_ui_blocking()

func _on_notebook_opened() -> void:
	player.can_move = false

func _on_notebook_closed() -> void:
	player.can_move = not is_ui_blocking()

func _load_map(map_id: String, spawn_position: Vector2) -> void:
	if not MAPS.has(map_id):
		return
	current_map_id = map_id
	GameManager.unlock_map(map_id)
	var data: Dictionary = MAPS[map_id]
	
	if current_map:
		if player.get_parent() == current_map:
			current_map.remove_child(player)
		current_map.queue_free()
		current_map = null
	
	current_map = data["scene"].instantiate()
	map_root.add_child(current_map)
	current_map.add_child(player)
	player.global_position = spawn_position
	player.set_map_bounds(data["size"], data["follow"], data["zoom"])
	
	for child in current_map.get_children():
		if child.has_signal("door_entered"):
			child.door_entered.connect(_on_door_entered)

func _on_door_entered(target_map: String, spawn_position: Vector2) -> void:
	if transitioning or not MAPS.has(target_map):
		return
	transitioning = true
	player.can_move = false
	await _set_fade(1.0, 0.15)
	_load_map(target_map, spawn_position)
	player.can_move = true
	await _set_fade(0.0, 0.15)
	transitioning = false

func _set_fade(alpha: float, duration: float) -> void:
	if not fade:
		return
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, duration)
	await tween.finished
