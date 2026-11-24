extends Control

@export var cutscene_id: String = ""
@export var next_scene_path: String = ""

const DIALOGUE_BOX_SCENE_PATH := "res://scenes/dialogue_box.tscn"

const CUTSCENES: Dictionary = {
	"prolog": {
		"flag": "prologue_completed",
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI PROLOG",
		"slides": [
			{
				"image": "res://assets/cutscenes/prolog-slide1.jpg",
				"lines": [
					{"name": "Edward Vance", "text": "Selama aksara ini hidup di dalam dadamu, tanah tumpah darahmu tidak akan pernah bisa dirampas oleh siapa pun."},
					{"name": "Arthur", "text": "Malam itu, kidung ayah masih terdengar dari balik dinding kayu. Aku belum tahu bahwa ingatan adalah barang paling berbahaya di Concord."}
				]
			},
			{
				"image": "res://assets/cutscenes/prolog-slide2.jpg",
				"lines": [
					{"name": "Lucian Graves", "text": "Edward Vance. Waktu negosiasi sudah habis. Di mana buku besar tanah ulayat dan naskah peta geologis itu?"},
					{"name": "Edward Vance", "text": "Kalian bukan membangun peradaban, Graves! Kalian mencuri hutan dan mengeruk gunung emas leluhur kami!"}
				]
			},
			{
				"image": "res://assets/cutscenes/prolog-slide3.jpg",
				"lines": [
					{"name": "Edward Vance", "text": "Arthur... Simpan ukiran ini... Ini kuncinya... Jangan biarkan mereka menghapus jiwamu... Ingat kidung itu, Thur..."},
					{"name": "Arthur", "text": "Darah ayah menetes di atas lempengan kayu ulin sebelum napasnya berhenti selamanya."}
				]
			},
			{
				"image": "res://assets/cutscenes/prolog-slide4.jpg",
				"lines": [
					{"name": "HUD-Mirror", "text": "[ANOMALI KOGNITIF: AIR MATA // DETAK JANTUNG +38 BPM // STATUS: MEMORI TIDAK STABIL]"},
					{"name": "Arthur Vance", "text": "Dua dekade kemudian di Concord 2084. The Tonic di meja, kepala berdenyut, dan satu nama yang tersisa: Thur."}
				]
			}
		]
	},
	"chapter_1": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/chapter1-slide1.jpg",
				"lines": [
					{"name": "Detective Miles Prescott", "text": "Miller tertangkap di pos pemeriksaan membawa pita magnetik ilegal zaman purba, Vance."},
					{"name": "Miller", "text": "Itu... itu suara ibu saya... Sebelum proyek restrukturisasi menghapus namanya dari data kota..."}
				]
			},
			{
				"image": "res://assets/cutscenes/chapter1-slide2.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Sub-Sektor 4. Jejak kaset Miller mengarah ke gudang suku cadang terbengkalai di balik kabut hujan asam."}
				]
			},
			{
				"image": "res://assets/cutscenes/chapter1-slide3.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Puntung kretek Black Clove, coretan fosfor T-CORE // SPARROW, dan catatan untuk Thur... Seseorang menungguku di sini."}
				]
			}
		]
	},
	"chapter_2": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/chapter2-slide1.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Dok Whitehall Bawah. Peti kargo bertanda JAYABAYA telah dibobol dan selongsong peluru berserakan di dermaga."}
				]
			},
			{
				"image": "res://assets/cutscenes/chapter2-slide2.jpg",
				"lines": [
					{"name": "Colin Ward", "text": "Thur...? Kamu yang merancang Protokol Jayabaya, Arthur! Kamu menanam pintu belakang dengan sandi aksara ayahmu, Edward Vance!"},
					{"name": "Arthur Vance", "text": "Colin... Ya Tuhan... Semua ingatanku kembali..."}
				]
			},
			{
				"image": "res://assets/cutscenes/chapter2-slide3.jpg",
				"lines": [
					{"name": "Sistem Biro", "text": "[OVERRIDE OTOMATIS // FAILSAFE NEUROTOXIN GRAVES DIJALANKAN]"},
					{"name": "Colin Ward", "text": "Selesaikan... tugas ayahmu, Thur... Sektor 0... Laci 884-B... Bebaskan kota ini..."}
				]
			}
		]
	},
	"chapter_3": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/chapter3-slide1.png",
				"lines": [
					{"name": "Arthur Vance", "text": "Arsip Bawah Tanah Sektor 0. Dial kunci 1-2-0-9-4 membuka Laci 884-B... Ukiran kayu ayah dan kaset rekamanku sendiri ada di dalamnya."}
				]
			},
			{
				"image": "res://assets/cutscenes/chapter3-slide2.jpg",
				"lines": [
					{"name": "Garrick Shaw", "text": "Edward Vance mati agar rahasia ini hidup, Arthur. Sekarang kau memakai lencana pembunuhnya, atau siap menyelesaikan apa yang kita mulai?"}
				]
			}
		]
	},
	"chapter_4": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/chapter4-slide1.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Lantai 80 Menara Eksekutif. Di tengah badai petir tengah malam, ruang kerja Direktur Graves berdiri kosong."}
				]
			},
			{
				"image": "res://assets/cutscenes/chapter4-slide2.jpg",
				"lines": [
					{"name": "Terminal Kuantum", "text": "[OTENTIKASI ARSITEK DITERIMA // PROTOKOL JAYABAYA TERVERIFIKASI // MASTER OVERRIDE KEY READY]"}
				]
			}
		]
	},
	"chapter_5": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/chapter5-slide1.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Fajar 06:58 di puncak menara transmisi nasional. Di ujung jariku bertumpu takdir jutaan warga Concord."}
				]
			}
		]
	},
	"ending_1": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/ending1-slide1.jpg",
				"lines": [
					{"name": "Siaran Nasional", "text": "Layar-layar di seluruh Concord menayangkan buku besar korupsi Graves, rekaman eksekusi Edward, dan kidung leluhur."}
				]
			},
			{
				"image": "res://assets/cutscenes/ending1-slide2.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Amnesia warga runtuh seketika dan meledak menjadi amarah. Kebenaran ditegakkan, namun Concord tenggelam dalam api perang saudara."}
				]
			}
		]
	},
	"ending_2": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/ending2-slide1.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Melalui gerbang Vance-Cipher, implan saraf Graves dan Dewan Direksi diretas secara senyap tanpa setetes darah."}
				]
			},
			{
				"image": "res://assets/cutscenes/ending2-slide2.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Kini aku memimpin The Registry dari balik bayang-bayang—menanggung kesepian mutlak demi memulihkan kemanusiaan Concord."}
				]
			}
		]
	},
	"ending_3": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/ending3-slide1.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Kebenaran instan hanya akan membakar jutaan warga tak bersalah. Maafkan aku, Ayah..."}
				]
			},
			{
				"image": "res://assets/cutscenes/ending3-slide2.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Kristal Master Override Key hancur berkeping-keping. Aku menolak The Tonic dan memikul dosa membunuh ayah untuk kedua kalinya."}
				]
			}
		]
	},
	"ending_4": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/ending4-slide1.jpg",
				"lines": [
					{"name": "Direktur Lucian Graves", "text": "Tingkat kewaspadaan biro terhadapmu mencapai batas kritis, Inspektur Vance. Prescott telah mencatat setiap kedipan matamu."}
				]
			},
			{
				"image": "res://assets/cutscenes/ending4-slide2.jpg",
				"lines": [
					{"name": "Sistem Sektor 0", "text": "[NEURO-INJEKSI PENGHAPUS KEPRIBADIAN SELESAI // SUBJEK ARTHUR VANCE DIREKONDISI PERMANEN]"}
				]
			}
		]
	},
	"ending_5": {
		"hint": "[KLIK / SPASI] LANJUT   [ESC] LEWATI CUTSCENE",
		"slides": [
			{
				"image": "res://assets/cutscenes/ending5-slide1.jpg",
				"lines": [
					{"name": "Direktur Lucian Graves", "text": "Keputusan yang bijak, Inspektur Vance. Terimalah Medali Keselarasan dan formula emas The Tonic ini."}
				]
			},
			{
				"image": "res://assets/cutscenes/ending5-slide2.jpg",
				"lines": [
					{"name": "Arthur Vance", "text": "Aku tidak akan pernah bermimpi lagi. Hidup tenang selamanya sebagai alat birokrasi yang patuh."}
				]
			}
		]
	}
}

var _active_id: String = "prolog"
var _active_slides: Array = []
var _index: int = 0
var _finishing: bool = false

var _bg: ColorRect
var _slide_image: TextureRect
var _counter: Label
var _hint: Label
var _dialogue_box: CanvasLayer

func _ready() -> void:
	_active_id = cutscene_id if not cutscene_id.is_empty() else GameManager.pending_cutscene_id
	if _active_id.is_empty() or not CUTSCENES.has(_active_id):
		_active_id = "prolog"
	var data: Dictionary = CUTSCENES[_active_id]
	_active_slides = data.get("slides", [])

	_build_ui()
	_hint.text = str(data.get("hint", "[KLIK / SPASI] LANJUT   [ESC] LEWATI"))
	_ensure_dialogue_box()
	UIManager.show_hud(false)
	_show_slide(0)
	UIManager.fade_in(0.5)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)

func _ensure_dialogue_box() -> void:
	_dialogue_box = get_node_or_null("DialogueBox") as CanvasLayer
	if _dialogue_box == null:
		var packed: PackedScene = load(DIALOGUE_BOX_SCENE_PATH)
		if packed:
			_dialogue_box = packed.instantiate() as CanvasLayer
			_dialogue_box.name = "DialogueBox"
			add_child(_dialogue_box)
	if _dialogue_box and not _dialogue_box.dialogue_finished.is_connected(_on_dialogue_finished):
		_dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.02, 0.05, 0.08, 1)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_slide_image = TextureRect.new()
	_slide_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slide_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_slide_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_slide_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slide_image)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.05, 0.14)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_hint = Label.new()
	_hint.position = Vector2(24, 16)
	_hint.size = Vector2(460, 14)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.add_theme_font_size_override("font_size", 7)
	_hint.add_theme_color_override("font_color", Color("#e8fcff"))
	_hint.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.05, 0.9))
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.text = "[KLIK / SPASI] LANJUT   [ESC] LEWATI PROLOG"
	add_child(_hint)

	_counter = Label.new()
	_counter.position = Vector2(24, 16)
	_counter.size = Vector2(592, 14)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter.add_theme_font_size_override("font_size", 7)
	_counter.add_theme_color_override("font_color", Color("#e8fcff"))
	_counter.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.05, 0.9))
	_counter.add_theme_constant_override("outline_size", 3)
	add_child(_counter)

func _show_slide(idx: int) -> void:
	if idx < 0 or idx >= _slide_count():
		return
	_index = idx
	var slide: Dictionary = _active_slides[idx]
	var img_path: String = str(slide.get("image", ""))
	if not img_path.is_empty() and ResourceLoader.exists(img_path):
		_slide_image.texture = load(img_path) as Texture2D
		_slide_image.visible = true
	else:
		_slide_image.visible = false
		_bg.color = _slide_color(idx)

	var vp_w: float = size.x if size.x > 0.0 else 640.0
	_counter.text = "%d / %d" % [idx + 1, _slide_count()]
	_counter.size.x = maxf(120.0, vp_w - 48.0)

	var lines: Array = slide.get("lines", [])
	if _dialogue_box and _dialogue_box.has_method("start_dialogue") and not lines.is_empty():
		_dialogue_box.visible = true
		_dialogue_box.start_dialogue(lines)
	modulate.a = 1.0

func _slide_color(idx: int) -> Color:
	var palette := [
		Color(0.10, 0.06, 0.04),
		Color(0.14, 0.03, 0.05),
		Color(0.06, 0.04, 0.08),
		Color(0.02, 0.06, 0.09),
	]
	return palette[idx % palette.size()]

func _slide_count() -> int:
	return _active_slides.size()

func _on_dialogue_finished() -> void:
	if _finishing:
		return
	_advance_slide()

func _unhandled_input(event: InputEvent) -> void:
	if _finishing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish_cutscene()
	elif _dialogue_box == null or not _dialogue_box.is_active:
		var advance: bool = event.is_action_pressed("ui_accept")
		advance = advance or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_E)
		advance = advance or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		if advance:
			get_viewport().set_input_as_handled()
			_advance_slide()

func _advance_slide() -> void:
	if _index + 1 < _slide_count():
		_show_slide(_index + 1)
	else:
		_finish_cutscene()

func _finish_cutscene() -> void:
	if _finishing:
		return
	_finishing = true
	if _dialogue_box:
		_dialogue_box.visible = false
	var data: Dictionary = CUTSCENES.get(_active_id, {})
	var flag_name: String = str(data.get("flag", ""))
	if not flag_name.is_empty():
		GameManager.set_flag(flag_name, true)
	await UIManager.play_fade_transition(true, 0.6)
	var target_scene: String = next_scene_path if not next_scene_path.is_empty() else GameManager.pending_cutscene_next_scene
	if target_scene.is_empty():
		target_scene = GameManager.chapter_scene_path(1)
	GameManager.pending_cutscene_id = "prolog"
	GameManager.pending_cutscene_next_scene = GameManager.chapter_scene_path(1)
	if ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		push_error("Cutscene target scene not found: " + target_scene)
