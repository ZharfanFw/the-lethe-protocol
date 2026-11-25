class_name Chapter2Controller
extends "res://scenes/chapters/chapter_base.gd"

@onready var world: Node = $World
@onready var office_nodes: Node2D = $OfficeNodes
@onready var van_nodes: Node2D = $VanNodes

var _current_exit_door: Area2D = null
var _door_transitioning: bool = false
var _prescott_van_triggered: bool = false

func _ready() -> void:
	super._ready()
	var tree := get_tree()
	if tree and not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	_sync_stage_nodes.call_deferred()

func _on_node_added(node: Node) -> void:
	if node.name == "IndoorOffice":
		_on_office_loaded.call_deferred()
	elif node.name == "Ch2TacticalVan":
		_on_van_loaded.call_deferred()

func _sync_stage_nodes() -> void:
	var map_id: String = str(world.get("current_map_id")) if world else "indoor"
	if map_id == "indoor":
		_on_office_loaded()
	elif map_id == "ch2_dock":
		_on_van_loaded()

func _reparent_children_to_map(source_group: Node2D, map_node: Node) -> void:
	if not source_group or not is_instance_valid(source_group) or not map_node:
		return
	for child in source_group.get_children():
		child.reparent(map_node, false)
		if child is Node2D:
			child.visible = true

func _on_office_loaded() -> void:
	var map_node: Node = world.get("current_map") if world else null
	_reparent_children_to_map(office_nodes, map_node)
	GameManager.unlock_profile("lucian")
	_configure_office_exit_door(map_node)
	_refresh_graves_post_lines(map_node)

	var dlg := UIManager.get_dialogue_box()
	if dlg and not dlg.dialogue_ended.is_connected(_on_office_dialogue_ended):
		dlg.dialogue_ended.connect(_on_office_dialogue_ended)

	if not GameManager.has_flag("ch2_office_intro_done"):
		GameManager.set_flag("ch2_office_intro_done", true)
		await get_tree().create_timer(0.35).timeout
		UIManager.say("Direktur Lucian Graves", [
			"Masuklah, Inspektur Vance. Mendekatlah ke meja kerjaku dan periksa proyeksi peretasan Deep Vault di Terminal Kuantum.",
			"Ada anomali kode yang harus kau lihat dengan matamu sendiri sebelum memimpin penyerbuan."
		])

func _on_office_dialogue_ended() -> void:
	if world and str(world.get("current_map_id")) != "indoor":
		return
	var map_node: Node = world.get("current_map") if world else null
	_refresh_graves_post_lines(map_node)

func _refresh_graves_post_lines(map_node: Node) -> void:
	if not map_node:
		return
	var lucian := map_node.get_node_or_null("NPCLucian")
	if not lucian or not is_instance_valid(lucian):
		return
	if GameManager.has_flag("graves_respon_membela"):
		lucian.set("npc_id", "")
		lucian.set("dialogue_lines", Array([
			"Jangan ulangi pertanyaan yang nyaris membenarkan teroris seperti tadi, Inspektur.",
			"Segera pimpin pasukan elit ke Dok Whitehall Bawah dan bawa Sparrow ke van komando taktis."
		], TYPE_STRING, "", null))
	elif GameManager.has_flag("graves_respon_dingin"):
		lucian.set("npc_id", "")
		lucian.set("dialogue_lines", Array([
			"Analisis yang tajam seperti biasa, Vance. Jangan biarkan peretas jalanan itu mempermalukan biro kita.",
			"Segera pimpin pasukan elit ke Dok Whitehall Bawah dan bawa dia hidup-hidup ke van komando taktis."
		], TYPE_STRING, "", null))

func _configure_office_exit_door(map_node: Node) -> void:
	if not map_node:
		return
	var exit_door := map_node.get_node_or_null("ExitDoor") as Area2D
	if not exit_door:
		return
	_current_exit_door = exit_door
	exit_door.set("target_map", "")
	if not exit_door.body_entered.is_connected(_on_office_door_touched):
		exit_door.body_entered.connect(_on_office_door_touched)

func _on_office_door_touched(body: Node2D) -> void:
	if _door_transitioning or not body.is_in_group("player"):
		return
	if not GameManager.has_flag("graves_token_issued"):
		UIManager.say("Arthur Vance", [
			"Aku belum bisa meninggalkan Lantai 80 sebelum memeriksa Terminal Kuantum dan menerima token penyerbuan dari Direktur Graves."
		])
		return
	_door_transitioning = true
	var player_node := world.get("player") as Node
	if player_node:
		player_node.set("can_move", false)
	UIManager.say("Arthur Vance", [
		"Pasukan elit Unit V-09 menyisir dok kargo Whitehall Bawah di bawah guyuran hujan asam.",
		"Setelah pengepungan singkat, buronan 'Sparrow' berhasil dibekuk dan diborgol ke dalam bilik kedap suara Van Komando Taktis."
	])
	var dlg := UIManager.get_dialogue_box()
	if dlg and is_instance_valid(dlg):
		await dlg.dialogue_ended
	if world and world.has_method("_on_door_entered"):
		await world._on_door_entered("ch2_dock", Vector2(320, 275))
	_door_transitioning = false

func _on_van_loaded() -> void:
	if office_nodes and is_instance_valid(office_nodes):
		office_nodes.visible = false
		office_nodes.process_mode = Node.PROCESS_MODE_DISABLED
	var map_node: Node = world.get("current_map") if world else null
	_reparent_children_to_map(van_nodes, map_node)
	GameManager.unlock_profile("colin")

	var prescott := map_node.get_node_or_null("NPCPrescott") as Node2D if map_node else null
	if prescott:
		if GameManager.has_flag("ch3_alibi_cleared"):
			prescott.visible = true
			prescott.process_mode = Node.PROCESS_MODE_INHERIT
			prescott.position = Vector2(264, 282)
			_refresh_prescott_van_lines(prescott)
		else:
			prescott.visible = false
			prescott.process_mode = Node.PROCESS_MODE_DISABLED

	var dlg := UIManager.get_dialogue_box()
	if dlg and not dlg.dialogue_ended.is_connected(_on_van_dialogue_ended):
		dlg.dialogue_ended.connect(_on_van_dialogue_ended)

	if not GameManager.has_flag("ch2_van_intro_done"):
		GameManager.set_flag("ch2_van_intro_done", true)
		await get_tree().create_timer(0.35).timeout
		UIManager.say("Detective Miles Prescott", [
			"Pintu baja van kukunci dari luar, Vance. Di luar hanya ada gemercik air laut dan tim taktis yang berjaga.",
			"Kau punya waktu sepuluh menit di bilik kedap suara ini untuk menginterogasi Sparrow."
		])

func _on_van_dialogue_ended() -> void:
	if not world or str(world.get("current_map_id")) != "ch2_dock":
		return
	if _prescott_van_triggered or GameManager.has_flag("ch3_alibi_cleared"):
		return
	var all_colin_done: bool = (
		GameManager.has_flag("colin_sparrow_met")
		and GameManager.has_flag("evid_204_collected")
		and GameManager.has_flag("evid_205_collected")
	)
	if not all_colin_done:
		return
	_prescott_van_triggered = true
	_trigger_prescott_van_entry.call_deferred()

func _trigger_prescott_van_entry() -> void:
	var map_node: Node = world.get("current_map") if world else null
	var prescott := map_node.get_node_or_null("NPCPrescott") as Node2D if map_node else null
	if prescott:
		prescott.visible = true
		prescott.process_mode = Node.PROCESS_MODE_INHERIT
		prescott.position = Vector2(320, 282)
		if prescott.has_method("_play_direction"):
			prescott._play_direction(&"idle_up", &"walk_up")
	GameManager.unlock_profile("prescott")

	await get_tree().create_timer(0.25).timeout
	var entry := GameManager.get_interactable_dialogue("CH3_ALIBI")
	if not entry.is_empty():
		var speaker: String = str(entry.get("speaker", "Detective Miles Prescott"))
		var lines: Array = entry.get("lines", [])
		UIManager.say(speaker, lines)
		var dlg := UIManager.get_dialogue_box()
		if dlg and is_instance_valid(dlg):
			await dlg.dialogue_ended

	if prescott and is_instance_valid(prescott):
		prescott.position = Vector2(264, 282)
		_refresh_prescott_van_lines(prescott)

func _refresh_prescott_van_lines(prescott: Node) -> void:
	if GameManager.has_flag("ch3_alibi_aggressive"):
		prescott.set("dialogue_lines", Array([
			"Jangan terlalu tegang, Vance. Surat Perintah Eksekutif Graves memang memberimu wewenang penuh.",
			"Jalan keluar ke Sektor 0 sudah terbuka. Aku tidak akan menghalangimu... untuk sekarang."
		], TYPE_STRING, "", null))
	elif GameManager.has_flag("ch3_alibi_nervous"):
		prescott.set("dialogue_lines", Array([
			"Pupilmu masih melebar, Vance. Apa yang sebenarnya dikatakan buronan itu sebelum tewas?",
			"Sebaiknya segera menuju Arsip Sektor 0. Aku terus memantau log biometrikmu."
		], TYPE_STRING, "", null))
	elif GameManager.has_flag("ch3_alibi_calm"):
		prescott.set("dialogue_lines", Array([
			"Tim forensik sudah mengamankan van taktis. Penangananmu cukup dingin dan bersih.",
			"Pintu van terbuka—lanjutkan pemeriksaan ke Arsip Sektor 0."
		], TYPE_STRING, "", null))
