class_name MapDoor
extends Area2D

signal door_entered(target_map: String, spawn_position: Vector2)

@export var target_map: String = ""
@export var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if target_map.is_empty():
		return
	if not body.is_in_group("player"):
		return
	door_entered.emit(target_map, spawn_position)
