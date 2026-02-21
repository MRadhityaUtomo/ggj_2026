extends Node

## Manages UI overlays on the UILayer based on loaded SubViewport content

var ui_layer: CanvasLayer
var current_ui: Node = null

# UI scene paths for different contexts
const LEVEL_UI_PATH = "res://ui/level_hud.tscn"

func initialize(ui_layer_ref: CanvasLayer):
	ui_layer = ui_layer_ref

func load_ui_for_scene(scene_path: String):
	if current_ui:
		current_ui.queue_free()
		current_ui = null
	
	var ui_scene_path = ""
	
	# Don't load level HUD for non-gameplay screens
	if scene_path.contains("username_entry") or scene_path.contains("leaderboard_screen") or scene_path.contains("title_screen"):
		return
	
	if scene_path.contains("level") or scene_path.contains("main_menu"):
		ui_scene_path = LEVEL_UI_PATH
	
	# Load UI
	if ui_scene_path and ResourceLoader.exists(ui_scene_path):
		var ui_scene = load(ui_scene_path)
		current_ui = ui_scene.instantiate()
		ui_layer.add_child(current_ui)
