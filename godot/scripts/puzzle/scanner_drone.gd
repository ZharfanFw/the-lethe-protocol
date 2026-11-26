class_name ScannerDrone
extends Node2D

signal player_spotted

@export var patrol_start: Vector2 = Vector2.ZERO
@export var patrol_end: Vector2 = Vector2(180, 0)
@export var speed: float = 72.0
@export var cone_size: Vector2 = Vector2(96, 68)
@export_range(0.0, 1.0) var start_progress: float = 0.0
@export var active_drone: bool = true

var _progress: float = 0.0
var _dir: int = 1
var _cooldown: float = 0.0
var _sensor_area: Area2D
var _sensor_shape: CollisionShape2D
var _cone_rect: ColorRect
var _core_rect: ColorRect

func _ready() -> void:
	_progress = clampf(start_progress, 0.0, 1.0)
	if patrol_start == Vector2.ZERO and patrol_end == Vector2(180, 0):
		patrol_start = position
		patrol_end = position + Vector2(160, 0)
	position = patrol_start.lerp(patrol_end, _progress)
	_build_visuals()
	_sync_active_state()

func _build_visuals() -> void:
	var body_bg := ColorRect.new()
	body_bg.size = Vector2(22, 16)
	body_bg.position = Vector2(-11, -8)
	body_bg.color = Color(0.12, 0.15, 0.2, 1.0)
	body_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body_bg)

	_core_rect = ColorRect.new()
	_core_rect.size = Vector2(8, 6)
	_core_rect.position = Vector2(-4, -3)
	_core_rect.color = Color(0.95, 0.22, 0.28, 1.0)
	_core_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_core_rect)

	_sensor_area = Area2D.new()
	_sensor_area.name = "SensorArea"
	_sensor_area.position = Vector2(0, cone_size.y * 0.5 + 8.0)
	_sensor_area.collision_layer = 0
	_sensor_area.collision_mask = 1
	add_child(_sensor_area)

	_sensor_shape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = cone_size
	_sensor_shape.shape = rect_shape
	_sensor_area.add_child(_sensor_shape)

	_cone_rect = ColorRect.new()
	_cone_rect.size = cone_size
	_cone_rect.position = -cone_size * 0.5
	_cone_rect.color = Color(0.95, 0.16, 0.22, 0.22)
	_cone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sensor_area.add_child(_cone_rect)

	_sensor_area.body_entered.connect(_on_sensor_body_entered)

func _physics_process(delta: float) -> void:
	if not active_drone:
		return
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)

	var dist := patrol_start.distance_to(patrol_end)
	if dist <= 1.0:
		return
	var step := (speed * delta) / dist
	_progress += step * float(_dir)
	if _progress >= 1.0:
		_progress = 1.0
		_dir = -1
	elif _progress <= 0.0:
		_progress = 0.0
		_dir = 1
	position = patrol_start.lerp(patrol_end, _progress)

func apply_security_profile(new_speed: float, sensor_scale: float, enabled: bool) -> void:
	speed = new_speed
	active_drone = enabled
	if _sensor_area and is_instance_valid(_sensor_area):
		_sensor_area.scale = Vector2(sensor_scale, sensor_scale)
		_sensor_area.position = Vector2(0, (cone_size.y * sensor_scale) * 0.5 + 8.0)
	_sync_active_state()

func _sync_active_state() -> void:
	visible = active_drone
	if _sensor_area and is_instance_valid(_sensor_area):
		_sensor_area.set_deferred("monitoring", active_drone)

func _on_sensor_body_entered(body: Node2D) -> void:
	if not active_drone or _cooldown > 0.0:
		return
	if not body.is_in_group("player"):
		return
	if UIManager.has_method("_is_any_overlay_open") and UIManager._is_any_overlay_open():
		return
	_cooldown = 1.2
	player_spotted.emit()
