extends Control

const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const C_CYAN := Color("#00f0ff")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")
const C_PANEL := Color(0.04, 0.12, 0.18, 0.94)
const C_ALERT := Color("#ff4444")
const C_WARN := Color("#ffaa00")

var _busy: bool = false
var _slot_container: VBoxContainer
var _confirm_modal: Control
var _confirm_title: Label
var _confirm_message: Label
var _confirm_btn: Button
var _cancel_btn: Button
var _pending_confirm_action: Callable

func _ready() -> void:
	_build_background()
	_slot_container = VBoxContainer.new()
	_slot_container.position = Vector2(44, 56)
	_slot_container.size = Vector2(552, 215)
	_slot_container.add_theme_constant_override("separation", 10)
	add_child(_slot_container)

	_build_confirmation_modal()
	_rebuild_slots()

	UIManager.fade_in(0.3)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0117647, 0.0431373, 0.0705882, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := _make_label("ARSIP SIMPANAN", 14, C_TEXT)
	title.position = Vector2(0, 18)
	title.size = Vector2(640, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var overline := _make_label("FORENSIC DIVISION // CASE 4092 // SLOT DATA MANAGEMENT", 7, C_DIM)
	overline.position = Vector2(0, 8)
	overline.size = Vector2(640, 12)
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(overline)

	var rule := ColorRect.new()
	rule.position = Vector2(240, 42)
	rule.size = Vector2(160, 1)
	rule.color = Color(C_CYAN, 0.35)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)

	var hint := _make_label("[ATAS/BAWAH/KIRI/KANAN] NAVIGASI   [ENTER] PILIH   [ESC] KEMBALI", 7, C_DIM)
	hint.position = Vector2(0, 336)
	hint.size = Vector2(640, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

func _rebuild_slots(focus_slot: int = 1) -> void:
	for child in _slot_container.get_children():
		child.queue_free()

	var target_focus_node: Control = null
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var meta: Dictionary = SaveManager.get_slot_metadata(slot)
		var card := _make_slot_card(meta)
		_slot_container.add_child(card)

		if slot == focus_slot:
			target_focus_node = card.get_meta("focus_target") as Control
		elif target_focus_node == null and slot == 1:
			target_focus_node = card.get_meta("focus_target") as Control

	if target_focus_node and is_inside_tree():
		target_focus_node.grab_focus()

func _make_slot_card(meta: Dictionary) -> PanelContainer:
	var slot: int = int(meta.get("slot", 1))
	var exists: bool = bool(meta.get("exists", false))

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(552, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.border_color = Color(C_CYAN, 0.40)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)

	var header := _make_label("SLOT %d" % slot, 8, C_CYAN)
	info.add_child(header)

	if exists:
		var ch_title := _make_label(str(meta.get("chapter_title", "-")), 7, C_TEXT)
		info.add_child(ch_title)

		var ts: String = str(meta.get("timestamp", "-"))
		if ts.contains("T"):
			ts = ts.substr(0, 16).replace("T", " ")
		var ts_lbl := _make_label(ts, 6, C_DIM)
		info.add_child(ts_lbl)
	else:
		var empty_lbl := _make_label("KOSONG // BELUM ADA REKAMAN KASUS", 6, C_DIM)
		info.add_child(empty_lbl)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(actions)

	if exists:
		var load_btn := Button.new()
		load_btn.custom_minimum_size = Vector2(95, 30)
		load_btn.add_theme_font_size_override("font_size", 7)
		load_btn.text = "LANJUTKAN"
		_style_button(load_btn, true, false)
		load_btn.pressed.connect(_on_load_pressed.bind(slot))
		actions.add_child(load_btn)

		var del_btn := Button.new()
		del_btn.custom_minimum_size = Vector2(60, 30)
		del_btn.add_theme_font_size_override("font_size", 7)
		del_btn.text = "HAPUS"
		_style_button(del_btn, false, true)
		del_btn.pressed.connect(_prompt_delete_slot.bind(slot))
		actions.add_child(del_btn)

		panel.set_meta("focus_target", load_btn)
	else:
		var new_btn := Button.new()
		new_btn.custom_minimum_size = Vector2(115, 30)
		new_btn.add_theme_font_size_override("font_size", 7)
		new_btn.text = "MULAI BARU"
		_style_button(new_btn, true, false)
		new_btn.pressed.connect(_on_new_game_pressed.bind(slot, false))
		actions.add_child(new_btn)
		panel.set_meta("focus_target", new_btn)

	return panel

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style_button(btn: Button, primary: bool = false, danger: bool = false) -> void:
	var bg_col: Color
	var border_col: Color
	var hover_bg: Color
	var hover_border: Color

	if danger:
		bg_col = Color(0.24, 0.06, 0.08, 0.85)
		border_col = Color(0.9, 0.3, 0.3, 0.7)
		hover_bg = Color(0.38, 0.10, 0.12, 1.0)
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
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb

func _on_load_pressed(slot: int) -> void:
	if _busy:
		return
	_busy = true
	_disable_all_buttons()
	SaveManager.load_game(slot)

func _on_new_game_pressed(slot: int, is_overwrite: bool) -> void:
	if _busy:
		return
	if is_overwrite:
		_prompt_overwrite_slot(slot)
		return
	_start_new_game(slot)

func _start_new_game(slot: int) -> void:
	_busy = true
	_disable_all_buttons()
	GameManager.reset_to_new_game(slot)
	SaveManager.save_game(slot)
	await UIManager.play_fade_transition(true, 0.4)
	GameManager.advance_to_chapter(0)

func _prompt_delete_slot(slot: int) -> void:
	_show_modal(
		"[ PERINGATAN HAPUS DATA ]",
		"Hapus file investigasi SLOT %d?\nData yang dihapus TIDAK DAPAT dipulihkan." % slot,
		"KONFIRMASI HAPUS",
		func():
			SaveManager.delete_save(slot)
			_close_modal()
			_rebuild_slots(slot)
	)

func _prompt_overwrite_slot(slot: int) -> void:
	_show_modal(
		"[ PERINGATAN TIMPA DATA ]",
		"Slot %d sudah memiliki rekaman kasus.\nApakah Anda yakin ingin menimpa data ini?" % slot,
		"TIMPA DATA",
		func():
			_close_modal()
			_start_new_game(slot)
	)

func _build_confirmation_modal() -> void:
	_confirm_modal = Control.new()
	_confirm_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_modal.visible = false
	add_child(_confirm_modal)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.03, 0.05, 0.92)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_modal.add_child(backdrop)

	var box := PanelContainer.new()
	box.position = Vector2(110, 85)
	box.size = Vector2(420, 180)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.10, 0.15, 0.98)
	style.border_color = Color(C_ALERT, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	box.add_theme_stylebox_override("panel", style)
	_confirm_modal.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	box.add_child(vbox)

	_confirm_title = Label.new()
	_confirm_title.add_theme_font_size_override("font_size", 9)
	_confirm_title.add_theme_color_override("font_color", C_ALERT)
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_confirm_title)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(C_ALERT, 0.4)
	vbox.add_child(sep)

	_confirm_message = Label.new()
	_confirm_message.add_theme_font_size_override("font_size", 7)
	_confirm_message.add_theme_color_override("font_color", C_TEXT)
	_confirm_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_confirm_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_confirm_message)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	_confirm_btn = Button.new()
	_confirm_btn.custom_minimum_size = Vector2(140, 30)
	_confirm_btn.add_theme_font_size_override("font_size", 7)
	_style_button(_confirm_btn, false, true)
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	btn_row.add_child(_confirm_btn)

	_cancel_btn = Button.new()
	_cancel_btn.text = "BATAL [ESC]"
	_cancel_btn.custom_minimum_size = Vector2(120, 30)
	_cancel_btn.add_theme_font_size_override("font_size", 7)
	_style_button(_cancel_btn, false, false)
	_cancel_btn.pressed.connect(_close_modal)
	btn_row.add_child(_cancel_btn)

func _show_modal(title: String, message: String, confirm_label: String, on_confirm: Callable) -> void:
	_confirm_title.text = title
	_confirm_message.text = message
	_confirm_btn.text = confirm_label
	_pending_confirm_action = on_confirm
	_confirm_modal.visible = true
	_confirm_modal.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_confirm_modal, "modulate:a", 1.0, 0.15)
	_cancel_btn.grab_focus()

func _close_modal() -> void:
	var tween := create_tween()
	tween.tween_property(_confirm_modal, "modulate:a", 0.0, 0.12)
	await tween.finished
	_confirm_modal.visible = false
	_pending_confirm_action = Callable()

func _on_confirm_pressed() -> void:
	if _pending_confirm_action.is_valid():
		_pending_confirm_action.call()

func _disable_all_buttons() -> void:
	for node in find_children("*", "Button", true, false):
		(node as Button).disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if _confirm_modal.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_modal()
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
