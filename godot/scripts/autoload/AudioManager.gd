extends Node

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_bgm_path: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

func play_bgm(path: String) -> void:
	if path.is_empty() or path == _current_bgm_path or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream:
		_current_bgm_path = path
		_bgm_player.stream = stream
		_bgm_player.play()

func stop_bgm() -> void:
	_current_bgm_path = ""
	_bgm_player.stop()

func play_sfx(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream:
		_sfx_player.stream = stream
		_sfx_player.play()
