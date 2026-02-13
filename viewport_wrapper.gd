extends Node2D

## Wraps the game in a SubViewport at 192x128 while UI renders at native resolution.

@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var ui_layer: CanvasLayer = $UILayer
@onready var white_outline_border: ColorRect = $UILayer/WhiteOutlineBorder

const GAME_WIDTH = 192*2
const GAME_HEIGHT = 128*2

var outline_tween: Tween

func _ready():
	# Ensure nearest-neighbor filtering for pixel art
	sub_viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sub_viewport_container.stretch = true
	
	_update_viewport_size()
	get_tree().root.size_changed.connect(_update_viewport_size)

func _update_viewport_size():
	var window_size = get_viewport().get_visible_rect().size
	
	# Calculate integer scale that fits the window
	var scale_x = floor(window_size.x / GAME_WIDTH)
	var scale_y = floor(window_size.y / GAME_HEIGHT)
	var s = max(1, min(scale_x, scale_y))
	
	# Size the container to the scaled game resolution, centered
	var container_size = Vector2(GAME_WIDTH * s, GAME_HEIGHT * s)
	sub_viewport_container.size = container_size
	sub_viewport_container.position = (window_size - container_size) / 2.0
	
	# stretch_shrink keeps the SubViewport at 192×128 while the container upscales
	sub_viewport_container.stretch_shrink = int(s)

## Call this to load a scene into the game viewport
func load_scene_into_viewport(scene_path: String) -> Node:
	for child in sub_viewport.get_children():
		child.queue_free()
	var scene = load(scene_path)
	var instance = scene.instantiate()
	sub_viewport.add_child(instance)
	return instance

## Get the SubViewport so other systems can add nodes to it
func get_game_viewport() -> SubViewport:
	return sub_viewport

## Get the UI layer for adding high-res UI
func get_ui_layer() -> CanvasLayer:
	return ui_layer

## Trigger white outline closing-in effect when cartridge is selected
func play_outline_close_effect(duration: float = 0.5):
	if outline_tween:
		outline_tween.kill()
	
	outline_tween = create_tween()
	outline_tween.set_ease(Tween.EASE_IN_OUT)
	outline_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate from 0 (no border) to 1 (fully closed)
	outline_tween.tween_property(
		white_outline_border.material,
		"shader_parameter/progress",
		1.0,
		duration
	).from(0.0)

## Reset the outline effect
func reset_outline_effect():
	if white_outline_border and white_outline_border.material:
		white_outline_border.material.set_shader_parameter("progress", 0.0)
	if outline_tween:
		outline_tween.kill()
