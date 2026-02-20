extends Control

func _ready():
	$VBoxContainer/PlayButton.grab_focus()

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen/loading_screen.tscn")

func _on_challenge_button_pressed():
	# Start challenge mode and go straight to level 1
	LevelProgression.start_challenge_mode()
	get_tree().change_scene_to_file("res://scenes/title_screen/loading_screen.tscn")

func _on_leaderboard_button_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen/leaderboard_screen.tscn")

func _on_tutorial_button_pressed():
	pass

func _on_exit_button_pressed():
	get_tree().quit()
