class_name Chapter1Controller
extends "res://scenes/chapters/chapter_base.gd"

@onready var world: Node = $World

var _waking_triggered: bool = false
var _prescott_intro_triggered: bool = false
var _combiner_tutorial_triggered: bool = false

func _ready() -> void:
	super._ready()
	if not GameManager.inventory_updated.is_connected(_on_inventory_updated):
		GameManager.inventory_updated.connect(_on_inventory_updated)
	_setup_map_listener()
	_trigger_waking_dialogue.call_deferred()

func _setup_map_listener() -> void:
	var tree := get_tree()
	if tree and not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.name == "SubSector4":
		_on_subsector4_loaded.call_deferred()

func _trigger_waking_dialogue() -> void:
	if _waking_triggered:
		return
	if GameManager.has_flag("ch1_waking_done"):
		return
	
	# Only trigger waking dialogue if player is in apartment
	if world and world.get("current_map_id") == "ch1_apartment":
		_waking_triggered = true
		GameManager.set_flag("ch1_waking_done", true)
		await get_tree().create_timer(0.4).timeout
		var entry := GameManager.get_interactable_dialogue("CH1_WAKING")
		if not entry.is_empty():
			var note_id: String = str(entry.get("note", ""))
			if not note_id.is_empty():
				GameManager.unlock_note(note_id)
			var speaker: String = str(entry.get("speaker", "Arthur Vance"))
			var lines: Array = entry.get("lines", [])
			UIManager.say(speaker, lines)

func _on_subsector4_loaded() -> void:
	if _prescott_intro_triggered or GameManager.has_flag("prescott_intro_done"):
		return
	_prescott_intro_triggered = true
	GameManager.set_flag("prescott_intro_done", true)
	GameManager.unlock_profile("prescott")
	await get_tree().create_timer(0.4).timeout
	var entry := GameManager.get_interactable_dialogue("CH1_PRESCOTT_INTRO")
	if not entry.is_empty():
		var note_id: String = str(entry.get("note", ""))
		if not note_id.is_empty():
			GameManager.unlock_note(note_id)
		var speaker: String = str(entry.get("speaker", "Detective Miles Prescott"))
		var lines: Array = entry.get("lines", [])
		UIManager.say(speaker, lines)

func _on_inventory_updated() -> void:
	_check_synthesis_tutorial()

func _check_synthesis_tutorial() -> void:
	if _combiner_tutorial_triggered or GameManager.has_flag("combiner_tutorial_done"):
		return
	var has_miller: bool = GameManager.has_evidence("EVID-102") or GameManager.has_flag("miller_interrogated")
	var has_warehouse_clue: bool = GameManager.has_evidence("EVID-103") or GameManager.has_evidence("EVID-104") or GameManager.has_evidence("EVID-105")
	if has_miller and has_warehouse_clue:
		_combiner_tutorial_triggered = true
		GameManager.set_flag("combiner_tutorial_done", true)
		await get_tree().create_timer(0.1).timeout
		var dlg := UIManager.get_dialogue_box()
		if dlg and dlg.is_active:
			await dlg.dialogue_ended
		await get_tree().create_timer(0.3).timeout
		var entry := GameManager.get_interactable_dialogue("CH1_SYNTHESIS_TUTORIAL")
		if not entry.is_empty():
			var speaker: String = str(entry.get("speaker", "Arthur Vance"))
			var lines: Array = entry.get("lines", [])
			UIManager.say(speaker, lines)
