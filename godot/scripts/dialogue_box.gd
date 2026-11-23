extends CanvasLayer

signal dialogue_started
signal dialogue_ended
signal dialogue_finished
signal choice_selected(choice_index: int, choice_text: String)

@onready var main_container: Control = $MainContainer if has_node("MainContainer") else get_node_or_null("VBoxContainer")
@onready var text_panel: Control = get_node_or_null("MainContainer/TextPanel") if has_node("MainContainer/TextPanel") else get_node_or_null("VBoxContainer/TextPanel")
@onready var name_box: Control = get_node_or_null("MainContainer/TextPanel/NameBox") if has_node("MainContainer/TextPanel/NameBox") else get_node_or_null("VBoxContainer/TextPanel/NameBox")
@onready var speaker_name: Label = get_node_or_null("MainContainer/TextPanel/NameBox/SpeakerName") if has_node("MainContainer/TextPanel/NameBox/SpeakerName") else get_node_or_null("VBoxContainer/TextPanel/NameBox/SpeakerName")
@onready var margin_container: MarginContainer = get_node_or_null("MainContainer/TextPanel/MarginContainer") if has_node("MainContainer/TextPanel/MarginContainer") else get_node_or_null("VBoxContainer/TextPanel/MarginContainer")
@onready var dialogue_text: RichTextLabel = get_node_or_null("MainContainer/TextPanel/MarginContainer/DialogueText") if has_node("MainContainer/TextPanel/MarginContainer/DialogueText") else get_node_or_null("VBoxContainer/TextPanel/MarginContainer/DialogueText")
@onready var next_indicator: TextureRect = get_node_or_null("MainContainer/TextPanel/NextIndicator") if has_node("MainContainer/TextPanel/NextIndicator") else get_node_or_null("VBoxContainer/TextPanel/NextIndicator")
@onready var choice_container: VBoxContainer = $ChoiceContainer

# Compatibility properties for legacy scripts if accessed
var portrait_section: Control = null
var portrait_frame: Control = null
var portrait_image: Control = null

@export var typing_speed: float = 0.025

# Cyberpunk UI Color Palette
const C_BG := Color(0.02, 0.08, 0.14, 0.96)
const C_PANEL_BORDER := Color(0.0, 0.94, 1.0, 0.85)
const C_NAME_BG := Color(0.04, 0.16, 0.28, 0.98)
const C_CYAN := Color("#00f0ff")
const C_TEAL := Color("#1693b8")
const C_CARD := Color(0.08, 0.36, 0.54, 0.78)
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")
const C_GREEN := Color("#00ff88")


var dialogue_queue: Array[Dictionary] = []
var is_active: bool = false
var is_typing: bool = false
var waiting_for_choice: bool = false
var typing_tween: Tween
var arrow_tween: Tween
var base_container_pos: Vector2
var ui_small: bool = false

func _ready() -> void:
	add_to_group("dialogue_box")
	dialogue_started.connect(func():
		var p = get_tree().get_first_node_in_group("player")
		if p and "can_move" in p:
			p.can_move = false
	)
	dialogue_ended.connect(func():
		var p = get_tree().get_first_node_in_group("player")
		if p and "can_move" in p:
			p.can_move = true
	)

	_ensure_node_references()
	_setup_layout_with_original_assets()

	if main_container:
		main_container.visible = false
	if choice_container:
		choice_container.visible = false
	if next_indicator:
		next_indicator.visible = false

	if is_inside_tree() and get_tree():
		await get_tree().process_frame

func _ensure_node_references() -> void:
	if not main_container:
		main_container = get_node_or_null("MainContainer")
		if not main_container:
			main_container = get_node_or_null("VBoxContainer")
	if not text_panel:
		text_panel = get_node_or_null("MainContainer/TextPanel")
		if not text_panel:
			text_panel = get_node_or_null("VBoxContainer/TextPanel")
	if not name_box:
		name_box = get_node_or_null("MainContainer/TextPanel/NameBox")
		if not name_box:
			name_box = get_node_or_null("VBoxContainer/TextPanel/NameBox")
	if not speaker_name:
		speaker_name = get_node_or_null("MainContainer/TextPanel/NameBox/SpeakerName")
		if not speaker_name:
			speaker_name = get_node_or_null("VBoxContainer/TextPanel/NameBox/SpeakerName")
	if not margin_container:
		margin_container = get_node_or_null("MainContainer/TextPanel/MarginContainer")
		if not margin_container:
			margin_container = get_node_or_null("VBoxContainer/TextPanel/MarginContainer")
	if not dialogue_text:
		dialogue_text = get_node_or_null("MainContainer/TextPanel/MarginContainer/DialogueText")
		if not dialogue_text:
			dialogue_text = get_node_or_null("VBoxContainer/TextPanel/MarginContainer/DialogueText")
	if not next_indicator:
		next_indicator = get_node_or_null("MainContainer/TextPanel/NextIndicator")
		if not next_indicator:
			next_indicator = get_node_or_null("VBoxContainer/TextPanel/NextIndicator")
	if not choice_container:
		choice_container = get_node_or_null("ChoiceContainer")

func _sanitize_speaker_name(raw_name: String) -> String:
	var clean := raw_name.strip_edges()
	var paren_idx := clean.find("(")
	if paren_idx > 0:
		clean = clean.substr(0, paren_idx).strip_edges()
	return clean

func _setup_layout_with_original_assets() -> void:
	_ensure_node_references()
	var vp = get_viewport()
	var vp_size: Vector2 = vp.get_visible_rect().size if vp else Vector2(640, 360)
	var is_compact: bool = vp_size.y <= 540.0
	var is_small: bool = vp_size.y < 420.0
	ui_small = is_small

	if main_container:
		main_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		if is_small:
			main_container.offset_left = 24
			main_container.offset_right = -24
			main_container.offset_bottom = -14
			main_container.offset_top = -84
		elif is_compact:
			main_container.offset_left = 32
			main_container.offset_right = -32
			main_container.offset_bottom = -18
			main_container.offset_top = -110
		else:
			main_container.offset_left = 48
			main_container.offset_right = -48
			main_container.offset_bottom = -24
			main_container.offset_top = -140
		base_container_pos = main_container.position

	if text_panel:
		text_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		var sb_panel := StyleBoxFlat.new()
		sb_panel.bg_color = C_BG
		sb_panel.border_color = C_PANEL_BORDER
		sb_panel.set_border_width_all(2)
		sb_panel.set_corner_radius_all(4)
		sb_panel.shadow_color = Color(0, 0.94, 1.0, 0.12)
		sb_panel.shadow_size = 4
		text_panel.add_theme_stylebox_override("panel", sb_panel)

	if name_box:
		var name_h: float = 20.0 if is_small else (24.0 if is_compact else 28.0)
		name_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
		name_box.offset_left = 12.0
		name_box.offset_top = -name_h + 2.0
		name_box.offset_bottom = 2.0
		name_box.offset_right = 132.0
		name_box.custom_minimum_size = Vector2(72.0, name_h)

		var sb_name := StyleBoxFlat.new()
		sb_name.bg_color = C_NAME_BG
		sb_name.border_color = C_CYAN
		sb_name.border_width_left = 2
		sb_name.border_width_top = 2
		sb_name.border_width_right = 2
		sb_name.border_width_bottom = 0
		sb_name.corner_radius_top_left = 4
		sb_name.corner_radius_top_right = 4
		name_box.add_theme_stylebox_override("panel", sb_name)

	if speaker_name:
		speaker_name.set_anchors_preset(Control.PRESET_FULL_RECT)
		speaker_name.offset_left = 10.0
		speaker_name.offset_right = -10.0
		speaker_name.offset_top = 1.0
		speaker_name.offset_bottom = -1.0
		speaker_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		speaker_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		speaker_name.add_theme_color_override("font_color", C_CYAN)
		speaker_name.add_theme_font_size_override("font_size", 8 if is_small else (9 if is_compact else 11))
		speaker_name.clip_text = false

	if margin_container:
		margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin_container.add_theme_constant_override("margin_left", 16 if is_small else 22)
		margin_container.add_theme_constant_override("margin_top", 12 if is_small else 16)
		margin_container.add_theme_constant_override("margin_right", 34 if is_small else 42)
		margin_container.add_theme_constant_override("margin_bottom", 12 if is_small else 16)

	if dialogue_text:
		dialogue_text.bbcode_enabled = true
		dialogue_text.add_theme_color_override("default_color", C_TEXT)
		var font_sz: int = 8 if is_small else (9 if is_compact else 11)
		dialogue_text.add_theme_font_size_override("normal_font_size", font_sz)
		dialogue_text.add_theme_font_size_override("bold_font_size", font_sz)
		dialogue_text.add_theme_constant_override("line_separation", 4 if is_small else 5)
	if next_indicator:
		next_indicator.modulate = C_CYAN
		next_indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		next_indicator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		next_indicator.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		next_indicator.custom_minimum_size = Vector2(14, 14)
		next_indicator.size = Vector2(14, 14)
		next_indicator.offset_left = -26
		next_indicator.offset_top = -24
		next_indicator.offset_right = -12
		next_indicator.offset_bottom = -10
		_animate_next_arrow()

	if choice_container:
		choice_container.set_anchors_preset(Control.PRESET_CENTER)
		choice_container.offset_top = -60 if is_small else (-90 if is_compact else -120)
		choice_container.add_theme_constant_override("separation", 6 if is_small else 8)

func _unhandled_input(event: InputEvent) -> void:
	if not main_container or not main_container.visible or waiting_for_choice:
		return

	var is_advance: bool = false
	if event.is_action_pressed("ui_accept"):
		is_advance = true
	elif event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_E or event.keycode == KEY_ENTER):
		is_advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_advance = true

	if is_advance:
		get_viewport().set_input_as_handled()
		if is_typing:
			_finish_typing_immediately()
		else:
			_show_next_line()

func start_dialogue(arg1: Variant, arg2: Variant = null) -> void:
	_ensure_node_references()
	dialogue_queue.clear()

	if arg1 is String:
		var spk: String = arg1
		var arr: Array = arg2 if arg2 is Array else []
		for item in arr:
			var txt: String = str(item)
			dialogue_queue.append({
				"name": spk,
				"text": txt
			})
	elif arg1 is Array:
		for item in arg1:
			if item is Dictionary:
				dialogue_queue.append(item)
			elif item is String:
				dialogue_queue.append({
					"name": "DATA",
					"text": item
				})

	if dialogue_queue.is_empty():
		return

	is_active = true
	dialogue_started.emit()

	if main_container and not main_container.visible:
		main_container.visible = true
		main_container.modulate.a = 0.0
		var open_tween := create_tween()
		open_tween.tween_property(main_container, "modulate:a", 1.0, 0.2)

	_show_next_line()

func _show_next_line() -> void:
	_clear_choices()
	if next_indicator:
		next_indicator.visible = false

	if dialogue_queue.is_empty():
		if main_container:
			var close_tween := create_tween()
			close_tween.tween_property(main_container, "modulate:a", 0.0, 0.18)
			close_tween.finished.connect(func():
				main_container.visible = false
				is_active = false
				dialogue_ended.emit()
				dialogue_finished.emit()
			)
		else:
			is_active = false
			dialogue_ended.emit()
			dialogue_finished.emit()
		return

	var current_line: Dictionary = dialogue_queue.pop_front()

	var s_name: String = _sanitize_speaker_name(str(current_line.get("name", "UNKNOWN")))
	if speaker_name:
		speaker_name.text = s_name
		var font := speaker_name.get_theme_font("font")
		var f_size := speaker_name.get_theme_font_size("font_size")
		var text_w: float = float(s_name.length() * f_size)
		if font:
			text_w = font.get_string_size(s_name, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size).x
		var pad_x: float = 24.0 if ui_small else 32.0
		var min_w: float = 72.0 if ui_small else 96.0
		var max_w: float = 320.0 if ui_small else 420.0
		var name_w: float = clampf(text_w + pad_x, min_w, max_w)
		if name_box:
			name_box.custom_minimum_size.x = name_w
			name_box.size.x = name_w
			name_box.offset_right = name_box.offset_left + name_w

	if current_line.get("effect", "") == "shake":
		_play_shake_effect()

	if dialogue_text:
		dialogue_text.text = current_line.get("text", "")
		dialogue_text.visible_ratio = 0.0
		is_typing = true

		var total_chars: int = dialogue_text.get_total_character_count()
		var duration: float = max(0.1, total_chars * typing_speed)

		if typing_tween:
			typing_tween.kill()
		typing_tween = create_tween()
		typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
		typing_tween.finished.connect(func():
			_on_typing_finished(current_line)
		)

func _play_shake_effect() -> void:
	if not main_container:
		return
	var shake_tween := create_tween()
	var shake_offset := 10.0
	shake_tween.tween_property(main_container, "position:x", base_container_pos.x + shake_offset, 0.04)
	shake_tween.tween_property(main_container, "position:x", base_container_pos.x - shake_offset, 0.04)
	shake_tween.tween_property(main_container, "position:x", base_container_pos.x + (shake_offset * 0.5), 0.04)
	shake_tween.tween_property(main_container, "position:x", base_container_pos.x, 0.04)

func _finish_typing_immediately() -> void:
	if typing_tween:
		typing_tween.kill()
	if dialogue_text:
		dialogue_text.visible_ratio = 1.0
	is_typing = false
	if next_indicator:
		next_indicator.visible = true

func _on_typing_finished(current_line: Dictionary) -> void:
	is_typing = false
	if current_line.has("choices") and not current_line["choices"].is_empty():
		_show_choices(current_line["choices"])
	else:
		if next_indicator:
			next_indicator.visible = true

func _show_choices(choices: Array) -> void:
	waiting_for_choice = true
	if next_indicator:
		next_indicator.visible = false
	if not choice_container:
		return
	choice_container.visible = true

	var buttons: Array[Button] = []
	for i in range(choices.size()):
		var choice_data = choices[i]
		var c_text: String = ""
		if choice_data is Dictionary:
			c_text = choice_data.get("text", "")
		else:
			c_text = str(choice_data)

		var btn := Button.new()
		btn.text = c_text
		btn.focus_mode = Control.FOCUS_ALL
		btn.custom_minimum_size = Vector2(260, 26) if ui_small else Vector2(300, 30)

		var sb_normal := StyleBoxFlat.new()
		sb_normal.bg_color = Color(0.04, 0.16, 0.28, 0.92)
		sb_normal.border_color = C_TEAL
		sb_normal.set_border_width_all(1)
		sb_normal.set_corner_radius_all(3)

		var sb_hover := StyleBoxFlat.new()
		sb_hover.bg_color = Color(0.08, 0.32, 0.50, 0.98)
		sb_hover.border_color = C_CYAN
		sb_hover.set_border_width_all(1)
		sb_hover.set_corner_radius_all(3)
		sb_hover.shadow_color = Color(0, 0.94, 1.0, 0.25)
		sb_hover.shadow_size = 3

		var sb_pressed := StyleBoxFlat.new()
		sb_pressed.bg_color = Color(0.12, 0.44, 0.66, 1.0)
		sb_pressed.border_color = C_GREEN
		sb_pressed.set_border_width_all(1)
		sb_pressed.set_corner_radius_all(3)

		btn.add_theme_stylebox_override("normal", sb_normal)
		btn.add_theme_stylebox_override("hover", sb_hover)
		btn.add_theme_stylebox_override("focus", sb_hover)
		btn.add_theme_stylebox_override("pressed", sb_pressed)

		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
		btn.add_theme_color_override("font_focus_color", Color("#ffffff"))
		btn.add_theme_color_override("font_pressed_color", C_GREEN)
		btn.add_theme_font_size_override("font_size", 8 if ui_small else 9)

		var btn_index: int = i
		var btn_text: String = c_text
		btn.pressed.connect(func():
			_on_choice_clicked(btn_index, btn_text)
		)
		choice_container.add_child(btn)
		buttons.append(btn)

	for i in range(buttons.size()):
		if i > 0:
			buttons[i].focus_neighbor_top = buttons[i - 1].get_path()
		if i < buttons.size() - 1:
			buttons[i].focus_neighbor_bottom = buttons[i + 1].get_path()

	if not buttons.is_empty():
		buttons[0].grab_focus()

func _on_choice_clicked(index: int, text: String) -> void:
	waiting_for_choice = false
	_clear_choices()
	choice_selected.emit(index, text)
	_show_next_line()

func _clear_choices() -> void:
	if not choice_container:
		return
	choice_container.visible = false
	for child in choice_container.get_children():
		child.queue_free()

func _animate_next_arrow() -> void:
	if not next_indicator:
		return
	if arrow_tween:
		arrow_tween.kill()
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(next_indicator, "modulate:a", 0.35, 0.45)
	arrow_tween.tween_property(next_indicator, "modulate:a", 1.0, 0.45)
