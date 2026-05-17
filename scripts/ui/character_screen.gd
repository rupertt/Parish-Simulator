extends "res://scripts/ui/base_ui_screen.gd"

const DESIGN_SIZE := Vector2(520, 44)
const VIEWPORT_MARGIN := Vector2(16, 14)

@onready var menu_root: Control = %MenuRoot

func _ready() -> void:
	super._ready()
	screen_id = "character"
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()

func open_screen() -> void:
	super.open_screen()
	_fit_to_viewport()

func _fit_to_viewport() -> void:
	if not is_node_ready():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var available_width: float = viewport_size.x - VIEWPORT_MARGIN.x * 2.0
	var scale_factor: float = min(available_width / DESIGN_SIZE.x, 1.0)
	scale_factor = clamp(scale_factor, 0.45, 1.0)
	menu_root.size = DESIGN_SIZE
	menu_root.scale = Vector2(scale_factor, scale_factor)
	menu_root.position = Vector2(
		(viewport_size.x - (DESIGN_SIZE.x * scale_factor)) * 0.5,
		VIEWPORT_MARGIN.y
	)
