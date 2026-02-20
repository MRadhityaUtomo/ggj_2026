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

const TOTAL_LEVELS: int = 1

# ─── CHALLENGE MODE ──────────────────────────────────────────────────────────
var challenge_mode: bool = false
var challenge_timer: float = 0.0
var challenge_timer_running: bool = false
var _challenge_level_start_time: float = 0.0  # Timer snapshot when entering a level

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if challenge_mode and challenge_timer_running:
		challenge_timer += delta

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
	# In challenge mode, revert timer to level start checkpoint
	if challenge_mode:
		on_challenge_death()
	load_level_scene(active_level_index)

## Helper to safely load a level scene by index
func load_level_scene(index: int) -> void:
	if index >= 0 and index < TOTAL_LEVELS:
		active_level_index = index
		
		# Save challenge checkpoint when entering a new level
		if challenge_mode:
			save_challenge_checkpoint()
		
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

# ─── CHALLENGE MODE HELPERS ───────────────────────────────────────────────────

## Start challenge mode: reset everything and begin at level 0
func start_challenge_mode() -> void:
	challenge_mode = true
	challenge_timer = 0.0
	challenge_timer_running = false
	_challenge_level_start_time = 0.0
	reset_progress()
	active_level_index = 0
	print("⏱ Challenge Mode started!")

## Call when a level begins playing (resumes timer and saves checkpoint)
func resume_challenge_timer() -> void:
	if challenge_mode:
		challenge_timer_running = true

## Save a checkpoint so we can revert on death
func save_challenge_checkpoint() -> void:
	if challenge_mode:
		_challenge_level_start_time = challenge_timer
		print("⏱ Checkpoint saved at %s" % Leaderboard.format_time(_challenge_level_start_time))

## Call when zoomed out / paused (pauses timer)
func pause_challenge_timer() -> void:
	if challenge_mode:
		challenge_timer_running = false

## Call when player dies / restarts level — revert timer to level start
func on_challenge_death() -> void:
	if challenge_mode:
		challenge_timer_running = false
		challenge_timer = _challenge_level_start_time
		print("⏱ Timer reverted to %s" % Leaderboard.format_time(challenge_timer))

## Call when all levels complete in challenge mode
func finish_challenge_mode() -> float:
	challenge_timer_running = false
	var final_time = challenge_timer
	print("⏱ Challenge Mode finished! Time: %s" % Leaderboard.format_time(final_time))
	return final_time

## End challenge mode and return to normal
func exit_challenge_mode() -> void:
	challenge_mode = false
	challenge_timer = 0.0
	challenge_timer_running = false

## Get formatted challenge timer string
func get_challenge_time_string() -> String:
	return Leaderboard.format_time(challenge_timer)

## Check if we are in challenge mode
func is_challenge_mode() -> bool:
	return challenge_mode
