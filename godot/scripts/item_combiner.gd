extends CanvasLayer

signal open_requested
signal combiner_opened
signal combiner_closed
signal item_crafted(new_item: Dictionary)
signal hp_changed(current_hp: int, max_hp: int)
signal investigation_failed

@onready var main_panel: NinePatchRect = $MainPanel
@onready var left_panel: NinePatchRect = $MainPanel/LeftPanel
@onready var item_list: VBoxContainer = $MainPanel/LeftPanel/ItemList
@onready var right_panel: NinePatchRect = $MainPanel/RightPanel
@onready var hp_row: HBoxContainer = $MainPanel/RightPanel/HpFrame/HpRow
@onready var icon_a: TextureRect = $MainPanel/RightPanel/SlotA/IconA
@onready var icon_b: TextureRect = $MainPanel/RightPanel/SlotB/IconB
@onready var result_slot: NinePatchRect = $MainPanel/RightPanel/ResultSlot
@onready var icon_result: TextureRect = $MainPanel/RightPanel/ResultSlot/IconResult
@onready var status_text: RichTextLabel = $MainPanel/RightPanel/StatusBox/StatusText
@onready var combine_btn: TextureButton = $MainPanel/RightPanel/CombineBtn
@onready var close_btn: TextureButton = $MainPanel/CloseBtn

const FLAT := "res://assets/Complete_UI_Essential_Pack_Free/Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/"
var pixel_font: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")
var default_icon := preload("res://icon.svg")
var tex_track := preload(FLAT + "UI_Flat_Bar02a.png")
var tex_handle := preload(FLAT + "UI_Flat_Handle01a.png")

const C_CARD := Color(0.0784314, 0.360784, 0.541176, 0.78)
const C_CYAN := Color("#00f0ff")
const C_TEAL := Color("#1693b8")
const C_GREEN := Color("#00ff88")
const C_WARN := Color("#ff3366")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")

@export var max_hp: int = 100
@export var wrong_combine_penalty: int = 10
var current_hp: int = 100

var inventory: Array[Dictionary] = [
	{"id": "lencana", "name": "Lencana Unit V-09", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Lencana resmi Inspektur Elit Unit V-09 The Registry."},
	{"id": "EVID-001", "name": "Lempengan Ukiran Kayu Ayah", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Lempengan kayu ulin kecil dengan ukiran Aksara Nusantara kuno peninggalan Edward Vance."},
	{"id": "EVID-002", "name": "Tembang Leluhur (Kidung)", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Melodi pengantar tidur Nusantara yang disenandungkan Edward sebelum meninggal."}
]

var recipes: Array[Dictionary] = [
	{"a": "EVID-103", "b": "EVID-105", "result": {"id": "EVID-COMB-101", "name": "Rute Selundupan Colin", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Puntung kretek Black Clove dan peta rute dok membuktikan jalur pelarian Colin Ward ke batas air!"}},
	{"a": "EVID-102", "b": "EVID-104", "result": {"id": "EVID-COMB-102", "name": "Dekripsi Identitas Sparrow", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Testimoni saksi dan coretan ventilasi mengonfirmasi Sparrow adalah Colin Ward!"}},
	{"a": "EVID-104", "b": "EVID-201", "result": {"id": "EVID-COMB-201", "name": "Protokol Jayabaya Rancangan Arthur", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Coretan T-CORE dan Log Vance-Cipher Rev3 membuktikan Protokol Jayabaya adalah pintu belakang buatan Arthur sendiri."}},
	{"a": "EVID-203", "b": "EVID-204", "result": {"id": "EVID-COMB-202", "name": "Brankas Rahasia Sektor 0", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Wasiat Colin dan goresan darah SEKTOR 0 // LACI 884-B mengarah pada penyimpanan peninggalan Edward Vance."}},
	{"a": "EVID-301", "b": "EVID-302", "result": {"id": "EVID-COMB-301", "name": "Kunci Enkripsi Ukiran Edward", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Pola aksara Nusantara pada ukiran kayu Edward Vance adalah kunci dekripsi logika Protokol Jayabaya."}},
	{"a": "EVID-302", "b": "EVID-303", "result": {"id": "EVID-COMB-302", "name": "Blueprint Master Override Key", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Ukiran kayu Edward, kaset mikro, dan tabung titanium Shaw harus disatukan di konsol kuantum kantor Graves."}},
	{"a": "EVID-402", "b": "EVID-403", "result": {"id": "EVID-COMB-401", "name": "Motif Tirani The Registry", "qty": 1, "icon": preload("res://icon.svg"), "desc": "Buku besar korupsi dan rekaman eksekusi Edward membuktikan amnesia warga dipakai menutupi perampokan tanah adat."}}
]

var rows: Array[Button] = []
var selector: Panel
var beam_left: ColorRect
var beam_right: ColorRect
var beam_down: ColorRect
var mystery_lbl: Label
var scroll_track: NinePatchRect
var scroll_handle: TextureRect
var idx := 0
var scroll_off := 0
var slot_a_idx := -1
var slot_b_idx := -1
var base_book_pos: Vector2
var base_scale: Vector2 = Vector2.ONE
var anim_tween: Tween
var is_animating := false
var is_game_over := false

func _ready() -> void:
	visible = false
	await get_tree().process_frame
	current_hp = max_hp
	base_book_pos = (get_viewport().get_visible_rect().size - main_panel.size) * 0.5
	main_panel.position = base_book_pos
	main_panel.pivot_offset = main_panel.size * 0.5
	var vp_size := get_viewport().get_visible_rect().size
	var fit := minf(vp_size.x * 0.74 / main_panel.size.x, vp_size.y * 0.77 / main_panel.size.y)
	base_scale = Vector2(fit, fit)
	main_panel.scale = base_scale
	
	_sync_inventory_from_game_manager()
	GameManager.inventory_updated.connect(_sync_inventory_from_game_manager)
	
	_build_rows()
	_build_circuit_and_decor()
	_apply_ui_theme()
	
	combine_btn.pressed.connect(_on_combine_pressed)
	close_btn.pressed.connect(close_combiner)
	
	_update_hp_ui(false)
	_refresh_ui()

func _sync_inventory_from_game_manager() -> void:
	if not GameManager:
		return
	inventory.clear()
	for ev_id in GameManager.collected_evidence:
		inventory.append(GameManager.get_evidence_display_dict(ev_id))
	slot_a_idx = -1
	slot_b_idx = -1
	idx = 0
	scroll_off = 0
	if rows.size() >= 6:
		_refresh_ui()

func open_combiner() -> void:
	_sync_inventory_from_game_manager()
	visible = true; is_animating = true; _set_content_visible(false)
	combiner_opened.emit()
	if anim_tween and anim_tween.is_valid(): anim_tween.kill()
	main_panel.scale = Vector2(base_scale.x * 0.04, base_scale.y * 0.90); main_panel.modulate.a = 0.0
	anim_tween = create_tween()
	anim_tween.tween_property(main_panel, "modulate:a", 1.0, 0.12)
	anim_tween.tween_property(main_panel, "scale", base_scale, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_tween.finished.connect(func():
		if visible: _set_content_visible(true)
		is_animating = false
	)

func close_combiner() -> void:
	is_animating = true; _set_content_visible(false)
	if anim_tween and anim_tween.is_valid(): anim_tween.kill()
	anim_tween = create_tween()
	anim_tween.tween_property(main_panel, "scale", Vector2(base_scale.x * 0.04, base_scale.y * 0.90), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	anim_tween.tween_property(main_panel, "modulate:a", 0.0, 0.12)
	anim_tween.finished.connect(func():
		visible = false
		main_panel.scale = base_scale; main_panel.modulate.a = 1.0
		is_animating = false
		combiner_closed.emit()
	)

func _set_content_visible(v: bool) -> void:
	left_panel.visible = v; right_panel.visible = v; close_btn.visible = v

func _build_circuit_and_decor() -> void:
	beam_left = ColorRect.new(); beam_left.position = Vector2(150, 148); beam_left.size = Vector2(52, 4); beam_left.color = C_DIM
	beam_right = ColorRect.new(); beam_right.position = Vector2(206, 148); beam_right.size = Vector2(52, 4); beam_right.color = C_DIM
	beam_down = ColorRect.new(); beam_down.position = Vector2(202, 148); beam_down.size = Vector2(4, 40); beam_down.color = C_DIM
	for b in [beam_left, beam_right, beam_down]:
		right_panel.add_child(b); right_panel.move_child(b, 0)
	
	for info in [[Vector2(48, 90), Vector2(120, 16), "KOMPONEN 01", 8], [Vector2(240, 90), Vector2(120, 16), "KOMPONEN 02", 8],
				 [Vector2(139, 191), Vector2(130, 16), "HASIL ANALISIS", 8], [Vector2(186, 110), Vector2(36, 36), "+", 18]]:
		var l := Label.new(); l.position = info[0]; l.size = info[1]; l.text = info[2]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", C_CYAN); l.add_theme_font_size_override("font_size", info[3])
		right_panel.add_child(l)
	
	mystery_lbl = Label.new(); mystery_lbl.size = result_slot.size; mystery_lbl.text = "?"
	mystery_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; mystery_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mystery_lbl.add_theme_color_override("font_color", C_CYAN); mystery_lbl.add_theme_font_size_override("font_size", 18)
	result_slot.add_child(mystery_lbl)
	
	scroll_track = NinePatchRect.new(); scroll_track.texture = tex_track
	scroll_track.self_modulate = Color(0.03, 0.14, 0.24, 0.82)
	scroll_track.position = Vector2(386, 82); scroll_track.size = Vector2(14, 310)
	scroll_track.patch_margin_left = 6; scroll_track.patch_margin_top = 6
	scroll_track.patch_margin_right = 6; scroll_track.patch_margin_bottom = 6
	scroll_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_child(scroll_track)
	scroll_handle = TextureRect.new(); scroll_handle.texture = tex_handle
	scroll_handle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scroll_handle.size = Vector2(18, 28); scroll_handle.position = Vector2(-2, 4)
	scroll_handle.modulate = C_CYAN; scroll_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_track.add_child(scroll_handle)
	
	for info2 in [[Vector2(24, 400), "[Enter] Pilih Slot  [Tab] Catatan", C_DIM], [Vector2(24, 418), "[C]/[Esc] Tutup", C_CYAN]]:
		var h := Label.new(); h.position = info2[0]; h.text = info2[1]
		h.add_theme_color_override("font_color", info2[2]); h.add_theme_font_size_override("font_size", 9)
		left_panel.add_child(h)
	
	var spine := ColorRect.new(); spine.color = Color(0, 0.94, 1, 0.4); spine.size = Vector2(4, 444); spine.position = Vector2(426, 16)
	main_panel.add_child(spine)
	for i in range(12):
		var ring := ColorRect.new(); ring.color = C_CYAN; ring.size = Vector2(20, 4); ring.position = Vector2(418, 28 + i * 35)
		main_panel.add_child(ring)

func _row_style(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(2)
	return sb

func _build_rows() -> void:
	for i in range(6):
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(360, 46)
		btn.add_theme_stylebox_override("normal", _row_style(C_CARD))
		btn.add_theme_stylebox_override("hover", _row_style(Color(0.10, 0.42, 0.60, 0.82)))
		btn.add_theme_stylebox_override("pressed", _row_style(Color(0.11, 0.48, 0.66, 0.88)))
		btn.add_theme_stylebox_override("disabled", _row_style(Color(0.03, 0.12, 0.20, 0.65)))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var ic := TextureRect.new(); ic.name = "Icon"; ic.position = Vector2(12, 7); ic.size = Vector2(32, 32)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nl := Label.new(); nl.name = "Name"; nl.position = Vector2(54, 2); nl.size = Vector2(286, 24); nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.add_theme_color_override("font_color", C_TEXT); nl.add_theme_font_size_override("font_size", 11)
		nl.clip_text = true; nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tag := Label.new(); tag.name = "Tag"; tag.position = Vector2(54, 23); tag.size = Vector2(286, 18)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.add_theme_color_override("font_color", C_CYAN); tag.add_theme_font_size_override("font_size", 9)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ic); btn.add_child(nl); btn.add_child(tag)
		btn.pressed.connect(func():
			if not is_game_over and scroll_off + i < inventory.size():
				idx = scroll_off + i
				_toggle_item_slot(idx)
		)
		item_list.add_child(btn); rows.append(btn)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0.94, 1, 0.06)
	sb.border_color = C_CYAN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	selector = Panel.new()
	selector.add_theme_stylebox_override("panel", sb)
	selector.position = Vector2(-3, -3); selector.size = Vector2(366, 52)
	selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows[0].add_child(selector)

func _apply_ui_theme() -> void:
	var th := Theme.new(); th.default_font = pixel_font; th.default_font_size = 10
	th.set_font("font", "Label", pixel_font); th.set_font("normal_font", "RichTextLabel", pixel_font)
	main_panel.theme = th

func _update_hp_ui(animate := true) -> void:
	current_hp = clampi(current_hp, 0, max_hp)
	var bars := hp_row.get_children()
	var active := ceili(float(current_hp) / 10.0)
	var c_on := C_GREEN if active > 5 else (Color("#ffb703") if active > 2 else C_WARN)
	var c_off := Color(0.06, 0.16, 0.24, 0.65)
	for i in range(bars.size()):
		var target := c_on if i < active else c_off
		if animate: create_tween().tween_property(bars[i], "color", target, 0.18)
		else: bars[i].color = target

func _toggle_item_slot(item_idx: int) -> void:
	if is_game_over: return
	if slot_a_idx == item_idx: slot_a_idx = -1
	elif slot_b_idx == item_idx: slot_b_idx = -1
	elif slot_a_idx == -1: slot_a_idx = item_idx
	elif slot_b_idx == -1: slot_b_idx = item_idx
	else: slot_b_idx = item_idx
	_refresh_ui()

func _refresh_ui() -> void:
	if inventory.is_empty():
		for r_i in range(rows.size()):
			rows[r_i].visible = false
		if selector and selector.get_parent():
			selector.visible = false
		if scroll_handle: scroll_handle.visible = false
		if scroll_track: scroll_track.visible = false
		if icon_a: icon_a.texture = null
		if icon_b: icon_b.texture = null
		if icon_result: icon_result.texture = null
		if mystery_lbl: mystery_lbl.visible = true
		if result_slot: result_slot.self_modulate = C_CARD
		if combine_btn: combine_btn.self_modulate = C_CARD
		for b in [beam_left, beam_right, beam_down]:
			if b: b.color = C_DIM
		if status_text: status_text.text = "[color=#88d4e8]Belum ada barang bukti yang dapat dianalisis.[/color]"
		return
	if selector:
		selector.visible = true
	idx = clampi(idx, 0, inventory.size() - 1)
	if idx < scroll_off: scroll_off = idx
	elif idx >= scroll_off + 6: scroll_off = idx - 5
	
	for r_i in range(6):
		var d_i := scroll_off + r_i; var r := rows[r_i]
		r.get_node("Icon").visible = d_i < inventory.size()
		r.get_node("Icon").texture = inventory[d_i].get("icon", default_icon) if d_i < inventory.size() else null
		r.get_node("Name").text = inventory[d_i]["name"] if d_i < inventory.size() else ""
		r.visible = d_i < inventory.size()
		if d_i >= inventory.size(): r.get_node("Tag").text = ""
		elif d_i == slot_a_idx: r.get_node("Tag").text = "[01]"; r.get_node("Tag").add_theme_color_override("font_color", C_GREEN)
		elif d_i == slot_b_idx: r.get_node("Tag").text = "[02]"; r.get_node("Tag").add_theme_color_override("font_color", C_GREEN)
		else:
			var qty_str := str(inventory[d_i].get("qty", 1))
			r.get_node("Tag").text = qty_str if qty_str.begins_with("x") else ("x" + qty_str)
			r.get_node("Tag").add_theme_color_override("font_color", C_CYAN)
	
	if selector.get_parent() != rows[idx - scroll_off]:
		selector.reparent(rows[idx - scroll_off]); selector.position = Vector2(-3, -3)
	
	var count := inventory.size()
	scroll_track.visible = count > 6
	if count > 6:
		var max_off := count - 6
		var travel := scroll_track.size.y - scroll_handle.size.y - 6.0
		scroll_handle.position.y = 4.0 + travel * (float(scroll_off) / max_off)
	
	icon_a.texture = inventory[slot_a_idx].get("icon", default_icon) if slot_a_idx != -1 else null
	icon_b.texture = inventory[slot_b_idx].get("icon", default_icon) if slot_b_idx != -1 else null
	icon_result.texture = null; mystery_lbl.visible = true; result_slot.self_modulate = C_CARD
	
	var ready := (slot_a_idx != -1 and slot_b_idx != -1)
	combine_btn.self_modulate = C_TEAL if ready else C_CARD
	for b in [beam_left, beam_right, beam_down]: b.color = C_CYAN if ready else C_DIM
	status_text.text = "[color=#00f0ff][KOMPONEN SIAP DIANALISIS][/color]\nTekan tombol Proses Sintesis untuk menguji keterkaitan." if ready else "[color=#88d4e8]Pilih 2 barang bukti untuk digabung.[/color]\n[color=#ffb703]Perhatian: Kegagalan sintesis mengurangi bar HP![/color]"

func _trigger_game_over() -> void:
	is_game_over = true
	combine_btn.disabled = true
	combine_btn.self_modulate = Color(0.25, 0.08, 0.12, 0.85)
	for r in rows:
		r.disabled = true
	selector.visible = false
	result_slot.self_modulate = C_WARN
	for b in [beam_left, beam_right, beam_down]: b.color = C_WARN
	status_text.text = "[color=#ff3366][GAME OVER - INTEGRITAS HABIS][/color]\nSistem forensik terkunci. Investigasi gagal."
	investigation_failed.emit()

func _on_combine_pressed() -> void:
	if is_game_over or current_hp <= 0 or slot_a_idx == -1 or slot_b_idx == -1: return
	var id_a: String = inventory[slot_a_idx]["id"]; var id_b: String = inventory[slot_b_idx]["id"]
	var matched: Dictionary = {}
	for r in recipes:
		if (r["a"] == id_a and r["b"] == id_b) or (r["a"] == id_b and r["b"] == id_a):
			matched = r; break
	
	if matched.is_empty():
		current_hp = maxi(0, current_hp - wrong_combine_penalty)
		_update_hp_ui(true); hp_changed.emit(current_hp, max_hp)
		var tw := create_tween()
		for ox in [-10.0, 10.0, -5.0, 5.0, 0.0]: tw.tween_property(main_panel, "position:x", base_book_pos.x + ox, 0.035)
		
		if current_hp <= 0:
			_trigger_game_over()
			return
		
		result_slot.self_modulate = C_WARN
		for b in [beam_left, beam_right, beam_down]: b.color = C_WARN
		status_text.text = "[color=#ff3366][SINTESIS GAGAL!][/color]\nBukti tidak memiliki keterkaitan logis."
		return
	
	var new_item: Dictionary = matched["result"].duplicate()
	var new_id: String = str(new_item.get("id", ""))
	GameManager.replace_evidence([id_a, id_b], new_id)
	GameManager.set_flag("evidence_combined", true)
	GameManager.set_flag("puzzle_ja_completed", true)
	var unlocked_any := false
	for ded_id in GameManager.deductions_db:
		var reqs: Array = GameManager.deductions_db[ded_id].get("requires", [])
		if reqs.size() == 2 and reqs.has(id_a) and reqs.has(id_b):
			var bonus: int = int(GameManager.deductions_db[ded_id].get("memory_bonus", 10))
			GameManager.unlock_deduction(str(ded_id), bonus)
			unlocked_any = true
			break
	if not unlocked_any:
		GameManager.add_memory(15)
	
	_sync_inventory_from_game_manager()
	mystery_lbl.visible = false
	icon_result.texture = new_item.get("icon", default_icon)
	result_slot.self_modulate = C_GREEN
	for b in [beam_left, beam_right, beam_down]: b.color = C_GREEN
	status_text.text = "[color=#00ff88][SINTESIS BERHASIL!][/color]\nBukti baru ditemukan: " + new_item["name"]
	item_crafted.emit(new_item)

func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		if e.is_action_pressed("toggle_combiner"):
			get_viewport().set_input_as_handled()
			open_requested.emit()
		return
	if is_animating: return
	if e.is_action_pressed("toggle_combiner") or e.is_action_pressed("ui_cancel") or (e is InputEventKey and e.is_pressed() and not e.is_echo() and e.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		close_combiner()
		return
	if is_game_over or inventory.is_empty(): return
	if e.is_action_pressed("ui_down"): get_viewport().set_input_as_handled(); idx = (idx + 1) % inventory.size(); _refresh_ui()
	elif e.is_action_pressed("ui_up"): get_viewport().set_input_as_handled(); idx = (idx - 1 + inventory.size()) % inventory.size(); _refresh_ui()
	elif e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
		get_viewport().set_input_as_handled(); idx += 1 if e.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1; _refresh_ui()
	elif e.is_action_pressed("ui_accept"): get_viewport().set_input_as_handled(); _toggle_item_slot(idx)
	elif e.is_action_pressed("ui_select"): get_viewport().set_input_as_handled(); _on_combine_pressed()
