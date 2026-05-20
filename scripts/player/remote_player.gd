class_name RemotePlayer
extends Node2D

const DEFAULT_CHARACTER_SCALE := 0.18
const WALK_BOB_AMOUNT := 0.7

@onready var body: Polygon2D = %Body
@onready var body_sprite: Sprite2D = %BodySprite

var target_position := Vector2.ZERO
var facing := "down"
var moving := false
var character_scale := DEFAULT_CHARACTER_SCALE
var _animation_time := 0.0
var _walk_animator := DirectionalWalkAnimator.new()

func _process(delta: float) -> void:
	position = position.lerp(target_position, min(delta * 12.0, 1.0))
	if moving:
		_animation_time += delta
	_update_animation(moving)

func apply_state(state: Dictionary) -> void:
	target_position = Vector2(float(state.get("x", position.x)), float(state.get("y", position.y)))
	body.modulate = Color(String(state.get("color", "#5d7fd8")))
	facing = String(state.get("facing", "down"))
	moving = bool(state.get("moving", false))

	var character := GameState.get_character(String(state.get("characterId", "char_01")))
	character_scale = max(0.01, float(character.get("scale", DEFAULT_CHARACTER_SCALE)))
	_apply_character_animation(String(character["walk_sheet"]))

func _update_animation(is_moving: bool) -> void:
	# Match the local player scale so every character reads clearly on the map.
	body_sprite.scale = Vector2(character_scale, character_scale)
	body_sprite.rotation = 0.0

	if is_moving:
		body_sprite.texture = _walk_animator.get_walk_texture(facing, _animation_time)
		var stride: float = sin(_animation_time * DirectionalWalkAnimator.FRAME_RATE * TAU / DirectionalWalkAnimator.FRAME_COUNT)
		body_sprite.position = Vector2(0.0, -abs(stride) * WALK_BOB_AMOUNT)
	else:
		body_sprite.texture = _walk_animator.get_idle_texture(facing)
		body_sprite.position = Vector2.ZERO

func _apply_character_animation(walk_sheet_path: String) -> void:
	# Remote players use the same sheet loading and frame logic as the local player.
	if _walk_animator.load_sheet(walk_sheet_path):
		body_sprite.texture = _walk_animator.get_idle_texture(facing)
		body_sprite.visible = true
		body.visible = false
	else:
		body_sprite.visible = false
		body.visible = true
