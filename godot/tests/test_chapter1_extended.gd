extends Node

func _ready() -> void:
	print("--- TEST CHAPTER 1 EXTENDED DIALOGUES & TUTORIALS START ---")
	GameManager.reset_to_new_game(1)
	
	var ch1_scene: PackedScene = load("res://scenes/chapters/chapter_1/chapter_1.tscn")
	var ch1 = ch1_scene.instantiate()
	add_child(ch1)
	
	await get_tree().create_timer(0.6).timeout
	
	var dlg = UIManager.get_dialogue_box()
	var player = ch1.find_child("Player", true, false)
	assert(player != null, "Player must exist!")
	assert(dlg != null, "DialogueBox must exist!")
	
	# 1. Verify Waking Dialogue was triggered in Apartment
	print("Checking waking dialogue...")
	assert(GameManager.has_flag("ch1_waking_done"), "Flag ch1_waking_done must be set!")
	assert(dlg.is_active, "Waking dialogue must be playing upon wake up!")
	
	# Advance waking dialogue (includes TAB and E tutorial lines)
	await _advance_dialogue(dlg)
	print("Waking dialogue completed.")
	
	# Verify inventory & profiles start empty
	assert(GameManager.collected_evidence.is_empty(), "Inventory must start empty!")
	assert(GameManager.unlocked_profiles.is_empty(), "Profiles must start empty!")
	print("Progressive empty inventory and profiles verified upon wake up.")
	
	# 2. Check Keycap Prompt on Apartment objects
	var mirror = ch1.find_child("TonicMirror", true, false)
	var wardrobe = ch1.find_child("DeskInteractable", true, false)
	var door = ch1.find_child("ExitDoor", true, false)
	assert(mirror != null, "TonicMirror must exist in Apartment!")
	assert(wardrobe != null, "DeskInteractable must exist in Apartment!")
	assert(door != null, "ExitDoor must exist in Apartment!")
	
	assert(mirror._prompt.text == "E", "Prompt on TonicMirror must be 'E' without extra text!")
	assert(wardrobe._prompt.text == "E", "Prompt on DeskInteractable must be 'E' without extra text!")
	assert(door._prompt.text == "E", "Prompt on ExitDoor must be 'E' without extra text!")
	print("Keycap prompt 'E' styling verified on apartment interactables.")
	
	# 3. Test Door Gating before preparing
	door.player_in_zone = true
	door._attempt_exit()
	await get_tree().create_timer(0.05).timeout
	assert(dlg.is_active, "Door must warn Arthur that he is not ready!")
	await _advance_dialogue(dlg)
	assert(ch1.world.current_map_id == "ch1_apartment", "Player must still be in apartment!")
	print("Door gating correctly prevents leaving before completing preparations.")
	
	# 4. Interact with Mirror (Take Tonic - SOP)
	mirror.interact()
	assert(dlg.is_active, "Mirror interaction must open dialogue!")
	
	# Simulate pressing E to advance past first line and skip typing on choice line
	var ev_e_skip = InputEventKey.new()
	ev_e_skip.pressed = true
	ev_e_skip.keycode = KEY_E
	
	# Skip/advance first line
	dlg._unhandled_input(ev_e_skip)
	await get_tree().create_timer(0.05).timeout
	dlg._unhandled_input(ev_e_skip)
	await get_tree().create_timer(0.05).timeout
	
	# Now line with choices is active or typing; press E to skip typing immediately
	if dlg.is_typing:
		dlg._unhandled_input(ev_e_skip)
		await get_tree().create_timer(0.05).timeout
	
	assert(dlg.waiting_for_choice, "Dialogue box MUST be waiting for choice even when text typing was skipped!")
	assert(dlg.choice_container.visible, "Choice container must be visible!")
	assert(dlg.choice_container.get_child_count() == 2, "Must show 2 choices!")
	
	# Pick choice 0 using keyboard number '1'
	var ev_1 = InputEventKey.new()
	ev_1.pressed = true
	ev_1.keycode = KEY_1
	dlg._unhandled_input(ev_1)
	
	await _advance_dialogue(dlg)
	assert(GameManager.has_flag("tonic_taken_ch1"), "Flag tonic_taken_ch1 must be set!")
	print("Mirror interaction choice verified: Tonic taken via key '1'.")
	
	# Re-inspect mirror to test post-choice feedback
	mirror.interact()
	assert(dlg.is_active, "Re-inspecting mirror should show status line!")
	assert(dlg.dialogue_text.text.contains("Denyut nadi terpantau stabil"), "Mirror should display pulse stabilized!")
	await _advance_dialogue(dlg)
	print("Mirror repeat inspection status feedback verified.")
	
	# 5. Interact with Wardrobe (Get equipped)
	wardrobe.interact()
	await _advance_dialogue(dlg)
	assert(GameManager.has_flag("vance_equipped_ch1"), "Flag vance_equipped_ch1 must be set!")
	assert(GameManager.has_evidence("lencana"), "Badge 'lencana' must be added to inventory upon equipping wardrobe!")
	
	# Re-inspect wardrobe to test post-equipped feedback
	wardrobe.interact()
	assert(dlg.is_active, "Re-inspecting wardrobe should show already equipped line!")
	assert(dlg.dialogue_text.text.contains("Mantel dinas dan lencana"), "Wardrobe should state Arthur is already equipped!")
	await _advance_dialogue(dlg)
	print("Wardrobe interaction and repeat inspection verified: Vance equipped.")
	
	# 6. Now Exit Door should allow leaving and transition to Sub-Sector 4
	door._attempt_exit()
	await _advance_dialogue(dlg)
	
	for i in range(25):
		await get_tree().physics_frame
	
	assert(ch1.world.current_map_id == "ch1_subsector4", "Current map must now be ch1_subsector4!")
	print("Transit to Sub-Sector 4 successful.")
	
	# 7. Check Prescott Opening Banter in Sub-Sector 4
	await get_tree().create_timer(0.6).timeout
	assert(GameManager.has_flag("prescott_intro_done"), "Flag prescott_intro_done must be set!")
	assert(dlg.is_active, "Prescott opening banter must be playing upon arrival!")
	while not dlg.waiting_for_choice:
		dlg._show_next_line()
		await get_tree().create_timer(0.04).timeout
	# Choose option 0: [Santai] Mengeluhkan cuaca dan kopi dinas
	dlg._on_choice_clicked(0, "[Santai]")
	await _advance_dialogue(dlg)
	assert(GameManager.has_profile("prescott"), "Prescott profile must be unlocked upon arriving in Sub-Sector 4!")
	print("Prescott opening banter & coffee choices verified.")
	
	# 8. Check Prescott Manual Branching Dialogue
	var prescott = ch1.find_child("NPCMilesPrescott", true, false)
	assert(prescott != null, "Prescott NPC must exist!")
	var ev_e = InputEventKey.new()
	ev_e.pressed = true
	ev_e.keycode = KEY_E
	prescott.player_in_range = true
	prescott._unhandled_input(ev_e)
	assert(dlg.is_active, "Talking to Prescott must open dialogue!")
	while not dlg.waiting_for_choice:
		dlg._show_next_line()
		await get_tree().create_timer(0.04).timeout
	# Select topic 0: [Tanya Situasi]
	dlg._on_choice_clicked(0, "[Tanya Situasi]")
	await _advance_dialogue(dlg)
	print("Prescott manual topic branching verified.")
	
	# 9. Interrogate Miller (Evidence102)
	var evid102 = ch1.find_child("Evidence102", true, false)
	assert(evid102 != null, "Evidence102 must exist!")
	evid102.player_in_zone = true
	evid102.interact()
	assert(dlg.is_active, "Interrogation dialogue must start!")
	while not dlg.waiting_for_choice:
		dlg._show_next_line()
		await get_tree().create_timer(0.04).timeout
	# Select [Empati]
	dlg._on_choice_clicked(0, "[Empati]")
	await _advance_dialogue(dlg)
	assert(GameManager.has_flag("miller_interrogated"), "Miller must be interrogated!")
	assert(GameManager.has_evidence("EVID-102"), "EVID-102 must be collected!")
	assert(GameManager.has_profile("miller"), "Miller profile must be unlocked upon interrogation!")
	
	# Verify Notebook Profile tab displays Prescott and Miller
	var notebook = ch1.find_child("DetectiveNotebook", true, false)
	if notebook:
		notebook.open_notebook()
		notebook._switch_tab(2)
		var names_in_profiles: Array[String] = []
		for it in notebook.items:
			names_in_profiles.append(it["name"])
		print("Profiles in notebook: ", names_in_profiles)
		assert("Miles Prescott" in names_in_profiles, "Prescott must appear in profile tab!")
		assert("Miller (Tahanan 402)" in names_in_profiles, "Miller must appear in profile tab!")
		notebook.close_notebook()
	
	print("Miller multi-stage interrogation & profile unlock verified.")
	
	# 10. Collect Evidence103 & check Synthesis Tutorial
	var evid103 = ch1.find_child("Evidence103", true, false)
	assert(evid103 != null, "Evidence103 must exist!")
	evid103.player_in_zone = true
	evid103.interact()
	await _advance_dialogue(dlg)
	
	# Wait for synthesis tutorial timer (0.3s)
	await get_tree().create_timer(0.45).timeout
	
	assert(GameManager.has_flag("combiner_tutorial_done"), "Flag combiner_tutorial_done must be set!")
	assert(dlg.is_active, "Synthesis tutorial dialogue must be playing!")
	await _advance_dialogue(dlg)
	print("Synthesis tutorial [C] correctly triggered upon clue correlation.")
	
	print("--- ALL CHAPTER 1 EXTENDED TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit()

func _advance_dialogue(dlg) -> void:
	while dlg.is_active:
		if dlg.waiting_for_choice:
			dlg._on_choice_clicked(0, "")
		else:
			dlg._show_next_line()
		await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(0.2).timeout
