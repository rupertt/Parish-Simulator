extends Node2D

const ROOM_SCALE := 1.0 / 3.0
const ROOM_WIDTH := 1672.0 * ROOM_SCALE
const ROOM_HEIGHT := 941.0 * ROOM_SCALE
const PLAYER_START := Vector2(836, 780) * ROOM_SCALE
const SANCTUARY_ENTRY_ZONE := Rect2(Vector2(236, 126), Vector2(86, 136))
const BLOCKERS := [
	Rect2(0, 0, 1672, 78),
	Rect2(0, 0, 310, 941),
	Rect2(1362, 0, 310, 941),
	Rect2(310, 0, 92, 154),
	Rect2(1270, 0, 92, 154),
	Rect2(310, 760, 390, 181),
	Rect2(972, 760, 390, 181),
	Rect2(710, 130, 252, 128),
	Rect2(1110, 230, 186, 96),
	Rect2(1070, 555, 250, 120),
	Rect2(360, 350, 120, 64),
	Rect2(355, 555, 105, 128),
	Rect2(1215, 385, 114, 70)
]

@onready var local_player: CharacterBody2D = %LocalPlayer
@onready var object_layer: Node2D = $ObjectLayer
@onready var interactables: Node2D = %Interactables
@onready var hud: CanvasLayer = %HUD
@onready var camera: Camera2D = %Camera2D

var current_interactable: Area2D

func _ready() -> void:
	local_player.global_position = PLAYER_START
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_WIDTH
	camera.limit_bottom = ROOM_HEIGHT
	hud.set_player_name(GameState.player_name)
	hud.set_status("Inside Church")
	hud.show_message("You step into the church entrance.")
	_create_blockers()

	for item in interactables.get_children():
		if item.has_signal("focus_entered"):
			item.focus_entered.connect(_on_interactable_focus_entered)
			item.focus_exited.connect(_on_interactable_focus_exited)

func _process(_delta: float) -> void:
	hud.update_debug(local_player.global_position, 1)
	if current_interactable == null:
		if SANCTUARY_ENTRY_ZONE.has_point(local_player.global_position):
			hud.set_prompt("Press E to enter sanctuary")
		else:
			hud.set_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable:
		var message: String = current_interactable.call("interact")
		if not message.is_empty():
			hud.show_message(message)
	elif event.is_action_pressed("interact") and SANCTUARY_ENTRY_ZONE.has_point(local_player.global_position):
		hud.show_message("You step toward the sanctuary.")
		SceneLoader.change_to.call_deferred("res://scenes/world/ChurchSanctuary.tscn")

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
	if current_interactable == interactable:
		current_interactable = null
		hud.set_prompt("")
