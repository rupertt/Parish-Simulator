class_name WorldInteractable
extends Area2D

signal focus_entered(interactable: Area2D)
signal focus_exited(interactable: Area2D)

@export var prompt_text := "Press E"
@export var message_text := "Nothing happens yet."
@export var object_color := Color("#d8b56d")
@export_file("*.tscn") var target_scene_path := ""

@onready var visual: Polygon2D = %Visual

func _ready() -> void:
	add_to_group("interactable")
	visual.modulate = object_color
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func interact() -> String:
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.12, 1.12), 0.08)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.10)
	if not target_scene_path.is_empty():
		SceneLoader.change_to.call_deferred(target_scene_path)
	return message_text

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_local_player"):
		focus_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("is_local_player"):
		focus_exited.emit(self)
