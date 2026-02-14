extends Node2D

## Wraps the game in a SubViewport at 192x128 while UI renders at native resolution.

@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var ui_layer: CanvasLayer = $UILayer

const GAME_WIDTH = 192*2
const GAME_HEIGHT = 128*2

var outline_tween: Tween
var ui_manager: Node

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

	# Initialize UI manager
	ui_manager = preload("res://ui_manager.gd").new()
	add_child(ui_manager)
	ui_manager.initialize(ui_layer)
	
	# Load initial UI (e.g., for main menu)
	ui_manager.load_ui_for_scene("main_menu")

## Call this to load a scene into the game viewport
func load_scene_into_viewport(scene_path: String) -> Node:
	for child in sub_viewport.get_children():
		child.queue_free()
	var scene = load(scene_path)
	var instance = scene.instantiate()
	sub_viewport.add_child(instance)
	
	# Update UI based on loaded scene
	if ui_manager:
		ui_manager.load_ui_for_scene(scene_path)
	
	return instance

## Get the SubViewport so other systems can add nodes to it
func get_game_viewport() -> SubViewport:
	return sub_viewport

## Get the UI layer for adding high-res UI
func get_ui_layer() -> CanvasLayer:
	return ui_layer
