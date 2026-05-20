class_name LocalPlayer
extends CharacterBody2D

signal input_changed(direction: Vector2, facing: String)

const SPEED := 92.0
const DEFAULT_CHARACTER_SCALE := 0.18
const WALK_BOB_AMOUNT := 0.7

@onready var body: Polygon2D = %Body
@onready var body_sprite: Sprite2D = %BodySprite
@onready var occlusion_outline_body: Polygon2D = %OcclusionOutlineBody
@onready var occlusion_outline_sprite: Sprite2D = %OcclusionOutlineSprite

var facing := "down"
var controls_locked := false
var occluded := false
var _animation_time := 0.0
var _last_direction := Vector2.ZERO
var _walk_animator := DirectionalWalkAnimator.new()

func _ready() -> void:
	body.modulate = GameState.character_color
	_apply_character_animation(GameState.character_walk_sheet_path)
	if not GameState.character_changed.is_connected(_on_character_changed):
		GameState.character_changed.connect(_on_character_changed)
	_update_occlusion_visual()

func _physics_process(delta: float) -> void:
	if controls_locked or GameState.is_ui_screen_open():
		velocity = Vector2.ZERO
		move_and_slide()
		if _last_direction != Vector2.ZERO:
			_last_direction = Vector2.ZERO
			input_changed.emit(Vector2.ZERO, facing)
		_update_animation(false)
		_update_direction_color(false)
		return

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
	_update_scene_occlusion_state()

func is_local_player() -> bool:
	return true

func set_occluded(is_occluded: bool) -> void:
	if occluded == is_occluded:
		return
	occluded = is_occluded
	_update_occlusion_visual()

func set_controls_locked(is_locked: bool) -> void:
	controls_locked = is_locked
	if is_locked:
		velocity = Vector2.ZERO
		_last_direction = Vector2.ZERO
		input_changed.emit(Vector2.ZERO, facing)

func face(direction_name: String) -> void:
	match direction_name:
		"up":
			facing = "up"
		"down":
			facing = "down"
		"left":
			facing = "left"
		"right":
			facing = "right"
	_update_animation(false)

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
	var scale_value: float = max(0.01, GameState.character_scale if GameState.character_scale > 0.0 else DEFAULT_CHARACTER_SCALE)
	body_sprite.scale = Vector2(scale_value, scale_value)
	body_sprite.rotation = 0.0

	if is_moving:
		body_sprite.texture = _walk_animator.get_walk_texture(facing, _animation_time)
		var stride: float = sin(_animation_time * DirectionalWalkAnimator.FRAME_RATE * TAU / DirectionalWalkAnimator.FRAME_COUNT)
		body_sprite.position = Vector2(0.0, -abs(stride) * WALK_BOB_AMOUNT)
	else:
		body_sprite.texture = _walk_animator.get_idle_texture(facing)
		body_sprite.position = Vector2.ZERO

	_sync_outline_sprite()

func _update_direction_color(is_moving: bool) -> void:
	var base := GameState.character_color
	body.modulate = base.lightened(0.12) if is_moving else base
	body_sprite.modulate = Color(1.08, 1.08, 1.08, 1.0) if is_moving else Color.WHITE
	occlusion_outline_body.color = Color(0.93, 0.98, 1.0, 0.92 if is_moving else 0.85)

func _apply_character_animation(walk_sheet_path: String) -> void:
	# The selected character chooses the sheet; the animator handles all slicing.
	if _walk_animator.load_sheet(walk_sheet_path):
		body_sprite.texture = _walk_animator.get_idle_texture(facing)
		body_sprite.visible = true
		body.visible = false
	else:
		body_sprite.visible = false
		body.visible = true
	_sync_outline_sprite()
	_update_occlusion_visual()

func _on_character_changed(_new_character_id: String) -> void:
	body.modulate = GameState.character_color
	_apply_character_animation(GameState.character_walk_sheet_path)
	_update_animation(velocity.length() > 0.0)

func _sync_outline_sprite() -> void:
	occlusion_outline_sprite.texture = body_sprite.texture
	occlusion_outline_sprite.position = body_sprite.position
	occlusion_outline_sprite.scale = body_sprite.scale
	occlusion_outline_sprite.rotation = body_sprite.rotation

func _update_occlusion_visual() -> void:
	var use_sprite_outline := occluded and body_sprite.visible and body_sprite.texture != null
	occlusion_outline_sprite.visible = use_sprite_outline
	occlusion_outline_body.visible = occluded and not use_sprite_outline
	if use_sprite_outline:
		_sync_outline_sprite()

func _update_scene_occlusion_state() -> void:
	var player_rect := _get_global_sprite_rect()
	if player_rect.size == Vector2.ZERO:
		set_occluded(false)
		return

	for node in get_tree().get_nodes_in_group("player_occluder_foreground"):
		var sprite := node as Sprite2D
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		if _get_sprite_rect(sprite).intersects(player_rect):
			set_occluded(true)
			return
	set_occluded(false)

func _get_global_sprite_rect() -> Rect2:
	if body_sprite == null or body_sprite.texture == null:
		return Rect2()
	return _get_sprite_rect(body_sprite)

func _get_sprite_rect(sprite: Sprite2D) -> Rect2:
	var size: Vector2 = sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
	var scaled_size := size * sprite.global_scale.abs()
	var center := sprite.global_position
	return Rect2(center - scaled_size * 0.5, scaled_size)
