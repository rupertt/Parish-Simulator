class_name GameHud
extends CanvasLayer

@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var prompt_panel: Control = %PromptPanel
@onready var prompt_label: Label = %PromptLabel
@onready var message_panel: Control = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var debug_label: Label = %DebugLabel

var ping_ms := 0
var current_prompt := ""
var message_token := 0

func _ready() -> void:
	GameState.connection_status_changed.connect(set_status)
	set_player_name(GameState.player_name)
	set_status(GameState.connection_status)
	set_prompt("")
	message_panel.visible = false
	debug_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		debug_panel.visible = not debug_panel.visible

func set_player_name(value: String) -> void:
	name_label.text = value

func set_status(value: String) -> void:
	status_label.text = value

func set_prompt(value: String) -> void:
	current_prompt = value
	if message_panel.visible:
		return
	prompt_panel.visible = not value.is_empty()
	prompt_label.text = value

func show_message(value: String) -> void:
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
