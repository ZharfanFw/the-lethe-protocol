extends Control

signal resumed

const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const C_CYAN := Color("#00f0ff")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")
const C_PANEL := Color(0.04, 0.12, 0.18, 0.96)

var _resume_btn: Button
var _settings_btn: Button
var _save_btn: Button
var _main_menu_btn: Button
var _quit_btn: Button
var _settings_menu: Control
var _feedback_label: Label
var _panel_container: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false

func open_pause_menu() -> void:
	visible = true
	get_tree().paused = true
	if _feedback_label:
		_feedback_label.text = ""
	_set_buttons_disabled(false)
	_resume_btn.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12)

func resume_game() -> void:
	if _settings_menu and _settings_menu.visible:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.10)
	await tween.finished
	visible = false
	get_tree().paused = false
	resumed.emit()

func _open_settings() -> void:
	_set_buttons_disabled(true)
	if _panel_container:
		_panel_container.visible = false
	_settings_menu.open_menu()

func _on_settings_closed() -> void:
	if _panel_container:
		_panel_container.visible = true
	_set_buttons_disabled(false)
	_settings_btn.grab_focus()

func _quick_save() -> void:
	var slot := GameManager.current_slot
	if slot <= 0:
		slot = 1
	var success := SaveManager.save_game(slot)
	if success:
		_feedback_label.text = "[ DATA TERSIMPAN KE SLOT %d ]" % slot
		_feedback_label.add_theme_color_override("font_color", Color("#00ff88"))
	else:
		_feedback_label.text = "[ GAGAL MENYIMPAN DATA ]"
		_feedback_label.add_theme_color_override("font_color", Color("#ff4444"))

func _go_to_main_menu() -> void:
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _quit_game() -> void:
	get_tree().quit()

func _set_buttons_disabled(disabled: bool) -> void:
	_resume_btn.disabled = disabled
	_settings_btn.disabled = disabled
	_save_btn.disabled = disabled
	_main_menu_btn.disabled = disabled
	_quit_btn.disabled = disabled

func _build_ui() -> void:
	# Semi-transparent backdrop dimmer
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.03, 0.06, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# Centered Dialog Box
	_panel_container = PanelContainer.new()
	_panel_container.position = Vector2(170, 24)
	_panel_container.size = Vector2(300, 312)
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.border_color = Color(C_CYAN, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel_container.add_theme_stylebox_override("panel", style)
	add_child(_panel_container)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	_panel_container.add_child(vbox)

	# Header Title
	var title := Label.new()
	title.text = "PROTOKOL DIHENTIKAN"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", C_CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SYSTEM PAUSED // CONCORD 2084"
	subtitle.add_theme_font_size_override("font_size", 7)
	subtitle.add_theme_color_override("font_color", C_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(C_CYAN, 0.3)
	vbox.add_child(sep)

	# Feedback Label (for Quick Save confirmation)
	_feedback_label = Label.new()
	_feedback_label.custom_minimum_size = Vector2(0, 14)
	_feedback_label.add_theme_font_size_override("font_size", 7)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_feedback_label)

	# Buttons Container
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 7)
	vbox.add_child(btn_vbox)

	_resume_btn = _create_menu_button("LANJUTKAN [ESC]", true, false)
	_resume_btn.pressed.connect(resume_game)
	btn_vbox.add_child(_resume_btn)

	_settings_btn = _create_menu_button("PENGATURAN", false, false)
	_settings_btn.pressed.connect(_open_settings)
	btn_vbox.add_child(_settings_btn)

	_save_btn = _create_menu_button("SIMPAN CEPAT", false, false)
	_save_btn.pressed.connect(_quick_save)
	btn_vbox.add_child(_save_btn)

	_main_menu_btn = _create_menu_button("MENU UTAMA", false, false)
	_main_menu_btn.pressed.connect(_go_to_main_menu)
	btn_vbox.add_child(_main_menu_btn)

	_quit_btn = _create_menu_button("KELUAR KE DESKTOP", false, true)
	_quit_btn.pressed.connect(_quit_game)
	btn_vbox.add_child(_quit_btn)

	# Add Settings Menu modal overlay instance
	var settings_scene := preload("res://scenes/menu/settings_menu.tscn")
	_settings_menu = settings_scene.instantiate()
	_settings_menu.visible = false
	_settings_menu.closed.connect(_on_settings_closed)
	add_child(_settings_menu)

func _create_menu_button(text: String, primary: bool = false, danger: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 30)
	btn.add_theme_font_size_override("font_size", 8)
	_style_button(btn, primary, danger)
	return btn

func _style_button(btn: Button, primary: bool = false, danger: bool = false) -> void:
	var bg_col: Color
	var border_col: Color
	var hover_bg: Color
	var hover_border: Color

	if danger:
		bg_col = Color(0.24, 0.06, 0.08, 0.8)
		border_col = Color(0.85, 0.3, 0.3, 0.65)
		hover_bg = Color(0.38, 0.10, 0.12, 0.95)
		hover_border = Color(1.0, 0.45, 0.45, 1.0)
		btn.add_theme_color_override("font_color", Color("#ff9999"))
		btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	elif primary:
		bg_col = Color(0.08, 0.51, 0.64, 0.95)
		border_col = Color(0, 0.94, 1, 0.8)
		hover_bg = Color(0.10, 0.60, 0.73, 1.0)
		hover_border = Color(0, 0.94, 1, 1.0)
		btn.add_theme_color_override("font_color", Color("#ffffff"))
		btn.add_theme_color_override("font_hover_color", Color("#e0ffff"))
	else:
		bg_col = Color(0.05, 0.22, 0.35, 0.7)
		border_col = Color(0.35, 0.78, 0.88, 0.55)
		hover_bg = Color(0.07, 0.32, 0.46, 0.9)
		hover_border = Color(0, 0.94, 1, 0.9)
		btn.add_theme_color_override("font_color", Color("#d5f4fb"))
		btn.add_theme_color_override("font_hover_color", Color("#ffffff"))

	var norm_sb := _make_box_style(bg_col, border_col)
	var hover_sb := _make_box_style(hover_bg, hover_border)
	var press_sb := _make_box_style(bg_col.darkened(0.2), hover_border)
	var focus_sb := StyleBoxFlat.new()
	focus_sb.bg_color = Color(0, 0, 0, 0)
	focus_sb.set_border_width_all(2)
	focus_sb.border_color = Color(0, 0.94, 1, 1)
	focus_sb.set_corner_radius_all(3)

	btn.add_theme_stylebox_override("normal", norm_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", press_sb)
	btn.add_theme_stylebox_override("focus", focus_sb)

func _make_box_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _settings_menu and _settings_menu.visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_P):
		get_viewport().set_input_as_handled()
		resume_game()
