extends Node

const SCENES := [
	"res://scenes/menu/main_menu.tscn",
	"res://scenes/menu/save_select.tscn",
	"res://scenes/menu/settings_menu.tscn",
	"res://scenes/menu/pause_menu.tscn",
	"res://scenes/cutscenes/cutscene_player.tscn",
	"res://scenes/chapters/chapter_1/chapter_1.tscn",
	"res://scenes/chapters/chapter_2/chapter_2.tscn",
	"res://scenes/chapters/chapter_3/chapter_3.tscn",
	"res://scenes/chapters/chapter_4/chapter_4.tscn",
	"res://scenes/chapters/chapter_5/chapter_5.tscn",
	"res://scenes/endings/ending_1.tscn",
	"res://scenes/endings/ending_4.tscn",
	"res://scenes/common/combine_station.tscn",
	"res://scenes/puzzle/affine_puzzle.tscn",
]

func _ready() -> void:
	for path in SCENES:
		if not ResourceLoader.exists(path):
			print("MISSING: ", path)
			continue
		var packed: PackedScene = load(path)
		var inst: Node = packed.instantiate()
		add_child(inst)
		await get_tree().process_frame
		print("OK: ", path, " -> ", inst.get_class())
		inst.queue_free()
		await get_tree().process_frame

	# Test SettingsManager
	SettingsManager.set_master_volume(0.75)
	SettingsManager.set_bgm_volume(0.60)
	SettingsManager.set_sfx_volume(0.85)
	SettingsManager.set_fullscreen_mode(false)
	SettingsManager.save_settings()
	SettingsManager.load_settings()
	print("SETTINGS: master=", SettingsManager.master_volume, " bgm=", SettingsManager.bgm_volume, " sfx=", SettingsManager.sfx_volume, " fullscreen=", SettingsManager.is_fullscreen)

	# Test Game Save & Slot Management
	GameManager.reset_to_new_game(3)
	GameManager.add_evidence("EVID-101")
	GameManager.add_evidence("EVID-103")
	GameManager.memory_meter = 42
	GameManager.suspicion_meter = 12
	GameManager.set_flag("miller_interrogated", true)
	var saved: bool = SaveManager.save_game(3)
	var meta: Dictionary = SaveManager.get_slot_metadata(3)
	var data: Dictionary = SaveManager.read_save_file(3)
	print("SAVE saved=", saved, " meta=", meta)

	GameManager.reset_to_new_game(1)
	var applied: bool = GameManager.apply_save_data(data)
	print("LOAD applied=", applied, " slot=", GameManager.current_slot, " ev=", GameManager.collected_evidence, " mem=", GameManager.memory_meter, " flag=", GameManager.has_flag("miller_interrogated"))
	print("ENDINGS available(1,2,5)=", GameManager.is_ending_available(1), GameManager.is_ending_available(2), GameManager.is_ending_available(5))

	SaveManager.delete_save(3)
	var deleted_meta: Dictionary = SaveManager.get_slot_metadata(3)
	print("DELETE_VERIFY slot=3 exists=", deleted_meta.get("exists", false))

	# Test Player Position Persistence
	GameManager.reset_to_new_game(2)
	GameManager.saved_player_position = Vector2(742.5, 318.0)
	GameManager.has_saved_position = true
	GameManager.saved_map_id = "indoor"
	SaveManager.save_game(2)
	var data2: Dictionary = SaveManager.read_save_file(2)
	GameManager.reset_to_new_game(1)
	GameManager.apply_save_data(data2)
	print("POS_PERSISTENCE: has_pos=", GameManager.has_saved_position, " pos=", GameManager.saved_player_position, " map=", GameManager.saved_map_id)
	assert(GameManager.has_saved_position == true)
	assert(GameManager.saved_player_position.distance_to(Vector2(742.5, 318.0)) < 0.1)
	assert(GameManager.saved_map_id == "indoor")
	SaveManager.delete_save(2)

	print("SMOKE_TEST_DONE")
	get_tree().quit()
