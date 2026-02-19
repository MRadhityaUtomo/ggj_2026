extends Control

func _ready():
	# Focus the play button by default for gamepad support
	$VBoxContainer/PlayButton.grab_focus()

func _on_play_button_pressed():
	# Load the existing main menu
	var main_manager = get_tree().root.get_node_or_null("MainSceneManager")
	if main_manager and main_manager.has_method("load_scene"):
		main_manager.load_scene("res://scenes/levels/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")

func _on_tutorial_button_pressed():
	# Load level 1 (or a dedicated tutorial level) directly
	var main_manager = get_tree().root.get_node_or_null("MainSceneManager")
	if main_manager and main_manager.has_method("load_scene"):
		main_manager.load_scene(LevelProgression.level_scenes[0])
	else:
		get_tree().change_scene_to_file(LevelProgression.level_scenes[0])

func _on_exit_button_pressed():
	get_tree().quit()
