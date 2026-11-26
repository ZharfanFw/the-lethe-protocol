extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("--- TEST CH2 COLIN INTERROGATION CUTSCENE START ---")
	var dummy := Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	await get_tree().process_frame

	GameManager.reset_to_new_game(3)
	GameManager.set_flag("ch2_office_intro_done", true)
	GameManager.set_flag("graves_token_issued", true)
	var err := get_tree().change_scene_to_file("res://scenes/chapters/chapter_2/chapter_2.tscn")
	assert(err == OK, "Failed to load chapter_2.tscn!")
	await get_tree().create_timer(0.4).timeout

	var ch2: Node = get_tree().current_scene
	assert(ch2 != null and ch2.name == "Chapter2", "Current scene must be Chapter2!")
	await ch2.world._on_door_entered("ch2_dock", Vector2(292, 110))
	await get_tree().create_timer(0.5).timeout

	assert(str(ch2.world.current_map_id) == "ch2_dock", "World must be on ch2_dock!")
	var dlg: Node = UIManager.get_dialogue_box()
	assert(dlg != null, "World DialogueBox must exist!")
	await _advance_dialogue(dlg)

	var colin: Node = ch2.world.current_map.get_node_or_null("NPCColin")
	assert(colin != null, "NPCColin must exist in Ch2TacticalVan!")
	assert(str(colin.get("quest_cutscene_id")) == "chapter_2", "NPCColin must use chapter_2 quest cutscene!")

	colin.set("player_ref", ch2.world.player)
	colin.set("player_in_range", true)
	var ev_e := InputEventKey.new()
	ev_e.pressed = true
	ev_e.keycode = KEY_E
	colin._unhandled_input(ev_e)

	await get_tree().create_timer(0.85).timeout
	assert(UIManager.is_cutscene_overlay_active(), "Overlay cutscene must activate on Colin interrogation!")
	assert(ch2.world.is_ui_blocking(), "World UI must report blocked during cutscene overlay!")
	assert(UIManager._is_any_overlay_open(), "UIManager must block PauseMenu during cutscene overlay!")
	assert(ch2.world.player.can_move == false, "Player movement must be locked during cutscene overlay!")

	var overlay: Node = ch2.find_child("CutsceneOverlay", true, false)
	assert(overlay != null, "CutsceneOverlay CanvasLayer must exist under Chapter2!")
	var cutscene: Node = overlay.get_child(0)
	assert(cutscene != null and str(cutscene.get("_active_id")) == "chapter_2", "Overlay cutscene must play chapter_2!")
	var slides: Array = cutscene.get("_active_slides")
	assert(slides.size() == 2, "Colin cutscene must have 2 slides (interrogation + neurotoxin death)!")
	assert(str(slides[0].get("image", "")) == "res://assets/cutscenes/chapter2-slide2.jpg", "Slide 1 must be Colin interrogation image!")
	assert(str(slides[1].get("image", "")) == "res://assets/cutscenes/chapter2-slide3.jpg", "Slide 2 must be Colin neurotoxin death image!")
	assert(UIManager.get_dialogue_box() == dlg, "World DialogueBox lookup must stay distinct from CutsceneDialogueBox!")

	# Advance from Slide 1 to Slide 2, then press ESC to finish/skip cleanly
	cutscene._advance_slide()
	await get_tree().create_timer(0.1).timeout
	assert(int(cutscene.get("_index")) == 1, "Cutscene must advance to Slide 2!")
	var ev_esc := InputEventAction.new()
	ev_esc.action = "ui_cancel"
	ev_esc.pressed = true
	cutscene._unhandled_input(ev_esc)
	await get_tree().create_timer(0.9).timeout

	assert(not UIManager.is_cutscene_overlay_active(), "Overlay cutscene must close cleanly!")
	assert(not UIManager.is_paused(), "ESC skipping overlay cutscene must NOT open PauseMenu!")
	assert(str(ch2.world.current_map_id) == "ch2_dock", "Player must stay in Ch2TacticalVan after cutscene!")
	assert(ch2.world.player.can_move == true, "Player movement must be restored after cutscene!")
	assert(GameManager.has_flag("colin_sparrow_met"), "colin_sparrow_met flag must be set!")
	assert(GameManager.has_evidence("EVID-203"), "EVID-203 must be collected!")
	assert(GameManager.has_note("identitas_thur"), "identitas_thur note must be unlocked!")
	assert(GameManager.memory_meter >= 35, "Colin memory bonus must be granted!")

	# Second interaction with Colin uses dead body description dialogue (not overlay cutscene)
	colin._unhandled_input(ev_e)
	await get_tree().create_timer(0.15).timeout
	assert(not UIManager.is_cutscene_overlay_active(), "Second interaction with Colin must not replay cutscene!")
	assert(dlg.is_active, "Second interaction must open standard inspection dialogue!")
	await _advance_dialogue(dlg)

	# Collect remaining van clues -> Prescott CH3_ALIBI must trigger normally
	var ev204: Node = ch2.world.current_map.get_node_or_null("Evidence204")
	var ev205: Node = ch2.world.current_map.get_node_or_null("Evidence205")
	assert(ev204 != null and ev205 != null, "Evidence204 and Evidence205 must exist in Ch2TacticalVan!")
	ev204.set("player_in_zone", true)
	ev204.interact()
	await _advance_dialogue(dlg)
	ev205.set("player_in_zone", true)
	ev205.interact()
	await _advance_dialogue(dlg)

	await get_tree().create_timer(0.45).timeout
	assert(dlg.is_active, "Prescott CH3_ALIBI encounter must trigger after van evidence!")
	await _advance_dialogue(dlg)
	assert(GameManager.has_flag("ch3_alibi_cleared"), "Prescott CH3_ALIBI must resolve cleanly!")

	SaveManager.delete_save(3)
	print("--- TEST CH2 COLIN INTERROGATION CUTSCENE PASS ---")
	get_tree().quit()

func _advance_dialogue(dlg: Node) -> void:
	while dlg and dlg.is_active:
		if dlg.waiting_for_choice:
			dlg._on_choice_clicked(0, "")
		elif dlg.is_typing:
			dlg._finish_typing_immediately()
		else:
			dlg._show_next_line()
		await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(0.15).timeout
