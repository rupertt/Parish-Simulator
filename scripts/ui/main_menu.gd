extends Control

signal join_requested(player_name: String, character_id: String)

@onready var name_input: LineEdit = %NameInput
@onready var character_grid: GridContainer = %CharacterGrid
@onready var selected_label: Label = %SelectedLabel

var selected_character_id := "char_01"
var _buttons: Array[Button] = []
var _selectable_characters: Array = []

func _ready() -> void:
	name_input.text = GameState.player_name
	selected_character_id = GameState.character_id
	_build_character_list()
	_select_character(selected_character_id)

func _build_character_list() -> void:
	for child in character_grid.get_children():
		child.queue_free()
	_buttons.clear()
	_selectable_characters = GameState.get_selectable_characters()
	character_grid.columns = max(1, _selectable_characters.size())

	for character in _selectable_characters:
		var button := Button.new()
		button.custom_minimum_size = Vector2(68, 68)
		button.icon = load(String(character["icon"]))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.flat = false
		button.text = ""
		button.toggle_mode = true
		button.tooltip_text = character["name"]
		button.add_theme_constant_override("icon_max_width", 56)
		button.add_theme_stylebox_override("normal", _make_character_style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
		button.add_theme_stylebox_override("hover", _make_character_style(Color("#ffffff14"), Color("#ffffff33"), 1))
		button.add_theme_stylebox_override("pressed", _make_character_style(Color("#d7f5ff3f"), Color("#d7f5ff"), 3))
		button.add_theme_stylebox_override("focus", _make_character_style(Color.TRANSPARENT, Color("#d7f5ff"), 2))
		button.pressed.connect(_select_character.bind(character["id"]))
		character_grid.add_child(button)
		_buttons.append(button)

func _select_character(character_id: String) -> void:
	selected_character_id = character_id
	GameState.select_character(character_id)
	for index in _buttons.size():
		var character: Dictionary = _selectable_characters[index]
		_buttons[index].button_pressed = character["id"] == selected_character_id
	selected_label.text = "Selected: %s" % GameState.character_name

func _on_enter_button_pressed() -> void:
	join_requested.emit(name_input.text, selected_character_id)

func _make_character_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style
