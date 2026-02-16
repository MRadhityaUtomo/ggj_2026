extends Node

## Main Scene Manager - Entry point that manages SubViewport content switching

@onready var viewport_wrapper: Node = null
var current_scene_path: String = ""

func _ready() -> void:
	# Load the viewport wrapper
	var wrapper_scene = preload("res://viewport_wrapper.tscn")
	viewport_wrapper = wrapper_scene.instantiate()
	add_child(viewport_wrapper)
	
	# Wait one frame for viewport wrapper to initialize
	await get_tree().process_frame
	
	# Load initial scene (main menu)
	load_scene("res://scenes/levels/main_menu.tscn")

## Switch the content inside the SubViewport using viewport_wrapper's method
func load_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		return
	
	current_scene_path = scene_path
	
	# Use the viewport_wrapper's built-in scene loading method
	if viewport_wrapper and viewport_wrapper.has_method("load_scene_into_viewport"):
		viewport_wrapper.load_scene_into_viewport(scene_path)
		print("Loaded scene via viewport_wrapper: ", scene_path)
	else:
		push_error("viewport_wrapper doesn't have load_scene_into_viewport method!")

## Called by LevelProgression autoload
func change_level(level_index: int) -> void:
	if level_index >= 0 and level_index < LevelProgression.level_scenes.size():
		load_scene(LevelProgression.level_scenes[level_index])

## Called to return to main menu
func return_to_main_menu() -> void:
	load_scene("res://scenes/levels/main_menu.tscn")
