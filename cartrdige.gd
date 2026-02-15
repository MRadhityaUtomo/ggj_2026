extends Node

@export var custom_ui_elements: Array[PackedScene] = []
@export var use_custom_ui: bool = false
@export_file("*.tscn") var custom_ui_path: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
