extends Node2D

const ROOM_SCALE := 2.0 / 3.0
const ROOM_WIDTH := 1672.0 * ROOM_SCALE
const ROOM_HEIGHT := 941.0 * ROOM_SCALE
const PLAYER_START := Vector2(836, 810) * ROOM_SCALE
const PREACHING_POSITION := Vector2(575, 380) * ROOM_SCALE
const PULPIT_ENTRY_ZONE := Rect2(Vector2(500, 300) * ROOM_SCALE, Vector2(180, 160) * ROOM_SCALE)
const BLOCKERS := [
	Rect2(0, 0, 1672, 74),
	Rect2(0, 0, 280, 941),
	Rect2(1392, 0, 280, 941),
	Rect2(280, 0, 115, 178),
	Rect2(1277, 0, 115, 178),
	Rect2(280, 756, 390, 185),
	Rect2(1002, 756, 390, 185),
	Rect2(520, 68, 632, 260),
	Rect2(430, 440, 340, 330),
	Rect2(890, 330, 360, 440),
	Rect2(355, 360, 60, 370),
	Rect2(1260, 360, 60, 370)
]

@onready var local_player: CharacterBody2D = %LocalPlayer
@onready var object_layer: Node2D = $ObjectLayer
@onready var interactables: Node2D = %Interactables
@onready var hud: CanvasLayer = %HUD
@onready var camera: Camera2D = %Camera2D

var current_interactable: Area2D
var is_preaching := false

func _ready() -> void:
	local_player.global_position = PLAYER_START
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_WIDTH
	camera.limit_bottom = ROOM_HEIGHT
	hud.set_player_name(GameState.player_name)
	hud.set_status("Sanctuary")
	hud.show_message("You enter the sanctuary.")
	_create_blockers()

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

func _create_blockers() -> void:
	for index in BLOCKERS.size():
		var rect: Rect2 = BLOCKERS[index]
		var body := StaticBody2D.new()
		body.name = "RoomBlocker%s" % index
		body.collision_layer = 1
		body.collision_mask = 2
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size * ROOM_SCALE
		shape.shape = rectangle
		shape.position = (rect.position + rect.size * 0.5) * ROOM_SCALE
		body.add_child(shape)
		object_layer.add_child(body)

func _on_interactable_focus_entered(interactable: Area2D) -> void:
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
	local_player.global_position = PREACHING_POSITION
	local_player.z_index = 20
	local_player.call("face", "down")
	local_player.call("set_controls_locked", true)
	hud.set_status("Preaching")
	hud.set_prompt("Press E to end sermon")
	hud.show_message("You stand at the pulpit and begin preaching.")

func _end_preaching() -> void:
	is_preaching = false
	local_player.z_index = 0
	local_player.call("set_controls_locked", false)
	hud.set_status("Sanctuary")
	hud.set_prompt("")
	hud.show_message("You step back from the pulpit.")
