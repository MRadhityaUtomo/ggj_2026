extends Control

@onready var level1_button = $VBoxContainer/Level1Button
@onready var level2_button = $VBoxContainer/Level2Button
@onready var level3_button = $VBoxContainer/Level3Button

# Save data
var save_path = "user://save_data.json"
var completed_levels = []

func _ready():
    # Load progress
    load_progress()
    
    # Connect buttons
    level1_button.pressed.connect(_on_level1_pressed)
    level2_button.pressed.connect(_on_level2_pressed)
    level3_button.pressed.connect(_on_level3_pressed)
    
    # Update button states based on progress
    update_button_states()

func load_progress():
    if FileAccess.file_exists(save_path):
        var file = FileAccess.open(save_path, FileAccess.READ)
        var json_string = file.get_as_text()
        var json = JSON.new()
        var parse_result = json.parse(json_string)
        if parse_result == OK:
            var data = json.get_data()
            completed_levels = data.get("completed_levels", [])
        file.close()

func save_progress():
    var data = {
        "completed_levels": completed_levels
    }
    var file = FileAccess.open(save_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data))
    file.close()

func update_button_states():
    # Level 1 is always available
    level1_button.disabled = false
    
    # Level 2 unlocks after completing level 1
    level2_button.disabled = not (1 in completed_levels)
    
    # Level 3 unlocks after completing level 2
    level3_button.disabled = not (2 in completed_levels)

func _on_level1_pressed():
    get_tree().change_scene_to_file("res://level_1.tscn")

func _on_level2_pressed():
    # Create level_2.tscn first
    pass

func _on_level3_pressed():
    # Create level_3.tscn first
    pass

# Called from game manager when level is completed
static func mark_level_complete(level_number: int):
    var selector = load("res://level_selector.gd").new()
    selector.load_progress()
    if not (level_number in selector.completed_levels):
        selector.completed_levels.append(level_number)
        selector.save_progress()