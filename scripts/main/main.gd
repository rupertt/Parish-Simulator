extends Node

const MAIN_MENU_SCENE := preload("res://scenes/ui/MainMenu.tscn")
const WORLD_SCENE := preload("res://scenes/world/TestMeadow.tscn")

var current_scene: Node

func _ready() -> void:
	_show_main_menu()

func _show_main_menu() -> void:
	_clear_current_scene()
	var menu := MAIN_MENU_SCENE.instantiate()
	menu.join_requested.connect(_start_game)
	add_child(menu)
	current_scene = menu

func _start_game(player_name: String, character_id: String) -> void:
	GameState.configure_session(player_name, character_id)
	_clear_current_scene()
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	current_scene = world
	world.start_session()

func _clear_current_scene() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
