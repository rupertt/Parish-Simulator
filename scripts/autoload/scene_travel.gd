extends CanvasLayer

const SCENE_TRAVEL_OPTIONS := [
	{"label": "Test Meadow", "path": "res://scenes/world/TestMeadow.tscn"},
	{"label": "New Map", "path": "res://scenes/world/new_map.tscn"},
	{"label": "Church Entrance", "path": "res://scenes/world/ChurchEntrance.tscn"},
	{"label": "Church Sanctuary", "path": "res://scenes/world/ChurchSanctuary.tscn"}
]

var panel: PanelContainer
var selector: OptionButton
var character_selector: OptionButton
var character_apply_button: Button

func _ready() -> void:
	layer = 100
	_build_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		_toggle()
		get_viewport().set_input_as_handled()
		return
	if panel.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		_toggle(false)
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.visible = false
	panel.custom_minimum_size = Vector2(340, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-170, 12)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)

	var title := Label.new()
	title.text = "Scene Travel (Test)"
	rows.add_child(title)

	var character_title := Label.new()
	character_title.text = "Character"
	rows.add_child(character_title)

	character_selector = OptionButton.new()
	character_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(character_selector)
	_refresh_character_selector()

	character_apply_button = Button.new()
	character_apply_button.text = "Apply Character"
	character_apply_button.pressed.connect(_apply_selected_character)
	rows.add_child(character_apply_button)

	var separator := HSeparator.new()
	rows.add_child(separator)

	selector = OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(selector)

	for option in SCENE_TRAVEL_OPTIONS:
		selector.add_item(String(option["label"]))

	var join_button := Button.new()
	join_button.text = "Join Selected Scene"
	join_button.pressed.connect(_join_selected_scene)
	rows.add_child(join_button)

	var hint := Label.new()
	hint.text = "Space: toggle, Esc: close"
	rows.add_child(hint)

func _toggle(force_visible: Variant = null) -> void:
	var show := not panel.visible
	if force_visible != null:
		show = bool(force_visible)
	panel.visible = show
	if show:
		_refresh_character_selector()

func _join_selected_scene() -> void:
	var index := selector.selected
	if index < 0 or index >= SCENE_TRAVEL_OPTIONS.size():
		return
	var path := String(SCENE_TRAVEL_OPTIONS[index]["path"])
	_toggle(false)
	SceneLoader.change_to(path)

func _refresh_character_selector() -> void:
	if character_selector == null:
		return
	character_selector.clear()
	var selected_index := 0
	var i := 0
	for character in GameState.get_selectable_characters():
		character_selector.add_item(String(character.get("name", "Character")))
		character_selector.set_item_metadata(i, String(character.get("id", "")))
		if String(character.get("id", "")) == GameState.character_id:
			selected_index = i
		i += 1
	character_selector.select(selected_index)

func _apply_selected_character() -> void:
	if character_selector == null:
		return
	var index := character_selector.selected
	if index < 0:
		return
	var character_id := String(character_selector.get_item_metadata(index))
	if character_id.is_empty():
		return
	GameState.select_character(character_id)
