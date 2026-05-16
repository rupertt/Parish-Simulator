extends Node2D

const TILE_SIZE := 24
const MAP_COLUMNS := 32
const MAP_ROWS := 18

const REMOTE_PLAYER_SCENE := preload("res://scenes/player/RemotePlayer.tscn")

@onready var local_player: CharacterBody2D = %LocalPlayer
@onready var remote_players: Node2D = %RemotePlayers
@onready var interactables: Node2D = %Interactables
@onready var hud: CanvasLayer = %HUD
@onready var camera: Camera2D = %Camera2D

var current_interactable: Area2D
var remote_nodes: Dictionary = {}

func _ready() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_COLUMNS * TILE_SIZE
	camera.limit_bottom = MAP_ROWS * TILE_SIZE
	local_player.input_changed.connect(_on_local_input_changed)
	NetworkManager.connected.connect(_on_network_connected)
	NetworkManager.snapshot_received.connect(_on_snapshot_received)
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	NetworkManager.ping_updated.connect(hud.set_ping)

	for item in interactables.get_children():
		if item.has_signal("focus_entered"):
			item.focus_entered.connect(_on_interactable_focus_entered)
			item.focus_exited.connect(_on_interactable_focus_exited)

func start_session() -> void:
	hud.set_player_name(GameState.player_name)
	NetworkManager.connect_to_server(GameState.server_url, GameState.player_name)

func _process(_delta: float) -> void:
	hud.update_debug(local_player.global_position, PlayerRegistry.count())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable:
		var message: String = current_interactable.call("interact")
		hud.show_message(message)

func _draw() -> void:
	for y in MAP_ROWS:
		for x in MAP_COLUMNS:
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var color := Color("#6fbf73") if (x + y) % 2 == 0 else Color("#68b96d")
			draw_rect(rect, color)
			if x == 0 or y == 0 or x == MAP_COLUMNS - 1 or y == MAP_ROWS - 1:
				draw_rect(rect, Color("#33573c"))

	for tile in [Vector2i(5, 5), Vector2i(9, 11), Vector2i(22, 6), Vector2i(26, 13)]:
		draw_rect(Rect2(tile.x * TILE_SIZE + 8, tile.y * TILE_SIZE + 8, 5, 5), Color("#e8d76c"))

func _on_local_input_changed(direction: Vector2, facing: String) -> void:
	NetworkManager.set_local_input(direction, facing)

func _on_network_connected(_client_id: String, players: Array) -> void:
	PlayerRegistry.set_players(players)
	_apply_players(players)

func _on_snapshot_received(players: Array) -> void:
	PlayerRegistry.set_players(players)
	_apply_players(players)

func _on_player_joined(player: Dictionary) -> void:
	PlayerRegistry.upsert_player(player)
	_apply_player(player)

func _on_player_left(player_id: String) -> void:
	PlayerRegistry.remove_player(player_id)
	if remote_nodes.has(player_id):
		var node: Node = remote_nodes[player_id]
		node.queue_free()
		remote_nodes.erase(player_id)

func _apply_players(players: Array) -> void:
	var seen: Dictionary = {}
	for player in players:
		if typeof(player) == TYPE_DICTIONARY:
			seen[String(player.get("id", ""))] = true
			_apply_player(player)

	for player_id in remote_nodes.keys():
		if not seen.has(player_id):
			var stale_node: Node = remote_nodes[player_id]
			stale_node.queue_free()
			remote_nodes.erase(player_id)

func _apply_player(player: Dictionary) -> void:
	var player_id := String(player.get("id", ""))
	if player_id.is_empty() or player_id == NetworkManager.client_id:
		return

	var node: Node2D
	if remote_nodes.has(player_id):
		node = remote_nodes[player_id] as Node2D
	else:
		node = REMOTE_PLAYER_SCENE.instantiate() as Node2D
		remote_players.add_child(node)
		remote_nodes[player_id] = node
	node.call("apply_state", player)

func _on_interactable_focus_entered(interactable: Area2D) -> void:
	current_interactable = interactable
	hud.set_prompt(String(interactable.get("prompt_text")))

func _on_interactable_focus_exited(interactable: Area2D) -> void:
	if current_interactable == interactable:
		current_interactable = null
		hud.set_prompt("")
