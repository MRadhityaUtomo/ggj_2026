extends Control

## Username Entry Screen - Shown after completing challenge mode

var final_time: float = 0.0

@onready var time_display: Label = $VBoxContainer/TimeDisplay
@onready var username_input: LineEdit = $VBoxContainer/UsernameInput
@onready var submit_button: Button = $VBoxContainer/SubmitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

func _ready():
	# Get the final time from LevelProgression meta
	if LevelProgression.has_meta("challenge_final_time"):
		final_time = LevelProgression.get_meta("challenge_final_time")
	
	time_display.text = "YOUR TIME: " + Leaderboard.format_time(final_time)
	username_input.grab_focus()
	username_input.max_length = 16
	username_input.placeholder_text = "Enter your name..."
	
	submit_button.pressed.connect(_on_submit_pressed)
	username_input.text_submitted.connect(_on_text_submitted)

func _on_text_submitted(_text: String):
	_on_submit_pressed()

func _on_submit_pressed():
	var username = username_input.text.strip_edges()
	if username.is_empty():
		username = "ANONYMOUS"
	
	# Record the score
	Leaderboard.add_entry(username, final_time)
	
	# Clean up challenge mode
	LevelProgression.exit_challenge_mode()
	
	# Go to leaderboard screen
	get_tree().change_scene_to_file("res://scenes/title_screen/leaderboard_screen.tscn")
