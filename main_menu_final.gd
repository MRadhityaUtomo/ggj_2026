extends Node2D

## Main Menu - Works like game_manager but cartridges are level selectors

## ─── CONFIGURATION ───────────────────────────────────────────────────────────
@export var cartridge_configs: Array[CartridgeConfig] = []
@export var spawn_marker: Marker2D  # Add spawn marker like game_manager

## ─── INTERNAL STATE ──────────────────────────────────────────────────────────
var cartridges: Array[Cartridge] = []
var current_cartridge_index = 0
var preview_cartridge_index = 0

# Player reference (same as game_manager)
var player: CharacterBody2D
var player_scene = preload("res://player.tscn")

# Store player state when pausing
var stored_player_velocity: Vector2

# Level loading cooldown to prevent rapid re-triggering
var level_load_cooldown: float = 0.0
const LOAD_COOLDOWN_TIME: float = 0.5

# Game states
enum MenuState {PLAYING, PAUSED_SELECTION}
var current_state = MenuState.PLAYING

# Camera
var camera: Camera2D
var zoom_tween: Tween

# Game resolution constants
const GAME_WIDTH = 384
const GAME_HEIGHT = 256
const GAME_CENTER = Vector2(192, 128)

# TV visuals
var tv_container: Node2D
var tv_frame: Sprite2D
var tv_bg: Sprite2D
var tv_frame_area: Area2D
var tv_rotation: float = 0.0
var rotation_index: int = 0

# Zoom animation settings
const ZOOM_DURATION = 0.3
const ZOOM_TRANS_TYPE = Tween.TRANS_CUBIC
const ZOOM_EASE_TYPE = Tween.EASE_IN_OUT

# Audio
var zoom_audio: AudioStreamPlayer
const ZOOM_OUT_SFX = preload("res://sounds/audio/Cassette Preview/AUDIO/BUTTON_03.wav")
const ZOOM_IN_SFX = preload("res://sounds/audio/Cassette Preview/AUDIO/CASSETTE_RATTLE_12.wav")

func _ready():
	# Setup zoom audio player
	zoom_audio = AudioStreamPlayer.new()
	zoom_audio.stream = ZOOM_OUT_SFX
	zoom_audio.bus = "Master"
	add_child(zoom_audio)
	
	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	camera.zoom = Vector2(1.0, 1.0)
	camera.position = GAME_CENTER
	camera.position_smoothing_enabled = false

	# Add TV background sprite OUTSIDE tv_container
	tv_bg = Sprite2D.new()
	tv_bg.texture = preload("res://tv_bg.png")
	tv_bg.centered = true
	tv_bg.position = GAME_CENTER
	tv_bg.z_index = -200
	tv_bg.visible = true
	add_child(tv_bg)
	
	# Create TV container
	tv_container = Node2D.new()
	add_child(tv_container)
	tv_container.z_index = 100
	tv_container.position = GAME_CENTER
	
	# Add TV frame sprite
	tv_frame = Sprite2D.new()
	tv_frame.texture = preload("res://tv_frame.png")
	tv_frame.centered = true
	tv_frame.position = Vector2.ZERO
	tv_frame.z_index = 200
	tv_frame.visible = true
	tv_container.add_child(tv_frame)
	
	# Create clickable area for the TV frame
	tv_frame_area = Area2D.new()
	tv_frame.add_child(tv_frame_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(768, 512)
	collision_shape.shape = shape
	tv_frame_area.add_child(collision_shape)
	
	tv_frame_area.input_event.connect(_on_tv_frame_input)
	tv_frame_area.mouse_entered.connect(_on_tv_frame_mouse_entered)
	tv_frame_area.mouse_exited.connect(_on_tv_frame_mouse_exited)
	tv_frame_area.input_pickable = true
	
	# Instantiate cartridge scenes from configs
	# Cartridge 0 = Menu (playable area)
	# Cartridge 1+ = Level previews (visual only, no collision)
	for i in range(cartridge_configs.size()):
		var config = cartridge_configs[i]
		if config and config.scene:
			var instance = config.scene.instantiate()
			if not instance is Cartridge:
				instance.set_script(preload("res://cartridge.gd"))
			tv_container.add_child(instance)
			instance.position -= GAME_CENTER
			
			# Disable collision for level preview cartridges (index 1+)
			if i > 0:
				if instance.has_method("set_collision_enabled"):
					instance.set_collision_enabled(false)
				# Disable physics for preview cartridges
				_disable_cartridge_physics(instance)
			
			cartridges.append(instance)
	
	# Spawn player (ONLY interacts with cartridge 0 - the menu)
	spawn_player()
	# Parent player to tv_container so it rotates with the screen
	if player:
		var player_world_pos = player.global_position
		remove_child(player)
		tv_container.add_child(player)
		player.position = player_world_pos - GAME_CENTER
	
	# Initialize cartridge visibility (only show menu cartridge)
	update_cartridge_visibility()
	
	# Start in playing mode (viewing menu)
	set_playing_view()

func _disable_cartridge_physics(cartridge: Node2D):
	# Recursively disable physics for all TileMapLayer nodes in preview cartridges
	for child in cartridge.get_children():
		if child is TileMapLayer:
			child.collision_enabled = false
		elif child.get_child_count() > 0:
			_disable_cartridge_physics(child)

func spawn_player():
	player = player_scene.instantiate()
	# Use spawn marker if set, otherwise fallback
	if spawn_marker:
		player.position = spawn_marker.global_position
	else:
		player.position = Vector2(96, 80)  # Default spawn on menu platforms
	add_child(player)  # Temporarily add to get position, will reparent in _ready

func _process(delta):
	# Update cooldown
	if level_load_cooldown > 0:
		level_load_cooldown -= delta
	
	match current_state:
		MenuState.PLAYING:
			# ESC to enter selection mode (zoom out to choose levels)
			if Input.is_action_just_pressed("exit"):
				pause_and_show_selection()
		
		MenuState.PAUSED_SELECTION:
			# Cycle cartridges
			if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("cycle_left"):
				cycle_preview(-1)
			elif Input.is_action_just_pressed("right") or Input.is_action_just_pressed("cycle_right"):
				cycle_preview(1)
			
			# JUMP BUTTON (Space/A) to load selected level
			elif Input.is_action_just_pressed("up") and level_load_cooldown <= 0:
				load_selected_level()
			
			# ESC to cancel and return to menu without loading
			elif Input.is_action_just_pressed("exit"):
				return_to_menu()
			
			# Rotate TV
			if Input.is_action_just_pressed("rotate_right"):
				rotate_tv_90_degrees()
			elif Input.is_action_just_pressed("rotate_left"):
				rotate_tv_90_degrees_ccw()

func pause_and_show_selection():
	# Start at cartridge 1 (first level preview), not cartridge 0 (menu itself)
	preview_cartridge_index = max(1, current_cartridge_index)
	set_selection_view()
	update_cartridge_preview()

func return_to_menu():
	# Go back to viewing the menu without loading a level
	current_cartridge_index = 0
	preview_cartridge_index = 0
	update_cartridge_visibility()
	set_playing_view()

func set_playing_view():
	current_state = MenuState.PLAYING
	animate_camera_zoom(Vector2(1.0, 1.0))
	play_zoom_sfx(true)
	camera.position = GAME_CENTER
	
	if player:
		player.set_physics_process(true)
		player.visible = true

func set_selection_view():
	current_state = MenuState.PAUSED_SELECTION
	animate_camera_zoom(Vector2(0.5, 0.5))
	play_zoom_sfx(false)
	camera.position = GAME_CENTER
	tv_frame.visible = true
	tv_bg.visible = true
	
	if player:
		stored_player_velocity = player.velocity
		player.set_physics_process(false)
		player.visible = false  # Hide player during selection

func cycle_preview(direction: int):
	if cartridges.size() <= 1:  # Only menu cartridge
		return
	
	# Cycle through level previews only (skip cartridge 0)
	preview_cartridge_index += direction
	
	# Wrap around (stay in range 1 to cartridges.size()-1)
	if preview_cartridge_index < 1:
		preview_cartridge_index = cartridges.size() - 1
	elif preview_cartridge_index >= cartridges.size():
		preview_cartridge_index = 1
	
	update_cartridge_preview()

func update_cartridge_visibility():
	# When playing, only show menu cartridge (index 0)
	for i in range(cartridges.size()):
		var is_active = (i == current_cartridge_index)
		cartridges[i].visible = is_active
		cartridges[i].modulate = Color(1, 1, 1, 1)

func update_cartridge_preview():
	# When in selection mode, show the preview cartridge
	for i in range(cartridges.size()):
		var is_preview = (i == preview_cartridge_index)
		cartridges[i].visible = is_preview
		cartridges[i].modulate = Color(1, 1, 1, 1)

func confirm_cartridge_change():
	# This is not used in menu - we use load_selected_level() instead
	current_cartridge_index = preview_cartridge_index
	update_cartridge_visibility()
	set_playing_view()

func load_selected_level():
	# Map preview cartridge index to level index
	# Cartridge 0 = Menu (skip)
	# Cartridge 1 = Level 0
	# Cartridge 2 = Level 1, etc.
	if preview_cartridge_index < 1:
		return  # Don't load if somehow on menu cartridge
	
	var level_index = preview_cartridge_index - 1
	
	if level_index < 0 or level_index >= LevelProgression.level_scenes.size():
		push_error("Invalid level index: %d" % level_index)
		return
	
	# Check if level is unlocked
	var highest_unlocked = 0
	for i in range(LevelProgression.level_flags.size()):
		if LevelProgression.level_flags[i]:
			highest_unlocked = i + 1
	
	if level_index <= highest_unlocked:
		# Set cooldown to prevent rapid re-loading
		level_load_cooldown = LOAD_COOLDOWN_TIME
		
		# Load the level
		var main_manager = get_tree().root.get_node_or_null("MainSceneManager")
		if main_manager and main_manager.has_method("change_level"):
			print("Loading Level %d (Cartridge %d)" % [level_index + 1, preview_cartridge_index])
			main_manager.change_level(level_index)
		else:
			push_error("MainSceneManager not found!")
	else:
		print("Level %d is locked! Complete Level %d first." % [level_index + 1, highest_unlocked])
		# TODO: Play locked sound/show locked message

func rotate_tv_90_degrees():
	if current_state != MenuState.PAUSED_SELECTION:
		return
	
	rotation_index += 1
	var target_rotation_degrees = rotation_index * 90.0
	rotate_tv_and_gravity(target_rotation_degrees)

func rotate_tv_90_degrees_ccw():
	if current_state != MenuState.PAUSED_SELECTION:
		return
	
	rotation_index -= 1
	var target_rotation_degrees = rotation_index * 90.0
	rotate_tv_and_gravity(target_rotation_degrees)

func rotate_tv_and_gravity(new_rotation_degrees: float):
	tv_rotation = deg_to_rad(new_rotation_degrees)
	
	var tween = create_tween()
	tween.tween_property(tv_container, "rotation", tv_rotation, 0.5).set_trans(Tween.TRANS_CUBIC)

func animate_camera_zoom(target_zoom: Vector2):
	if zoom_tween:
		zoom_tween.kill()
	
	zoom_tween = create_tween()
	zoom_tween.set_trans(ZOOM_TRANS_TYPE)
	zoom_tween.set_ease(ZOOM_EASE_TYPE)
	zoom_tween.tween_property(camera, "zoom", target_zoom, ZOOM_DURATION)

func play_zoom_sfx(zoom_in: bool) -> void:
	zoom_audio.stop()
	if zoom_in:
		zoom_audio.stream = ZOOM_IN_SFX
		zoom_audio.pitch_scale = 2.4
	else:
		zoom_audio.stream = ZOOM_OUT_SFX
		zoom_audio.pitch_scale = 1.0
	zoom_audio.play()

func _on_tv_frame_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			rotate_tv_90_degrees()

func _on_tv_frame_mouse_entered():
	if tv_frame and current_state == MenuState.PAUSED_SELECTION:
		tv_frame.modulate = Color(1.2, 1.2, 1.2)

func _on_tv_frame_mouse_exited():
	if tv_frame:
		tv_frame.modulate = Color(1, 1, 1)
