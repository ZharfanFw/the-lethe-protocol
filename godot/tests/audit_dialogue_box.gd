extends Node

func _ready() -> void:
	var packed: PackedScene = load("res://scenes/dialogue_box.tscn")
	var box: CanvasLayer = packed.instantiate()
	add_child(box)
	await get_tree().process_frame

	box.start_dialogue("Director Lucian", [
		"Arthur Vance. Anda terlambat dari jadwal biasanya.",
		"Biro Forensik Pusat sedang mengamati setiap langkah Anda di sub-sektor ini."
	])
	await get_tree().process_frame
	await get_tree().process_frame

	print("=== DIALOGUE BOX AUDIT ===")
	var mc: Control = box.get_node_or_null("MainContainer")
	if not mc:
		mc = box.get_node_or_null("VBoxContainer")
	print("MainContainer pos=", mc.position, " size=", mc.size, " global_pos=", mc.global_position)
	for child in mc.get_children():
		print("  Child ", child.name, " (", child.get_class(), "): pos=", child.position, " size=", child.size)
		for sub in child.get_children():
			print("    Sub ", sub.name, " (", sub.get_class(), "): pos=", sub.position, " size=", sub.size)
			for sub2 in sub.get_children():
				print("      Sub2 ", sub2.name, " (", sub2.get_class(), "): pos=", sub2.position, " size=", sub2.size, " text=", sub2.get("text"))

	print("=== DIALOGUE BOX AUDIT PASS ===")
	get_tree().quit()
