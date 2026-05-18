extends "res://scripts/ui/base_ui_screen.gd"

const MENU_SIZE := Vector2(520, 44)
const VIEWPORT_MARGIN := Vector2(16, 14)
const SCREEN_TITLES := {
	"character": "CHARACTER",
	"inventory": "INVENTORY",
	"quests": "QUESTS",
	"maps": "MAPS"
}
const SCREEN_DESCRIPTIONS := {
	"inventory": "Inventory screen placeholder.",
	"quests": "Quest log placeholder.",
	"maps": "Map screen placeholder."
}
const CHARACTER_STATS := [
	["Intelligence", "3"],
	["Strength", "3"],
	["Morality", "3"],
	["Health", "3"],
	["Fervor", "3"]
]

@onready var menu_root: Control = %MenuRoot
@onready var title_label: Label = %ScreenTitleLabel
@onready var description_label: Label = %ScreenDescriptionLabel
@onready var character_button: Button = %CharacterButton
@onready var inventory_button: Button = %InventoryButton
@onready var quests_button: Button = %QuestsButton
@onready var maps_button: Button = %MapsButton
@onready var character_content: Control = %CharacterContent
@onready var placeholder_content: Control = %PlaceholderContent
@onready var portrait_texture: TextureRect = %PortraitTexture
@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_role_label: Label = %CharacterRoleLabel
@onready var stats_container: VBoxContainer = %StatsContainer

func _ready() -> void:
	super._ready()
	screen_id = "character"
	get_viewport().size_changed.connect(_fit_to_viewport)
	character_button.pressed.connect(func() -> void: GameState.open_ui_screen("character"))
	inventory_button.pressed.connect(func() -> void: GameState.open_ui_screen("inventory"))
	quests_button.pressed.connect(func() -> void: GameState.open_ui_screen("quests"))
	maps_button.pressed.connect(func() -> void: GameState.open_ui_screen("maps"))
	_fit_to_viewport()
	_build_stats()
	_refresh_for_screen(GameState.active_ui_screen if not GameState.active_ui_screen.is_empty() else "character")

func open_screen(target_screen_id: String = "character") -> void:
	screen_id = target_screen_id
	super.open_screen()
	_fit_to_viewport()
	_refresh_for_screen(target_screen_id)

func _fit_to_viewport() -> void:
	if not is_node_ready():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var available_width: float = viewport_size.x - VIEWPORT_MARGIN.x * 2.0
	var scale_factor: float = min(available_width / MENU_SIZE.x, 1.0)
	scale_factor = clamp(scale_factor, 0.45, 1.0)
	menu_root.size = MENU_SIZE
	menu_root.scale = Vector2(scale_factor, scale_factor)
	menu_root.position = Vector2(
		(viewport_size.x - (MENU_SIZE.x * scale_factor)) * 0.5,
		VIEWPORT_MARGIN.y
	)

func _refresh_for_screen(target_screen_id: String) -> void:
	var resolved_screen_id := target_screen_id
	if not SCREEN_TITLES.has(resolved_screen_id):
		resolved_screen_id = "character"
	screen_id = resolved_screen_id
	title_label.text = String(SCREEN_TITLES[resolved_screen_id])
	_set_button_state(character_button, resolved_screen_id == "character")
	_set_button_state(inventory_button, resolved_screen_id == "inventory")
	_set_button_state(quests_button, resolved_screen_id == "quests")
	_set_button_state(maps_button, resolved_screen_id == "maps")
	character_content.visible = resolved_screen_id == "character"
	placeholder_content.visible = resolved_screen_id != "character"
	if resolved_screen_id == "character":
		_refresh_character_content()
	else:
		description_label.text = String(SCREEN_DESCRIPTIONS[resolved_screen_id])

func _set_button_state(button: Button, is_active: bool) -> void:
	button.disabled = is_active

func _refresh_character_content() -> void:
	character_name_label.text = GameState.character_name if not GameState.character_name.is_empty() else GameState.player_name
	character_role_label.text = "Parish Steward"
	var texture := load(GameState.character_icon_path) as Texture2D
	portrait_texture.texture = texture

func _build_stats() -> void:
	for child in stats_container.get_children():
		child.queue_free()
	for stat_data in CHARACTER_STATS:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = String(stat_data[0])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := Label.new()
		value.text = String(stat_data[1])
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(label)
		row.add_child(value)
		stats_container.add_child(row)
