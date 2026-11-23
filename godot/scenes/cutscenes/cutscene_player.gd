extends Control

@export var slides: Array[Texture2D] = []
@export var slide_titles: Array[String] = [
	"RUMAH PANGGUNG // 2068",
	"SERBUAN GRAVES",
	"KEMATIAN EDWARD VANCE",
	"APARTEMEN 2084",
]
@export var narrative_texts: Array[String] = [
	"Malam itu, kidung ayah masih terdengar dari balik dinding kayu. Arthur kecil belum tahu bahwa ingatan adalah barang paling berbahaya di Concord.",
	"Direktur Lucian Graves datang bersama pasukannya. Tidak ada surat perintah, hanya kilat senjata dan kaki-kaki yang menghentak lantai panggung.",
	"Edward Vance menutup mata dengan lempengan ukiran kayu di tangannya. Darah menetes di atas aksara yang tidak sempat ia ajarkan kepada putranya.",
	"Dua dekade kemudian, Inspektur Arthur Vance terbangun di apartemennya. The Tonic di meja, kepala berdenyut, dan satu nama yang tidak bisa ia ingat: Thur.",
]
@export var next_scene_chapter: int = 1

const DIALOGUE_BOX_SCENE_PATH := "res://scenes/dialogue_box.tscn"

var _index: int = 0
var _finishing: bool = false

var _bg: ColorRect
var _slide_image: TextureRect
var _counter: Label
var _hint: Label
var _dialogue_box: CanvasLayer

func _ready() -> void:
	_build_ui()
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
	shade.color = Color(0.01, 0.03, 0.05, 0.45)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_hint = Label.new()
	_hint.position = Vector2(24, 16)
	_hint.size = Vector2(460, 14)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.add_theme_font_size_override("font_size", 7)
	_hint.add_theme_color_override("font_color", Color("#88d4e8"))
	_hint.text = "[KLIK / SPASI] LANJUT   [ESC] LEWATI PROLOG"
	add_child(_hint)

	_counter = Label.new()
	_counter.position = Vector2(24, 16)
	_counter.size = Vector2(592, 14)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter.add_theme_font_size_override("font_size", 7)
	_counter.add_theme_color_override("font_color", Color("#88d4e8"))
	add_child(_counter)

func _show_slide(idx: int) -> void:
	if idx < 0 or idx >= _slide_count():
		return
	_index = idx
	if idx < slides.size() and slides[idx] != null:
		_slide_image.texture = slides[idx]
		_slide_image.visible = true
	else:
		_slide_image.visible = false
		_bg.color = _slide_color(idx)

	var vp_w: float = size.x if size.x > 0.0 else 640.0
	_counter.text = "%d / %d" % [idx + 1, _slide_count()]
	_counter.size.x = maxf(120.0, vp_w - 48.0)

	var speaker: String = slide_titles[idx] if idx < slide_titles.size() else "PROLOG"
	var body: String = narrative_texts[idx] if idx < narrative_texts.size() else ""
	if _dialogue_box and _dialogue_box.has_method("start_dialogue"):
		_dialogue_box.visible = true
		_dialogue_box.start_dialogue(speaker, [body])
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
	return max(slide_titles.size(), narrative_texts.size())

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
	GameManager.set_flag("prologue_completed", true)
	await UIManager.play_fade_transition(true, 0.6)
	GameManager.advance_to_chapter(next_scene_chapter)
