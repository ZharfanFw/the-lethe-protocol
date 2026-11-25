extends Node

func _ready() -> void:
	print("--- TEST INTERACTION & INVENTORY SYNC START ---")
	GameManager.reset_to_new_game(1)
	
	var ch1_scene: PackedScene = load("res://scenes/chapters/chapter_1/chapter_1.tscn")
	var ch1 = ch1_scene.instantiate()
	add_child(ch1)
	
	for i in range(10):
		await get_tree().physics_frame
	
	var player = ch1.find_child("Player", true, false)
	var dlg = UIManager.get_dialogue_box()
	var notebook = ch1.find_child("DetectiveNotebook", true, false)
	var combiner = ch1.find_child("ItemCombiner", true, false)
	
	print("Player: ", player)
	print("DialogueBox: ", dlg)
	print("Notebook: ", notebook)
	print("Combiner: ", combiner)
	
	# 0. Verify Apartment start & elements
	var tonic_mirror = ch1.find_child("TonicMirror", true, false)
	var wardrobe = ch1.find_child("DeskInteractable", true, false)
	assert(tonic_mirror != null, "TonicMirror must exist in apartment!")
	assert(wardrobe != null, "DeskInteractable must exist in apartment!")
	print("Apartment verified: TonicMirror and DeskInteractable present.")

	# Transition from Apartment to Sub-Sector 4
	var world = ch1.find_child("World", true, false)
	world._load_map("ch1_subsector4", Vector2(480, 320))
	for i in range(15):
		await get_tree().physics_frame
	player = ch1.find_child("Player", true, false)

	# 1. Verify Chapter 1 only has Miller & Prescott (no Lucian/Garrick/Edward)
	assert(ch1.find_child("NPCLucian", true, false) == null, "NPCLucian must be removed from Chapter 1!")
	assert(ch1.find_child("NPCMilesPrescott", true, false) != null, "NPCMilesPrescott must exist in Chapter 1!")
	var miller = ch1.find_child("NPCMiller", true, false)
	assert(miller != null, "NPCMiller must exist in Chapter 1!")
	
	# Wait for Prescott intro timer to start, then dismiss it
	await get_tree().create_timer(0.5).timeout
	while dlg.is_active:
		if dlg.waiting_for_choice:
			dlg._on_choice_clicked(0, "")
		else:
			dlg._show_next_line()
		await get_tree().create_timer(0.04).timeout
	await get_tree().create_timer(0.1).timeout
	
	player.global_position = miller.global_position
	for i in range(10):
		await get_tree().physics_frame
		
	print("Miller player_in_range: ", miller.player_in_range)
	print("Miller prompt_label text: ", miller.prompt_label.text)
	
	var ev_space = InputEventKey.new()
	ev_space.pressed = true
	ev_space.keycode = KEY_SPACE
	ev_space.physical_keycode = KEY_SPACE
	miller._unhandled_input(ev_space)
	print("After KEY_SPACE on Miller: is_talking=", miller.is_talking, " dlg_active=", dlg.is_active)
	assert(not miller.is_talking, "Spacebar must NOT trigger NPC dialogue!")
	
	# 2. Test KEY_E DOES interact with NPCMiller
	var ev_e = InputEventKey.new()
	ev_e.pressed = true
	ev_e.keycode = KEY_E
	ev_e.physical_keycode = KEY_E
	miller._unhandled_input(ev_e)
	print("After KEY_E on Miller: is_talking=", miller.is_talking, " dlg_active=", dlg.is_active)
	assert(miller.is_talking, "Key E must trigger NPC dialogue!")
	while dlg.is_active:
		dlg._show_next_line()
		await get_tree().process_frame
	print("Dialogue closed, player.can_move: ", player.can_move)

	# 3. Test pickup Evidence103 with KEY_E
	var evid103 = ch1.get_node_or_null("Evidence103")
	player.global_position = evid103.global_position
	for i in range(10):
		await get_tree().physics_frame
		
	print("Evidence103 prompt: ", evid103._prompt.text)
	evid103._unhandled_input(ev_e)
	print("After picking Evidence103 -> collected_evidence has EVID-103: ", GameManager.has_evidence("EVID-103"))
	assert(GameManager.has_evidence("EVID-103"), "EVID-103 must be in collected_evidence!")
	
	while dlg.is_active:
		dlg._show_next_line()
		await get_tree().process_frame

	# 4. Test pickup Evidence105 with KEY_E
	var evid105 = ch1.get_node_or_null("Evidence105")
	player.global_position = evid105.global_position
	for i in range(10):
		await get_tree().physics_frame
		
	evid105._unhandled_input(ev_e)
	print("After picking Evidence105 -> collected_evidence has EVID-105: ", GameManager.has_evidence("EVID-105"))
	assert(GameManager.has_evidence("EVID-105"), "EVID-105 must be in collected_evidence!")
	
	while dlg.is_active:
		dlg._show_next_line()
		await get_tree().process_frame

	# 5. Check DetectiveNotebook contains both new evidence items
	notebook.open_notebook()
	notebook._switch_tab(0) # BUKTI tab
	var names_in_notebook: Array[String] = []
	for it in notebook.items:
		names_in_notebook.append(it["name"])
	print("Notebook Tab Bukti items: ", names_in_notebook)
	assert("Puntung Kretek Black Clove" in names_in_notebook, "Puntung Kretek must appear in notebook!")
	assert("Peta Rute Dok & Catatan Thur" in names_in_notebook, "Peta Rute Dok must appear in notebook!")
	notebook.close_notebook()

	# 6. Check ItemCombiner has both items
	combiner.open_combiner()
	var ids_in_combiner: Array[String] = []
	for it in combiner.inventory:
		ids_in_combiner.append(it["id"])
	print("Combiner inventory IDs: ", ids_in_combiner)
	assert("EVID-103" in ids_in_combiner, "EVID-103 must appear in combiner!")
	assert("EVID-105" in ids_in_combiner, "EVID-105 must appear in combiner!")

	# 7. Perform combine on EVID-103 and EVID-105 in ItemCombiner
	var idx_103 = ids_in_combiner.find("EVID-103")
	var idx_105 = ids_in_combiner.find("EVID-105")
	combiner.slot_a_idx = idx_103
	combiner.slot_b_idx = idx_105
	combiner._on_combine_pressed()
	
	print("After combine:")
	print("GameManager has EVID-103: ", GameManager.has_evidence("EVID-103"))
	print("GameManager has EVID-105: ", GameManager.has_evidence("EVID-105"))
	print("GameManager has EVID-COMB-101: ", GameManager.has_evidence("EVID-COMB-101"))
	print("GameManager flag evidence_combined: ", GameManager.has_flag("evidence_combined"))
	
	assert(not GameManager.has_evidence("EVID-103"), "EVID-103 must be removed after successful combine!")
	assert(not GameManager.has_evidence("EVID-105"), "EVID-105 must be removed after successful combine!")
	assert(GameManager.has_evidence("EVID-COMB-101"), "EVID-COMB-101 must be added after combine!")

	# 8. Verify DetectiveNotebook updated and old items are gone
	notebook.open_notebook()
	notebook._switch_tab(0)
	var updated_notebook_names: Array[String] = []
	for it in notebook.items:
		updated_notebook_names.append(it["name"])
	print("Updated Notebook Tab Bukti items: ", updated_notebook_names)
	assert(not ("Puntung Kretek Black Clove" in updated_notebook_names), "Old evidence must be replaced in notebook!")
	assert("Rute Selundupan Colin" in updated_notebook_names, "Combined evidence must appear in notebook!")
	notebook.close_notebook()
	combiner.close_combiner()

	print("--- TEST INTERACTION & INVENTORY SYNC PASS ---")
	get_tree().quit()
