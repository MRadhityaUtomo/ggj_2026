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
var tv_outline_mat : ShaderMaterial


# Game states
enum GameState {PLAYING, PAUSED_SELECTION}
var current_state = GameState.PLAYING

# Camera
var camera: Camera2D
var zoom_tween: Tween

# Game resolution constants
const GAME_WIDTH = 384
const GAME_HEIGHT = 256
const GAME_CENTER = Vector2(192, 128)

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

# Add to your variables section
var tv_container: Node2D  # Container for TV frame and decorations
var tv_frame: Sprite2D    # The TV bezel/frame
var tv_frame_area: Area2D  # For mouse detection
var tv_rotation: float = 0.0  # Current TV rotation for gravity changes
var rotation_index: int = 0  # Track number of rotations (can be > 4)
var tv_bg: Sprite2D  # Background - NOT rotated

# Audio
var zoom_audio: AudioStreamPlayer
const ZOOM_OUT_SFX = preload("res://sounds/audio/Cassette Preview/AUDIO/BUTTON_03.wav")
const ZOOM_IN_SFX = preload("res://sounds/audio/Cassette Preview/AUDIO/CASSETTE_RATTLE_12.wav")

func _ready():
	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	camera.position_smoothing_enabled = false  # Pixel-perfect

	# Add TV background sprite OUTSIDE tv_container (so it doesn't rotate)
	tv_bg = Sprite2D.new()
	tv_bg.texture = preload("res://tv_bg.png")
	tv_bg.centered = true
	tv_bg.position = GAME_CENTER  # Changed from Vector2(192, 128)
	tv_bg.z_index = -200  # Render behind everything
	tv_bg.visible = false  # Hidden during gameplay
	add_child(tv_bg)  # Add to main scene, not tv_container
	
	# Setup zoom audio player (non-positional so it plays at full volume)
	zoom_audio = AudioStreamPlayer.new()
	zoom_audio.stream = ZOOM_OUT_SFX
	zoom_audio.bus = "Master"
	add_child(zoom_audio)

	# Create TV container (this will rotate when gravity changes)
	tv_container = Node2D.new()
	add_child(tv_container)
	tv_container.z_index = 100  # Render above gameplay
	tv_container.position = GAME_CENTER  # Changed from Vector2(96, 64)

	# Add TV frame sprite (rotates with container)
	tv_frame = Sprite2D.new()
	tv_frame.texture = preload("res://tv_frame.png")
	tv_frame.centered = true
	tv_frame.position = Vector2.ZERO
	tv_frame.z_index = 200  # Render in front
	tv_frame.visible = false
	tv_container.add_child(tv_frame)  # Inside tv_container - will rotate

	# Setup shader material AFTER tv_frame is created
	tv_outline_mat = ShaderMaterial.new()
	tv_outline_mat.shader = preload("res://outline_shader.gdshader")
	# Initialize shader parameters
	tv_outline_mat.set_shader_parameter("enabled", 0.0)
	tv_outline_mat.set_shader_parameter("progress", 1.0)
	tv_outline_mat.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0, 1.0))
	tv_outline_mat.set_shader_parameter("thickness", 1.0)
	tv_frame.material = tv_outline_mat

	# Create clickable area for the TV frame
	tv_frame_area = Area2D.new()
	tv_frame.add_child(tv_frame_area)
	tv_outline_mat = ShaderMaterial.new()
	tv_outline_mat.shader = preload("res://outline_shader.gdshader")
	tv_frame.material = tv_outline_mat
	# Add collision shape that matches your frame size
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(768, 512)  # Doubled from 384x256
	collision_shape.shape = shape
	tv_frame_area.add_child(collision_shape)

	# Connect mouse signals
	tv_frame_area.input_event.connect(_on_tv_frame_input)
	tv_frame_area.mouse_entered.connect(_on_tv_frame_mouse_entered)
	tv_frame_area.mouse_exited.connect(_on_tv_frame_mouse_exited)
	tv_frame_area.input_pickable = true

	# Instantiate cartridge scenes from configs
	for config in cartridge_configs:
		if config and config.scene:
			var instance = config.scene.instantiate()
			# Ensure it has the Cartridge script for collision toggling
			if not instance is Cartridge:
				instance.set_script(preload("res://cartridge.gd"))
			# Parent cartridges to tv_container so they rotate with the TV
			tv_container.add_child(instance)
			# Offset cartridges relative to container center
			instance.position -= GAME_CENTER  # Changed from Vector2(96, 64)
			cartridges.append(instance)

	# Spawn player
	spawn_player()
	# Parent player to tv_container so it rotates with the screen
	if player:
		var player_world_pos = player.global_position
		remove_child(player)
		tv_container.add_child(player)
		player.position = player_world_pos - GAME_CENTER  # Changed from Vector2(96, 64)

	# Initialize cartridge visibility and collisions
	update_cartridge_visibility()

	# Start in playing mode
	set_playing_view()
	update_player_abilities()

func _process(_delta):
	match current_state:
		GameState.PLAYING:
			if Input.is_action_just_pressed("exit"):  # ESC key / Y button
				pause_and_show_selection()
		
		GameState.PAUSED_SELECTION:
			# Cycle cartridges: arrow keys OR LB/RB
			if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("cycle_left"):
				cycle_preview(-1)
			elif Input.is_action_just_pressed("right") or Input.is_action_just_pressed("cycle_right"):
				cycle_preview(1)
			elif Input.is_action_just_pressed("exit"):  # Enter/Space / Y button
				confirm_cartridge_change()
			
			# Spin level: RT (clockwise) / LT (counter-clockwise)
			if Input.is_action_just_pressed("rotate_right"):
				rotate_tv_90_degrees()
			elif Input.is_action_just_pressed("rotate_left"):
				rotate_tv_90_degrees_ccw()

func play_tv_selection_outline():
	if not tv_outline_mat:
		return
	
	tv_outline_mat.set_shader_parameter("enabled", 1.0)
	tv_outline_mat.set_shader_parameter("progress", 0.0)

	var t = create_tween()
	t.tween_property(
		tv_outline_mat,
		"shader_parameter/progress",
		1.0,
		0.25
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func spawn_player():
	player = player_scene.instantiate()
	# Use spawn marker if set, otherwise fallback
	if spawn_marker:
		player.position = spawn_marker.global_position
	else:
		player.position = Vector2(64, 160)  # Adjusted for 384x256 resolution
	add_child(player)  # Temporarily add to get position, will reparent in _ready

func set_playing_view():
	current_state = GameState.PLAYING
	animate_camera_zoom(Vector2(1.0, 1.0))  # Zoom in
	play_zoom_sfx(true)  # Reversed (zoom in)
	camera.position = GAME_CENTER  # Changed from Vector2(192, 128)
	if player:
		# Unpause physics
		player.set_physics_process(true)
		# Restore player state
		player.velocity = stored_player_velocity

func set_selection_view():
	current_state = GameState.PAUSED_SELECTION
	animate_camera_zoom(Vector2(0.5, 0.5))  # Zoom out
	play_zoom_sfx(false)  # Normal (zoom out)
	camera.position = GAME_CENTER  # Changed from Vector2(192, 128)
	
	# Show the TV frame and background
	if tv_frame:
		tv_frame.visible = true
	if tv_bg:
		tv_bg.visible = true

	if player:
		# Freeze player
		stored_player_position = player.position
		stored_player_velocity = player.velocity
		player.set_physics_process(false)

## Play zoom SFX.
##   - Zoom out: Temp_Zoom_out.wav at normal pitch
##   - Zoom in:  Temp_Zoom_in.mp3 at pitch 2.4
func play_zoom_sfx(zoom_in: bool) -> void:
	zoom_audio.stop()
	if zoom_in:
		zoom_audio.stream = ZOOM_IN_SFX
		zoom_audio.pitch_scale = 2.4
	else:
		zoom_audio.stream = ZOOM_OUT_SFX
		zoom_audio.pitch_scale = 1.0
	zoom_audio.play()

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
	for i in range(cartridges.size()):
		var is_preview = (i == preview_cartridge_index)
		cartridges[i].visible = is_preview
		cartridges[i].modulate = Color(1, 1, 1, 1)
		cartridges[i].set_collision_enabled(false)

	play_tv_selection_outline() # ← ADD THIS LINE


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

# For later when you implement gravity rotation
func rotate_tv_and_gravity(new_rotation_degrees: float):
	tv_rotation = deg_to_rad(new_rotation_degrees)
	
	# Rotate the TV visuals AND the gameplay screen
	var tween = create_tween()
	tween.tween_property(tv_container, "rotation", tv_rotation, 0.5).set_trans(Tween.TRANS_CUBIC)
	
	# Tell player to counter-rotate its sprite
	if player and player.has_method("set_parent_rotation"):
		player.set_parent_rotation(tv_rotation)
	
	# Change gravity direction
	var gravity_vector = Vector2.DOWN.rotated(tv_rotation)
	PhysicsServer2D.area_set_param(
		get_viewport().find_world_2d().space,
		PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR,
		gravity_vector
	)

func _on_tv_frame_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			rotate_tv_90_degrees()

func _on_tv_frame_mouse_entered():
	# Optional: Visual feedback when hovering
	if tv_frame and current_state == GameState.PAUSED_SELECTION:
		tv_frame.modulate = Color(1.2, 1.2, 1.2)  # Brighten slightly

func _on_tv_frame_mouse_exited():
	# Reset visual feedback
	if tv_frame:
		tv_frame.modulate = Color(1, 1, 1)

func rotate_tv_90_degrees():
	if current_state != GameState.PAUSED_SELECTION:
		return  # Only allow rotation during selection
	
	# Increment rotation index (no wrapping, keeps increasing)
	rotation_index += 1
	
	# Calculate target rotation as continuous value
	var target_rotation_degrees = rotation_index * 90.0
	
	rotate_tv_and_gravity(target_rotation_degrees)

func rotate_tv_90_degrees_ccw():
	if current_state != GameState.PAUSED_SELECTION:
		return  # Only allow rotation during selection
	
	# Decrement rotation index for counter-clockwise
	rotation_index -= 1
	
	var target_rotation_degrees = rotation_index * 90.0
	
	rotate_tv_and_gravity(target_rotation_degrees)


# Calculate appropriate zoom based on TV rotation
func get_zoom_for_rotation(rotation_rad: float) -> Vector2:
	# Normalize rotation to 0-360 degrees for calculation
	var rotation_deg = fmod(rad_to_deg(rotation_rad), 360.0)
	if rotation_deg < 0:
		rotation_deg += 360.0
	
	# Check if rotation is vertical (90° or 270°)
	var is_vertical = (abs(rotation_deg - 90.0) < 5.0) or (abs(rotation_deg - 270.0) < 5.0)
	
	if is_vertical:
		# When vertical, zoom out to fit the rotated screen
		return Vector2(0.67, 0.67)
	else:
		# Normal horizontal view - standard zoom
		return Vector2(1.0, 1.0)
