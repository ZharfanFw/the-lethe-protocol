class_name Chapter3Controller
extends "res://scenes/chapters/chapter_base.gd"

@onready var world: Node = $World
@onready var prescott_npc: Node = $NPCPrescott

func _ready() -> void:
	super._ready()
	_sync_prescott_to_map.call_deferred()
	_trigger_alibi_encounter.call_deferred()

func _sync_prescott_to_map() -> void:
	if not prescott_npc or not is_instance_valid(prescott_npc):
		return
	var map_node: Node = world.get("current_map") if world else null
	if map_node:
		prescott_npc.reparent(map_node, false)
	_refresh_prescott_lines()

func _trigger_alibi_encounter() -> void:
	if GameManager.has_flag("ch3_alibi_cleared"):
		return
	GameManager.unlock_profile("prescott")
	await get_tree().create_timer(0.35).timeout
	var entry := GameManager.get_interactable_dialogue("CH3_ALIBI")
	if not entry.is_empty():
		var speaker: String = str(entry.get("speaker", "Detective Miles Prescott"))
		var lines: Array = entry.get("lines", [])
		UIManager.say(speaker, lines)
		var dlg := UIManager.get_dialogue_box()
		if dlg and is_instance_valid(dlg):
			await dlg.dialogue_ended
		_refresh_prescott_lines()

func _refresh_prescott_lines() -> void:
	if not prescott_npc or not is_instance_valid(prescott_npc):
		return
	if GameManager.has_flag("ch3_alibi_aggressive"):
		prescott_npc.set("dialogue_lines", Array([
			"Jangan terlalu tegang, Vance. Surat Perintah Eksekutif Graves memang memberimu wewenang penuh.",
			"Selesaikan urusanmu di Sektor 0. Aku tidak akan menghalangi... untuk sekarang."
		], TYPE_STRING, "", null))
	elif GameManager.has_flag("ch3_alibi_nervous"):
		prescott_npc.set("dialogue_lines", Array([
			"Pupilmu masih melebar, Vance. Apa yang sebenarnya dikatakan buronan itu sebelum tewas?",
			"Sebaiknya segera kembali ke tugasmu di Sektor 0. Aku terus memantau log biometrikmu."
		], TYPE_STRING, "", null))
	elif GameManager.has_flag("ch3_alibi_calm"):
		prescott_npc.set("dialogue_lines", Array([
			"Tim forensik sudah mengamankan van taktis. Penangananmu cukup dingin dan bersih.",
			"Lanjutkan pemeriksaan ke Arsip Sektor 0 sesuai protokol."
		], TYPE_STRING, "", null))
