extends Node

signal connection_status_changed(status: String)

var player_name: String = "Player"
var server_url: String = "ws://localhost:3000/ws"
var connection_status: String = "Offline"
var character_id: String = "char_01"
var character_name: String = "Character 1"
var character_color: Color = Color("#d95f5f")

const SHARED_ROOM := "main"
const CHARACTERS := [
	{"id": "char_01", "name": "Character 1", "color": "#d95f5f"},
	{"id": "char_02", "name": "Character 2", "color": "#e6a84f"}
]

func configure_session(new_player_name: String, new_character_id: String) -> void:
	player_name = new_player_name.strip_edges()
	if player_name.is_empty():
		player_name = "Player"

	select_character(new_character_id)
	server_url = detect_server_url()

func select_character(new_character_id: String) -> void:
	for character in CHARACTERS:
		if character["id"] == new_character_id:
			character_id = character["id"]
			character_name = character["name"]
			character_color = Color(character["color"])
			return
	character_id = CHARACTERS[0]["id"]
	character_name = CHARACTERS[0]["name"]
	character_color = Color(CHARACTERS[0]["color"])

func detect_server_url() -> String:
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js := Engine.get_singleton("JavaScriptBridge")
		var detected := String(js.eval("""
			(function () {
				var protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
				return protocol + '//' + window.location.host + '/ws';
			})()
		"""))
		if not detected.is_empty():
			return detected
	return "ws://localhost:3000/ws"

func set_connection_status(status: String) -> void:
	connection_status = status
	connection_status_changed.emit(status)
