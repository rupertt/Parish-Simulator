class_name GameHud
extends CanvasLayer

@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var top_bar: Control = $TopBar
@onready var character_button: Button = %CharacterButton
@onready var inventory_button: Button = %InventoryButton
@onready var quests_button: Button = %QuestsButton
@onready var maps_button: Button = %MapsButton
@onready var prompt_panel: Control = %PromptPanel
@onready var prompt_label: Label = %PromptLabel
@onready var message_panel: Control = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var character_screen: Control = %CharacterScreen
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var debug_label: Label = %DebugLabel

var ping_ms := 0
var current_prompt := ""
var message_token := 0

func _ready() -> void:
	GameState.connection_status_changed.connect(set_status)
	GameState.ui_screen_toggled.connect(_on_ui_screen_toggled)
	character_button.pressed.connect(func() -> void: GameState.toggle_ui_screen("character"))
	inventory_button.pressed.connect(func() -> void: GameState.toggle_ui_screen("inventory"))
	quests_button.pressed.connect(func() -> void: GameState.toggle_ui_screen("quests"))
	maps_button.pressed.connect(func() -> void: GameState.toggle_ui_screen("maps"))
	set_player_name(GameState.player_name)
	set_status(GameState.connection_status)
	set_prompt("")
	message_panel.visible = false
	character_screen.visible = false
	debug_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_screen"):
		GameState.toggle_ui_screen("character")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory_screen"):
		GameState.toggle_ui_screen("inventory")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("quests_screen"):
		GameState.toggle_ui_screen("quests")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("maps_screen"):
		GameState.toggle_ui_screen("maps")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("debug_toggle"):
		debug_panel.visible = not debug_panel.visible

func set_player_name(value: String) -> void:
	name_label.text = value

func set_status(value: String) -> void:
	status_label.text = value

func set_prompt(value: String) -> void:
	current_prompt = value
	if message_panel.visible or GameState.is_ui_screen_open():
		return
	prompt_panel.visible = not value.is_empty()
	prompt_label.text = value

func show_message(value: String) -> void:
	if GameState.is_ui_screen_open():
		return
	message_token += 1
	var active_token := message_token
	message_label.text = value
	prompt_panel.visible = false
	message_panel.visible = true
	await get_tree().create_timer(2.0).timeout
	if active_token != message_token:
		return
	message_panel.visible = false
	prompt_label.text = current_prompt
	prompt_panel.visible = not current_prompt.is_empty()

func _on_ui_screen_toggled(screen_id: String, is_open: bool) -> void:
	if not ["character", "inventory", "quests", "maps"].has(screen_id):
		return
	character_button.disabled = is_open and screen_id == "character"
	inventory_button.disabled = is_open and screen_id == "inventory"
	quests_button.disabled = is_open and screen_id == "quests"
	maps_button.disabled = is_open and screen_id == "maps"
	if is_open:
		message_panel.visible = false
		prompt_panel.visible = false
		character_screen.call("open_screen", screen_id)
	else:
		character_screen.call("close_screen")
		prompt_label.text = current_prompt
		prompt_panel.visible = not current_prompt.is_empty()

func set_ping(value: int) -> void:
	ping_ms = value

func update_debug(local_position: Vector2, player_count: int) -> void:
	if not debug_panel.visible:
		return
	debug_label.text = "FPS: %d\nPos: %.0f, %.0f\nPlayers: %d\nPing: %d ms" % [
		Engine.get_frames_per_second(),
		local_position.x,
		local_position.y,
		player_count,
		ping_ms
	]
