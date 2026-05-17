class_name DirectionalWalkAnimator
extends RefCounted

const DIRECTIONS := [
	"down",
	"up",
	"left",
	"right",
	"up_left",
	"up_right",
	"down_left",
	"down_right"
]
const FRAME_COUNT := 4
const FRAME_RATE := 8.0
const FRAME_SIZE := Vector2i(224, 320)

var _frames: Dictionary = {}
var _sheet_path := ""

func load_sheet(sheet_path: String) -> bool:
	if sheet_path == _sheet_path and not _frames.is_empty():
		return true

	var sheet := load(sheet_path) as Texture2D
	if not sheet:
		return false

	# Sprite sheets are normalized to 8 rows by 4 columns:
	# one row per direction, one column per walking frame.
	_frames.clear()
	_sheet_path = sheet_path
	for row in range(DIRECTIONS.size()):
		var direction: String = DIRECTIONS[row]
		var direction_frames: Array[Texture2D] = []
		for frame in range(FRAME_COUNT):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(
				frame * FRAME_SIZE.x,
				row * FRAME_SIZE.y,
				FRAME_SIZE.x,
				FRAME_SIZE.y
			)
			direction_frames.append(atlas)
		_frames[direction] = direction_frames
	return true

func has_direction(direction: String) -> bool:
	return _frames.has(direction)

func get_idle_texture(direction: String) -> Texture2D:
	return _get_direction_frame(direction, 0)

func get_walk_texture(direction: String, animation_time: float) -> Texture2D:
	var frame := int(animation_time * FRAME_RATE) % FRAME_COUNT
	return _get_direction_frame(direction, frame)

func direction_from_vector(direction: Vector2) -> String:
	# Exact diagonal input gets its own animation instead of borrowing a cardinal row.
	if direction.x < 0.0 and direction.y < 0.0:
		return "up_left"
	if direction.x > 0.0 and direction.y < 0.0:
		return "up_right"
	if direction.x < 0.0 and direction.y > 0.0:
		return "down_left"
	if direction.x > 0.0 and direction.y > 0.0:
		return "down_right"
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"

func _get_direction_frame(direction: String, frame: int) -> Texture2D:
	var direction_frames := _frames.get(direction, []) as Array
	if direction_frames.is_empty():
		direction_frames = _frames.get("down", []) as Array
	if direction_frames.is_empty():
		return null
	return direction_frames[clampi(frame, 0, direction_frames.size() - 1)]
