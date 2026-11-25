extends CanvasLayer

signal open_requested
signal notebook_opened
signal notebook_closed
signal item_selected(item_data: Dictionary)
signal item_used(item_data: Dictionary)

@onready var book_cover: NinePatchRect = $BookCover
@onready var left_page: NinePatchRect = $BookCover/LeftPage
@onready var title_label: Label = $BookCover/LeftPage/BannerTitle/TitleLabel
@onready var item_list: VBoxContainer = $BookCover/LeftPage/ItemListContainer
@onready var right_page: NinePatchRect = $BookCover/RightPage
@onready var preview_frame: NinePatchRect = $BookCover/RightPage/ItemPreviewFrame
@onready var preview_icon: TextureRect = $BookCover/RightPage/ItemPreviewFrame/ItemPreviewIcon
@onready var detail_box: NinePatchRect = $BookCover/RightPage/ItemDetailBox
@onready var item_name: Label = $BookCover/RightPage/ItemDetailBox/ItemNameLabel
@onready var item_desc: RichTextLabel = $BookCover/RightPage/ItemDetailBox/ItemDescLabel
@onready var close_btn: TextureButton = $BookCover/CloseButton
@onready var close_label: Label = $BookCover/CloseButton/CloseLabel

var book_base_scale: Vector2 = Vector2.ONE
var book_tween: Tween
var book_animating := false
var book_closing := false

const DESIGN_SIZE := Vector2(880, 500)
const TAB_OVERHANG := 68.0
const UI_MAX_FILL := 0.82
const FLAT := "res://assets/Complete_UI_Essential_Pack_Free/Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/"
var tex := {
	"white": preload(FLAT + "UI_Flat_Frame01a.png"), "track": preload(FLAT + "UI_Flat_Bar02a.png"),
	"handle": preload(FLAT + "UI_Flat_Handle01a.png"), "line": preload(FLAT + "UI_Flat_IconLine01a.png")
}
var default_icon := preload("res://icon.svg")
var custom_map_image: Texture2D = preload("res://assets/WorldMap.png")

const C_CARD := Color(0.08, 0.36, 0.54, 0.78)
const C_CYAN := Color("#00f0ff")
const C_TEAL := Color("#1693b8")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")

var db := {
	0: [ # BUKTI (Fallback awal prolog & identitas Unit V-09)
		{
			"name": "Lencana Unit V-09", "qty": "x1",
			"desc": "Lencana resmi Inspektur Elit Unit V-09\nThe Registry (Whitehall Complex).",
			"note": "[color=#00f0ff][b][LOG ANALISIS][/b][/color]\nOtorisasi investigasi lapangan distrik Concord aktif.",
			"extra": "[color=#00ff88][b][CATATAN TAMBAHAN][/b][/color]\n• Memberikan akses ke area penyelidikan birokrasi.\n• Terhubung dengan pemindai biometrik HUD-Mirror."
		},
		{
			"name": "Lempengan Ukiran Kayu Ayah", "qty": "x1",
			"desc": "Lempengan kayu ulin kecil dengan ukiran\nAksara Nusantara kuno peninggalan Edward Vance.",
			"note": "[color=#00f0ff][b][LOG ANALISIS][/b][/color]\nMasih menyimpan jejak darah kering dari malam penyerbuan 2068.",
			"extra": "[color=#00ff88][b][CATATAN TAMBAHAN][/b][/color]\n• Diselipkan Edward Vance ke tangan Arthur kecil sebelum wafat."
		},
		{
			"name": "Tembang Leluhur (Kidung)", "qty": "x1",
			"desc": "Nada melodi pengantar tidur tentang perahu kayu\ndan tanah air dari ingatan masa kecil Arthur.",
			"note": "[color=#00f0ff][b][LOG ANALISIS][/b][/color]\nMemicu anomali resonansi emosional di pemindai biometrik.",
			"extra": "[color=#00ff88][b][CATATAN TAMBAHAN][/b][/color]\n• Selaras dengan rekaman kaset analog milik buruh pabrik Miller."
		}
	],
	1: [ # CATATAN (Kronologi Kejadian & Rangkuman Penyelidikan)
		{
			"name": "Malam Hujan 2068", "qty": "",
			"desc": "Pasukan bersenjata dipimpin Lucian Graves muda\nmenyerbu rumah panggung kayu ulin di desa adat.",
			"note": "[color=#00f0ff][b][KESIMPULAN SEMENTARA][/b][/color]\nEdward Vance ditembak mati demi buku besar tanah ulayat.",
			"extra": "[color=#ffcc00][b][TINDAK LANJUT][/b][/color]\n• Simpan ukiran aksara kayu peninggalan ayah sebagai kunci ingatan."
		},
		{
			"name": "Anomali HUD-Mirror 2084", "qty": "",
			"desc": "Pemindai biometrik apartemen mencatat lonjakan\ndetak jantung +38 BPM dan air mata pasca mimpi buruk.",
			"note": "[color=#00f0ff][b][KESIMPULAN SEMENTARA][/b][/color]\nEfek penekan memori The Tonic mulai melemah.",
			"extra": "[color=#ffcc00][b][TINDAK LANJUT][/b][/color]\n• Jaga kestabilan emosi agar tidak memicu audit Detective Prescott."
		},
		{
			"name": "Kaset Kargo Miller", "qty": "",
			"desc": "Tahanan 402 tertangkap membawa kaset berpelindung\ntimbal berisi lagu tidur tradisional Nusantara.",
			"note": "[color=#00f0ff][b][KESIMPULAN SEMENTARA][/b][/color]\nKaset berasal dari pria bernama Colin di Sub-Sektor 4.",
			"extra": "[color=#ffcc00][b][TINDAK LANJUT][/b][/color]\n• Sisir gudang suku cadang terbengkalai di Sub-Sektor 4."
		},
		{
			"name": "Jejak Kode T-CORE", "qty": "",
			"desc": "Coretan fosfor 0x4F5552 // T-CORE // SPARROW\nditemukan di kisi ventilasi gudang Sub-Sektor 4.",
			"note": "[color=#00f0ff][b][KESIMPULAN SEMENTARA][/b][/color]\nPelaku memiliki akses arsitektur komputasi tingkat tinggi rezim.",
			"extra": "[color=#ffcc00][b][TINDAK LANJUT][/b][/color]\n• Gabungkan bukti TKP di Item Combiner untuk melacak rute Sparrow."
		}
	],
	2: [ # PROFIL (Tokoh Utama, Saksi, dan Target Investigasi)
		{
			"id": "lucian",
			"name": "Direktur Lucian Graves", "qty": "Direktur",
			"desc": "Pemimpin tertinggi The Registry di Menara Eksekutif\nLt. 80. Mengendalikan distribusi The Tonic.",
			"note": "[color=#00f0ff][b][ALIBI & STATUS][/b][/color]\nMengawasi langsung operasi perburuan buronan Sparrow.",
			"extra": "[color=#ff66aa][b][KETERKAITAN KASUS][/b][/color]\n• Menembak mati Edward Vance pada peristiwa 2068.\n• Mengatur failsafe neurotoksin jarak jauh birokrasi."
		},
		{
			"id": "prescott",
			"name": "Miles Prescott", "qty": "Rekan",
			"desc": "Detektif lapangan Unit V-09 dengan kacamata\nanalitik biometrik pemantau kepatuhan.",
			"note": "[color=#00f0ff][b][ALIBI & STATUS][/b][/color]\nMendampingi Arthur dalam interogasi dan olah TKP.",
			"extra": "[color=#ff66aa][b][KETERKAITAN KASUS][/b][/color]\n• Mencatat setiap anomali emosi dan kecurigaan Arthur.\n• Melaporkan penyimpangan langsung ke Direktur Graves."
		},
		{
			"id": "colin",
			"name": "Colin Ward (Sparrow)", "qty": "Buronan",
			"desc": "Peretas pembobol Deep Vault dengan algoritma\nVance-Cipher Rev3. Sahabat masa kecil Arthur.",
			"note": "[color=#00f0ff][b][ALIBI & STATUS][/b][/color]\nMenyebarkan kaset lagu tidur Nusantara ke buruh.",
			"extra": "[color=#ff66aa][b][KETERKAITAN KASUS][/b][/color]\n• Meninggalkan pesan darah SEKTOR 0 // LACI 884-B.\n• Mengetahui identitas asli Arthur sebagai Arsitek Kognitif."
		},
		{
			"id": "garrick",
			"name": "Garrick Shaw", "qty": "Komandan",
			"desc": "Mantan perwira keamanan biro yang membelot dan\nmemimpin perlawanan di Stasiun Maglev Undercity.",
			"note": "[color=#00f0ff][b][ALIBI & STATUS][/b][/color]\nMemegang modul titanium Dead Drop #2.",
			"extra": "[color=#ff66aa][b][KETERKAITAN KASUS][/b][/color]\n• Rekan seperjuangan mendiang Edward Vance.\n• Mengisap rokok kretek Black Clove khas selatan."
		},
		{
			"id": "miller",
			"name": "Miller (Tahanan 402)", "qty": "Saksi",
			"desc": "Buruh pabrik Sub-Sektor 4 yang tertangkap\nmembawa kaset analog lagu tidur Nusantara.",
			"note": "[color=#00f0ff][b][ALIBI & STATUS][/b][/color]\nDitahan di ruang interogasi Whitehall Complex.",
			"extra": "[color=#ff66aa][b][KETERKAITAN KASUS][/b][/color]\n• Menerima kaset dari Colin di gudang suku cadang lama."
		}
	],
	3: [ # PETA (Titik Lokasi Penting & Investigasi Lapangan)
		{
			"name": "Sub-Sektor 4", "qty": "Distrik",
			"desc": "Kawasan industri kumuh tempat gudang suku cadang\ntersangka Colin ditemukan terbengkalai.",
			"pos": Vector2(109, 159),
			"info": "[color=#00f0ff][b]TITIK INVESTIGASI #1[/b][/color]\nPeriksa puntung kretek, ventilasi UV,\ndan generator berhologram aksara."
		},
		{
			"name": "Dok Whitehall Bawah", "qty": "Kanal",
			"desc": "Dermaga kargo bawah tanah jalur penyelundupan\npeti bertanda JAYABAYA menuju batas air.",
			"pos": Vector2(256, 75),
			"info": "[color=#ffd500][b]TITIK INVESTIGASI #2[/b][/color]\nLokasi penyergapan Sparrow dan\nvan komando taktis Unit V-09."
		},
		{
			"name": "Arsip Sektor 0", "qty": "Bunker",
			"desc": "Bunker arsip fisik pra-amnesia yang dijaga\ndrone sensor pemindai otomatis.",
			"pos": Vector2(74, 212),
			"info": "[color=#ffd500][b]TITIK INVESTIGASI #3[/b][/color]\nSimpanan Laci 884-B berisi Dead Drop #1\n(ukiran kayu Edward & kaset mikro)."
		},
		{
			"name": "Menara Whitehall Lt. 80", "qty": "Puncak",
			"desc": "Kantor obsidian Direktur Lucian Graves dan\nkonsol kuantum pusat Project Tabula Rasa.",
			"pos": Vector2(306, 178),
			"info": "[color=#ffd500][b]TARGET INFILTRASI[/b][/color]\nTempat perakitan The Master Override Key\nuntuk satelit pemancar nasional."
		}
	]
}

var tab: int = 0
var items: Array = []
var idx: int = 0
var scroll_off: int = 0

var tabs: Array[Button] = []
var dots: Array[ColorRect] = []
var rows: Array[Button] = []
var selector: Panel
var scroll_track: NinePatchRect
var handle: TextureRect

var note_box: NinePatchRect
var note_lbl: RichTextLabel
var extra_box: NinePatchRect
var extra_lbl: RichTextLabel
var map_panel: NinePatchRect
var target_pin: ColorRect
var target_lbl: Label
var player_pin: ColorRect
var map_info_lbl: RichTextLabel

func _ready() -> void:
	visible = false
	
	# Rapikan tombol Close
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_SCALE
	close_btn.custom_minimum_size = Vector2(114, 30)
	close_label.text = "Tutup [Esc]"
	close_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_btn.pressed.connect(func(): close_notebook())
	
	# Connect to Player if in parent scene
	if get_parent():
		var p = get_parent().get_node_or_null("Player")
		if p:
			notebook_opened.connect(func(): p.can_move = false)
			notebook_closed.connect(func(): p.can_move = true)
	
	book_cover.pivot_offset = DESIGN_SIZE * 0.5
	_build_decorations()
	_build_right_notes()
	_generate_rows()
	_build_map_panel()
	GameManager.inventory_updated.connect(_on_inventory_updated)
	_switch_tab(0)
	
	_update_layout.call_deferred()
	if get_viewport():
		get_viewport().size_changed.connect(_update_layout)

func _update_layout() -> void:
	if not book_cover:
		book_cover = get_node_or_null("BookCover")
	if not book_cover:
		return
	var vp = get_viewport()
	var vp_size: Vector2 = vp.get_visible_rect().size if vp else Vector2(640, 360)
	var content_w: float = DESIGN_SIZE.x + TAB_OVERHANG
	var avail: Vector2 = vp_size * UI_MAX_FILL
	var scale_factor: float = min(avail.x / content_w, avail.y / DESIGN_SIZE.y)
	scale_factor = clampf(scale_factor, 0.35, 1.0)
	book_base_scale = Vector2(scale_factor, scale_factor)
	if not book_animating:
		book_cover.scale = book_base_scale
	var total_w: float = content_w * scale_factor
	var book_h: float = DESIGN_SIZE.y * scale_factor
	var target_pos := Vector2(
		(vp_size.x - total_w) * 0.5 + TAB_OVERHANG * scale_factor,
		(vp_size.y - book_h) * 0.5
	)
	book_cover.position = target_pos - book_cover.pivot_offset * (1.0 - scale_factor)

func _process(_d: float) -> void:
	if visible and tab == 3 and player_pin:
		player_pin.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)

func open_notebook() -> void:
	if visible and not book_closing:
		return
	book_closing = false
	visible = true
	_update_layout()
	_switch_tab(tab)
	notebook_opened.emit()
	if book_tween and book_tween.is_valid(): book_tween.kill()
	book_animating = true
	book_cover.scale = Vector2(book_base_scale.x * 0.12, book_base_scale.y * 0.94)
	book_cover.modulate.a = 0.0
	book_tween = create_tween()
	book_tween.set_parallel(true)
	book_tween.tween_property(book_cover, "modulate:a", 1.0, 0.12)
	book_tween.tween_property(book_cover, "scale", book_base_scale, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	book_tween.finished.connect(func():
		book_animating = false
		book_cover.scale = book_base_scale
		book_cover.modulate.a = 1.0
	)

func close_notebook() -> void:
	if book_closing:
		return
	book_closing = true
	if book_tween and book_tween.is_valid(): book_tween.kill()
	book_animating = true
	book_tween = create_tween()
	book_tween.set_parallel(true)
	book_tween.tween_property(book_cover, "modulate:a", 0.0, 0.12)
	book_tween.tween_property(book_cover, "scale", Vector2(book_base_scale.x * 0.08, book_base_scale.y * 0.94), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	book_tween.finished.connect(func():
		visible = false
		book_animating = false
		book_closing = false
		book_cover.scale = book_base_scale
		book_cover.modulate.a = 1.0
		notebook_closed.emit()
	)

func toggle_notebook() -> void:
	if visible and not book_closing:
		close_notebook()
	else:
		open_requested.emit()

func _make_patch(t: Texture2D, c: Color, p: Vector2, s: Vector2, m: int) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = t; n.self_modulate = c; n.position = p; n.size = s
	n.patch_margin_left = m; n.patch_margin_top = m; n.patch_margin_right = m; n.patch_margin_bottom = m
	return n

func _build_decorations() -> void:
	var tab_names := ["BUKTI", "CATATAN", "PROFIL", "PETA"]
	for i in range(4):
		var t := Button.new()
		t.focus_mode = Control.FOCUS_NONE
		t.add_theme_stylebox_override("normal", _row_style(Color(1, 1, 1, 0.78)))
		t.add_theme_stylebox_override("hover", _row_style(Color(1, 1, 1, 0.88)))
		t.add_theme_stylebox_override("pressed", _row_style(Color(1, 1, 1, 0.94)))
		t.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		t.size = Vector2(74, 60); t.position = Vector2(-62, 48 + i * 68); t.self_modulate = C_TEAL if i == 0 else C_CARD
		book_cover.add_child(t); book_cover.move_child(t, 0); tabs.append(t)
		var l := Label.new()
		l.text = tab_names[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", C_TEXT); l.add_theme_font_size_override("font_size", 9)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(l)
		l.size = Vector2(74, 60)
		t.pressed.connect(func(): _switch_tab(i))
		
		var d := ColorRect.new()
		d.size = Vector2(8, 8); d.position = Vector2(184 + i * 14, 76); d.color = C_CYAN if i == 0 else C_DIM
		left_page.add_child(d); dots.append(d)
	
	var beam := ColorRect.new()
	beam.color = Color(0, 0.94, 1, 0.35); beam.size = Vector2(4, 468); beam.position = Vector2(438, 16)
	book_cover.add_child(beam)
	for i in range(13):
		var c := ColorRect.new()
		c.color = C_CYAN; c.size = Vector2(20, 4); c.position = Vector2(430, 30 + i * 35)
		book_cover.add_child(c)
	
	scroll_track = _make_patch(tex.track, Color(0.03, 0.14, 0.24, 0.82), Vector2(386, 100), Vector2(14, 304), 6)
	left_page.add_child(scroll_track)
	handle = TextureRect.new()
	handle.texture = tex.handle; handle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	handle.size = Vector2(18, 28); handle.position = Vector2(-2, 4); handle.modulate = C_CYAN
	scroll_track.add_child(handle)
	
	var hint := Label.new()
	hint.text = "[Atas/Bawah] Pilih  [Kiri/Kanan] Tab"; hint.position = Vector2(22, 420)
	hint.add_theme_color_override("font_color", C_DIM); hint.add_theme_font_size_override("font_size", 9)
	left_page.add_child(hint)
	
	var combine_hint := Label.new()
	combine_hint.text = "Tekan [C] untuk Gabungkan Bukti"; combine_hint.position = Vector2(22, 436)
	combine_hint.add_theme_color_override("font_color", C_CYAN); combine_hint.add_theme_font_size_override("font_size", 9)
	left_page.add_child(combine_hint)

func _build_right_notes() -> void:
	# Garis pemisah cyan di bawah nama item
	var line := TextureRect.new()
	line.texture = tex.line; line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line.position = Vector2(12, 36); line.size = Vector2(236, 2); line.modulate = C_CYAN
	detail_box.add_child(line)
	
	# Kotak Tengah: [LOG ANALISIS] / [KESIMPULAN] / [ALIBI & STATUS]
	note_box = _make_patch(tex.white, C_CARD, Vector2(22, 168), Vector2(374, 88), 10)
	right_page.add_child(note_box)
	note_lbl = RichTextLabel.new()
	note_lbl.bbcode_enabled = true; note_lbl.position = Vector2(12, 10); note_lbl.size = Vector2(350, 68)
	note_lbl.add_theme_color_override("default_color", C_TEXT)
	note_lbl.add_theme_font_size_override("normal_font_size", 10)
	note_lbl.add_theme_font_size_override("bold_font_size", 10)
	note_lbl.add_theme_constant_override("line_separation", 5)
	note_box.add_child(note_lbl)
	
	# Kotak Bawah Pengganti Item Slots: [KEGUNAAN & SINTESIS] / [TINDAK LANJUT] / [KETERKAITAN KASUS]
	extra_box = _make_patch(tex.white, C_CARD, Vector2(22, 268), Vector2(374, 132), 10)
	right_page.add_child(extra_box)
	extra_lbl = RichTextLabel.new()
	extra_lbl.bbcode_enabled = true; extra_lbl.position = Vector2(12, 12); extra_lbl.size = Vector2(350, 108)
	extra_lbl.add_theme_color_override("default_color", C_TEXT)
	extra_lbl.add_theme_font_size_override("normal_font_size", 10)
	extra_lbl.add_theme_font_size_override("bold_font_size", 10)
	extra_lbl.add_theme_constant_override("line_separation", 6)
	extra_box.add_child(extra_lbl)

func _generate_rows() -> void:
	for i in range(6):
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(354, 46)
		btn.add_theme_stylebox_override("normal", _row_style(C_CARD))
		btn.add_theme_stylebox_override("hover", _row_style(Color(0.10, 0.42, 0.60, 0.82)))
		btn.add_theme_stylebox_override("pressed", _row_style(Color(0.11, 0.48, 0.66, 0.88)))
		btn.add_theme_stylebox_override("disabled", _row_style(Color(0.03, 0.12, 0.20, 0.65)))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		var ic := TextureRect.new()
		ic.name = "Icon"; ic.position = Vector2(12, 7); ic.size = Vector2(32, 32)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var nl := Label.new()
		nl.name = "Name"; nl.position = Vector2(54, 2); nl.size = Vector2(280, 24)
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.add_theme_color_override("font_color", C_TEXT); nl.add_theme_font_size_override("font_size", 11)
		nl.clip_text = true; nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var ql := Label.new()
		ql.name = "Qty"; ql.position = Vector2(54, 23); ql.size = Vector2(280, 18)
		ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; ql.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ql.add_theme_color_override("font_color", C_CYAN); ql.add_theme_font_size_override("font_size", 9)
		ql.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		btn.add_child(ic); btn.add_child(nl); btn.add_child(ql)
		btn.pressed.connect(func(): if scroll_off + i < items.size(): _select(scroll_off + i))
		item_list.add_child(btn); rows.append(btn)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0.94, 1, 0.06)
	sb.border_color = C_CYAN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	selector = Panel.new()
	selector.add_theme_stylebox_override("panel", sb)
	selector.position = Vector2(-3, -3); selector.size = Vector2(360, 52)
	selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows[0].add_child(selector)

func _row_style(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(2)
	return sb

func _build_map_panel() -> void:
	map_panel = _make_patch(tex.white, C_CARD, Vector2(22, 24), Vector2(374, 376), 10)
	map_panel.visible = false; right_page.add_child(map_panel)
	
	var scr := ColorRect.new()
	scr.color = Color(0.02, 0.11, 0.19); scr.position = Vector2(10, 10); scr.size = Vector2(354, 250); scr.clip_contents = true
	map_panel.add_child(scr)
	
	if custom_map_image:
		var img := TextureRect.new()
		img.set_anchors_preset(Control.PRESET_FULL_RECT); img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; img.texture = custom_map_image
		scr.add_child(img)
	else:
		for x in range(0, 360, 32):
			var vl := ColorRect.new(); vl.color = Color(0, 0.9, 1, 0.14); vl.position = Vector2(x, 0); vl.size = Vector2(1, 250); scr.add_child(vl)
		for y in range(0, 260, 32):
			var hl := ColorRect.new(); hl.color = Color(0, 0.9, 1, 0.14); hl.position = Vector2(0, y); hl.size = Vector2(354, 1); scr.add_child(hl)
		var rv := ColorRect.new(); rv.color = Color(0, 0.65, 0.95, 0.35); rv.position = Vector2(215, 0); rv.size = Vector2(22, 250); scr.add_child(rv)
		var rd := ColorRect.new(); rd.color = Color(0, 0.94, 1, 0.25); rd.position = Vector2(35, 132); rd.size = Vector2(285, 8); scr.add_child(rd)
	
	player_pin = ColorRect.new(); player_pin.color = Color("#00ff88"); player_pin.size = Vector2(12, 12); player_pin.position = Vector2(109, 159); scr.add_child(player_pin)
	var pl := Label.new(); pl.text = "KAMU"; pl.add_theme_color_override("font_color", Color("#00ff88")); pl.add_theme_font_size_override("font_size", 8); player_pin.add_child(pl)
	pl.reset_size(); pl.position = Vector2((12.0 - pl.size.x) * 0.5, 14.0)
	
	target_pin = ColorRect.new(); target_pin.color = Color("#ffd500"); target_pin.size = Vector2(14, 14); scr.add_child(target_pin)
	target_lbl = Label.new(); target_lbl.position = Vector2(-18, -14); target_lbl.add_theme_color_override("font_color", Color("#ffd500")); target_lbl.add_theme_font_size_override("font_size", 8); target_pin.add_child(target_lbl)
	
	map_info_lbl = RichTextLabel.new(); map_info_lbl.bbcode_enabled = true; map_info_lbl.position = Vector2(12, 272); map_info_lbl.size = Vector2(350, 92)
	map_info_lbl.add_theme_color_override("default_color", C_TEXT); map_info_lbl.add_theme_font_size_override("normal_font_size", 9)
	map_info_lbl.add_theme_font_size_override("bold_font_size", 9); map_info_lbl.add_theme_constant_override("line_separation", 6); map_panel.add_child(map_info_lbl)

func _on_inventory_updated() -> void:
	if tab == 0 or tab == 1:
		_switch_tab(tab)

func _switch_tab(t: int) -> void:
	if tabs.is_empty():
		return
	tab = clamp(t, 0, 3)
	for i in range(4):
		tabs[i].self_modulate = C_TEAL if i == tab else C_CARD
		tabs[i].position.x = -68 if i == tab else -60
		dots[i].color = C_CYAN if i == tab else C_DIM
	var is_map := (tab == 3)
	for n in [preview_frame, detail_box, note_box, extra_box]:
		if n: n.visible = not is_map
	if map_panel:
		map_panel.visible = is_map
	if title_label:
		title_label.text = ["Bukti", "Catatan", "Profil", "Peta"][tab]
	if tab == 0:
		var ev_items: Array = []
		for ev_id in GameManager.collected_evidence:
			ev_items.append(GameManager.get_evidence_display_dict(ev_id))
		items = ev_items
	elif tab == 1:
		var note_items: Array = []
		for ded_id in GameManager.unlocked_deductions:
			var ded_info: Dictionary = GameManager.get_deduction_info(ded_id)
			var ded_title: String = str(ded_info.get("name", ded_id))
			var reqs: Array = ded_info.get("requires", [])
			note_items.append({
				"name": "[DEDUKSI] " + ded_title,
				"qty": "",
				"desc": "Kesimpulan investigasi terverifikasi dari sintesis bukti: %s." % ", ".join(reqs),
				"note": "[color=#00ff88][b][DEDUKSI TERBUKA][/b][/color]\nID: %s (+%d%% Memori)" % [ded_id, int(ded_info.get("memory_bonus", 10))],
				"extra": "[color=#00f0ff][b][KOMPONEN BUKTI][/b][/color]\n• " + "\n• ".join(reqs)
			})
		note_items.append_array(db[1])
		items = note_items
	elif tab == 2:
		var prof_items: Array = []
		for p in db[2]:
			var pid: String = str(p.get("id", "")).to_lower()
			if GameManager.has_profile(pid):
				prof_items.append(p)
		items = prof_items
	else:
		items = db[tab]
	scroll_off = 0
	_select(0)

func _select(i: int) -> void:
	if items.is_empty():
		for r_i in range(6):
			rows[r_i].visible = false
		if selector and selector.get_parent():
			selector.visible = false
		if handle: handle.visible = false
		if scroll_track: scroll_track.visible = false
		if preview_icon: preview_icon.texture = null
		if item_name: item_name.text = ""
		if item_desc:
			if tab == 0:
				item_desc.text = "[color=#88d4e8]Belum ada barang bukti yang ditemukan.[/color]"
			elif tab == 2:
				item_desc.text = "[color=#88d4e8]Belum ada profil karakter yang tercatat.\n\nTemui atau ajak bicara karakter untuk mencatat data profil mereka ke dalam arsip.[/color]"
			else:
				item_desc.text = "[color=#88d4e8]Belum ada catatan.[/color]"
		if note_lbl: note_lbl.text = ""
		if extra_lbl: extra_lbl.text = ""
		return
	if selector:
		selector.visible = true
	idx = clamp(i, 0, items.size() - 1)
	if idx < scroll_off: scroll_off = idx
	elif idx >= scroll_off + 6: scroll_off = idx - 5
	
	for r_i in range(6):
		var d_i := scroll_off + r_i; var r := rows[r_i]
		r.visible = d_i < items.size()
		r.get_node("Icon").visible = d_i < items.size()
		r.get_node("Icon").texture = default_icon
		r.get_node("Name").text = items[d_i]["name"] if d_i < items.size() else ""
		r.get_node("Qty").text = items[d_i]["qty"] if d_i < items.size() else ""
	
	if selector and selector.get_parent() != rows[idx - scroll_off]:
		selector.reparent(rows[idx - scroll_off]); selector.position = Vector2(-3, -3)
	if handle:
		handle.position.y = lerp(4.0, 270.0, float(idx) / max(1.0, float(items.size() - 1)))
		handle.visible = items.size() > 6
	if scroll_track:
		scroll_track.visible = items.size() > 6
	
	var it: Dictionary = items[idx]
	if tab == 3:
		if target_pin: target_pin.position = it["pos"] - Vector2(7, 7)
		if target_lbl:
			target_lbl.text = it["name"]
			target_lbl.reset_size()
			target_lbl.position = Vector2((14.0 - target_lbl.size.x) * 0.5, -14.0)
		if map_info_lbl: map_info_lbl.text = it["info"]
	else:
		if preview_icon: preview_icon.texture = default_icon
		if item_name: item_name.text = it["name"]
		if item_desc: item_desc.text = it["desc"]
		if note_lbl: note_lbl.text = it["note"]
		if extra_lbl: extra_lbl.text = it["extra"]
	item_selected.emit(it)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("toggle_notebook") or (e is InputEventKey and e.is_pressed() and not e.is_echo() and e.keycode == KEY_TAB):
		get_viewport().set_input_as_handled()
		toggle_notebook()
		return
		
	if not visible or items.is_empty(): return
	if e.is_action_pressed("ui_down"): get_viewport().set_input_as_handled(); _select((idx + 1) % items.size())
	elif e.is_action_pressed("ui_up"): get_viewport().set_input_as_handled(); _select((idx - 1 + items.size()) % items.size())
	elif e.is_action_pressed("ui_right"): get_viewport().set_input_as_handled(); _switch_tab((tab + 1) % 4)
	elif e.is_action_pressed("ui_left"): get_viewport().set_input_as_handled(); _switch_tab((tab - 1 + 4) % 4)
	elif e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
		get_viewport().set_input_as_handled(); _select(idx + (1 if e.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1))
	elif e.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled(); item_used.emit(items[idx])
	elif e.is_action_pressed("ui_cancel") or (e is InputEventKey and e.is_pressed() and not e.is_echo() and e.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled(); close_notebook()
