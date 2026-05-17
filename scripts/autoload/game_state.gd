extends Node

signal connection_status_changed(status: String)

var player_name: String = "Player"
var server_url: String = "ws://localhost:3000/ws"
var connection_status: String = "Offline"
var character_id: String = "char_01"
var character_name: String = "Vicar"
var character_color: Color = Color("#d95f5f")
var character_icon_path: String = "res://assets/art/animations/icons/vicar.png"
var character_walk_sheet_path: String = "res://assets/art/animations/vicar_walk_sheet.png"

const SHARED_ROOM := "main"
const SELECTABLE_CHARACTER_IDS := ["char_01", "char_11", "char_12", "char_13"]
const CHARACTERS := [
	{"id": "char_01", "name": "Vicar", "color": "#d95f5f", "icon": "res://assets/art/animations/icons/vicar.png", "walk_sheet": "res://assets/art/animations/vicar_walk_sheet.png"},
	{"id": "char_02", "name": "Old Man", "color": "#e6a84f", "icon": "res://assets/art/animations/icons/old_man.png", "walk_sheet": "res://assets/art/animations/old_man_walk_sheet.png"},
	{"id": "char_03", "name": "Grandma", "color": "#d79c5f", "icon": "res://assets/art/animations/icons/grandma.png", "walk_sheet": "res://assets/art/animations/grandma_walk_sheet.png"},
	{"id": "char_04", "name": "Girl", "color": "#df7aa8", "icon": "res://assets/art/animations/icons/girl.png", "walk_sheet": "res://assets/art/animations/girl_walk_sheet.png"},
	{"id": "char_05", "name": "Boy Hoodie", "color": "#5f8fd9", "icon": "res://assets/art/animations/icons/boy_hoodie.png", "walk_sheet": "res://assets/art/animations/boy_hoodie_walk_sheet.png"},
	{"id": "char_06", "name": "Boy Jeans", "color": "#6d8bb8", "icon": "res://assets/art/animations/icons/boy_jeans.png", "walk_sheet": "res://assets/art/animations/boy_jeans_walk_sheet.png"},
	{"id": "char_07", "name": "Red Hair", "color": "#c95757", "icon": "res://assets/art/animations/icons/red_hair.png", "walk_sheet": "res://assets/art/animations/red_hair_walk_sheet.png"},
	{"id": "char_08", "name": "Jacket", "color": "#8d6a4a", "icon": "res://assets/art/animations/icons/jacket.png", "walk_sheet": "res://assets/art/animations/jacket_walk_sheet.png"},
	{"id": "char_09", "name": "Yellow Shirt", "color": "#d6b94d", "icon": "res://assets/art/animations/icons/yellow_shirt.png", "walk_sheet": "res://assets/art/animations/yellow_shirt_walk_sheet.png"},
	{"id": "char_10", "name": "Chinos", "color": "#7b8f67", "icon": "res://assets/art/animations/icons/chinos.png", "walk_sheet": "res://assets/art/animations/chinos_walk_sheet.png"},
	{"id": "char_11", "name": "Black-Haired Vicar", "color": "#5f7fd9", "icon": "res://assets/art/animations/icons/vicar_black_hair.png", "walk_sheet": "res://assets/art/animations/vicar_black_hair_walk_sheet.png"},
	{"id": "char_12", "name": "Gray-Haired Vicar", "color": "#b7b7c4", "icon": "res://assets/art/animations/icons/vicar_gray_hair.png", "walk_sheet": "res://assets/art/animations/vicar_gray_hair_walk_sheet.png"},
	{"id": "char_13", "name": "Bearded Vicar", "color": "#7b6154", "icon": "res://assets/art/animations/icons/vicar_bearded.png", "walk_sheet": "res://assets/art/animations/vicar_bearded_walk_sheet.png"}
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
			character_icon_path = String(character["icon"])
			character_walk_sheet_path = String(character["walk_sheet"])
			return
	character_id = CHARACTERS[0]["id"]
	character_name = CHARACTERS[0]["name"]
	character_color = Color(CHARACTERS[0]["color"])
	character_icon_path = String(CHARACTERS[0]["icon"])
	character_walk_sheet_path = String(CHARACTERS[0]["walk_sheet"])

func get_character(character_id_value: String) -> Dictionary:
	for character in CHARACTERS:
		if character["id"] == character_id_value:
			return character
	return CHARACTERS[0]

func get_selectable_characters() -> Array:
	var selectable: Array = []
	for character_id_value in SELECTABLE_CHARACTER_IDS:
		selectable.append(get_character(character_id_value))
	return selectable

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
