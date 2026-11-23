extends Control

signal closed

const C_CYAN := Color("#00f0ff")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")
const C_PANEL := Color(0.04, 0.12, 0.18, 0.96)

var _master_slider: HSlider
var _bgm_slider: HSlider
var _sfx_slider: HSlider
var _master_val_label: Label
var _bgm_val_label: Label
var _sfx_val_label: Label
var _fullscreen_btn: Button
var _save_btn: Button
var _cancel_btn: Button

# Backup values for cancel/revert
var _orig_master: float = 1.0
var _orig_bgm: float = 0.8
var _orig_sfx: float = 0.9
var _orig_fullscreen: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false

func open_menu() -> void:
	_orig_master = SettingsManager.master_volume
	_orig_bgm = SettingsManager.bgm_volume
	_orig_sfx = SettingsManager.sfx_volume
	_orig_fullscreen = SettingsManager.is_fullscreen

	_master_slider.value = _orig_master * 100.0
	_bgm_slider.value = _orig_bgm * 100.0
	_sfx_slider.value = _orig_sfx * 100.0
	_update_val_labels()
	_update_fullscreen_button_text()

	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	_master_slider.grab_focus()

func close_menu(save: bool = false) -> void:
	if save:
		SettingsManager.save_settings()
	else:
		SettingsManager.set_master_volume(_orig_master)
		SettingsManager.set_bgm_volume(_orig_bgm)
		SettingsManager.set_sfx_volume(_orig_sfx)
		SettingsManager.set_fullscreen_mode(_orig_fullscreen)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	await tween.finished
	visible = false
	closed.emit()

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.03, 0.05, 0.90)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.position = Vector2(70, 24)
	panel.size = Vector2(500, 312)
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.border_color = Color(C_CYAN, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.layout_mode = 1
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	# Header
	var title := Label.new()
	title.text = "TERMINAL PENGATURAN"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", C_CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SYSTEM PARAMETERS // AUDIO & DISPLAY CONFIG"
	subtitle.add_theme_font_size_override("font_size", 7)
	subtitle.add_theme_color_override("font_color", C_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(C_CYAN, 0.3)
	vbox.add_child(sep)

	# Sliders content
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	vbox.add_child(content)

	# Master Volume
	var master_row := _create_slider_row("MASTER AUDIO", func(v: float):
		SettingsManager.set_master_volume(v / 100.0)
		_update_val_labels()
	)
	_master_slider = master_row.slider
	_master_val_label = master_row.val_label
	content.add_child(master_row.container)

	# BGM Volume
	var bgm_row := _create_slider_row("MUSIK (BGM)", func(v: float):
		SettingsManager.set_bgm_volume(v / 100.0)
		_update_val_labels()
	)
	_bgm_slider = bgm_row.slider
	_bgm_val_label = bgm_row.val_label
	content.add_child(bgm_row.container)

	# SFX Volume
	var sfx_row := _create_slider_row("EFEK SUARA (SFX)", func(v: float):
		SettingsManager.set_sfx_volume(v / 100.0)
		_update_val_labels()
	)
	_sfx_slider = sfx_row.slider
	_sfx_val_label = sfx_row.val_label
	content.add_child(sfx_row.container)

	# Display Row
	var disp_row := HBoxContainer.new()
	disp_row.add_theme_constant_override("separation", 12)
	content.add_child(disp_row)

	var disp_label := Label.new()
	disp_label.custom_minimum_size = Vector2(150, 26)
	disp_label.text = "MODE TAMPILAN"
	disp_label.add_theme_font_size_override("font_size", 8)
	disp_label.add_theme_color_override("font_color", C_TEXT)
	disp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	disp_row.add_child(disp_label)

	_fullscreen_btn = Button.new()
	_fullscreen_btn.custom_minimum_size = Vector2(280, 26)
	_fullscreen_btn.add_theme_font_size_override("font_size", 8)
	_style_button(_fullscreen_btn, false, false)
	_fullscreen_btn.pressed.connect(_on_fullscreen_toggled)
	disp_row.add_child(_fullscreen_btn)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Action Buttons Row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	_save_btn = Button.new()
	_save_btn.text = "SIMPAN"
	_save_btn.custom_minimum_size = Vector2(140, 32)
	_save_btn.add_theme_font_size_override("font_size", 8)
	_style_button(_save_btn, true, false)
	_save_btn.pressed.connect(func(): close_menu(true))
	btn_row.add_child(_save_btn)

	_cancel_btn = Button.new()
	_cancel_btn.text = "KEMBALI [ESC]"
	_cancel_btn.custom_minimum_size = Vector2(140, 32)
	_cancel_btn.add_theme_font_size_override("font_size", 8)
	_style_button(_cancel_btn, false, false)
	_cancel_btn.pressed.connect(func(): close_menu(false))
	btn_row.add_child(_cancel_btn)

func _create_slider_row(label_text: String, on_value_changed: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.custom_minimum_size = Vector2(150, 20)
	label.text = label_text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", C_TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.custom_minimum_size = Vector2(230, 20)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_value_changed)
	row.add_child(slider)

	var val_label := Label.new()
	val_label.custom_minimum_size = Vector2(50, 20)
	val_label.text = "100%"
	val_label.add_theme_font_size_override("font_size", 8)
	val_label.add_theme_color_override("font_color", C_DIM)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(val_label)

	return {"container": row, "slider": slider, "val_label": val_label}

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

func _update_val_labels() -> void:
	if _master_val_label and _master_slider:
		_master_val_label.text = "%3d%%" % int(_master_slider.value)
	if _bgm_val_label and _bgm_slider:
		_bgm_val_label.text = "%3d%%" % int(_bgm_slider.value)
	if _sfx_val_label and _sfx_slider:
		_sfx_val_label.text = "%3d%%" % int(_sfx_slider.value)

func _update_fullscreen_button_text() -> void:
	if _fullscreen_btn:
		_fullscreen_btn.text = "[ FULLSCREEN ]" if SettingsManager.is_fullscreen else "[ WINDOWED (1280x720) ]"

func _on_fullscreen_toggled() -> void:
	var new_mode := not SettingsManager.is_fullscreen
	SettingsManager.set_fullscreen_mode(new_mode)
	_update_fullscreen_button_text()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_menu(false)
