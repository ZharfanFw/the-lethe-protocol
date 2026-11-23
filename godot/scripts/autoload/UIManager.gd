extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@onready var hud_panel: Control = $HUDPanel
@onready var pause_menu: Control = get_node_or_null("PauseMenu")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if fade_rect:
		fade_rect.modulate.a = 0.0
	if hud_panel:
		hud_panel.hide()

func show_hud(show_hud: bool) -> void:
	if hud_panel:
		hud_panel.visible = show_hud

func get_dialogue_box() -> CanvasLayer:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var matches := scene.find_children("DialogueBox", "CanvasLayer", true, false)
	if matches.is_empty():
		return null
	return matches[0] as CanvasLayer

func say(speaker: String, lines: Array) -> bool:
	var box := get_dialogue_box()
	if box == null or not box.has_method("start_dialogue"):
		push_warning("DialogueBox tidak ditemukan di scene aktif.")
		return false
	box.start_dialogue(speaker, lines)
	return true

func play_fade_transition(fade_out: bool, duration: float = 0.5) -> void:
	if fade_rect == null:
		return
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0 if fade_out else 0.0, duration)
	await tween.finished

func fade_in(duration: float = 0.5) -> void:
	if fade_rect == null:
		return
	fade_rect.modulate.a = 1.0
	await play_fade_transition(false, duration)

func reset_fade() -> void:
	if fade_rect:
		fade_rect.modulate.a = 0.0

func toggle_mind_vault() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var vault := scene.get_node_or_null("MindVaultUI")
	if vault == null:
		return
	if vault.visible and vault.has_method("hide_vault"):
		vault.hide_vault()
	elif vault.has_method("show_and_refresh"):
		vault.show_and_refresh()
	else:
		vault.visible = not vault.visible

func open_pause_menu() -> void:
	if pause_menu and not pause_menu.visible:
		pause_menu.open_pause_menu()

func close_pause_menu() -> void:
	if pause_menu and pause_menu.visible:
		pause_menu.resume_game()

func is_paused() -> bool:
	return pause_menu != null and pause_menu.visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_P):
		_handle_pause_key()

func _handle_pause_key() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var scene_name := scene.name.to_lower()
	# Jangan memunculkan pause menu jika sedang di Main Menu atau Save Select
	if scene_name.contains("mainmenu") or scene_name.contains("main_menu") or scene_name.contains("saveselect") or scene_name.contains("save_select"):
		return

	if pause_menu:
		if pause_menu.visible:
			pause_menu.resume_game()
			get_viewport().set_input_as_handled()
		else:
			# Cek apakah ada overlay modal aktif (Notebook, Item Combiner, DialogueBox, atau Puzzle)
			if _is_any_overlay_open():
				return
			pause_menu.open_pause_menu()
			get_viewport().set_input_as_handled()

func _is_any_overlay_open() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	# Dialogue box
	for b in scene.find_children("DialogueBox", "CanvasLayer", true, false):
		if b.get("is_active"):
			return true
	# Notebook
	for n in scene.find_children("DetectiveNotebook", "CanvasLayer", true, false):
		if n.get("is_open"):
			return true
	# Combiner
	for c in scene.find_children("ItemCombiner", "CanvasLayer", true, false):
		if c.get("is_open"):
			return true
	# Affine puzzle
	for a in scene.find_children("AffinePuzzle", "Area2D", true, false):
		if a.get("_open"):
			return true
	return false
