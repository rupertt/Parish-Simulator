extends Node2D

const MAP_WIDTH := 1254
const MAP_HEIGHT := 1254
const CHURCH_ENTRY_ZONE := Rect2(Vector2(590, 560), Vector2(120, 120))

const REMOTE_PLAYER_SCENE := preload("res://scenes/player/RemotePlayer.tscn")
const MAP_COLLISION_SHAPES := [
	# Building walls only. Roofs and overhangs remain visual foreground.
	{ "kind": "polygon", "points": [Vector2(96, 118), Vector2(208, 118), Vector2(208, 184), Vector2(190, 200), Vector2(112, 200), Vector2(96, 184)] },
	{ "kind": "polygon", "points": [Vector2(286, 120), Vector2(390, 120), Vector2(390, 188), Vector2(374, 204), Vector2(302, 204), Vector2(286, 188)] },
	{ "kind": "polygon", "points": [Vector2(486, 122), Vector2(604, 122), Vector2(604, 188), Vector2(586, 204), Vector2(504, 204), Vector2(486, 188)] },
	{ "kind": "polygon", "points": [Vector2(686, 126), Vector2(796, 126), Vector2(796, 192), Vector2(778, 208), Vector2(704, 208), Vector2(686, 192)] },
	{ "kind": "polygon", "points": [Vector2(900, 126), Vector2(1028, 126), Vector2(1028, 200), Vector2(1008, 218), Vector2(920, 218), Vector2(900, 200)] },
	{ "kind": "polygon", "points": [Vector2(1086, 122), Vector2(1202, 122), Vector2(1202, 194), Vector2(1184, 210), Vector2(1104, 210), Vector2(1086, 194)] },
	{ "kind": "polygon", "points": [Vector2(192, 344), Vector2(386, 344), Vector2(386, 420), Vector2(362, 442), Vector2(216, 442), Vector2(192, 420)] },
	{ "kind": "polygon", "points": [Vector2(900, 360), Vector2(1122, 360), Vector2(1122, 458), Vector2(1096, 480), Vector2(926, 480), Vector2(900, 458)] },
	{ "kind": "polygon", "points": [Vector2(560, 350), Vector2(714, 350), Vector2(714, 542), Vector2(692, 568), Vector2(582, 568), Vector2(560, 542)] },
	{ "kind": "polygon", "points": [Vector2(250, 562), Vector2(412, 562), Vector2(412, 650), Vector2(388, 672), Vector2(274, 672), Vector2(250, 650)] },
	{ "kind": "polygon", "points": [Vector2(46, 648), Vector2(190, 648), Vector2(190, 732), Vector2(168, 752), Vector2(68, 752), Vector2(46, 732)] },
	{ "kind": "polygon", "points": [Vector2(1044, 578), Vector2(1178, 578), Vector2(1178, 662), Vector2(1160, 680), Vector2(1062, 680), Vector2(1044, 662)] },
	{ "kind": "polygon", "points": [Vector2(292, 790), Vector2(426, 790), Vector2(426, 872), Vector2(406, 890), Vector2(312, 890), Vector2(292, 872)] },
	{ "kind": "polygon", "points": [Vector2(1114, 796), Vector2(1244, 796), Vector2(1244, 878), Vector2(1226, 896), Vector2(1132, 896), Vector2(1114, 878)] },
	{ "kind": "polygon", "points": [Vector2(400, 1050), Vector2(520, 1050), Vector2(520, 1132), Vector2(500, 1150), Vector2(420, 1150), Vector2(400, 1132)] },
	{ "kind": "polygon", "points": [Vector2(592, 1050), Vector2(722, 1050), Vector2(722, 1132), Vector2(702, 1150), Vector2(612, 1150), Vector2(592, 1132)] },
	{ "kind": "polygon", "points": [Vector2(796, 1048), Vector2(928, 1048), Vector2(928, 1130), Vector2(908, 1148), Vector2(816, 1148), Vector2(796, 1130)] },
	{ "kind": "polygon", "points": [Vector2(1040, 1050), Vector2(1184, 1050), Vector2(1184, 1134), Vector2(1162, 1152), Vector2(1062, 1152), Vector2(1040, 1134)] },
	# Tree trunks, rocks, wells, graves, and bushes use tight rounded footprints.
	{ "kind": "circle", "position": Vector2(28, 78), "radius": 15 },
	{ "kind": "circle", "position": Vector2(125, 34), "radius": 14 },
	{ "kind": "circle", "position": Vector2(224, 34), "radius": 14 },
	{ "kind": "circle", "position": Vector2(348, 34), "radius": 15 },
	{ "kind": "circle", "position": Vector2(492, 42), "radius": 14 },
	{ "kind": "circle", "position": Vector2(594, 48), "radius": 14 },
	{ "kind": "circle", "position": Vector2(772, 36), "radius": 15 },
	{ "kind": "circle", "position": Vector2(968, 36), "radius": 15 },
	{ "kind": "circle", "position": Vector2(1124, 36), "radius": 15 },
	{ "kind": "circle", "position": Vector2(1225, 72), "radius": 16 },
	{ "kind": "circle", "position": Vector2(30, 185), "radius": 15 },
	{ "kind": "circle", "position": Vector2(1226, 240), "radius": 16 },
	{ "kind": "circle", "position": Vector2(30, 380), "radius": 16 },
	{ "kind": "circle", "position": Vector2(1222, 430), "radius": 16 },
	{ "kind": "circle", "position": Vector2(1222, 628), "radius": 16 },
	{ "kind": "circle", "position": Vector2(38, 850), "radius": 16 },
	{ "kind": "circle", "position": Vector2(36, 1140), "radius": 16 },
	{ "kind": "circle", "position": Vector2(146, 1210), "radius": 15 },
	{ "kind": "circle", "position": Vector2(288, 1210), "radius": 15 },
	{ "kind": "circle", "position": Vector2(510, 1210), "radius": 15 },
	{ "kind": "circle", "position": Vector2(718, 1210), "radius": 15 },
	{ "kind": "circle", "position": Vector2(908, 1210), "radius": 15 },
	{ "kind": "circle", "position": Vector2(1148, 1210), "radius": 16 },
	{ "kind": "circle", "position": Vector2(633, 778), "radius": 28 },
	{ "kind": "circle", "position": Vector2(632, 826), "radius": 20 },
	{ "kind": "circle", "position": Vector2(820, 764), "radius": 12 },
	{ "kind": "circle", "position": Vector2(890, 764), "radius": 12 },
	{ "kind": "circle", "position": Vector2(942, 820), "radius": 12 },
	{ "kind": "circle", "position": Vector2(828, 850), "radius": 12 },
	{ "kind": "circle", "position": Vector2(912, 866), "radius": 12 },
	{ "kind": "circle", "position": Vector2(226, 520), "radius": 12 },
	{ "kind": "circle", "position": Vector2(1180, 92), "radius": 11 },
	{ "kind": "circle", "position": Vector2(1168, 415), "radius": 12 },
	# Fences and hedges are thin capsules instead of large rectangles.
	{ "kind": "capsule", "from": Vector2(72, 76), "to": Vector2(238, 76), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(74, 184), "to": Vector2(232, 184), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(274, 76), "to": Vector2(416, 76), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(274, 184), "to": Vector2(416, 184), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(476, 76), "to": Vector2(626, 76), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(476, 184), "to": Vector2(626, 184), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(672, 76), "to": Vector2(822, 76), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(672, 184), "to": Vector2(822, 184), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(886, 76), "to": Vector2(1048, 76), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(886, 184), "to": Vector2(1048, 184), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(1070, 76), "to": Vector2(1230, 76), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(1070, 184), "to": Vector2(1230, 184), "radius": 5 },
	{ "kind": "capsule", "from": Vector2(460, 304), "to": Vector2(460, 570), "radius": 8 },
	{ "kind": "capsule", "from": Vector2(796, 304), "to": Vector2(796, 586), "radius": 8 },
	{ "kind": "capsule", "from": Vector2(530, 296), "to": Vector2(530, 445), "radius": 9 },
	{ "kind": "capsule", "from": Vector2(746, 296), "to": Vector2(746, 455), "radius": 9 },
	{ "kind": "capsule", "from": Vector2(56, 462), "to": Vector2(202, 462), "radius": 6 },
	{ "kind": "capsule", "from": Vector2(56, 560), "to": Vector2(202, 560), "radius": 6 },
	{ "kind": "capsule", "from": Vector2(864, 312), "to": Vector2(864, 500), "radius": 6 },
	{ "kind": "capsule", "from": Vector2(1138, 312), "to": Vector2(1138, 470), "radius": 6 },
	{ "kind": "capsule", "from": Vector2(862, 494), "to": Vector2(1138, 494), "radius": 6 },
	{ "kind": "capsule", "from": Vector2(772, 726), "to": Vector2(1018, 726), "radius": 7 },
	{ "kind": "capsule", "from": Vector2(772, 906), "to": Vector2(1018, 906), "radius": 7 },
	{ "kind": "capsule", "from": Vector2(782, 724), "to": Vector2(782, 906), "radius": 7 },
	{ "kind": "capsule", "from": Vector2(1010, 724), "to": Vector2(1010, 906), "radius": 7 },
	{ "kind": "capsule", "from": Vector2(536, 718), "to": Vector2(536, 910), "radius": 8 },
	{ "kind": "capsule", "from": Vector2(746, 718), "to": Vector2(746, 910), "radius": 8 },
	{ "kind": "capsule", "from": Vector2(548, 732), "to": Vector2(724, 732), "radius": 8 },
	{ "kind": "capsule", "from": Vector2(548, 894), "to": Vector2(724, 894), "radius": 8 },
	{ "kind": "polygon", "points": [Vector2(0, 845), Vector2(120, 820), Vector2(160, 930), Vector2(265, 1015), Vector2(260, 1254), Vector2(0, 1254)] }
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
	_create_map_collision()
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

func _create_map_collision() -> void:
	for index in MAP_COLLISION_SHAPES.size():
		var shape_data: Dictionary = MAP_COLLISION_SHAPES[index]
		var body := StaticBody2D.new()
		body.name = "MapCollision%s" % index
		body.collision_layer = 1
		body.collision_mask = 2
		var shape := CollisionShape2D.new()
		var kind := String(shape_data.get("kind", ""))
		if kind == "polygon":
			var polygon := ConvexPolygonShape2D.new()
			polygon.points = PackedVector2Array(shape_data["points"])
			shape.shape = polygon
		elif kind == "circle":
			var circle := CircleShape2D.new()
			circle.radius = float(shape_data["radius"])
			shape.shape = circle
			shape.position = shape_data["position"]
		elif kind == "capsule":
			var start: Vector2 = shape_data["from"]
			var end: Vector2 = shape_data["to"]
			var capsule := CapsuleShape2D.new()
			capsule.radius = float(shape_data["radius"])
			capsule.height = start.distance_to(end) + capsule.radius * 2.0
			shape.shape = capsule
			shape.position = (start + end) * 0.5
			shape.rotation = (end - start).angle() + PI * 0.5
		else:
			push_warning("Unknown map collision kind: %s" % kind)
			continue
		body.add_child(shape)
		object_layer.add_child(body)

func start_session() -> void:
	hud.set_player_name(GameState.player_name)
	NetworkManager.connect_to_server(GameState.server_url, GameState.player_name)

func _process(_delta: float) -> void:
	hud.update_debug(local_player.global_position, PlayerRegistry.count())
	if current_interactable == null:
		if CHURCH_ENTRY_ZONE.has_point(local_player.global_position):
			hud.set_prompt("Press E to enter church")
		else:
			hud.set_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable:
		var message: String = current_interactable.call("interact")
		hud.show_message(message)
	elif event.is_action_pressed("interact") and CHURCH_ENTRY_ZONE.has_point(local_player.global_position):
		hud.show_message("You open the church door.")
		SceneLoader.change_to.call_deferred("res://scenes/world/ChurchEntrance.tscn")

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
