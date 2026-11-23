extends Node

signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_deleted(slot: int)

const SAVE_DIR: String = "user://saves/"
const SLOT_COUNT: int = 3
const SAVE_VERSION: String = "1.0"

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

func has_save_file(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func save_game(slot: int) -> bool:
	var file: FileAccess = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Gagal membuka file save untuk ditulis: " + get_save_path(slot))
		return false
	file.store_string(JSON.stringify(GameManager.to_save_dict(), "\t"))
	file.close()
	game_saved.emit(slot)
	return true

func load_game(slot: int) -> bool:
	var data: Dictionary = read_save_file(slot)
	if data.is_empty():
		return false
	if not GameManager.apply_save_data(data):
		return false
	game_loaded.emit(slot)
	_go_to_chapter(GameManager.current_chapter)
	return true

func read_save_file(slot: int) -> Dictionary:
	if not has_save_file(slot):
		return {}
	var file: FileAccess = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		push_error("Gagal membaca file save slot: %d" % slot)
		return {}
	var content: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		push_error("Gagal parsing JSON save file slot: %d" % slot)
		return {}
	return parsed

func get_slot_metadata(slot: int) -> Dictionary:
	if not has_save_file(slot):
		return {"slot": slot, "exists": false}
	var data: Dictionary = read_save_file(slot)
	if data.is_empty():
		return {"slot": slot, "exists": false}
	var game_state: Dictionary = data.get("game_state", {})
	var psych: Dictionary = data.get("psychological_variables", {})
	var chapter: int = int(game_state.get("current_chapter", 0))
	return {
		"slot": slot,
		"exists": true,
		"timestamp": str(data.get("save_timestamp", "-")),
		"chapter": chapter,
		"chapter_title": str(game_state.get("chapter_title", GameManager.CHAPTER_TITLES.get(chapter, "-"))),
		"memory": int(psych.get("memory_meter", 0)),
		"suspicion": int(psych.get("suspicion_meter", 0)),
	}

func delete_save(slot: int) -> void:
	var path: String = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		save_deleted.emit(slot)

func _go_to_chapter(chapter: int) -> void:
	var path: String = GameManager.CUTSCENE_SCENE_PATH if chapter == 0 else GameManager.chapter_scene_path(chapter)
	if not ResourceLoader.exists(path):
		push_error("Scene for save slot not found: " + path)
		return
	get_tree().change_scene_to_file(path)
