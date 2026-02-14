extends Control

@onready var lives_label: Label = $TopBar/LivesLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var custom_container: Control = %CustomElements

var game_time: float = 0.0

func _ready():
	# Connect to game manager signals if needed
	pass

func _process(delta: float):
	game_time += delta
	update_time_display()

func update_lives(lives: int):
	lives_label.text = "Lives: %d" % lives

func update_time_display():
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	time_label.text = "Time: %d:%02d" % [minutes, seconds]

## Allows levels to add custom UI elements
func add_custom_element(element: Control):
	custom_container.add_child(element)

func clear_custom_elements():
	for child in custom_container.get_children():
		child.queue_free()
