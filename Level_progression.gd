extends Node

## Global Level Progression & Scene Manager
## Manage level completion, scene paths, and restart logic (lose conditions)

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
var level_scenes: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_dash_tutorial.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_4.tscn",
	"res://scenes/levels/level_5.tscn",
	"res://scenes/levels/level_6.tscn",
	"res://scenes/levels/jump_intermediate_level.tscn",
	"res://scenes/levels/level_dash_intro.tscn",
	"res://scenes/levels/glitch_trap_level.tscn",
]

const MAIN_MENU_SCENE: String = "res://scenes/levels/main_menu.tscn"

# ─── STATE ────────────────────────────────────────────────────────────────────
var level_flags: Array[bool] = [true, true, true, true, true, true, true, true,true]

# Track which level the player is currently playing (not just first incomplete)
var active_level_index: int = 0

const TOTAL_LEVELS: int = 9

func _ready() -> void:
	pass

# ─── PROGRESSION LOGIC ────────────────────────────────────────────────────────

## Set which level the player is about to play
func set_active_level(index: int) -> void:
	if index >= 0 and index < TOTAL_LEVELS:
		active_level_index = index
		print("▶ Active level set to %d" % index)
	else:
		push_error("LevelProgression: Invalid level index %d" % index)

## Get the level the player is currently playing
func get_active_level_index() -> int:
	return active_level_index

## Mark a level as finished and advance to next level
func finish_level(level_number: int) -> void:
	var index = level_number
	if index < 0 or index >= TOTAL_LEVELS:
		push_error("LevelProgression: Invalid level number %d" % level_number)
		return
	
	level_flags[index] = true
	print("✓ Level %d Completed." % level_number)
	
	# Advance active level to next one
	active_level_index = index + 1

## Get the next level to load after completing current
func get_next_level_index() -> int:
	return active_level_index + 1

## Check if a specific level has been completed
func is_level_completed(index: int) -> bool:
	if index >= 0 and index < TOTAL_LEVELS:
		return level_flags[index]
	return false

## Check if all levels are complete
func all_levels_complete() -> bool:
	for flag in level_flags:
		if not flag:
			return false
	return true

# ─── LOSE CONDITION / RESET LOGIC ─────────────────────────────────────────────

## Reload the SAME level the player was playing
func on_lose_condition_met() -> void:
	print("⚠ Lose condition met. Restarting level %d..." % (active_level_index + 1))
	load_level_scene(active_level_index)

## Helper to safely load a level scene by index
func load_level_scene(index: int) -> void:
	if index >= 0 and index < TOTAL_LEVELS:
		active_level_index = index
		
		# Use MainSceneManager - DO NOT fall back to direct scene change
		var main_manager = get_tree().root.get_node_or_null("MainSceneManager")
		if main_manager and main_manager.has_method("change_level"):
			main_manager.change_level(index)
		else:
			push_error("CRITICAL: MainSceneManager not found! Cannot load level. Make sure main_scene_manager.tscn is the main scene.")
	else:
		push_error("LevelProgression: Invalid level index for loading: %d" % index)

# ─── UTILS ────────────────────────────────────────────────────────────────────

func reset_progress() -> void:
	for i in range(level_flags.size()):
		level_flags[i] = false
	active_level_index = 0
	print("⟲ Progress Reset")

func go_to_main_menu() -> void:
	var main_manager = get_tree().root.get_node_or_null("MainSceneManager")
	if main_manager and main_manager.has_method("return_to_main_menu"):
		main_manager.return_to_main_menu()
	else:
		push_error("CRITICAL: MainSceneManager not found! Cannot return to menu.")
