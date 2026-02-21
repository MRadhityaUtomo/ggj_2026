extends Control

@onready var tutorial_image = $tutorial_image
@onready var close_overlay = $Button
@onready var controls_close_hint = $Label
@onready var menu_container = $VBoxContainer # Reference to your button list
@onready var shadow = $shadow 


func _ready():
	menu_container.get_node("PlayButton").grab_focus()
	tutorial_image.visible = false
	close_overlay.visible = false
	controls_close_hint.visible = false
	shadow.visible = false
	

func _input(event):
	if tutorial_image.visible:
		# If any key or controller button is pressed while tutorial is open
		if event is InputEventKey or event is InputEventJoypadButton:
			if event.is_pressed():
				# We use 'accept_event()' to tell Godot "I handled this, 
				# don't pass it to the buttons underneath!"
				get_viewport().set_input_as_handled()
				_on_close_overlay_pressed()

func _on_tutorial_button_pressed():
	tutorial_image.visible = true
	close_overlay.visible = true
	controls_close_hint.visible = true
	shadow.visible = true
	
	# DISABLE the menu focus
	_set_menu_focus(Control.FOCUS_NONE)

func _on_close_overlay_pressed():
	tutorial_image.visible = false
	close_overlay.visible = false
	controls_close_hint.visible = false
	shadow.visible = false
	
	# RE-ENABLE the menu focus
	_set_menu_focus(Control.FOCUS_ALL)
	# Put the cursor back on the Play button so controller navigation works
	menu_container.get_node("PlayButton").grab_focus()

# Helper function to loop through all buttons and toggle their focus
func _set_menu_focus(mode: Control.FocusMode):
	for button in menu_container.get_children():
		if button is Button:
			button.focus_mode = mode

# --- Navigation Functions ---

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen/loading_screen.tscn")

func _on_challenge_button_pressed():
	LevelProgression.start_challenge_mode()
	get_tree().change_scene_to_file("res://scenes/title_screen/loading_screen.tscn")

func _on_leaderboard_button_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen/leaderboard_screen.tscn")

func _on_exit_button_pressed():
	get_tree().quit()
