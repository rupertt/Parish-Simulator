class_name RemotePlayer
extends Node2D

@onready var body: Polygon2D = %Body
@onready var name_label: Label = %NameLabel

var target_position := Vector2.ZERO

func _process(delta: float) -> void:
	position = position.lerp(target_position, min(delta * 12.0, 1.0))

func apply_state(state: Dictionary) -> void:
	target_position = Vector2(float(state.get("x", position.x)), float(state.get("y", position.y)))
	name_label.text = String(state.get("name", "Player"))
	body.modulate = Color(String(state.get("color", "#5d7fd8")))

	var facing := String(state.get("facing", "down"))
	match facing:
		"up":
			body.scale = Vector2(0.92, 1.0)
		"down":
			body.scale = Vector2(1.0, 1.0)
		"left":
			body.scale = Vector2(0.88, 1.0)
		"right":
			body.scale = Vector2(1.08, 1.0)
