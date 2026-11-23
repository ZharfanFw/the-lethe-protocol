extends Control

const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const C_CYAN := Color("#00f0ff")
const C_TEXT := Color("#e8fcff")
const C_DIM := Color("#88d4e8")

const ENDING_BODIES: Dictionary = {
	1: "Arthur menancapkan kunci ke pemancar nasional. Layar raksasa di seluruh Concord menayangkan buku besar korupsi Graves, rekaman pembantaian tanah adat, dan tembang tidur Edward Vance. Amnesia jutaan rakyat runtuh seketika; kesedihan meledak menjadi amarah liar. Rakyat membakar markas kementerian dan menggantung pejabat korup. Arthur berdiri di atas gedung yang terbakar, menangis menyaksikan kota tenggelam dalam lautan api perang saudara. Kebenaran ditegakkan, namun dibayar dengan anarki total.",
	2: "Memanfaatkan aksesnya yang bersih dari kecurigaan, Arthur meretas implan saraf Direktur Graves dan seluruh Dewan Direksi. Esok paginya, Graves mengundurkan diri dan menyerahkan mandat kepada Arthur. Ia memimpin The Registry dari balik bayang-bayang, menanggung kesepian mutlak, sambil diam-diam mengalirkan kredit korporasi ke rumah sakit rakyat dan menyiarkan dongeng Nusantara ke sekolah pinggiran. Reformasi tanpa setetes darah.",
	3: "Arthur menyadari bahwa membongkar kebenaran instan akan memicu perang saudara dan pembantaian jutaan orang tak bersalah. Dengan tangan gemetar, ia mencabut Master Override Key dan menginjaknya hingga hancur. Bukti tentang ayahnya musnah selamanya. Ia menolak The Tonic dan memikul dosa itu sendirian sampai akhir hayat, setelah membunuh ayahnya untuk kedua kalinya demi kedamaian palsu.",
	4: "Arthur disergap di ruang kerja Graves sebelum sempat merakit kunci. Ia dilumpuhkan dengan pengekang neural dan disuntik neuro-injeksi penghapus kepribadian total di laboratorium Sektor 0. Arthur Vance lenyap selamanya; keesokan harinya birokrasi memiliki inspektur baru yang patuh, dingin, dan tidak akan pernah bermimpi lagi.",
	5: "Arthur gagal merekonstruksi memorinya. Menganggap kunci itu virus teroris, ia menyerahkan seluruh modul ke meja Graves. Graves memberinya Medali Keselarasan dan pil The Tonic formula emas. Arthur kembali ke apartemennya, meminum obatnya, dan tersenyum hampa menatap cermin biometrik. Ia hidup damai selamanya sebagai pion tanpa jiwa.",
}

@export var ending_id: int = 1

func _ready() -> void:
	GameManager.set_flag("ending_%d_reached" % ending_id, true)
	_build_ui()
	UIManager.fade_in(0.6)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0117647, 0.0313725, 0.0509804, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var overline := _label("CASE 4092 // RESOLUSI FINAL", 7, C_DIM)
	overline.position = Vector2(0, 26)
	overline.size = Vector2(640, 14)
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(overline)

	var title := _label(String(GameManager.ENDING_TITLES.get(ending_id, "ENDING")), 14, C_CYAN)
	title.position = Vector2(30, 48)
	title.size = Vector2(580, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(title)

	var rule := ColorRect.new()
	rule.position = Vector2(250, 84)
	rule.size = Vector2(140, 2)
	rule.color = Color(C_CYAN, 0.35)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)

	var body := RichTextLabel.new()
	body.position = Vector2(60, 102)
	body.size = Vector2(520, 160)
	body.bbcode_enabled = true
	body.scroll_active = false
	body.add_theme_font_size_override("normal_font_size", 8)
	body.add_theme_color_override("default_color", C_TEXT)
	body.add_theme_constant_override("line_separation", 4)
	body.text = String(ENDING_BODIES.get(ending_id, ""))
	add_child(body)

	var stats := _label("MEMORI %d%%   //   KECURIGAAN %d%%   //   BUKTI %d" % [
		GameManager.memory_meter,
		GameManager.suspicion_meter,
		GameManager.collected_evidence.size(),
	], 7, C_DIM)
	stats.position = Vector2(0, 274)
	stats.size = Vector2(640, 14)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(stats)

	var back := Button.new()
	back.position = Vector2(230, 300)
	back.size = Vector2(180, 36)
	back.add_theme_font_size_override("font_size", 9)
	back.text = "KEMBALI KE MENU"
	back.pressed.connect(_return_to_menu)
	add_child(back)
	back.grab_focus()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_return_to_menu()
