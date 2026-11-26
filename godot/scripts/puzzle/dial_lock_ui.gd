class_name DialLockUI
extends CanvasLayer

signal unlocked
signal cancelled

const TARGET_CODE: Array[int] = [1, 2, 0, 9, 4]
const CUTSCENE_TEXTURE := preload("res://assets/cutscenes/chapter3-slide1.png")
const CUTSCENE_CAPTIONS: Array[String] = [
	"Setelah kombinasi 5 digit dimasukkan, laci besi itu terbuka. Di dalamnya terdapat dua artefak berharga: Lempengan Ukiran Kayu Beraksara Nusantara milik ayahmu, Edward Vance dan Kaset Mikro Analog Kuno berisi rekaman suaramu sendiri di masa lalu. Kau memasang earphone pemutar sakumu dan mulai memutar rekamannya.\n[Tekan E / Enter / Klik untuk melanjutkan]",
	"\"Dengarkan, Arthur... Kau yang menanam Protokol Jayabaya. Kunci logikanya ada pada ukiran kayu ayahmu. Tapi modul fisik peluncurnya ada pada Komandan Garrick Shaw. Pergilah padanya, satukan kuncinya!\"\n[Tekan E / Enter / Klik untuk melanjutkan]"
]

var _open: bool = false
var _in_cutscene: bool = false
var _cutscene_step: int = 0
var _digits: Array[int] = [0, 0, 0, 0, 0]
var _selected_idx: int = 0

var _backdrop: ColorRect
var _panel: PanelContainer
var _digit_labels: Array[Label] = []
var _digit_frames: Array[PanelContainer] = []
var _status_label: Label
var _cutscene_root: Control
var _cutscene_caption: Label

func _ready() -> void:
	layer = 60
	add_to_group("modal_overlay")
	_build_ui()
	_set_all_hidden()

func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.02, 0.03, 0.05, 0.72)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 160)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	style.border_color = Color(0.0, 0.85, 0.95, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "BRANKAS // LACI 884-B"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.2, 0.92, 1.0))
	title.add_theme_font_size_override("font_size", 9)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Masukkan 5 digit (Panah / 0-9)"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	subtitle.add_theme_font_size_override("font_size", 6)
	vbox.add_child(subtitle)

	var hbox_digits := HBoxContainer.new()
	hbox_digits.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_digits.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox_digits)

	for i in range(5):
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		hbox_digits.add_child(col)

		var btn_up := Button.new()
		btn_up.text = "+"
		btn_up.custom_minimum_size = Vector2(34, 18)
		btn_up.add_theme_font_size_override("font_size", 8)
		btn_up.pressed.connect(_on_step_digit.bind(i, 1))
		col.add_child(btn_up)

		var frame := PanelContainer.new()
		frame.custom_minimum_size = Vector2(34, 34)
		col.add_child(frame)
		_digit_frames.append(frame)

		var lbl := Label.new()
		lbl.text = "0"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
		frame.add_child(lbl)
		_digit_labels.append(lbl)

		var btn_down := Button.new()
		btn_down.text = "-"
		btn_down.custom_minimum_size = Vector2(34, 18)
		btn_down.add_theme_font_size_override("font_size", 8)
		btn_down.pressed.connect(_on_step_digit.bind(i, -1))
		col.add_child(btn_down)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 6)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(_status_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	vbox.add_child(actions)

	var btn_unlock := Button.new()
	btn_unlock.text = "BUKA"
	btn_unlock.custom_minimum_size = Vector2(88, 22)
	btn_unlock.add_theme_font_size_override("font_size", 7)
	btn_unlock.pressed.connect(_submit_code)
	actions.add_child(btn_unlock)

	var btn_cancel := Button.new()
	btn_cancel.text = "BATAL"
	btn_cancel.custom_minimum_size = Vector2(88, 22)
	btn_cancel.add_theme_font_size_override("font_size", 7)
	btn_cancel.pressed.connect(_cancel)
	actions.add_child(btn_cancel)

	_cutscene_root = Control.new()
	_cutscene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cutscene_root)

	var cs_bg := ColorRect.new()
	cs_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cs_bg.color = Color(0.01, 0.015, 0.025, 1.0)
	_cutscene_root.add_child(cs_bg)

	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.texture = CUTSCENE_TEXTURE
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cutscene_root.add_child(tex_rect)

	var caption_bg := ColorRect.new()
	caption_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption_bg.offset_top = -92
	caption_bg.color = Color(0.02, 0.03, 0.05, 0.88)
	_cutscene_root.add_child(caption_bg)

	_cutscene_caption = Label.new()
	_cutscene_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cutscene_caption.offset_left = 18
	_cutscene_caption.offset_right = -18
	_cutscene_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cutscene_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cutscene_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cutscene_caption.text = CUTSCENE_CAPTIONS[0]
	_cutscene_caption.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))
	_cutscene_caption.add_theme_font_size_override("font_size", 7)
	caption_bg.add_child(_cutscene_caption)

func _set_all_hidden() -> void:
	_backdrop.visible = false
	_cutscene_root.visible = false

func open_dial() -> void:
	_open = true
	_in_cutscene = false
	_selected_idx = 0
	_digits = [0, 0, 0, 0, 0]
	_status_label.text = ""
	_refresh_digits()
	_backdrop.visible = true
	_cutscene_root.visible = false
	_set_player_can_move(false)

func _refresh_digits() -> void:
	for i in range(5):
		_digit_labels[i].text = str(_digits[i])
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0.03, 0.05, 0.08, 1.0)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(3)
		frame_style.border_color = Color(0.0, 0.9, 1.0, 1.0) if i == _selected_idx else Color(0.25, 0.35, 0.45, 0.8)
		_digit_frames[i].add_theme_stylebox_override("panel", frame_style)

func _on_step_digit(idx: int, delta_val: int) -> void:
	_selected_idx = idx
	_digits[idx] = (_digits[idx] + delta_val + 10) % 10
	_status_label.text = ""
	_refresh_digits()

func _submit_code() -> void:
	for i in range(5):
		if _digits[i] != TARGET_CODE[i]:
			_status_label.text = "KOMBINASI SALAH"
			return
	_backdrop.visible = false
	_in_cutscene = true
	_cutscene_step = 0
	if _cutscene_caption:
		_cutscene_caption.text = CUTSCENE_CAPTIONS[0]
	_cutscene_root.visible = true

func _advance_cutscene() -> void:
	_cutscene_step += 1
	if _cutscene_step < CUTSCENE_CAPTIONS.size():
		if _cutscene_caption:
			_cutscene_caption.text = CUTSCENE_CAPTIONS[_cutscene_step]
		return
	_finish_cutscene()

func _finish_cutscene() -> void:
	_set_all_hidden()
	_in_cutscene = false
	_open = false
	_set_player_can_move(true)
	unlocked.emit()

func _cancel() -> void:
	_set_all_hidden()
	_in_cutscene = false
	_open = false
	_set_player_can_move(true)
	cancelled.emit()

func _set_player_can_move(enabled: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		p.set("can_move", enabled)

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if _in_cutscene:
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or event.is_action_pressed("ui_accept") \
		or event.is_action_pressed("interact") \
		or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
			get_viewport().set_input_as_handled()
			_advance_cutscene()
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_cancel()
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_A):
		get_viewport().set_input_as_handled()
		_selected_idx = (_selected_idx + 4) % 5
		_refresh_digits()
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_D):
		get_viewport().set_input_as_handled()
		_selected_idx = (_selected_idx + 1) % 5
		_refresh_digits()
	elif event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_W):
		get_viewport().set_input_as_handled()
		_on_step_digit(_selected_idx, 1)
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_S):
		get_viewport().set_input_as_handled()
		_on_step_digit(_selected_idx, -1)
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()
		_submit_code()
	elif event is InputEventKey and event.pressed and not event.echo:
		var num := -1
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			num = event.keycode - KEY_0
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
			num = event.keycode - KEY_KP_0
		if num >= 0:
			get_viewport().set_input_as_handled()
			_digits[_selected_idx] = num
			_status_label.text = ""
			if _selected_idx < 4:
				_selected_idx += 1
			_refresh_digits()
