extends Node2D

## ─── CONFIGURATION ───────────────────────────────────────────────────────────
## Drag cartridge scenes here and pick their type (RED / BLUE / GREEN)
@export var cartridge_configs: Array[CartridgeConfig] = []

## Optional: place a Marker2D child named "SpawnPoint" in this scene.
## The player will spawn there on first load. If missing, falls back to (32, 80).
@export var spawn_marker: Marker2D

## ─── INTERNAL STATE ──────────────────────────────────────────────────────────
var cartridges: Array[Cartridge] = []  # instantiated cartridge nodes
var current_cartridge_index = 0
var preview_cartridge_index = 0

# Game states
enum GameState {PLAYING, PAUSED_SELECTION}
var current_state = GameState.PLAYING

# Camera
var camera: Camera2D
var zoom_tween: Tween

# Player reference
var player: CharacterBody2D
var player_scene = preload("res://player.tscn")

# Store player state when pausing
var stored_player_position: Vector2
var stored_player_velocity: Vector2

# Zoom animation settings
const ZOOM_DURATION = 0.3
const ZOOM_TRANS_TYPE = Tween.TRANS_CUBIC
const ZOOM_EASE_TYPE = Tween.EASE_IN_OUT

func _ready():
	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	camera.position_smoothing_enabled = false  # Pixel-perfect

	# Instantiate cartridge scenes from configs
	for config in cartridge_configs:
		if config and config.scene:
			var instance = config.scene.instantiate()
			# Ensure it has the Cartridge script for collision toggling
			if not instance is Cartridge:
				instance.set_script(preload("res://cartridge.gd"))
			add_child(instance)
			cartridges.append(instance)

	# Spawn player
	spawn_player()

	# Initialize cartridge visibility and collisions
	update_cartridge_visibility()

	# Start in playing mode
	set_playing_view()
	update_player_abilities()

func _process(_delta):
	match current_state:
		GameState.PLAYING:
			if Input.is_action_just_pressed("ui_cancel"):  # ESC key
				pause_and_show_selection()
		
		GameState.PAUSED_SELECTION:
			if Input.is_action_just_pressed("left"):
				cycle_preview(-1)
			elif Input.is_action_just_pressed("right"):
				cycle_preview(1)
			elif Input.is_action_just_pressed("ui_accept"):  # Enter/Space
				confirm_cartridge_change()
			elif Input.is_action_just_pressed("ui_cancel"):  # ESC to go back
				resume_game()

func spawn_player():
	player = player_scene.instantiate()
	# Use spawn marker if set, otherwise fallback
	if spawn_marker:
		player.position = spawn_marker.global_position
	else:
		player.position = Vector2(32, 80)
	add_child(player)

func set_playing_view():
	current_state = GameState.PLAYING
	animate_camera_zoom(Vector2(1.0, 1.0))  # Zoom in
	camera.position = Vector2(96, 64)  # Static camera centered on level
	if player:
		# Unpause physics
		player.set_physics_process(true)
		# Restore player state
		player.velocity = stored_player_velocity

func set_selection_view():
	current_state = GameState.PAUSED_SELECTION
	animate_camera_zoom(Vector2(0.5, 0.5))  # Zoom out
	camera.position = Vector2(96, 64)
	if player:
		# Freeze player
		stored_player_position = player.position
		stored_player_velocity = player.velocity
		player.set_physics_process(false)

func animate_camera_zoom(target_zoom: Vector2):
	# Kill existing tween if running
	if zoom_tween:
		zoom_tween.kill()
	
	# Create new tween
	zoom_tween = create_tween()
	zoom_tween.set_trans(ZOOM_TRANS_TYPE)
	zoom_tween.set_ease(ZOOM_EASE_TYPE)
	
	# Animate the zoom
	zoom_tween.tween_property(camera, "zoom", target_zoom, ZOOM_DURATION)

func pause_and_show_selection():
	preview_cartridge_index = current_cartridge_index
	set_selection_view()
	# Show preview of current cartridge
	update_cartridge_preview()

func resume_game():
	# Go back to playing without changing cartridge
	preview_cartridge_index = current_cartridge_index
	update_cartridge_visibility()
	set_playing_view()

func cycle_preview(direction: int):
	preview_cartridge_index = (preview_cartridge_index + direction) % cartridges.size()
	if preview_cartridge_index < 0:
		preview_cartridge_index = cartridges.size() - 1
	update_cartridge_preview()

func update_cartridge_preview():
	# Show only the preview cartridge, hide all others
	for i in range(cartridges.size()):
		var is_preview = (i == preview_cartridge_index)
		cartridges[i].visible = is_preview
		cartridges[i].modulate = Color(1, 1, 1, 1)
		# Keep collisions disabled during preview since physics is paused
		cartridges[i].set_collision_enabled(false)

func confirm_cartridge_change():
	current_cartridge_index = preview_cartridge_index
	update_cartridge_visibility()
	update_player_abilities()
	set_playing_view()

func update_cartridge_visibility():
	for i in range(cartridges.size()):
		var is_active = (i == current_cartridge_index)
		cartridges[i].visible = is_active
		cartridges[i].modulate = Color(1, 1, 1, 1)
		cartridges[i].set_collision_enabled(is_active)

func update_player_abilities():
	if player and current_cartridge_index < cartridge_configs.size():
		var abilities = cartridge_configs[current_cartridge_index].get_abilities()
		player.set_cartridge_abilities(abilities["can_dash"], abilities["can_double_jump"])
