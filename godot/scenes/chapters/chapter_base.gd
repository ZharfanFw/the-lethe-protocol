class_name ChapterController
extends Node2D

@export var chapter_number: int = 1
@export var check_suspicion_ending: bool = false

func _ready() -> void:
	GameManager.current_chapter = chapter_number
	UIManager.show_hud(true)
	UIManager.fade_in(0.5)
	if check_suspicion_ending and GameManager.suspicion_meter >= 75:
		_trigger_capture_ending.call_deferred()

func _trigger_capture_ending() -> void:
	GameManager.set_flag("chapter_4_completed", true)
	GameManager.resolve_ending(4)
