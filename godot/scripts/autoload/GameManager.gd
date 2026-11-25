extends Node

signal memory_changed(new_value: int)
signal suspicion_changed(new_value: int)
signal inventory_updated()
signal deduction_unlocked(deduction_id: String)
signal profile_unlocked(character_id: String)
signal chapter_transition_started(target_chapter: int)
signal ending_reached(ending_id: int)

const TOTAL_CHAPTERS: int = 5
const ENDING_SCENE_PATH: String = "res://scenes/endings/ending_%d.tscn"
const CUTSCENE_SCENE_PATH: String = "res://scenes/cutscenes/cutscene_player.tscn"

const CHAPTER_TITLES: Dictionary = {
	0: "Prolog: Kidung yang Hilang",
	1: "Chapter 1: Kidung yang Hilang & Jejak Sub-Sektor 4",
	2: "Chapter 2: Dok Whitehall Bawah",
	3: "Chapter 3: Sektor 0 & Undercity",
	4: "Chapter 4: Lantai 80 Infiltrasi",
	5: "Chapter 5: Fajar 07:00",
}

const ENDING_TITLES: Dictionary = {
	1: "Ending 1: Pengorbanan yang Membakar Kota",
	2: "Ending 2: Kesepian Sang Pemimpin Bayangan",
	3: "Ending 3: Membunuh Ayah untuk Kedua Kalinya",
	4: "Ending 4: Dihapus & Direkondisi Permanen",
	5: "Ending 5: Alat yang Patuh",
}

var current_slot: int = 1
var current_chapter: int = 0
var pending_cutscene_id: String = "prolog"
var pending_cutscene_next_scene: String = "res://scenes/chapters/chapter_1/chapter_1.tscn"
var memory_meter: int = 0:
	set(value):
		memory_meter = clamp(value, 0, 100)
		memory_changed.emit(memory_meter)
var suspicion_meter: int = 0:
	set(value):
		suspicion_meter = clamp(value, 0, 100)
		suspicion_changed.emit(suspicion_meter)

var collected_evidence: Array[String] = []
var unlocked_deductions: Array[String] = []
var unlocked_profiles: Array[String] = []
var story_flags: Dictionary = {}
var evidence_db: Dictionary = {}
var deductions_db: Dictionary = {}
var chapter_dialogues_cache: Dictionary = {}
const KNOWN_ITEMS: Dictionary = {
	"lencana": {
		"name": "Lencana Unit V-09",
		"category": "Identitas / Biro",
		"desc": "Lencana resmi Inspektur Elit Unit V-09 The Registry (Whitehall Complex)."
	},
	"EVID-COMB-101": {
		"name": "Rute Selundupan Colin",
		"category": "Deduksi / Jalur Pelarian",
		"desc": "Puntung kretek Black Clove dan peta saluran air membuktikan Colin Ward menuju Dok Pelabuhan Whitehall Bawah."
	},
	"EVID-COMB-102": {
		"name": "Dekripsi Identitas Sparrow",
		"category": "Deduksi / Identitas",
		"desc": "Testimoni Miller dan coretan fosfor T-CORE mengonfirmasi buronan Sparrow adalah Colin Ward."
	},
	"EVID-COMB-201": {
		"name": "Protokol Jayabaya Rancangan Arthur",
		"category": "Deduksi / Kognitif",
		"desc": "Coretan T-CORE dan Log Vance-Cipher Rev3 membuktikan Protokol Jayabaya adalah pintu belakang buatan Arthur sendiri."
	},
	"EVID-COMB-202": {
		"name": "Brankas Rahasia Sektor 0",
		"category": "Deduksi / Koordinat",
		"desc": "Wasiat Colin dan goresan darah SEKTOR 0 // LACI 884-B mengarah pada penyimpanan peninggalan Edward Vance."
	},
	"EVID-COMB-301": {
		"name": "Kunci Enkripsi Ukiran Edward",
		"category": "Deduksi / Artefak",
		"desc": "Pola aksara Nusantara pada ukiran kayu Edward Vance adalah kunci dekripsi logika Protokol Jayabaya."
	},
	"EVID-COMB-302": {
		"name": "Blueprint Master Override Key",
		"category": "Deduksi / Perakitan",
		"desc": "Ukiran kayu Edward, kaset mikro, dan tabung titanium Shaw harus disatukan di konsol kuantum kantor Graves."
	},
	"EVID-COMB-401": {
		"name": "Motif Tirani The Registry",
		"category": "Deduksi / Kebenaran",
		"desc": "Buku besar korupsi triliunan kredit dan rekaman eksekusi Edward membuktikan amnesia warga dipakai menutupi perampokan tanah adat."
	}
}

const LEGACY_ITEM_MIGRATION: Dictionary = {
	"chip_rusak": "EVID-001",
	"pembaca_chip": "EVID-002",
	"kertas_sobek": "",
	"lensa_uv": "",
	"kunci_patah": "",
	"kepala_kunci": "",
	"log_server": "EVID-COMB-101",
	"kode_brankas": "EVID-COMB-102",
	"kunci_vip_utuh": "EVID-COMB-202",
}

var saved_player_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false
var saved_map_id: String = ""

func _ready() -> void:
	_load_evidence_db()
	_ensure_story_flags()

func _load_evidence_db() -> void:
	var path := "res://data/evidence/evidence_database.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			evidence_db = json.data.get("evidence", {})
			deductions_db = json.data.get("deductions", {})

func get_chapter_dialogue_data(chapter_num: int = -1) -> Dictionary:
	var ch: int = current_chapter if chapter_num < 0 else chapter_num
	if ch <= 0:
		ch = 1
	if chapter_dialogues_cache.has(ch):
		return chapter_dialogues_cache[ch]
	var path := "res://data/dialogues/chapter_%d_dialogue.json" % ch
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			chapter_dialogues_cache[ch] = json.data
			return json.data
	return {}

func get_npc_dialogue(npc_id: String, chapter_num: int = -1) -> Dictionary:
	if npc_id.is_empty():
		return {}
	var data := get_chapter_dialogue_data(chapter_num)
	var npcs: Dictionary = data.get("npcs", {})
	if npcs.has(npc_id) and npcs[npc_id] is Dictionary:
		return npcs[npc_id]
	if chapter_num < 0:
		for ch in range(1, TOTAL_CHAPTERS + 1):
			var ch_npcs: Dictionary = get_chapter_dialogue_data(ch).get("npcs", {})
			if ch_npcs.has(npc_id) and ch_npcs[npc_id] is Dictionary:
				return ch_npcs[npc_id]
	return {}

func get_interactable_dialogue(entry_id: String, chapter_num: int = -1) -> Dictionary:
	if entry_id.is_empty():
		return {}
	var data := get_chapter_dialogue_data(chapter_num)
	var items: Dictionary = data.get("interactables", {})
	if items.has(entry_id) and items[entry_id] is Dictionary:
		return items[entry_id]
	if chapter_num < 0:
		for ch in range(1, TOTAL_CHAPTERS + 1):
			var ch_items: Dictionary = get_chapter_dialogue_data(ch).get("interactables", {})
			if ch_items.has(entry_id) and ch_items[entry_id] is Dictionary:
				return ch_items[entry_id]
	return {}

func get_deduction_info(deduction_id: String) -> Dictionary:
	return deductions_db.get(deduction_id, {})
func reset_to_new_game(slot_id: int) -> void:
	current_slot = slot_id
	current_chapter = 0
	memory_meter = 0
	suspicion_meter = 0
	saved_player_position = Vector2.ZERO
	has_saved_position = false
	saved_map_id = ""
	collected_evidence.clear()
	unlocked_deductions.clear()
	unlocked_profiles.clear()
	story_flags = _default_story_flags()
	inventory_updated.emit()

func _default_story_flags() -> Dictionary:
	return {
		"prologue_completed": false,
		"miller_interrogated": false,
		"puzzle_ja_completed": false,
		"warehouse_evidence_hidden": false,
		"colin_sparrow_met": false,
		"garrick_shaw_saved": false,
		"master_key_assembled": false,
		"evid_103_collected": false,
		"evid_104_collected": false,
		"evid_105_collected": false,
		"chapter_1_completed": false,
		"chapter_2_completed": false,
		"chapter_3_completed": false,
		"chapter_4_completed": false,
		"chapter_5_completed": false,
	}

func _ensure_story_flags() -> void:
	var defaults := _default_story_flags()
	for flag in defaults:
		if not story_flags.has(flag):
			story_flags[flag] = defaults[flag]

func add_evidence(evidence_id: String) -> bool:
	if evidence_id.is_empty() or collected_evidence.has(evidence_id):
		return false
	collected_evidence.append(evidence_id)
	inventory_updated.emit()
	return true

func has_evidence(evidence_id: String) -> bool:
	return collected_evidence.has(evidence_id)

func unlock_profile(character_id: String) -> bool:
	var clean_id := character_id.to_lower().strip_edges()
	if clean_id.is_empty() or unlocked_profiles.has(clean_id):
		return false
	unlocked_profiles.append(clean_id)
	profile_unlocked.emit(clean_id)
	inventory_updated.emit()
	return true

func has_profile(character_id: String) -> bool:
	return unlocked_profiles.has(character_id.to_lower().strip_edges())

func unlock_profile_by_name(raw_name: String) -> bool:
	var lower := raw_name.to_lower()
	if lower.contains("graves") or lower.contains("lucian"):
		return unlock_profile("lucian")
	elif lower.contains("prescott") or lower.contains("miles"):
		return unlock_profile("prescott")
	elif lower.contains("sparrow") or lower.contains("colin"):
		return unlock_profile("colin")
	elif lower.contains("garrick") or lower.contains("shaw"):
		return unlock_profile("garrick")
	elif lower.contains("miller"):
		return unlock_profile("miller")
	return false

func remove_evidence(evidence_id: String) -> bool:
	var idx := collected_evidence.find(evidence_id)
	if idx != -1:
		collected_evidence.remove_at(idx)
		inventory_updated.emit()
		return true
	return false

func replace_evidence(remove_ids: Array, new_id: String) -> void:
	for r_id in remove_ids:
		var s_id: String = str(r_id)
		var idx := collected_evidence.find(s_id)
		if idx != -1:
			collected_evidence.remove_at(idx)
	if not collected_evidence.has(new_id):
		collected_evidence.insert(0, new_id)
	inventory_updated.emit()

func get_evidence_display_dict(ev_id: String) -> Dictionary:
	var base_icon := preload("res://icon.svg")
	var custom_icon := base_icon
	if ev_id == "EVID-101" and ResourceLoader.exists("res://assets/wallpaper/Kaset2.png"):
		custom_icon = load("res://assets/wallpaper/Kaset2.png")
	elif ev_id == "EVID-302" and ResourceLoader.exists("res://assets/wallpaper/Kaset.png"):
		custom_icon = load("res://assets/wallpaper/Kaset.png")
	
	if evidence_db.has(ev_id):
		var info: Dictionary = evidence_db[ev_id]
		return {
			"id": ev_id,
			"name": str(info.get("name", ev_id)),
			"qty": "x1",
			"icon": custom_icon,
			"desc": str(info.get("description", "")),
			"note": "[color=#00f0ff][b][KATEGORI][/b][/color]\n" + str(info.get("category", "Bukti")),
			"extra": "[color=#00ff88][b][STATUS BUKTI][/b][/color]\nTersimpan di inventaris forensik. Dapat diuji keterkaitannya di Item Combiner."
		}
	elif KNOWN_ITEMS.has(ev_id):
		var k: Dictionary = KNOWN_ITEMS[ev_id]
		return {
			"id": ev_id,
			"name": str(k.get("name", ev_id)),
			"qty": "x1",
			"icon": custom_icon,
			"desc": str(k.get("desc", "")),
			"note": "[color=#00f0ff][b][LOG ANALISIS][/b][/color]\n" + str(k.get("category", "Investigasi")),
			"extra": "[color=#00ff88][b][CATATAN SINTESIS][/b][/color]\n" + str(k.get("desc", ""))
		}
	else:
		var clean_name := ev_id.replace("_", " ").capitalize()
		return {
			"id": ev_id,
			"name": clean_name,
			"qty": "x1",
			"icon": custom_icon,
			"desc": "Barang bukti penyelidikan.",
			"note": "[color=#00f0ff][b][LOG ANALISIS][/b][/color]\nID: " + ev_id,
			"extra": "[color=#00ff88][b][STATUS BUKTI][/b][/color]\nTersimpan di inventaris."
		}

func unlock_deduction(deduction_id: String, bonus_memory: int = 10) -> void:
	if deduction_id.is_empty() or unlocked_deductions.has(deduction_id):
		return
	unlocked_deductions.append(deduction_id)
	memory_meter += bonus_memory
	deduction_unlocked.emit(deduction_id)

func set_flag(flag: String, value: bool = true) -> void:
	if flag.is_empty():
		return
	story_flags[flag] = value

func has_flag(flag: String) -> bool:
	return bool(story_flags.get(flag, false))

func add_suspicion(amount: int) -> void:
	suspicion_meter += amount

func add_memory(amount: int) -> void:
	memory_meter += amount

func chapter_title(chapter_number: int = -1) -> String:
	var chapter: int = current_chapter if chapter_number < 0 else chapter_number
	return String(CHAPTER_TITLES.get(chapter, "Unknown Chapter"))

func chapter_scene_path(chapter_number: int) -> String:
	return "res://scenes/chapters/chapter_%d/chapter_%d.tscn" % [chapter_number, chapter_number]

func play_cutscene(cutscene_id: String, next_scene_path: String) -> void:
	pending_cutscene_id = cutscene_id
	pending_cutscene_next_scene = next_scene_path
	if not ResourceLoader.exists(CUTSCENE_SCENE_PATH):
		push_error("Cutscene scene not found: " + CUTSCENE_SCENE_PATH)
		if ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
		return
	get_tree().change_scene_to_file(CUTSCENE_SCENE_PATH)

func advance_to_chapter(chapter_number: int, autosave: bool = true) -> void:
	if chapter_number < 0 or chapter_number > TOTAL_CHAPTERS:
		push_error("Invalid chapter number: %d" % chapter_number)
		return
	current_chapter = chapter_number
	if autosave:
		SaveManager.save_game(current_slot)
	chapter_transition_started.emit(chapter_number)
	if chapter_number == 0:
		play_cutscene("prolog", chapter_scene_path(1))
		return
	var target_path: String = chapter_scene_path(chapter_number)
	if not ResourceLoader.exists(target_path):
		push_error("Chapter scene not found: " + target_path)
		return
	play_cutscene("chapter_%d" % chapter_number, target_path)

func resolve_ending(ending_id: int) -> void:
	if not ENDING_TITLES.has(ending_id):
		push_error("Unknown ending id: %d" % ending_id)
		return
	ending_reached.emit(ending_id)
	SaveManager.save_game(current_slot)
	var path: String = ENDING_SCENE_PATH % ending_id
	if not ResourceLoader.exists(path):
		push_error("Ending scene not found: " + path)
		return
	play_cutscene("ending_%d" % ending_id, path)

func is_ending_available(ending_id: int) -> bool:
	match ending_id:
		1, 3:
			return memory_meter >= 70
		2:
			return memory_meter >= 70 and suspicion_meter < 40
		4:
			return suspicion_meter >= 75
		5:
			return memory_meter < 50
	return false

func to_save_dict() -> Dictionary:
	var tree := get_tree()
	if tree:
		var player := tree.get_first_node_in_group("player") as Node2D
		if player and is_instance_valid(player):
			saved_player_position = player.global_position
			has_saved_position = true
		var world := tree.get_first_node_in_group("world") as Node
		if world and is_instance_valid(world) and world.get("current_map_id") != null:
			saved_map_id = str(world.get("current_map_id"))

	return {
		"version": "1.0",
		"save_timestamp": Time.get_datetime_string_from_system(),
		"slot_id": current_slot,
		"game_state": {
			"current_chapter": current_chapter,
			"chapter_title": chapter_title(),
			"has_saved_position": has_saved_position,
			"player_pos_x": saved_player_position.x if has_saved_position else 0.0,
			"player_pos_y": saved_player_position.y if has_saved_position else 0.0,
			"current_map": saved_map_id,
		},
		"psychological_variables": {
			"memory_meter": memory_meter,
			"suspicion_meter": suspicion_meter,
		},
		"inventory": {
			"evidence_collected": collected_evidence.duplicate(),
			"unlocked_deductions": unlocked_deductions.duplicate(),
			"unlocked_profiles": unlocked_profiles.duplicate(),
		},
		"story_flags": story_flags.duplicate(true),
	}

func apply_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	var game_state: Dictionary = data.get("game_state", {})
	var psych: Dictionary = data.get("psychological_variables", {})
	var inventory: Dictionary = data.get("inventory", {})
	var flags: Dictionary = data.get("story_flags", {})

	current_slot = int(data.get("slot_id", current_slot))
	current_chapter = int(game_state.get("current_chapter", 0))
	memory_meter = int(psych.get("memory_meter", 0))
	suspicion_meter = int(psych.get("suspicion_meter", 0))

	has_saved_position = bool(game_state.get("has_saved_position", false))
	if has_saved_position:
		saved_player_position = Vector2(
			float(game_state.get("player_pos_x", 0.0)),
			float(game_state.get("player_pos_y", 0.0))
		)
		saved_map_id = str(game_state.get("current_map", ""))
	else:
		saved_player_position = Vector2.ZERO
		saved_map_id = ""

	_set_string_array(collected_evidence, _migrate_legacy_evidence(inventory.get("evidence_collected", [])))
	_set_string_array(unlocked_deductions, unlocked_deductions if not inventory.has("unlocked_deductions") else inventory.get("unlocked_deductions", []))
	_set_string_array(unlocked_profiles, inventory.get("unlocked_profiles", []))
	story_flags = _default_story_flags()
	for key in flags:
		story_flags[key] = flags[key]
	inventory_updated.emit()
	return true

func _set_string_array(target: Array[String], source: Variant) -> void:
	target.clear()
	if source is Array:
		for item in source:
			target.append(str(item))

func _migrate_legacy_evidence(raw_list: Variant) -> Array[String]:
	var result: Array[String] = []
	var had_legacy := false
	if raw_list is Array:
		for item in raw_list:
			var ev_id := str(item)
			if LEGACY_ITEM_MIGRATION.has(ev_id):
				had_legacy = true
				ev_id = LEGACY_ITEM_MIGRATION[ev_id]
			if not ev_id.is_empty() and not result.has(ev_id):
				result.append(ev_id)
	if had_legacy and not result.has("lencana"):
		result.push_front("lencana")
	return result
