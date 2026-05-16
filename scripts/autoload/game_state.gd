extends Node

signal connection_status_changed(status: String)

var player_name: String = "Player"
var server_url: String = "ws://localhost:3000/ws"
var connection_status: String = "Offline"
var character_id: String = "char_01"
var character_name: String = "Vicar"
var character_color: Color = Color("#d95f5f")
var character_texture_path: String = "res://Images for game/Characters/Vicar.png"

const SHARED_ROOM := "main"
const CHARACTERS := [
	{"id": "char_01", "name": "Vicar", "color": "#d95f5f", "texture": "res://Images for game/Characters/Vicar.png"},
	{"id": "char_02", "name": "Old Man", "color": "#e6a84f", "texture": "res://Images for game/Characters/Old Man.png"},
	{"id": "char_03", "name": "Grandma", "color": "#d79c5f", "texture": "res://Images for game/Characters/Grandma In Card.png"},
	{"id": "char_04", "name": "Girl", "color": "#df7aa8", "texture": "res://Images for game/Characters/Girl in pink dress.png"},
	{"id": "char_05", "name": "Boy Hoodie", "color": "#5f8fd9", "texture": "res://Images for game/Characters/Boy in blue hoddie.png"},
	{"id": "char_06", "name": "Boy Jeans", "color": "#6d8bb8", "texture": "res://Images for game/Characters/Boy In Jeans1.png"},
	{"id": "char_07", "name": "Red Hair", "color": "#c95757", "texture": "res://Images for game/Characters/Women with Red Hair.png"},
	{"id": "char_08", "name": "Jacket", "color": "#8d6a4a", "texture": "res://Images for game/Characters/Women with Jacket.png"},
	{"id": "char_09", "name": "Yellow Shirt", "color": "#d6b94d", "texture": "res://Images for game/Characters/Black Women Yellow Shirt.png"},
	{"id": "char_10", "name": "Chinos", "color": "#7b8f67", "texture": "res://Images for game/Characters/Black man in chinos.png"}
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
			character_texture_path = String(character["texture"])
			return
	character_id = CHARACTERS[0]["id"]
	character_name = CHARACTERS[0]["name"]
	character_color = Color(CHARACTERS[0]["color"])
	character_texture_path = String(CHARACTERS[0]["texture"])

func get_character(character_id_value: String) -> Dictionary:
	for character in CHARACTERS:
		if character["id"] == character_id_value:
			return character
	return CHARACTERS[0]

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
