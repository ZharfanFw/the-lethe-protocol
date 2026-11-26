extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("--- TEST CH2 -> CH3 FULL FLOW START ---")
	var dummy := Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	await get_tree().process_frame

	GameManager.reset_to_new_game(3)
	GameManager.set_flag("ch2_office_intro_done", true)
	GameManager.set_flag("graves_token_issued", true)
	GameManager.set_flag("ch2_van_intro_done", true)

	var err := get_tree().change_scene_to_file("res://scenes/chapters/chapter_2/chapter_2.tscn")
	assert(err == OK, "Failed to load chapter_2.tscn!")
	await get_tree().create_timer(0.4).timeout

	var ch2: Node = get_tree().current_scene
	await ch2.world._on_door_entered("ch2_dock", Vector2(292, 110))
	await get_tree().create_timer(0.3).timeout

	GameManager.add_evidence("EVID-203")
	GameManager.set_flag("colin_sparrow_met", true)
	var dlg: Node = UIManager.get_dialogue_box()
	assert(dlg != null, "World DialogueBox must exist in Chapter 2!")

	var ev204: Node = ch2.world.current_map.get_node_or_null("Evidence204")
	var ev205: Node = ch2.world.current_map.get_node_or_null("Evidence205")
	assert(ev204 != null and ev205 != null, "Evidence204 and Evidence205 must exist!")
	ev204.set("player_in_zone", true)
	ev204.interact()
	await _advance_dialogue(dlg)
	ev205.set("player_in_zone", true)
	ev205.interact()
	await _advance_dialogue(dlg)

	# Wait for CH3_ALIBI, pick option 0 -> triggers _go_to_chapter_3() automatically
	await get_tree().create_timer(0.45).timeout
	assert(dlg.is_active, "Prescott CH3_ALIBI must activate!")
	await _advance_dialogue(dlg)
	assert(GameManager.has_flag("ch3_alibi_cleared"), "ch3_alibi_cleared must be set!")
	assert(GameManager.has_flag("ch3_alibi_calm"), "ch3_alibi_calm must be set for option 0!")

	await get_tree().create_timer(0.8).timeout
	var ch3: Node = get_tree().current_scene
	assert(ch3 != null and ch3.scene_file_path == "res://scenes/chapters/chapter_3/chapter_3.tscn", "Chapter 2 must auto-advance directly into Chapter 3!")
	assert(GameManager.current_chapter == 3, "GameManager.current_chapter must be 3!")
	assert(GameManager.has_flag("chapter_2_completed"), "chapter_2_completed must be set!")
	assert(str(ch3.world.current_map_id) == "ch3_sector0", "Chapter 3 must start in ch3_sector0!")
	assert(ch3.world.current_map != null and ch3.world.current_map.name == "Ch3Sector0", "Chapter 3 map node must be Ch3Sector0!")

	await _advance_dialogue(UIManager.get_dialogue_box())

	# 1. Interacting with Locker 884-B BEFORE combining EVID-203 + EVID-204 must prompt synthesis hint instead of opening DialLockUI
	var locker: Node = ch3.world.current_map.get_node_or_null("Locker884BTrigger")
	assert(locker != null, "Locker884BTrigger must exist in Ch3Sector0!")
	locker.set("player_in_zone", true)
	locker.interact()
	await get_tree().create_timer(0.1).timeout
	assert(not UIManager.is_modal_overlay_open(), "DialLockUI must stay locked before combining EVID-203 + EVID-204!")
	var block_dlg: Node = UIManager.get_dialogue_box()
	assert(block_dlg != null and block_dlg.is_active, "Locker must prompt synthesis hint when EVID-COMB-202 is missing!")
	await _advance_dialogue(block_dlg)

	# 2. Synthesize EVID-203 + EVID-204 in ItemCombiner -> reveals 1-2-0-9-4
	var comb: Node = ch3.world.get_node_or_null("ItemCombiner")
	assert(comb != null, "ItemCombiner must exist in Chapter3 World!")
	comb._sync_inventory_from_game_manager()
	var idx_203 := -1
	var idx_204 := -1
	for i in range(comb.inventory.size()):
		if str(comb.inventory[i].get("id", "")) == "EVID-203":
			idx_203 = i
		elif str(comb.inventory[i].get("id", "")) == "EVID-204":
			idx_204 = i
	assert(idx_203 != -1 and idx_204 != -1, "EVID-203 and EVID-204 must both be in ItemCombiner!")
	comb.idx = idx_203
	comb._refresh_ui()
	assert(comb.status_text.text.contains("12-09-4"), "ItemCombiner highlight must show clue_link for EVID-203!")
	comb._toggle_item_slot(idx_203)
	comb._toggle_item_slot(idx_204)
	comb._on_combine_pressed()
	assert(GameManager.has_evidence("EVID-COMB-202"), "EVID-COMB-202 must be crafted!")
	assert(comb.status_text.text.contains("1-2-0-9-4"), "EVID-COMB-202 synthesis result must reveal 1-2-0-9-4!")

	var nb: Node = ch3.world.get_node_or_null("DetectiveNotebook")
	assert(nb != null, "DetectiveNotebook must exist!")
	nb._switch_tab(1)
	var found_code_note := false
	for item in nb.items:
		if str(item.get("name", "")).contains("1-2-0-9-4") and str(item.get("desc", "")).contains("1-2-0-9-4"):
			found_code_note = true
	assert(found_code_note, "Notebook Catatan tab DEDUKSI-202 must display 1-2-0-9-4 clue!")

	# 3. Now Locker 884-B opens DialLockUI cleanly
	locker.interact()
	await get_tree().create_timer(0.1).timeout
	assert(UIManager.is_modal_overlay_open(), "DialLockUI must open once EVID-COMB-202 is crafted!")
	assert(UIManager._is_any_overlay_open(), "PauseMenu must be blocked while DialLockUI is open!")
	assert(ch3.world.is_ui_blocking(), "World must block Notebook/Combiner while DialLockUI is open!")

	var dial_ui: Node = ch3.get("_dial_ui")
	assert(dial_ui != null, "DialLockUI must exist on Chapter3Controller!")
	dial_ui.set("_digits", Array([1, 2, 0, 9, 4], TYPE_INT, "", null))
	dial_ui._submit_code()
	await get_tree().create_timer(0.05).timeout
	assert(bool(dial_ui.get("_in_cutscene")), "DialLockUI must enter locker cutscene on code 12094!")
	dial_ui._advance_cutscene()
	dial_ui._advance_cutscene()
	await get_tree().create_timer(0.1).timeout

	assert(not UIManager.is_modal_overlay_open(), "DialLockUI must close after cutscene!")
	assert(GameManager.has_flag("sektor0_drawer_unlocked"), "sektor0_drawer_unlocked must be set!")
	assert(GameManager.has_evidence("EVID-301") and GameManager.has_evidence("EVID-302"), "EVID-301 and EVID-302 must be granted!")
	assert(GameManager.has_note("sektor_0_laci") and GameManager.has_note("undercity_shaw"), "Chapter 3 notes must unlock!")
	await _advance_dialogue(UIManager.get_dialogue_box())

	# Transition to Undercity
	ch3._on_sector0_door_touched(ch3.world.player)
	await get_tree().create_timer(0.1).timeout
	await _advance_dialogue(UIManager.get_dialogue_box())
	await get_tree().create_timer(0.55).timeout

	assert(str(ch3.world.current_map_id) == "ch3_undercity", "Sector 0 ExitDoor must load ch3_undercity!")
	assert(GameManager.has_profile("garrick"), "Garrick profile must unlock in Undercity!")
	await _advance_dialogue(UIManager.get_dialogue_box())

	# Talk to Garrick Shaw -> choose Spare (tests dialogue_box inline cutscene_image too!)
	var garrick: Node = ch3.world.current_map.get_node_or_null("NPCGarrick")
	assert(garrick != null, "NPCGarrick must exist in Ch3Undercity!")
	garrick.set("player_ref", ch3.world.player)
	garrick.set("player_in_range", true)
	var ev_e := InputEventKey.new()
	ev_e.pressed = true
	ev_e.keycode = KEY_E
	garrick._unhandled_input(ev_e)
	await get_tree().create_timer(0.1).timeout

	var ch3_dlg: Node = UIManager.get_dialogue_box()
	assert(ch3_dlg != null and ch3_dlg.is_active, "Garrick dialogue must start!")
	await _advance_dialogue(ch3_dlg)
	assert(GameManager.has_flag("garrick_shaw_spared") and GameManager.has_flag("garrick_shaw_saved"), "Garrick moral resolution flags must be set!")
	assert(GameManager.has_evidence("EVID-303"), "EVID-303 must be awarded!")

	SaveManager.delete_save(3)
	print("--- TEST CH2 -> CH3 FULL FLOW PASS ---")
	get_tree().quit()

func _advance_dialogue(dlg: Node) -> void:
	while dlg and dlg.is_active:
		if dlg.get("showing_cutscene_image") == true:
			var ev := InputEventKey.new()
			ev.pressed = true
			ev.keycode = KEY_SPACE
			dlg._unhandled_input(ev)
		elif dlg.waiting_for_choice:
			dlg._on_choice_clicked(0, "")
		elif dlg.is_typing:
			dlg._finish_typing_immediately()
		else:
			dlg._show_next_line()
		await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(0.15).timeout
