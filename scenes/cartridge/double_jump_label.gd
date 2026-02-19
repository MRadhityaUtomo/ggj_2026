extends Label

# Adjust these to change the "feel"
@export var hover_amplitude: float = 4.0  # How far up/down it moves
@export var hover_speed: float = 2.0      # How fast it moves

var time_passed: float = 0.0
@onready var start_y: float = position.y

func _process(delta: float) -> void:
	time_passed += delta
	
	# Calculate the new Y position using a sine wave
	# Formula: position = amplitude * sin(speed * time)
	var offset = sin(time_passed * hover_speed) * hover_amplitude
	
	position.y = start_y + offset
