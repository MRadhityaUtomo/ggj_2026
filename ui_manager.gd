extends Node

## Manages UI overlays on the UILayer based on loaded SubViewport content

var ui_layer: CanvasLayer
var current_ui: Node = null

# UI scene paths for different contexts
const LEVEL_UI_PATH = "res://ui/level_hud.tscn"
const MENU_UI_PATH = "res://ui/menu_overlay.tscn"

func initialize(ui_layer_ref: CanvasLayer):
	ui_layer = ui_layer_ref

func load_ui_for_scene(scene_path: String):
	if current_ui:
		current_ui.queue_free()
		current_ui = null
	
	var ui_scene_path = ""
	
	# Check if the loaded scene has a game_manager with custom UI flag
	var game_manager = _get_game_manager_from_scene(scene_path)
	if game_manager and game_manager.use_custom_ui and game_manager.custom_ui_path:
		# Use completely custom UI
		ui_scene_path = game_manager.custom_ui_path
	elif scene_path.contains("level") or scene_path.contains("main_menu"):
		# Use base level UI for both levels AND main menu (has decor system)
		ui_scene_path = LEVEL_UI_PATH
	
	# Load UI
	if ui_scene_path and ResourceLoader.exists(ui_scene_path):
		var ui_scene = load(ui_scene_path)
		current_ui = ui_scene.instantiate()
		ui_layer.add_child(current_ui)
		
		# If using base UI, add custom elements from game_manager
		if game_manager and not game_manager.use_custom_ui:
			_add_custom_elements_from_manager(game_manager)

func _get_game_manager_from_scene(scene_path: String):
	# Try to peek into the scene to get its game_manager export values
	var scene = load(scene_path)
	if scene:
		var temp_instance = scene.instantiate()
		var manager = temp_instance
		temp_instance.queue_free()
		return manager
	return null

func _add_custom_elements_from_manager(game_manager):
	if current_ui and current_ui.has_method("add_custom_element"):
		for ui_scene in game_manager.custom_ui_elements:
			var element = ui_scene.instantiate()
			current_ui.add_custom_element(element)
