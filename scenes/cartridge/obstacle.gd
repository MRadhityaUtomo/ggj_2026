extends TileMapLayer

# Subtle settings
@export var hover_amplitude: float = 2.0  # Moves 2 pixels up and 2 pixels down
@export var hover_speed: float = 5      # Slow oscillation

var time_passed: float = 0.0
@onready var start_y: float = position.y

func _process(delta: float) -> void:
	time_passed += delta
	
	# Small, slow sine wave calculation
	var offset = sin(time_passed * hover_speed) * hover_amplitude
	
	position.y = start_y + offset
