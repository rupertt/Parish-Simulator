extends Control

signal join_requested(player_name: String, character_id: String)

@onready var name_input: LineEdit = %NameInput
@onready var character_grid: GridContainer = %CharacterGrid
@onready var selected_label: Label = %SelectedLabel

var selected_character_id := "char_01"
var _buttons: Array[Button] = []

func _ready() -> void:
	name_input.text = GameState.player_name
	selected_character_id = GameState.character_id
	_build_character_list()
	_select_character(selected_character_id)

func _build_character_list() -> void:
	for child in character_grid.get_children():
		child.queue_free()
	_buttons.clear()

	for character in GameState.CHARACTERS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(88, 32)
		button.text = character["name"]
		button.toggle_mode = true
		button.modulate = Color(character["color"])
		button.pressed.connect(_select_character.bind(character["id"]))
		character_grid.add_child(button)
		_buttons.append(button)

func _select_character(character_id: String) -> void:
	selected_character_id = character_id
	GameState.select_character(character_id)
	for index in _buttons.size():
		var character: Dictionary = GameState.CHARACTERS[index]
		_buttons[index].button_pressed = character["id"] == selected_character_id
	selected_label.text = "Selected: %s" % GameState.character_name

func _on_enter_button_pressed() -> void:
	join_requested.emit(name_input.text, selected_character_id)
