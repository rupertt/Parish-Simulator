class_name RemotePlayer
extends Node2D

const CHARACTER_SCALE := 0.07

@onready var body: Polygon2D = %Body
@onready var body_sprite: Sprite2D = %BodySprite

var target_position := Vector2.ZERO

func _process(delta: float) -> void:
	position = position.lerp(target_position, min(delta * 12.0, 1.0))

func apply_state(state: Dictionary) -> void:
	target_position = Vector2(float(state.get("x", position.x)), float(state.get("y", position.y)))
	body.modulate = Color(String(state.get("color", "#5d7fd8")))
	var character := GameState.get_character(String(state.get("characterId", "char_01")))
	_apply_character_texture(String(character["texture"]))

	var facing := String(state.get("facing", "down"))
	match facing:
		"up":
			body.scale = Vector2(0.92, 1.0)
			body_sprite.scale = Vector2(CHARACTER_SCALE * 0.9, CHARACTER_SCALE)
		"down":
			body.scale = Vector2(1.0, 1.0)
			body_sprite.scale = Vector2(CHARACTER_SCALE, CHARACTER_SCALE)
		"left":
			body.scale = Vector2(0.88, 1.0)
			body_sprite.scale = Vector2(-CHARACTER_SCALE, CHARACTER_SCALE)
		"right":
			body.scale = Vector2(1.08, 1.0)
			body_sprite.scale = Vector2(CHARACTER_SCALE, CHARACTER_SCALE)

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
