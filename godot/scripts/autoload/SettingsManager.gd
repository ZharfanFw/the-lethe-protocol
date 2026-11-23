extends Node

signal settings_changed
signal settings_saved

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_AUDIO: String = "audio"
const SECTION_DISPLAY: String = "display"

var master_volume: float = 1.0
var bgm_volume: float = 0.8
var sfx_volume: float = 0.9
var is_fullscreen: bool = false

func _ready() -> void:
	_ensure_audio_buses()
	load_settings()

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("BGM") == -1:
		AudioServer.add_bus()
		var bgm_idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bgm_idx, "BGM")
		AudioServer.set_bus_send(bgm_idx, "Master")

	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var sfx_idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

func load_settings() -> void:
	_ensure_audio_buses()
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err == OK:
		master_volume = float(config.get_value(SECTION_AUDIO, "master_volume", 1.0))
		bgm_volume = float(config.get_value(SECTION_AUDIO, "bgm_volume", 0.8))
		sfx_volume = float(config.get_value(SECTION_AUDIO, "sfx_volume", 0.9))
		is_fullscreen = bool(config.get_value(SECTION_DISPLAY, "fullscreen", false))
	apply_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION_AUDIO, "master_volume", master_volume)
	config.set_value(SECTION_AUDIO, "bgm_volume", bgm_volume)
	config.set_value(SECTION_AUDIO, "sfx_volume", sfx_volume)
	config.set_value(SECTION_DISPLAY, "fullscreen", is_fullscreen)
	var err := config.save(SETTINGS_PATH)
	if err == OK:
		settings_saved.emit()
	else:
		push_warning("Gagal menyimpan file konfigurasi settings: %s" % SETTINGS_PATH)

func apply_settings() -> void:
	_ensure_audio_buses()
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("BGM", bgm_volume)
	_apply_bus_volume("SFX", sfx_volume)

	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	settings_changed.emit()

func _apply_bus_volume(bus_name: String, volume_linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if volume_linear <= 0.01:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(volume_linear, 0.01, 1.0)))

func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)
	settings_changed.emit()

func set_bgm_volume(val: float) -> void:
	bgm_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume("BGM", bgm_volume)
	settings_changed.emit()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)
	settings_changed.emit()

func set_fullscreen_mode(fullscreen: bool) -> void:
	is_fullscreen = fullscreen
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed.emit()
