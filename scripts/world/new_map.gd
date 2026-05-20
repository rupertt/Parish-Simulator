extends Node2D

const DEFAULT_FOREGROUND_CROP := 0.72
const FOREGROUND_CROP_BY_PROP := {
	"HouseProp": 0.72,
	# Keep only the upper roof as foreground so the player can render in front
	# near the lower doorway/foundation area.
	"HouseProp2": 0.56,
	"ParishChurchProp": 0.74,
	"GothicCathedralProp": 0.78,
	"BigCathedralProp": 0.78,
}

@onready var world: Node2D = $World
@onready var local_player: LocalPlayer = $World/LocalPlayer
@onready var above_player_layer: Node2D = $AbovePlayerLayer

func _ready() -> void:
	_build_occluder_foregrounds()
	_update_occluder_foregrounds()
	local_player.set_occluded(false)

func _process(_delta: float) -> void:
	_update_occluder_foregrounds()
	_update_local_player_occlusion()

func _build_occluder_foregrounds() -> void:
	for child in above_player_layer.get_children():
		child.queue_free()

	for child in world.get_children():
		if child == local_player:
			continue
		var source_sprite := child.get_node_or_null("Sprite2D") as Sprite2D
		if source_sprite == null or source_sprite.texture == null:
			continue

		var crop_ratio := float(FOREGROUND_CROP_BY_PROP.get(child.name, DEFAULT_FOREGROUND_CROP))
		var texture_size := source_sprite.texture.get_size()
		var foreground_height := clampi(int(round(texture_size.y * crop_ratio)), 1, int(texture_size.y))

		var foreground := Sprite2D.new()
		foreground.name = "%sForeground" % child.name
		foreground.texture = source_sprite.texture
		foreground.region_enabled = true
		foreground.region_rect = Rect2(Vector2.ZERO, Vector2(texture_size.x, foreground_height))
		foreground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		foreground.z_index = 80
		foreground.add_to_group("player_occluder_foreground")
		foreground.set_meta("source_prop_path", child.get_path())
		foreground.set_meta("source_sprite_path", source_sprite.get_path())
		above_player_layer.add_child(foreground)

func _update_occluder_foregrounds() -> void:
	for child in above_player_layer.get_children():
		var foreground := child as Sprite2D
		if foreground == null:
			continue
		var source_sprite := get_node_or_null(NodePath(String(foreground.get_meta("source_sprite_path", "")))) as Sprite2D
		if source_sprite == null or source_sprite.texture == null:
			foreground.visible = false
			continue

		var texture_size := source_sprite.texture.get_size()
		var foreground_height := foreground.region_rect.size.y
		var local_offset := Vector2(0.0, (foreground_height - texture_size.y) * source_sprite.global_scale.y * 0.5)
		foreground.position = source_sprite.global_position + local_offset.rotated(source_sprite.global_rotation)
		foreground.scale = source_sprite.global_scale
		foreground.rotation = source_sprite.global_rotation
		foreground.visible = source_sprite.visible

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
