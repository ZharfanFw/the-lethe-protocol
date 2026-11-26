extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("--- TEST CH1 -> CUTSCENE -> CH2 TRANSITION START ---")
	var dummy := Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	await get_tree().process_frame

	GameManager.reset_to_new_game(3)
	var err := get_tree().change_scene_to_file("res://scenes/chapters/chapter_1/chapter_1.tscn")
	assert(err == OK, "Failed to change scene to chapter_1.tscn!")
	await get_tree().create_timer(0.6).timeout

	var ch1: Node = get_tree().current_scene
	assert(ch1 != null and ch1.name == "Chapter1", "Current scene must be Chapter1!")
	assert(ch1.world != null, "Chapter1.world must exist!")

	ch1.world._load_map("ch1_subsector4", Vector2(1240, 330))
	await get_tree().create_timer(0.2).timeout
	assert(ch1.world.current_map_id == "ch1_subsector4", "Chapter1 must load ch1_subsector4!")

	var exit_trigger: Node = ch1.world.current_map.get_node_or_null("ExitTrigger")
	assert(exit_trigger != null, "SubSector4 ExitTrigger must exist!")
	assert(int(exit_trigger.get("target_next_chapter")) == 2, "ExitTrigger must target chapter 2!")
	assert(str(exit_trigger.get("cutscene_id")) == "chapter_1", "ExitTrigger must play chapter_1 closing cutscene!")

	# Verify missing flags block exit
	exit_trigger.try_transition()
	await get_tree().create_timer(0.2).timeout
	assert(not GameManager.has_flag("chapter_1_completed"), "ExitTrigger must block transition before required clues are collected!")
	assert(GameManager.current_chapter == 1, "Chapter must remain 1 while blocked!")
	var dlg: Node = UIManager.get_dialogue_box()
	while dlg and dlg.is_active:
		dlg._show_next_line()
		await get_tree().create_timer(0.05).timeout

	# Complete Chapter 1 exit requirements and cross the Dock gate
	GameManager.set_flag("miller_interrogated", true)
	GameManager.set_flag("evid_103_collected", true)
	GameManager.set_flag("evid_104_collected", true)
	GameManager.set_flag("evid_105_collected", true)

	exit_trigger.try_transition()
	await get_tree().create_timer(0.7).timeout

	var cutscene: Node = get_tree().current_scene
	assert(cutscene != null and cutscene.scene_file_path == GameManager.CUTSCENE_SCENE_PATH, "ExitTrigger must transition to CutscenePlayer!")
	assert(str(cutscene.get("_active_id")) == "chapter_1", "CutscenePlayer must play chapter_1 closing bridge, not spoil chapter 2 ending!")
	var slides: Array = cutscene.get("_active_slides")
	assert(slides.size() == 2, "Bridge cutscene chapter_1 must have 2 slides (Sub-Sektor 4 -> Lantai 80)!")
	assert(str(slides[0].get("image", "")) == "res://assets/cutscenes/chapter1-slide3.jpg", "Slide 1 must depict Sub-Sektor 4 warehouse findings!")
	assert(str(slides[1].get("image", "")) == "res://assets/cutscenes/chapter4-slide1.jpg", "Slide 2 must depict Executive Tower Floor 80 summons!")
	assert(GameManager.current_chapter == 2, "Current chapter must advance to 2!")
	assert(GameManager.has_flag("chapter_1_completed"), "chapter_1_completed flag must be set!")
	assert(not GameManager.has_saved_position and GameManager.saved_map_id.is_empty(), "Chapter transition must clear prior chapter saved map/position!")

	var save_data: Dictionary = SaveManager.read_save_file(3)
	var gs: Dictionary = save_data.get("game_state", {})
	assert(int(gs.get("current_chapter", 0)) == 2, "Autosave must record chapter 2!")
	assert(not bool(gs.get("has_saved_position", true)), "Autosave on chapter transition must not persist Chapter 1 position!")
	assert(str(gs.get("current_map", "bad")) == "", "Autosave on chapter transition must not persist ch1_subsector4!")

	# Finish cutscene -> Chapter 2
	cutscene._finish_cutscene()
	await get_tree().create_timer(0.9).timeout

	var ch2: Node = get_tree().current_scene
	assert(ch2 != null and ch2.scene_file_path == "res://scenes/chapters/chapter_2/chapter_2.tscn", "Cutscene must transition directly into Chapter 2!")
	assert(ch2.world != null and str(ch2.world.current_map_id) == "indoor", "Chapter 2 must start in IndoorOffice ('indoor'), got: " + str(ch2.world.current_map_id))
	assert(ch2.world.current_map != null and ch2.world.current_map.name == "IndoorOffice", "Chapter 2 map node must be IndoorOffice!")
	assert(ch2.world.current_map.get_node_or_null("NPCLucian") != null, "Chapter 2 NPCLucian must be loaded in IndoorOffice!")
	assert(ch2.world.current_map.get_node_or_null("Evidence201") != null, "Chapter 2 Evidence201 (Terminal Kuantum) must be loaded!")

	SaveManager.delete_save(3)
	print("--- TEST CH1 -> CUTSCENE -> CH2 TRANSITION PASS ---")
	get_tree().quit()
