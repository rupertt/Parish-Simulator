class_name LocalPlayer
extends CharacterBody2D

signal input_changed(direction: Vector2, facing: String)

const SPEED := 92.0
const CHARACTER_SCALE := 0.18
const WALK_BOB_AMOUNT := 0.7

@onready var body: Polygon2D = %Body
@onready var body_sprite: Sprite2D = %BodySprite

var facing := "down"
var _animation_time := 0.0
var _last_direction := Vector2.ZERO
var _walk_animator := DirectionalWalkAnimator.new()

func _ready() -> void:
	body.modulate = GameState.character_color
	_apply_character_animation(GameState.character_walk_sheet_path)

func _physics_process(delta: float) -> void:
	var direction := _get_move_direction()
	var is_moving := direction.length() > 0.0
	velocity = direction * SPEED
	move_and_slide()

	if is_moving:
		facing = _walk_animator.direction_from_vector(direction)
		_animation_time += delta

	_update_animation(is_moving)

	if direction != _last_direction:
		_last_direction = direction
		input_changed.emit(direction, facing)

	_update_direction_color(is_moving)

func is_local_player() -> bool:
	return true

func _get_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	# Normalizing keeps diagonal walking the same speed as straight walking.
	return direction.normalized() if direction.length() > 0.0 else Vector2.ZERO

func _update_animation(is_moving: bool) -> void:
	# Scale the source pixel art up in-engine without stretching the sprite.
	body_sprite.scale = Vector2(CHARACTER_SCALE, CHARACTER_SCALE)
	body_sprite.rotation = 0.0

	if is_moving:
		body_sprite.texture = _walk_animator.get_walk_texture(facing, _animation_time)
		var stride: float = sin(_animation_time * DirectionalWalkAnimator.FRAME_RATE * TAU / DirectionalWalkAnimator.FRAME_COUNT)
		body_sprite.position = Vector2(0.0, -abs(stride) * WALK_BOB_AMOUNT)
	else:
		body_sprite.texture = _walk_animator.get_idle_texture(facing)
		body_sprite.position = Vector2.ZERO

func _update_direction_color(is_moving: bool) -> void:
	var base := GameState.character_color
	body.modulate = base.lightened(0.12) if is_moving else base
	body_sprite.modulate = Color(1.08, 1.08, 1.08, 1.0) if is_moving else Color.WHITE

func _apply_character_animation(walk_sheet_path: String) -> void:
	# The selected character chooses the sheet; the animator handles all slicing.
	if _walk_animator.load_sheet(walk_sheet_path):
		body_sprite.texture = _walk_animator.get_idle_texture(facing)
		body_sprite.visible = true
		body.visible = false
	else:
		body_sprite.visible = false
		body.visible = true
