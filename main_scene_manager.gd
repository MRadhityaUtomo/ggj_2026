extends Node

## Main Scene Manager - Entry point that manages SubViewport content switching

@onready var viewport_wrapper: Node = null
var current_scene_path: String = ""

func _ready() -> void:
	# Load the viewport wrapper
	var wrapper_scene = preload("res://viewport_wrapper.tscn")  # Adjust path to your wrapper scene
	viewport_wrapper = wrapper_scene.instantiate()
	add_child(viewport_wrapper)
	
	# Load initial scene (main menu)
	load_scene("res://scenes/levels/main_menu.tscn")

## Switch the content inside the SubViewport
func load_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		return
	
	current_scene_path = scene_path
	
	# Get the SubViewport from the wrapper
	var subviewport = viewport_wrapper.get_node_or_null("SubViewport")
	if not subviewport:
		push_error("SubViewport not found in wrapper!")
		return
	
	# Clear existing content
	for child in subviewport.get_children():
		child.queue_free()
	
	# Load and add new scene
	var new_scene = load(scene_path).instantiate()
	subviewport.add_child(new_scene)
	
	print("Loaded scene: ", scene_path)

## Called by LevelProgression autoload
func change_level(level_index: int) -> void:
	if level_index >= 0 and level_index < LevelProgression.level_scenes.size():
		load_scene(LevelProgression.level_scenes[level_index])

## Called to return to main menu
func return_to_main_menu() -> void:
	load_scene("res://scenes/levels/main_menu.tscn")
