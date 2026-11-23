extends Control

const SAVE_SELECT_SCENE := "res://scenes/menu/save_select.tscn"

@onready var start_btn: Button = $Buttons/Start
@onready var load_btn: Button = $Buttons/Load
@onready var settings_btn: Button = $Buttons/Settings
@onready var quit_btn: Button = $Buttons/Quit
@onready var settings_menu: Control = $SettingsMenu

func _ready() -> void:
	_build_decor()
	start_btn.pressed.connect(_open_save_select)
	load_btn.pressed.connect(_open_save_select)
	settings_btn.pressed.connect(_open_settings)
	quit_btn.pressed.connect(_on_quit)
	settings_menu.closed.connect(_on_settings_closed)

	start_btn.grab_focus()
	UIManager.fade_in(0.4)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)

func _build_decor() -> void:
	var decor: Control = $Decor
	for x in range(24, 640, 40):
		for y in range(24, 360, 40):
			var dot := ColorRect.new()
			dot.color = Color(0, 0.94, 1, 0.045)
			dot.position = Vector2(x, y)
			dot.size = Vector2(2, 2)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			decor.add_child(dot)

	var col := Color(0, 0.94, 1, 0.30)
	for r in [[Vector2(16, 16), Vector2(26, 2)], [Vector2(16, 16), Vector2(2, 26)],
			[Vector2(598, 16), Vector2(26, 2)], [Vector2(622, 16), Vector2(2, 26)],
			[Vector2(16, 342), Vector2(26, 2)], [Vector2(16, 318), Vector2(2, 26)],
			[Vector2(598, 342), Vector2(26, 2)], [Vector2(622, 318), Vector2(2, 26)]]:
		var line := ColorRect.new()
		line.color = col
		line.position = r[0]
		line.size = r[1]
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor.add_child(line)

	for y in [8, 352]:
		var edge := ColorRect.new()
		edge.color = Color(0, 0.94, 1, 0.08)
		edge.position = Vector2(0, y)
		edge.size = Vector2(640, 1)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor.add_child(edge)

func _open_save_select() -> void:
	_set_buttons_disabled(true)
	get_tree().change_scene_to_file(SAVE_SELECT_SCENE)

func _open_settings() -> void:
	_set_buttons_disabled(true)
	settings_menu.open_menu()

func _on_settings_closed() -> void:
	_set_buttons_disabled(false)
	settings_btn.grab_focus()

func _set_buttons_disabled(disabled: bool) -> void:
	start_btn.disabled = disabled
	load_btn.disabled = disabled
	settings_btn.disabled = disabled
	quit_btn.disabled = disabled

func _on_quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if settings_menu.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().quit()
