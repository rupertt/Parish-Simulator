class_name LocalPlayer
extends CharacterBody2D

signal input_changed(direction: Vector2, facing: String)

const SPEED := 92.0
const CHARACTER_SCALE := 0.07

@onready var body: Polygon2D = %Body
@onready var body_sprite: Sprite2D = %BodySprite

var facing := "down"
var _walk_time := 0.0
var _last_direction := Vector2.ZERO

func _ready() -> void:
	body.modulate = GameState.character_color
	_apply_character_texture(GameState.character_texture_path)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()

	if direction.length() > 0.0:
		_update_facing(direction)
		_walk_time += delta * 12.0
		body_sprite.position.y = sin(_walk_time) * 1.5
	else:
		body_sprite.position.y = 0.0

	if direction != _last_direction:
		_last_direction = direction
		input_changed.emit(direction, facing)

	_update_direction_color(direction.length() > 0.0)

func is_local_player() -> bool:
	return true

func _update_facing(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		facing = "right" if direction.x > 0.0 else "left"
	else:
		facing = "down" if direction.y > 0.0 else "up"
	match facing:
		"up":
			body_sprite.scale = Vector2(CHARACTER_SCALE * 0.9, CHARACTER_SCALE)
		"down":
			body_sprite.scale = Vector2(CHARACTER_SCALE, CHARACTER_SCALE)
		"left":
			body_sprite.scale = Vector2(-CHARACTER_SCALE, CHARACTER_SCALE)
		"right":
			body_sprite.scale = Vector2(CHARACTER_SCALE, CHARACTER_SCALE)

func _update_direction_color(is_moving: bool) -> void:
	var base := GameState.character_color
	body.modulate = base.lightened(0.12) if is_moving else base
	body_sprite.modulate = Color(1.08, 1.08, 1.08, 1.0) if is_moving else Color.WHITE

func _apply_character_texture(texture_path: String) -> void:
	var texture := load(texture_path) as Texture2D
	if texture:
		body_sprite.texture = texture
		body_sprite.scale = Vector2(CHARACTER_SCALE, CHARACTER_SCALE)
		body_sprite.visible = true
		body.visible = false
	else:
		body_sprite.visible = false
		body.visible = true
