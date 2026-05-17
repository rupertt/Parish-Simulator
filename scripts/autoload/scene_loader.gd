extends Node

func change_to(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_warning("Could not change scene to %s: %s" % [path, error])
