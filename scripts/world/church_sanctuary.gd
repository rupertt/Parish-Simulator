extends Node2D

const ROOM_SCALE := 2.0 / 3.0
const ROOM_WIDTH := 1672.0 * ROOM_SCALE
const ROOM_HEIGHT := 941.0 * ROOM_SCALE
const WORLD_COLLISION_LAYER := 1
const PLAYER_COLLISION_LAYER := 2
const PLAYER_START := Vector2(836, 810) * ROOM_SCALE
const PULPIT_ENTRY_ZONE := Rect2(Vector2(500, 300) * ROOM_SCALE, Vector2(180, 160) * ROOM_SCALE)

const NAVIGATION_AREAS := [
	{
		"name": "CenterAisleNavigation",
		"points": [
			Vector2(774, 352),
			Vector2(898, 352),
			Vector2(898, 770),
			Vector2(1020, 770),
			Vector2(1020, 834),
			Vector2(652, 834),
			Vector2(652, 770),
			Vector2(774, 770)
		]
	},
	{
		"name": "LeftAisleNavigation",
		"points": [
			Vector2(284, 342),
			Vector2(404, 342),
			Vector2(404, 760),
			Vector2(652, 760),
			Vector2(652, 834),
			Vector2(284, 834)
		]
	},
	{
		"name": "RightAisleNavigation",
		"points": [
			Vector2(1268, 342),
			Vector2(1388, 342),
			Vector2(1388, 834),
			Vector2(1020, 834),
			Vector2(1020, 760),
			Vector2(1268, 760)
		]
	}
]

@onready var local_player: CharacterBody2D = %LocalPlayer
@onready var interactables: Node2D = %Interactables
@onready var hud: CanvasLayer = %HUD
@onready var camera: Camera2D = %Camera2D
@onready var preach_point: Marker2D = $Interactables/Pulpit/Preachpoint
@onready var pulpit_foreground: Polygon2D = $ObjectLayer/PulpitForeground

var current_interactable: Area2D
var is_preaching := false

func _ready() -> void:
	local_player.global_position = PLAYER_START
	_configure_player_collision()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_WIDTH
	camera.limit_bottom = ROOM_HEIGHT
	hud.set_player_name(GameState.player_name)
	hud.set_status("Sanctuary")
	hud.show_message("You enter the sanctuary.")
	_create_navigation_regions()

	for item in interactables.get_children():
		if item.has_signal("focus_entered"):
			item.focus_entered.connect(_on_interactable_focus_entered)
			item.focus_exited.connect(_on_interactable_focus_exited)

func _process(_delta: float) -> void:
	hud.update_debug(local_player.global_position, 1)
	if is_preaching or current_interactable != null:
		return
	if PULPIT_ENTRY_ZONE.has_point(local_player.global_position):
		hud.set_prompt("Press E to start preaching")
	else:
		hud.set_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_preaching:
		_end_preaching()
	elif event.is_action_pressed("interact") and PULPIT_ENTRY_ZONE.has_point(local_player.global_position):
		_start_preaching()
	elif event.is_action_pressed("interact") and current_interactable:
		if current_interactable.name == "Pulpit":
			_start_preaching()
			return
		var message: String = current_interactable.call("interact")
		if not message.is_empty():
			hud.show_message(message)

func _configure_player_collision() -> void:
	local_player.set_collision_layer_value(PLAYER_COLLISION_LAYER, true)
	local_player.set_collision_mask_value(WORLD_COLLISION_LAYER, true)

func _create_navigation_regions() -> void:
	for nav_area in NAVIGATION_AREAS:
		var points := _scale_points(nav_area["points"])
		var region := NavigationRegion2D.new()
		var polygon := NavigationPolygon.new()
		var indices := PackedInt32Array()

		for index in points.size():
			indices.append(index)

		polygon.vertices = points
		polygon.add_polygon(indices)
		region.name = nav_area["name"]
		region.navigation_polygon = polygon
		add_child(region)

func _scale_points(points: Array) -> PackedVector2Array:
	var scaled_points := PackedVector2Array()
	for point: Vector2 in points:
		scaled_points.append(point * ROOM_SCALE)
	return scaled_points

func _on_interactable_focus_entered(interactable: Area2D) -> void:
	if is_preaching:
		return
	current_interactable = interactable
	hud.set_prompt(String(interactable.get("prompt_text")))

func _on_interactable_focus_exited(interactable: Area2D) -> void:
	if is_preaching:
		return
	if current_interactable == interactable:
		current_interactable = null
		hud.set_prompt("")

func _start_preaching() -> void:
	is_preaching = true
	local_player.global_position = preach_point.global_position
	local_player.z_index = 20
	pulpit_foreground.visible = true
	local_player.call("face", "down")
	local_player.call("set_controls_locked", true)
	hud.set_status("Preaching")
	hud.set_prompt("Press E to end sermon")
	hud.show_message("You stand at the pulpit and begin preaching.")

func _end_preaching() -> void:
	is_preaching = false
	pulpit_foreground.visible = false
	local_player.z_index = 0
	local_player.call("set_controls_locked", false)
	hud.set_status("Sanctuary")
	hud.set_prompt("")
	hud.show_message("You step back from the pulpit.")
