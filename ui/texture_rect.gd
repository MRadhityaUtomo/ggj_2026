extends TextureRect

@export var hover_amplitude: float = 8.0  # Distance
@export var hover_speed: float = 2.5      # Frequency
@export var phase_offset: float = 0.0     # Offset in radians (e.g., 1.5 for a "delayed" start)

var time_passed: float = 0.0
@onready var start_y: float = position.y

func _process(delta: float) -> void:
	time_passed += delta
	
	# The math: sin(time * speed + offset) * amplitude
	var offset = sin((time_passed * hover_speed) + phase_offset) * hover_amplitude
	
	position.y = start_y + offset
