extends Node2D

const MAP_WIDTH := 1254
const MAP_HEIGHT := 1254

const REMOTE_PLAYER_SCENE := preload("res://scenes/player/RemotePlayer.tscn")
const MAP_BLOCKERS := [
	# Buildings
	Rect2(252, 86, 150, 133),
	Rect2(468, 35, 186, 160),
	Rect2(718, 97, 126, 142),
	Rect2(976, 96, 158, 140),
	Rect2(210, 330, 164, 124),
	Rect2(915, 294, 222, 166),
	Rect2(50, 560, 156, 150),
	Rect2(260, 552, 126, 126),
	Rect2(552, 306, 168, 304),
	Rect2(924, 512, 188, 170),
	Rect2(282, 775, 178, 160),
	Rect2(792, 772, 158, 148),
	Rect2(1020, 773, 160, 152),
	Rect2(1000, 985, 178, 168),
	# Large tree trunks and crowns
	Rect2(0, 0, 70, 110),
	Rect2(128, 62, 70, 100),
	Rect2(216, 12, 64, 100),
	Rect2(310, 0, 70, 100),
	Rect2(662, 0, 72, 110),
	Rect2(958, 0, 78, 112),
	Rect2(1052, 20, 74, 112),
	Rect2(1140, 60, 72, 108),
	Rect2(0, 190, 78, 118),
	Rect2(1200, 175, 54, 112),
	Rect2(456, 330, 64, 118),
	Rect2(748, 336, 62, 112),
	Rect2(810, 318, 72, 120),
	Rect2(1180, 326, 74, 110),
	Rect2(0, 468, 82, 108),
	Rect2(1188, 535, 66, 112),
	Rect2(1185, 745, 69, 120),
	Rect2(10, 770, 68, 112),
	Rect2(92, 784, 66, 106),
	Rect2(154, 780, 62, 110),
	Rect2(790, 640, 62, 110),
	Rect2(970, 980, 70, 112),
	Rect2(396, 1010, 68, 105),
	Rect2(502, 1000, 72, 118),
	Rect2(650, 1080, 70, 118),
	Rect2(870, 1090, 70, 118),
	Rect2(1180, 1042, 74, 110),
	# Hedges, bushes, fences, gates, gardens, and small obstacles
	Rect2(20, 323, 150, 20),
	Rect2(20, 450, 150, 20),
	Rect2(20, 323, 18, 148),
	Rect2(154, 323, 18, 148),
	Rect2(198, 128, 55, 20),
	Rect2(198, 145, 18, 138),
	Rect2(244, 262, 39, 20),
	Rect2(348, 262, 100, 20),
	Rect2(406, 128, 44, 20),
	Rect2(430, 140, 20, 122),
	Rect2(462, 191, 86, 20),
	Rect2(688, 126, 18, 160),
	Rect2(838, 128, 18, 160),
	Rect2(820, 262, 50, 28),
	Rect2(930, 128, 18, 152),
	Rect2(1130, 128, 18, 152),
	Rect2(948, 263, 50, 20),
	Rect2(1085, 263, 54, 20),
	Rect2(435, 480, 22, 142),
	Rect2(538, 572, 88, 42),
	Rect2(650, 596, 74, 28),
	Rect2(800, 480, 26, 160),
	Rect2(280, 692, 96, 22),
	Rect2(50, 586, 18, 128),
	Rect2(204, 586, 18, 128),
	Rect2(258, 692, 130, 22),
	Rect2(520, 665, 42, 26),
	Rect2(650, 665, 82, 32),
	Rect2(520, 820, 210, 90),
	Rect2(778, 790, 18, 132),
	Rect2(946, 790, 18, 132),
	Rect2(796, 912, 150, 20),
	Rect2(1000, 792, 18, 134),
	Rect2(1178, 792, 18, 134),
	Rect2(1020, 914, 160, 20),
	Rect2(688, 1002, 212, 24),
	Rect2(688, 1000, 18, 196),
	Rect2(898, 1000, 18, 196),
	Rect2(760, 1130, 70, 46),
	Rect2(960, 1032, 42, 180),
	Rect2(1176, 1032, 18, 180),
	Rect2(1000, 1160, 176, 20),
	Rect2(0, 922, 270, 64),
	Rect2(0, 978, 220, 276),
	Rect2(206, 1048, 70, 160)
]

@onready var local_player: CharacterBody2D = %LocalPlayer
@onready var object_layer: Node2D = $ObjectLayer
@onready var remote_players: Node2D = %RemotePlayers
@onready var interactables: Node2D = %Interactables
@onready var hud: CanvasLayer = %HUD
@onready var camera: Camera2D = %Camera2D

var current_interactable: Area2D
var remote_nodes: Dictionary = {}

func _ready() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_WIDTH
	camera.limit_bottom = MAP_HEIGHT
	_create_map_blockers()
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

func _create_map_blockers() -> void:
	for index in MAP_BLOCKERS.size():
		var rect: Rect2 = MAP_BLOCKERS[index]
		var body := StaticBody2D.new()
		body.name = "MapBlocker%s" % index
		body.collision_layer = 1
		body.collision_mask = 2
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		shape.position = rect.position + rect.size * 0.5
		body.add_child(shape)
		object_layer.add_child(body)

func start_session() -> void:
	hud.set_player_name(GameState.player_name)
	NetworkManager.connect_to_server(GameState.server_url, GameState.player_name)

func _process(_delta: float) -> void:
	hud.update_debug(local_player.global_position, PlayerRegistry.count())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable:
		var message: String = current_interactable.call("interact")
		hud.show_message(message)

func _on_local_input_changed(direction: Vector2, facing: String) -> void:
	NetworkManager.set_local_input(direction, facing)

func _on_network_connected(_client_id: String, players: Array) -> void:
	PlayerRegistry.set_players(players)
	_apply_players(players)
	hud.show_message("Connected to the shared meadow.")

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
