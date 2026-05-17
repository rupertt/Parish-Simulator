extends Node

const INPUTS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E],
	"character_screen": [KEY_C],
	"debug_toggle": [KEY_F3]
}

func _ready() -> void:
	ensure_input_map()

func ensure_input_map() -> void:
	for action in INPUTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in INPUTS[action]:
			if not _has_key_event(action, keycode):
				var event := InputEventKey.new()
				event.physical_keycode = keycode
				InputMap.action_add_event(action, event)

func _has_key_event(action: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false
