class_name BaseUIScreen
extends Control

@export var screen_id := ""
@export var close_on_cancel := true

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _unhandled_input(event: InputEvent) -> void:
	if visible and close_on_cancel and event.is_action_pressed("ui_cancel"):
		GameState.close_ui_screen(screen_id)
		get_viewport().set_input_as_handled()

func open_screen() -> void:
	visible = true

func close_screen() -> void:
	visible = false

func toggle_screen() -> void:
	visible = not visible
