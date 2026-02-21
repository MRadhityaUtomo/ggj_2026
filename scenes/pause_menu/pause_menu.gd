extends Control

signal resume_pressed
signal exit_to_title_pressed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Make sure it fills the screen
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	$VBoxContainer/ResumeButton.grab_focus()

func _on_resume_button_pressed():
	emit_signal("resume_pressed")

func _on_exit_button_pressed():
	emit_signal("exit_to_title_pressed")
