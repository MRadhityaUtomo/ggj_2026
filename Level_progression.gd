extends Node

## Global Level Progression & Scene Manager
## Manage level completion, scene paths, and restart logic (lose conditions)

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
# Paths to your level scenes. Update these to match your actual file structure.
var level_scenes: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	#"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
	#"res://scenes/levels/level_5.tscn",
	#"res://scenes/levels/level_6.tscn"
]

const MAIN_MENU_SCENE: String = "res://scenes/Main_Menu.tscn"

# ─── STATE ────────────────────────────────────────────────────────────────────
# Track completion status for 6 levels
var level_flags: Array[bool] = [false, false, false, false, false, false]



const TOTAL_LEVELS: int = 3

func _ready() -> void:
	pass

# ─── PROGRESSION LOGIC ────────────────────────────────────────────────────────

## Mark a level as finished
## level_idx: 0-based index (Level 1 = 0) OR 1-based number handled via helper
func finish_level(level_number: int, return_to_menu: bool = false) -> void:
	var index = level_number 
	if index < 0 or index >= TOTAL_LEVELS:
		push_error("LevelProgression: Invalid level number %d" % level_number)
		return
		
	level_flags[index] = true
	print("✓ Level %d Completed. valid for progression." % level_number)
	

## Determined by looking for the first incomplete level
func get_current_level_index() -> int:
	for i in range(level_flags.size()):
		if not level_flags[i]:
			return i
	# If all complete, return the last one (or handle game over screen)
	return level_flags.size()

# ─── LOSE CONDITION / RESET LOGIC ─────────────────────────────────────────────

## Call this when the player dies or fails a level condition
## It will reload the current active level scene
func on_lose_condition_met() -> void:
	var current_idx = get_current_level_index()
	print("⚠ Lose condition met. Restarting level %d..." % (current_idx + 1))
	load_level_scene(current_idx)

## Helper to safely load a level scene by index
func load_level_scene(index: int) -> void:
	if index >= 0 and index < level_scenes.size():
		var path = level_scenes[index]
		if ResourceLoader.exists(path):
			get_tree().change_scene_to_file(path)
		else:
			push_error("LevelProgression: Scene path not found: %s" % path)
	else:
		push_error("LevelProgression: Invalid level index for loading: %d" % index)

# ─── UTILS ────────────────────────────────────────────────────────────────────

func reset_progress() -> void:
	for i in range(level_flags.size()):
		level_flags[i] = false
	print("⟲ Progress Reset")

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
