extends Node2D

const MAP_WIDTH := 1600
const MAP_HEIGHT := 1400
const GRASS_TILE_SIZE := 128

const REMOTE_PLAYER_SCENE := preload("res://scenes/player/RemotePlayer.tscn")
const INTERACTABLE_SCENE := preload("res://scenes/interactables/Interactable.tscn")
const GRASS_TEXTURE := preload("res://assets/art/tilesets/grass_tile.png")
const DIRT_PATH_TEXTURE := preload("res://assets/art/tilesets/dirt_path_tile.png")
const DIRT_TILE_TEXTURE := preload("res://assets/art/tilesets/dirt_tile.png")
const GRAVEL_TILE_TEXTURE := preload("res://assets/art/tilesets/gravel_tile.png")
const STONE_TILE_TEXTURE := preload("res://assets/art/tilesets/stone_tile.png")
const HOUSE_TEXTURE := preload("res://assets/art/objects/village_house_red_roof.png")
const CHURCH_TEXTURE := preload("res://assets/art/objects/stone_church.png")
const TREE_TEXTURE := preload("res://assets/art/objects/oak_tree.png")
const BUSH_TEXTURE := preload("res://assets/art/objects/round_bush.png")
const FENCE_TEXTURE := preload("res://assets/art/objects/wooden_fence_segment.png")
const GATE_TEXTURE := preload("res://assets/art/objects/wooden_gate.png")
const WELL_TEXTURE := preload("res://assets/art/objects/stone_well.png")
const SIGN_TEXTURE := preload("res://assets/art/objects/wooden_sign_post.png")
const GRAVESTONE_TEXTURE := preload("res://assets/art/objects/gravestone.png")
const CROSS_TEXTURE := preload("res://assets/art/objects/graveyard_cross.png")
const LAMP_TEXTURE := preload("res://assets/art/objects/lamp_post.png")
const FLOWERS_TEXTURE := preload("res://assets/art/objects/flower_garden_patch.png")

const ROAD_LINES := []
const ROAD_TILE_SIZE := 32
const ROAD_HALF_WIDTH := 32
const MAP_EDITOR_SAVE_PATH := "user://village_layout_v2.json"
const MAP_EDITOR_GRID_SIZE := 16
const MAP_EDITOR_TILE_GRID_SIZE := 32

const TILE_DEFINITIONS := {
	"dirt_tile": { "label": "Dirt", "texture": DIRT_TILE_TEXTURE, "scale": Vector2.ONE },
	"gravel_tile": { "label": "Gravel", "texture": GRAVEL_TILE_TEXTURE, "scale": Vector2.ONE },
	"stone_tile": { "label": "Stone", "texture": STONE_TILE_TEXTURE, "scale": Vector2.ONE }
}

const OBJECT_DEFINITIONS := {
	"house": { "label": "House", "texture": HOUSE_TEXTURE, "scale": Vector2(0.42, 0.42), "depth": true, "foreground_crop": 0.70, "collision_size": Vector2(0.62, 0.22), "collision_offset": Vector2(0.0, 0.29) },
	"church": { "label": "Church", "texture": CHURCH_TEXTURE, "scale": Vector2(0.58, 0.58), "depth": true, "foreground_crop": 0.72, "collision_size": Vector2(0.58, 0.24), "collision_offset": Vector2(0.0, 0.28), "church_entry": true, "entry_offset": Vector2(0.0, 0.48), "entry_size": Vector2(72, 48) },
	"tree": { "label": "Tree", "texture": TREE_TEXTURE, "scale": Vector2(0.34, 0.34) },
	"bush": { "label": "Bush", "texture": BUSH_TEXTURE, "scale": Vector2(0.22, 0.22) },
	"fence": { "label": "Fence", "texture": FENCE_TEXTURE, "scale": Vector2(0.42, 0.22) },
	"gate": { "label": "Gate", "texture": GATE_TEXTURE, "scale": Vector2(0.24, 0.24) },
	"well": { "label": "Well", "texture": WELL_TEXTURE, "scale": Vector2(0.30, 0.30) },
	"sign": { "label": "Sign", "texture": SIGN_TEXTURE, "scale": Vector2(0.26, 0.26) },
	"gravestone": { "label": "Grave", "texture": GRAVESTONE_TEXTURE, "scale": Vector2(0.20, 0.20) },
	"cross": { "label": "Cross", "texture": CROSS_TEXTURE, "scale": Vector2(0.18, 0.18) },
	"lamp": { "label": "Lamp", "texture": LAMP_TEXTURE, "scale": Vector2(0.22, 0.22) },
	"flowers": { "label": "Flowers", "texture": FLOWERS_TEXTURE, "scale": Vector2(0.22, 0.22) }
}

const DEFAULT_OBJECTS := []
const DEFAULT_TILES := []

const MAP_COLLISION_SHAPES := []

@onready var local_player: CharacterBody2D = %LocalPlayer
@onready var ground_layer: Node2D = $GroundLayer
@onready var object_layer: Node2D = $ObjectLayer
@onready var remote_players: Node2D = %RemotePlayers
@onready var interactables: Node2D = %Interactables
@onready var hud: CanvasLayer = %HUD
@onready var camera: Camera2D = %Camera2D
@onready var above_player_layer: Node2D = $AbovePlayerLayer

var current_interactable: Area2D
var remote_nodes: Dictionary = {}
var map_editor_enabled := false
var selected_editor_type := "dirt_tile"
var selected_editor_sprite: Sprite2D
var dragged_editor_sprite: Sprite2D
var drag_offset := Vector2.ZERO
var editor_status_label: Label
var editor_selection_box: Line2D
var editor_layer: CanvasLayer

func _ready() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_WIDTH
	camera.limit_bottom = MAP_HEIGHT
	_create_grass_background()
	_create_roads()
	_create_village_objects()
	_create_map_collision()
	_create_map_editor_ui()
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

func _create_grass_background() -> void:
	for y in range(0, MAP_HEIGHT, GRASS_TILE_SIZE):
		for x in range(0, MAP_WIDTH, GRASS_TILE_SIZE):
			var tile := Sprite2D.new()
			tile.texture = GRASS_TEXTURE
			tile.centered = false
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.position = Vector2(x, y)
			ground_layer.add_child(tile)

func _create_roads() -> void:
	for line_points in ROAD_LINES:
		_add_tiled_road(line_points[0], line_points[1])

func _add_tiled_road(start: Vector2, end: Vector2) -> void:
	var min_x: int = int(floor((min(start.x, end.x) - ROAD_HALF_WIDTH) / ROAD_TILE_SIZE)) * ROAD_TILE_SIZE
	var max_x: int = int(ceil((max(start.x, end.x) + ROAD_HALF_WIDTH) / ROAD_TILE_SIZE)) * ROAD_TILE_SIZE
	var min_y: int = int(floor((min(start.y, end.y) - ROAD_HALF_WIDTH) / ROAD_TILE_SIZE)) * ROAD_TILE_SIZE
	var max_y: int = int(ceil((max(start.y, end.y) + ROAD_HALF_WIDTH) / ROAD_TILE_SIZE)) * ROAD_TILE_SIZE

	for y in range(min_y, max_y, ROAD_TILE_SIZE):
		for x in range(min_x, max_x, ROAD_TILE_SIZE):
			if x < 0 or y < 0 or x >= MAP_WIDTH or y >= MAP_HEIGHT:
				continue
			_add_road_tile(Vector2(x, y))

func _add_road_tile(tile_position: Vector2) -> void:
	var tile := Sprite2D.new()
	tile.texture = DIRT_PATH_TEXTURE
	tile.centered = false
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile.position = tile_position
	tile.z_index = 1
	ground_layer.add_child(tile)

func _create_village_objects() -> void:
	var layout := _load_editor_layout()
	for item in layout["tiles"]:
		_add_tile(item)
	for item in layout["objects"]:
		_add_object(item)

func _get_editor_definition(editor_type: String) -> Dictionary:
	if TILE_DEFINITIONS.has(editor_type):
		return TILE_DEFINITIONS[editor_type]
	return OBJECT_DEFINITIONS.get(editor_type, {})

func _is_editor_tile_type(editor_type: String) -> bool:
	return TILE_DEFINITIONS.has(editor_type)

func _add_tile(item: Dictionary) -> void:
	var tile_type := String(item.get("type", "dirt_tile"))
	if not TILE_DEFINITIONS.has(tile_type):
		return
	var definition: Dictionary = TILE_DEFINITIONS[tile_type]
	var sprite := Sprite2D.new()
	sprite.name = String(item.get("name", "%sTile" % tile_type.capitalize()))
	sprite.texture = definition["texture"]
	sprite.centered = false
	sprite.position = item["position"]
	sprite.scale = item.get("scale", definition["scale"])
	sprite.rotation = float(item.get("rotation", 0.0))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 2
	sprite.set_meta("editor_type", tile_type)
	sprite.set_meta("editor_kind", "tile")
	ground_layer.add_child(sprite)

func _add_object(item: Dictionary) -> void:
	var object_type := String(item.get("type", "house"))
	if not OBJECT_DEFINITIONS.has(object_type):
		return
	var definition: Dictionary = OBJECT_DEFINITIONS[object_type]
	var sprite := Sprite2D.new()
	sprite.name = String(item.get("name", "%sObject" % object_type.capitalize()))
	sprite.texture = definition["texture"]
	sprite.position = item["position"]
	sprite.scale = item.get("scale", definition["scale"])
	sprite.rotation = float(item.get("rotation", 0.0))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 12
	sprite.set_meta("editor_type", object_type)
	sprite.set_meta("editor_kind", "object")
	object_layer.add_child(sprite)
	if bool(definition.get("depth", false)):
		_add_depth_for_object(sprite, definition)
	if bool(definition.get("church_entry", false)):
		_add_church_entry_for_object(sprite, definition)

func _add_depth_for_object(sprite: Sprite2D, definition: Dictionary) -> void:
	if sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	var foreground_height := int(round(texture_size.y * float(definition.get("foreground_crop", 0.7))))
	foreground_height = clampi(foreground_height, 1, int(texture_size.y))

	var foreground := Sprite2D.new()
	foreground.name = "%sForeground" % sprite.name
	foreground.texture = sprite.texture
	foreground.region_enabled = true
	foreground.region_rect = Rect2(Vector2.ZERO, Vector2(texture_size.x, foreground_height))
	foreground.scale = sprite.scale
	foreground.rotation = sprite.rotation
	foreground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	foreground.z_index = 80
	foreground.set_meta("editor_companion", true)
	foreground.set_meta("source_object", sprite.name)
	above_player_layer.add_child(foreground)

	var body := StaticBody2D.new()
	body.name = "%sCollision" % sprite.name
	body.collision_layer = 1
	body.collision_mask = 2
	body.set_meta("editor_companion", true)
	body.set_meta("source_object", sprite.name)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	var collision_ratio: Vector2 = definition.get("collision_size", Vector2(0.6, 0.22))
	box.size = texture_size * sprite.scale.abs() * collision_ratio
	shape.shape = box
	body.add_child(shape)
	object_layer.add_child(body)

	sprite.set_meta("foreground_path", foreground.get_path())
	sprite.set_meta("collision_path", body.get_path())
	_sync_depth_for_object(sprite)

func _add_church_entry_for_object(sprite: Sprite2D, definition: Dictionary) -> void:
	if sprite.texture == null:
		return
	var entry := INTERACTABLE_SCENE.instantiate() as Area2D
	entry.name = "%sEntry" % sprite.name
	entry.set("prompt_text", "Press E to enter church")
	entry.set("message_text", "You open the church door.")
	entry.set("object_color", Color(0.4, 0.275, 0.188, 0.0))
	entry.set("target_scene_path", "res://scenes/world/ChurchEntrance.tscn")
	entry.set_meta("editor_companion", true)
	entry.set_meta("source_object", sprite.name)
	interactables.add_child(entry)
	var trigger := entry.get_node_or_null("Trigger") as CollisionShape2D
	if trigger:
		var shape := RectangleShape2D.new()
		shape.size = definition.get("entry_size", Vector2(48, 36))
		trigger.shape = shape
	if entry.has_signal("focus_entered"):
		entry.focus_entered.connect(_on_interactable_focus_entered)
		entry.focus_exited.connect(_on_interactable_focus_exited)
	sprite.set_meta("entry_path", entry.get_path())
	_sync_church_entry_for_object(sprite, definition)

func _sync_church_entry_for_object(sprite: Sprite2D, definition: Dictionary = {}) -> void:
	if sprite == null or not sprite.has_meta("entry_path") or sprite.texture == null:
		return
	if definition.is_empty():
		definition = _get_editor_definition(String(sprite.get_meta("editor_type", "")))
	var entry := get_node_or_null(NodePath(String(sprite.get_meta("entry_path")))) as Area2D
	if entry == null:
		return
	var texture_size := sprite.texture.get_size()
	var entry_offset: Vector2 = definition.get("entry_offset", Vector2.ZERO)
	var local_entry_offset := texture_size * sprite.scale.abs() * entry_offset
	entry.position = sprite.position + local_entry_offset.rotated(sprite.rotation)
	entry.rotation = sprite.rotation
	entry.visible = sprite.visible

func _sync_depth_for_object(sprite: Sprite2D) -> void:
	if sprite == null or not sprite.has_meta("foreground_path") or not sprite.has_meta("collision_path"):
		return
	var object_type := String(sprite.get_meta("editor_type", ""))
	var definition := _get_editor_definition(object_type)
	if definition.is_empty() or sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	var foreground := get_node_or_null(NodePath(String(sprite.get_meta("foreground_path")))) as Sprite2D
	if foreground:
		var foreground_height := foreground.region_rect.size.y
		var local_offset := Vector2(0.0, (foreground_height - texture_size.y) * sprite.scale.y * 0.5)
		foreground.position = sprite.position + local_offset.rotated(sprite.rotation)
		foreground.scale = sprite.scale
		foreground.rotation = sprite.rotation
		foreground.visible = sprite.visible

	var body := get_node_or_null(NodePath(String(sprite.get_meta("collision_path")))) as StaticBody2D
	if body:
		var collision_offset: Vector2 = definition.get("collision_offset", Vector2.ZERO)
		var local_collision_offset := texture_size * sprite.scale.abs() * collision_offset
		body.position = sprite.position + local_collision_offset.rotated(sprite.rotation)
		body.rotation = sprite.rotation
	_sync_church_entry_for_object(sprite, definition)

func _remove_depth_for_object(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	if sprite.has_meta("foreground_path"):
		var foreground := get_node_or_null(NodePath(String(sprite.get_meta("foreground_path"))))
		if foreground:
			foreground.queue_free()
	if sprite.has_meta("collision_path"):
		var body := get_node_or_null(NodePath(String(sprite.get_meta("collision_path"))))
		if body:
			body.queue_free()
	_remove_church_entry_for_object(sprite)

func _remove_church_entry_for_object(sprite: Sprite2D) -> void:
	if sprite == null or not sprite.has_meta("entry_path"):
		return
	var entry := get_node_or_null(NodePath(String(sprite.get_meta("entry_path"))))
	if entry:
		if current_interactable == entry:
			current_interactable = null
			hud.set_prompt("")
		entry.queue_free()

func _empty_editor_layout() -> Dictionary:
	return {
		"objects": DEFAULT_OBJECTS.duplicate(true),
		"tiles": DEFAULT_TILES.duplicate(true)
	}

func _load_editor_layout() -> Dictionary:
	if not FileAccess.file_exists(MAP_EDITOR_SAVE_PATH):
		return _empty_editor_layout()
	var file := FileAccess.open(MAP_EDITOR_SAVE_PATH, FileAccess.READ)
	if file == null:
		return _empty_editor_layout()
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return _empty_editor_layout()
	return {
		"objects": _objects_from_json_array(parsed.get("objects", [])),
		"tiles": _tiles_from_json_array(parsed.get("tiles", []))
	}

func _tiles_from_json_array(items: Array) -> Array:
	var tiles: Array = []
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var tile_type := String(item.get("type", ""))
		if not TILE_DEFINITIONS.has(tile_type):
			continue
		var position_values: Array = item.get("position", [0.0, 0.0])
		var scale_values: Array = item.get("scale", _vector_to_array(TILE_DEFINITIONS[tile_type]["scale"]))
		tiles.append({
			"name": String(item.get("name", "%sTile" % tile_type.capitalize())),
			"type": tile_type,
			"position": Vector2(float(position_values[0]), float(position_values[1])),
			"scale": Vector2(float(scale_values[0]), float(scale_values[1])),
			"rotation": float(item.get("rotation", 0.0))
		})
	return tiles

func _objects_from_json_array(items: Array) -> Array:
	var objects: Array = []
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var object_type := String(item.get("type", ""))
		if not OBJECT_DEFINITIONS.has(object_type):
			continue
		var position_values: Array = item.get("position", [0.0, 0.0])
		var scale_values: Array = item.get("scale", _vector_to_array(OBJECT_DEFINITIONS[object_type]["scale"]))
		objects.append({
			"name": String(item.get("name", "%sObject" % object_type.capitalize())),
			"type": object_type,
			"position": Vector2(float(position_values[0]), float(position_values[1])),
			"scale": Vector2(float(scale_values[0]), float(scale_values[1])),
			"rotation": float(item.get("rotation", 0.0))
		})
	return objects

func _create_map_collision() -> void:
	for index in MAP_COLLISION_SHAPES.size():
		var shape_data: Dictionary = MAP_COLLISION_SHAPES[index]
		var body := StaticBody2D.new()
		body.name = "MapCollision%s" % index
		body.collision_layer = 1
		body.collision_mask = 2
		var shape := CollisionShape2D.new()
		var kind := String(shape_data.get("kind", ""))
		if kind == "footprint":
			var polygon := ConvexPolygonShape2D.new()
			var size: Vector2 = shape_data["size"]
			polygon.points = _make_footprint_points(size)
			shape.shape = polygon
			shape.position = shape_data["position"]
		elif kind == "polygon":
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

func _make_footprint_points(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	var bevel: float = min(18.0, size.x * 0.18)
	return PackedVector2Array([
		Vector2(-half.x + bevel, -half.y),
		Vector2(half.x - bevel, -half.y),
		Vector2(half.x, -half.y + bevel),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
		Vector2(-half.x, -half.y + bevel),
	])

func _create_map_editor_ui() -> void:
	editor_layer = CanvasLayer.new()
	editor_layer.name = "MapEditor"
	editor_layer.layer = 50
	add_child(editor_layer)

	var panel := PanelContainer.new()
	panel.name = "EditorPanel"
	panel.visible = false
	panel.custom_minimum_size = Vector2(374, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(10, 10)
	editor_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 3)
	margin.add_child(list)

	var title := Label.new()
	title.text = "Map Editor"
	list.add_child(title)

	var tile_title := Label.new()
	tile_title.text = "Tiles"
	list.add_child(tile_title)

	var tile_palette := GridContainer.new()
	tile_palette.columns = 3
	tile_palette.add_theme_constant_override("h_separation", 4)
	tile_palette.add_theme_constant_override("v_separation", 3)
	list.add_child(tile_palette)

	var ordered_tiles := ["dirt_tile", "gravel_tile", "stone_tile"]
	for tile_type in ordered_tiles:
		var tile_definition: Dictionary = TILE_DEFINITIONS[tile_type]
		var tile_button := Button.new()
		tile_button.text = String(tile_definition["label"])
		tile_button.custom_minimum_size = Vector2(116, 24)
		tile_button.pressed.connect(_select_editor_type.bind(tile_type))
		tile_palette.add_child(tile_button)

	var object_title := Label.new()
	object_title.text = "Objects"
	list.add_child(object_title)

	var palette := GridContainer.new()
	palette.columns = 3
	palette.add_theme_constant_override("h_separation", 4)
	palette.add_theme_constant_override("v_separation", 3)
	list.add_child(palette)

	var ordered_types := ["house", "church", "tree", "bush", "fence", "gate", "well", "sign", "gravestone", "cross", "lamp", "flowers"]
	for object_type in ordered_types:
		var definition: Dictionary = OBJECT_DEFINITIONS[object_type]
		var button := Button.new()
		button.text = String(definition["label"])
		button.custom_minimum_size = Vector2(116, 24)
		button.pressed.connect(_select_editor_type.bind(object_type))
		palette.add_child(button)

	var separator := HSeparator.new()
	list.add_child(separator)

	var actions := GridContainer.new()
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 4)
	actions.add_theme_constant_override("v_separation", 3)
	list.add_child(actions)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.custom_minimum_size = Vector2(116, 24)
	save_button.pressed.connect(_save_editor_layout)
	actions.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "Load"
	load_button.custom_minimum_size = Vector2(116, 24)
	load_button.pressed.connect(_reload_editor_layout_from_disk)
	actions.add_child(load_button)

	var copy_button := Button.new()
	copy_button.text = "Copy JSON"
	copy_button.custom_minimum_size = Vector2(116, 24)
	copy_button.pressed.connect(_copy_editor_layout_json)
	actions.add_child(copy_button)

	var paste_button := Button.new()
	paste_button.text = "Paste JSON"
	paste_button.custom_minimum_size = Vector2(116, 24)
	paste_button.pressed.connect(_paste_editor_layout_json)
	actions.add_child(paste_button)

	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(116, 24)
	reset_button.pressed.connect(_reset_editor_layout)
	actions.add_child(reset_button)

	editor_status_label = Label.new()
	editor_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	editor_status_label.text = "F2 toggles"
	list.add_child(editor_status_label)

	editor_selection_box = Line2D.new()
	editor_selection_box.name = "EditorSelectionBox"
	editor_selection_box.width = 2.0
	editor_selection_box.default_color = Color(0.25, 0.72, 1.0, 1.0)
	editor_selection_box.closed = true
	editor_selection_box.z_index = 200
	editor_selection_box.visible = false
	object_layer.add_child(editor_selection_box)

func _select_editor_type(object_type: String) -> void:
	selected_editor_type = object_type
	var definition := _get_editor_definition(object_type)
	_set_editor_status("Selected: %s" % String(definition.get("label", object_type)))

func _set_map_editor_enabled(is_enabled: bool) -> void:
	map_editor_enabled = is_enabled
	if editor_layer:
		var panel := editor_layer.get_node_or_null("EditorPanel") as Control
		if panel:
			panel.visible = is_enabled
	local_player.call("set_controls_locked", is_enabled)
	_select_editor_sprite(null)
	_set_editor_status("Editor on" if is_enabled else "Editor off")

func _set_editor_status(message: String) -> void:
	if editor_status_label:
		editor_status_label.text = message

func _is_pointer_over_editor_ui() -> bool:
	if not map_editor_enabled or editor_layer == null:
		return false
	var panel := editor_layer.get_node_or_null("EditorPanel") as Control
	if panel == null or not panel.visible:
		return false
	return panel.get_global_rect().has_point(get_viewport().get_mouse_position())

func _select_editor_sprite(sprite: Sprite2D) -> void:
	if selected_editor_sprite:
		selected_editor_sprite.modulate = Color.WHITE
	selected_editor_sprite = sprite
	if selected_editor_sprite:
		selected_editor_sprite.modulate = Color(1.15, 1.15, 1.15, 1.0)
		_update_editor_selection_box()
	else:
		editor_selection_box.visible = false

func _update_editor_selection_box() -> void:
	if selected_editor_sprite == null or selected_editor_sprite.texture == null:
		editor_selection_box.visible = false
		return
	var size := selected_editor_sprite.texture.get_size() * selected_editor_sprite.scale.abs()
	editor_selection_box.clear_points()
	editor_selection_box.position = selected_editor_sprite.position
	editor_selection_box.rotation = selected_editor_sprite.rotation
	if selected_editor_sprite.centered:
		var half := size * 0.5
		editor_selection_box.add_point(Vector2(-half.x, -half.y))
		editor_selection_box.add_point(Vector2(half.x, -half.y))
		editor_selection_box.add_point(Vector2(half.x, half.y))
		editor_selection_box.add_point(Vector2(-half.x, half.y))
	else:
		editor_selection_box.add_point(Vector2.ZERO)
		editor_selection_box.add_point(Vector2(size.x, 0))
		editor_selection_box.add_point(size)
		editor_selection_box.add_point(Vector2(0, size.y))
	editor_selection_box.visible = true

func _snap_to_editor_grid(point: Vector2) -> Vector2:
	return Vector2(
		round(point.x / MAP_EDITOR_GRID_SIZE) * MAP_EDITOR_GRID_SIZE,
		round(point.y / MAP_EDITOR_GRID_SIZE) * MAP_EDITOR_GRID_SIZE
	)

func _place_editor_object(world_position: Vector2) -> void:
	var definition := _get_editor_definition(selected_editor_type)
	if definition.is_empty():
		return
	var is_tile := _is_editor_tile_type(selected_editor_type)
	var snapped_position := _snap_to_editor_grid(world_position)
	if is_tile:
		snapped_position = Vector2(
			floor(world_position.x / MAP_EDITOR_TILE_GRID_SIZE) * MAP_EDITOR_TILE_GRID_SIZE,
			floor(world_position.y / MAP_EDITOR_TILE_GRID_SIZE) * MAP_EDITOR_TILE_GRID_SIZE
		)
	var item := {
		"name": "%s%s" % [selected_editor_type.capitalize(), Time.get_ticks_msec()],
		"type": selected_editor_type,
		"position": snapped_position,
		"scale": definition["scale"],
		"rotation": 0.0
	}
	if is_tile:
		_add_tile(item)
		_select_editor_sprite(ground_layer.get_child(ground_layer.get_child_count() - 1) as Sprite2D)
	else:
		_add_object(item)
		_select_editor_sprite(object_layer.get_child(object_layer.get_child_count() - 1) as Sprite2D)
	_set_editor_status("Placed: %s" % String(definition["label"]))

func _get_editor_sprite_at(world_position: Vector2) -> Sprite2D:
	var object_sprite := _get_editor_sprite_at_in_layer(object_layer, world_position)
	if object_sprite:
		return object_sprite
	return _get_editor_sprite_at_in_layer(ground_layer, world_position)

func _get_editor_sprite_at_in_layer(layer: Node, world_position: Vector2) -> Sprite2D:
	var children := layer.get_children()
	for index in range(children.size() - 1, -1, -1):
		var sprite := children[index] as Sprite2D
		if sprite == null or not sprite.has_meta("editor_type") or sprite.texture == null:
			continue
		if bool(sprite.get_meta("editor_companion", false)):
			continue
		var size := sprite.texture.get_size() * sprite.scale.abs()
		var local := (world_position - sprite.position).rotated(-sprite.rotation)
		if sprite.centered:
			if abs(local.x) <= size.x * 0.5 and abs(local.y) <= size.y * 0.5:
				return sprite
		elif local.x >= 0 and local.y >= 0 and local.x <= size.x and local.y <= size.y:
			return sprite
	return null

func _delete_selected_editor_sprite() -> void:
	if selected_editor_sprite == null:
		return
	var deleted_name := selected_editor_sprite.name
	_remove_depth_for_object(selected_editor_sprite)
	selected_editor_sprite.queue_free()
	selected_editor_sprite = null
	dragged_editor_sprite = null
	editor_selection_box.visible = false
	_set_editor_status("Deleted: %s" % deleted_name)

func _rotate_selected_editor_sprite() -> void:
	if selected_editor_sprite == null:
		return
	selected_editor_sprite.rotation += PI * 0.5
	_sync_depth_for_object(selected_editor_sprite)
	_update_editor_selection_box()

func _serialize_editor_layout() -> Dictionary:
	var objects: Array = []
	var tiles: Array = []
	for child in ground_layer.get_children():
		var tile := child as Sprite2D
		if tile == null or not tile.has_meta("editor_type") or bool(tile.get_meta("editor_companion", false)) or String(tile.get_meta("editor_kind", "")) != "tile":
			continue
		tiles.append({
			"name": tile.name,
			"type": String(tile.get_meta("editor_type")),
			"position": _vector_to_array(tile.position),
			"scale": _vector_to_array(tile.scale),
			"rotation": tile.rotation
		})
	for child in object_layer.get_children():
		var sprite := child as Sprite2D
		if sprite == null or not sprite.has_meta("editor_type") or bool(sprite.get_meta("editor_companion", false)) or String(sprite.get_meta("editor_kind", "")) != "object":
			continue
		objects.append({
			"name": sprite.name,
			"type": String(sprite.get_meta("editor_type")),
			"position": _vector_to_array(sprite.position),
			"scale": _vector_to_array(sprite.scale),
			"rotation": sprite.rotation
		})
	return { "objects": objects, "tiles": tiles }

func _vector_to_array(value: Vector2) -> Array:
	return [snapped(value.x, 0.01), snapped(value.y, 0.01)]

func _save_editor_layout() -> void:
	var file := FileAccess.open(MAP_EDITOR_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_set_editor_status("Save failed")
		return
	file.store_string(JSON.stringify(_serialize_editor_layout(), "\t"))
	_set_editor_status("Saved layout")

func _copy_editor_layout_json() -> void:
	DisplayServer.clipboard_set(JSON.stringify(_serialize_editor_layout(), "\t"))
	_set_editor_status("Copied JSON")

func _paste_editor_layout_json() -> void:
	var parsed = JSON.parse_string(DisplayServer.clipboard_get())
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_editor_status("Paste failed")
		return
	_replace_editor_layout({
		"objects": _objects_from_json_array(parsed.get("objects", [])),
		"tiles": _tiles_from_json_array(parsed.get("tiles", []))
	})
	_set_editor_status("Pasted layout")

func _reload_editor_layout_from_disk() -> void:
	_replace_editor_layout(_load_editor_layout())
	_set_editor_status("Loaded layout")

func _reset_editor_layout() -> void:
	_replace_editor_layout(_empty_editor_layout())
	_set_editor_status("Reset layout")

func _replace_editor_layout(layout: Dictionary) -> void:
	for child in ground_layer.get_children():
		if child is Sprite2D and (child.has_meta("editor_type") or bool(child.get_meta("editor_companion", false))):
			child.queue_free()
	for child in object_layer.get_children():
		if (child is Sprite2D or child is StaticBody2D) and (child.has_meta("editor_type") or bool(child.get_meta("editor_companion", false))):
			child.queue_free()
	for child in above_player_layer.get_children():
		if child.has_meta("editor_companion"):
			child.queue_free()
	_select_editor_sprite(null)
	for item in layout.get("tiles", []):
		_add_tile(item)
	for item in layout.get("objects", []):
		_add_object(item)

func start_session() -> void:
	hud.set_player_name(GameState.player_name)
	NetworkManager.connect_to_server(GameState.server_url, GameState.player_name)

func _process(_delta: float) -> void:
	_update_local_player_occlusion()
	hud.update_debug(local_player.global_position, PlayerRegistry.count())
	if current_interactable == null:
		hud.set_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F2:
		_set_map_editor_enabled(not map_editor_enabled)
		get_viewport().set_input_as_handled()
		return
	if map_editor_enabled:
		_handle_map_editor_input(event)
		get_viewport().set_input_as_handled()
		return
	if GameState.is_ui_screen_open():
		return
	if event.is_action_pressed("interact"):
		var target := current_interactable if current_interactable else _get_nearest_interactable()
		if target == null:
			return
		var message: String = target.call("interact")
		hud.show_message(message)

func _get_nearest_interactable() -> Area2D:
	var nearest: Area2D
	var nearest_distance := 72.0
	for child in interactables.get_children():
		var interactable := child as Area2D
		if interactable == null or not interactable.visible:
			continue
		var distance := local_player.global_position.distance_to(interactable.global_position)
		if distance < nearest_distance:
			nearest = interactable
			nearest_distance = distance
	return nearest

func _update_local_player_occlusion() -> void:
	if local_player == null:
		return
	var player_rect := _get_sprite_global_rect(local_player.body_sprite)
	if player_rect.size == Vector2.ZERO:
		local_player.set_occluded(false)
		return
	var occluded := false
	for child in above_player_layer.get_children():
		var foreground := child as Sprite2D
		if foreground == null or not foreground.visible:
			continue
		if _get_sprite_global_rect(foreground).intersects(player_rect):
			occluded = true
			break
	local_player.set_occluded(occluded)

func _get_sprite_global_rect(sprite: Sprite2D) -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2()
	var size: Vector2 = sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
	var scaled_size := size * sprite.global_scale.abs()
	var center := sprite.global_position
	return Rect2(center - scaled_size * 0.5, scaled_size)

func _handle_map_editor_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_pointer_over_editor_ui():
				return
			var world_position := get_global_mouse_position()
			var sprite := _get_editor_sprite_at(world_position)
			if sprite:
				_select_editor_sprite(sprite)
				dragged_editor_sprite = sprite
				drag_offset = sprite.position - world_position
			else:
				_place_editor_object(world_position)
		else:
			dragged_editor_sprite = null
	elif event is InputEventMouseMotion and dragged_editor_sprite:
		if String(dragged_editor_sprite.get_meta("editor_kind", "")) == "tile":
			var pointer := get_global_mouse_position() + drag_offset
			dragged_editor_sprite.position = Vector2(
				floor(pointer.x / MAP_EDITOR_TILE_GRID_SIZE) * MAP_EDITOR_TILE_GRID_SIZE,
				floor(pointer.y / MAP_EDITOR_TILE_GRID_SIZE) * MAP_EDITOR_TILE_GRID_SIZE
			)
		else:
			dragged_editor_sprite.position = _snap_to_editor_grid(get_global_mouse_position() + drag_offset)
			_sync_depth_for_object(dragged_editor_sprite)
		_update_editor_selection_box()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_DELETE or event.physical_keycode == KEY_BACKSPACE:
			_delete_selected_editor_sprite()
		elif event.physical_keycode == KEY_R:
			_rotate_selected_editor_sprite()

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
