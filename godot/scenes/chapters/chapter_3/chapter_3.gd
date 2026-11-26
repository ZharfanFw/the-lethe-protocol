class_name Chapter3Controller
extends "res://scenes/chapters/chapter_base.gd"

const DialLockUIScript = preload("res://scripts/puzzle/dial_lock_ui.gd")

@onready var world: Node = $World
@onready var sector0_nodes: Node2D = $Sector0Nodes
@onready var undercity_nodes: Node2D = $UndercityNodes

var _dial_ui: CanvasLayer = null
var _door_transitioning: bool = false
var _resetting_player: bool = false

func _ready() -> void:
	super._ready()
	_setup_dial_ui()
	var tree := get_tree()
	if tree and not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	_sync_stage_nodes.call_deferred()

func _setup_dial_ui() -> void:
	_dial_ui = DialLockUIScript.new()
	add_child(_dial_ui)
	if not _dial_ui.is_connected("unlocked", _on_locker_unlocked):
		_dial_ui.connect("unlocked", _on_locker_unlocked)

func _on_node_added(node: Node) -> void:
	if node.name == "Ch3Sector0":
		_on_sector0_loaded.call_deferred()
	elif node.name == "Ch3Undercity":
		_on_undercity_loaded.call_deferred()

func _sync_stage_nodes() -> void:
	var map_id: String = str(world.get("current_map_id")) if world else "ch3_sector0"
	if map_id == "ch3_sector0":
		_on_sector0_loaded()
	elif map_id == "ch3_undercity":
		_on_undercity_loaded()

func _reparent_children_to_map(source_group: Node2D, map_node: Node) -> void:
	if not source_group or not is_instance_valid(source_group) or not map_node:
		return
	for child in source_group.get_children():
		child.reparent(map_node, false)
		if child is Node2D:
			child.visible = true

func _on_sector0_loaded() -> void:
	var map_node: Node = world.get("current_map") if world else null
	if not map_node:
		return
	if undercity_nodes and is_instance_valid(undercity_nodes):
		undercity_nodes.visible = false
		undercity_nodes.process_mode = Node.PROCESS_MODE_DISABLED

	_reparent_children_to_map(sector0_nodes, map_node)
	_configure_sector0_drones(map_node)
	_configure_locker_trigger(map_node)
	_configure_sector0_exit_door(map_node)

	if not GameManager.has_flag("ch3_sector0_intro_done"):
		GameManager.set_flag("ch3_sector0_intro_done", true)
		await get_tree().create_timer(0.3).timeout
		var sec_note := "Ketatnya patroli drone Sektor 0 terasa normal."
		if GameManager.has_flag("ch3_alibi_nervous"):
			sec_note = "Kecurigaan Prescott membuat keamanan Sektor 0 diperketat! Dua drone berpatroli cepat dengan sensor lebar."
		elif GameManager.has_flag("ch3_alibi_aggressive"):
			sec_note = "Otoritasmu membuat Prescott mundur, tetapi dua drone keamanan tetap berpatroli di koridor arsip."
		elif GameManager.has_flag("ch3_alibi_calm"):
			sec_note = "Alibimu yang tenang meredam kecurigaan. Hanya satu drone patroli lambat yang aktif di Sektor 0."
		var locker_hint := "Hindari sorotan merah drone patroli dan buka Laci 884-B dengan kombinasi 1-2-0-9-4 dari deduksimu." if (GameManager.has_evidence("EVID-COMB-202") or GameManager.has_deduction("DEDUKSI-202")) else "Hindari sorotan merah drone patroli. Gabungkan wasiat Colin dan goresan kaca van di Analisis Sintesis [C] untuk memecahkan sandi Laci 884-B."
		UIManager.say("Arthur Vance", [
			"Aku tiba di Arsip Sektor 0. Laci 884-B ada di pojok kanan atas ruangan.",
			sec_note,
			locker_hint
		])

func _configure_sector0_drones(map_node: Node) -> void:
	if not map_node:
		return
	var drone_speed := 58.0
	var sensor_scale := 0.85
	var drone2_enabled := false

	if GameManager.has_flag("ch3_alibi_nervous"):
		drone_speed = 110.0
		sensor_scale = 1.25
		drone2_enabled = true
	elif GameManager.has_flag("ch3_alibi_aggressive"):
		drone_speed = 82.0
		sensor_scale = 1.0
		drone2_enabled = true
	elif GameManager.has_flag("ch3_alibi_calm"):
		drone_speed = 58.0
		sensor_scale = 0.85
		drone2_enabled = false

	var d1 := map_node.get_node_or_null("ScannerDrone1")
	if d1 and d1.has_method("apply_security_profile"):
		d1.apply_security_profile(drone_speed, sensor_scale, true)
		if not d1.is_connected("player_spotted", _on_drone_spotted):
			d1.connect("player_spotted", _on_drone_spotted)

	var d2 := map_node.get_node_or_null("ScannerDrone2")
	if d2 and d2.has_method("apply_security_profile"):
		d2.apply_security_profile(drone_speed, sensor_scale, drone2_enabled)
		if not d2.is_connected("player_spotted", _on_drone_spotted):
			d2.connect("player_spotted", _on_drone_spotted)

func _on_drone_spotted() -> void:
	if _resetting_player or _door_transitioning:
		return
	_resetting_player = true
	var player_node := world.get("player") as Node2D
	if player_node:
		player_node.set("can_move", false)
	UIManager.say("Sistem Keamanan Sektor 0", [
		"PERINGATAN! Gerakan mencurigakan terdeteksi oleh drone patroli! Mengembalikan inspektur ke titik masuk..."
	])
	var dlg := UIManager.get_dialogue_box()
	if dlg and is_instance_valid(dlg):
		await dlg.dialogue_ended
	if player_node and is_instance_valid(player_node):
		player_node.position = Vector2(70, 286)
		player_node.set("can_move", true)
	_resetting_player = false

func _configure_locker_trigger(map_node: Node) -> void:
	var trigger := map_node.get_node_or_null("Locker884BTrigger")
	if trigger and not trigger.is_connected("collected", _on_locker_interacted):
		trigger.connect("collected", _on_locker_interacted)
	if trigger and GameManager.has_flag("sektor0_drawer_unlocked"):
		trigger.set("prompt_text", "[E] Periksa Laci 884-B (Terbuka)")

func _on_locker_interacted(_evidence_id: String = "") -> void:
	if GameManager.has_flag("sektor0_drawer_unlocked"):
		UIManager.say("Arthur Vance", [
			"Laci 884-B sudah terbuka. Ukiran kayu ayah dan kaset mikro sudah kuamankan.",
			"Saatnya menuju pintu akses Undercity di pojok kanan bawah."
		])
		return
	var has_combo_clue: bool = GameManager.has_evidence("EVID-COMB-202") or GameManager.has_deduction("DEDUKSI-202")
	if not has_combo_clue:
		if GameManager.has_evidence("EVID-203") and GameManager.has_evidence("EVID-204"):
			UIManager.say("Arthur Vance", [
				"Laci 884-B ini terkunci 5 digit kombinasi.",
				"Aku menyimpan wasiat sandi Colin dan goresan darah di kaca van—aku harus menggabungkan keduanya lewat Analisis Sintesis [C] untuk memecahkan kode pembukanya!"
			])
		else:
			UIManager.say("Arthur Vance", [
				"Laci 884-B ini terkunci 5 digit kombinasi. Periksa kembali hasil sintesis bukti dari Colin di Catatan [Tab] / Analisis [C]."
			])
		return
	if _dial_ui and _dial_ui.has_method("open_dial"):
		_dial_ui.open_dial()

func _on_locker_unlocked() -> void:
	GameManager.set_flag("sektor0_drawer_unlocked", true)
	GameManager.add_evidence("EVID-301")
	GameManager.add_evidence("EVID-302")
	GameManager.add_memory(20)
	GameManager.unlock_note("sektor_0_laci")
	GameManager.unlock_note("undercity_shaw")

	var map_node: Node = world.get("current_map") if world else null
	if map_node:
		var trigger := map_node.get_node_or_null("Locker884BTrigger")
		if trigger:
			trigger.set("prompt_text", "[E] Periksa Laci 884-B (Terbuka)")

	var combined_lines: Array = []
	var e301 := GameManager.get_interactable_dialogue("EVID-301", 3)
	for line in e301.get("lines", []):
		combined_lines.append(line)
	var e302 := GameManager.get_interactable_dialogue("EVID-302", 3)
	for line in e302.get("lines", []):
		combined_lines.append(line)
	if combined_lines.is_empty():
		combined_lines = [
			"Dial kunci 1-2-0-9-4 membuka Laci 884-B. Ukiran kayu ulin ayah dan kaset mikro rekaman suaraku ada di dalamnya.",
			"Graves mengirim pasukan ke Stasiun Maglev Tua Undercity. Aku harus segera menemui Komandan Garrick Shaw."
		]
	UIManager.say("Arthur Vance", combined_lines)

func _configure_sector0_exit_door(map_node: Node) -> void:
	var exit_door := map_node.get_node_or_null("ExitDoor") as Area2D
	if not exit_door:
		return
	exit_door.set("target_map", "")
	if not exit_door.body_entered.is_connected(_on_sector0_door_touched):
		exit_door.body_entered.connect(_on_sector0_door_touched)

func _on_sector0_door_touched(body: Node2D) -> void:
	if _door_transitioning or not body.is_in_group("player"):
		return
	if not GameManager.has_flag("sektor0_drawer_unlocked"):
		UIManager.say("Arthur Vance", [
			"Aku belum bisa meninggalkan Arsip Sektor 0 sebelum membuka Laci 884-B dengan kombinasi 5 digit."
		])
		return
	_door_transitioning = true
	var player_node := world.get("player") as Node
	if player_node:
		player_node.set("can_move", false)
	UIManager.say("Arthur Vance", [
		"Dengan ukiran kayu dan kaset mikro di saku mantelku, aku menyelinap turun ke terowongan tua menuju Stasiun Maglev Undercity."
	])
	var dlg := UIManager.get_dialogue_box()
	if dlg and is_instance_valid(dlg):
		await dlg.dialogue_ended
	if world and world.has_method("_on_door_entered"):
		await world._on_door_entered("ch3_undercity", Vector2(76, 276))
	_door_transitioning = false

func _on_undercity_loaded() -> void:
	if sector0_nodes and is_instance_valid(sector0_nodes):
		sector0_nodes.visible = false
		sector0_nodes.process_mode = Node.PROCESS_MODE_DISABLED
	if undercity_nodes and is_instance_valid(undercity_nodes):
		undercity_nodes.process_mode = Node.PROCESS_MODE_INHERIT
	var map_node: Node = world.get("current_map") if world else null
	if not map_node:
		return
	_reparent_children_to_map(undercity_nodes, map_node)
	GameManager.unlock_profile("garrick")

	var dlg := UIManager.get_dialogue_box()
	if dlg and not dlg.dialogue_ended.is_connected(_on_undercity_dialogue_ended):
		dlg.dialogue_ended.connect(_on_undercity_dialogue_ended)

	_apply_undercity_moral_state(map_node)

	if not GameManager.has_flag("ch3_undercity_intro_done"):
		GameManager.set_flag("ch3_undercity_intro_done", true)
		await get_tree().create_timer(0.35).timeout
		UIManager.say("Arthur Vance", [
			"Stasiun Maglev Tua Undercity dipenuhi kabut besi dan regu taktis Biro yang bersiap menembak.",
			"Seberangi jembatan tengah rel untuk menemui Komandan Garrick Shaw di peron utara dan tentukan nasibnya."
		])

func _on_undercity_dialogue_ended() -> void:
	if world and str(world.get("current_map_id")) != "ch3_undercity":
		return
	var map_node: Node = world.get("current_map") if world else null
	if map_node:
		_apply_undercity_moral_state(map_node)

func _apply_undercity_moral_state(map_node: Node) -> void:
	var garrick := map_node.get_node_or_null("NPCGarrick")
	var officer := map_node.get_node_or_null("TacticalOfficer")
	var fire_group := map_node.get_node_or_null("PhosphorFireGroup") as Node2D

	if GameManager.has_flag("garrick_shaw_spared"):
		if garrick and is_instance_valid(garrick):
			garrick.visible = false
			garrick.process_mode = Node.PROCESS_MODE_DISABLED
		if officer and is_instance_valid(officer):
			officer.visible = false
			officer.process_mode = Node.PROCESS_MODE_DISABLED
		if fire_group:
			fire_group.visible = false
	elif GameManager.has_flag("garrick_shaw_killed"):
		if garrick and is_instance_valid(garrick):
			garrick.visible = false
			garrick.process_mode = Node.PROCESS_MODE_DISABLED
		if fire_group:
			fire_group.visible = true
		if officer and is_instance_valid(officer):
			officer.set("dialogue_lines", Array([
				"Peron utara sudah dibersihkan dengan granat fosfor, Inspektur. Tidak ada pemberontak yang tersisa.",
				"Silakan kembali ke Menara Putih Lantai 80 untuk melapor kepada Direktur Graves."
			], TYPE_STRING, "", null))
