extends Node2D

# Cartridges will be populated dynamically from children
var cartridges = []
var current_cartridge_index = 0
var preview_cartridge_index = 0

# Game states
enum GameState {PLAYING, PAUSED_SELECTION}
var current_state = GameState.PLAYING

# Camera
var camera: Camera2D

# Player reference
var player: CharacterBody2D
var player_scene = preload("res://player.tscn")

# Store player state when pausing
var stored_player_position: Vector2
var stored_player_velocity: Vector2

# Cartridge abilities configuration
# [can_dash, can_double_jump]
var cartridge_abilities = [
	[false, false],  # Cartridge 1: basic jump only
	[true, false],   # Cartridge 2: dash ability
	[false, true]    # Cartridge 3: double jump ability
]

func _ready():
	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	# Pixel-perfect camera settings
	camera.position_smoothing_enabled = false  # Disable smoothing for pixel-perfect
	
	# Dynamically get all cartridge children from root node
	for child in get_children():
		if child.name.begins_with("cartridge_"):
			cartridges.append(child)
	
	# Sort cartridges by name to ensure consistent ordering
	cartridges.sort_custom(func(a, b): return a.name < b.name)
	
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
			if Input.is_action_just_pressed("ui_left"):
				cycle_preview(-1)
			elif Input.is_action_just_pressed("ui_right"):
				cycle_preview(1)
			elif Input.is_action_just_pressed("ui_accept"):  # Enter/Space
				confirm_cartridge_change()
			elif Input.is_action_just_pressed("ui_cancel"):  # ESC to go back
				resume_game()

func spawn_player():
	player = player_scene.instantiate()
	# Spawn at a reasonable starting position (center-left of screen)
	player.position = Vector2(32, 80)
	add_child(player)

func set_playing_view():
	current_state = GameState.PLAYING
	camera.zoom = Vector2(1.0, 1.0)  # Full viewport size (shows 192x128 area)
	camera.position = Vector2(96, 64)  # Static camera centered on level
	if player:
		# Unpause physics
		player.set_physics_process(true)
		# Restore player state
		player.velocity = stored_player_velocity

func set_selection_view():
	current_state = GameState.PAUSED_SELECTION
	camera.zoom = Vector2(0.5, 0.5)  # Zoomed out to show cartridges side by side (shows 384x256 area)
	camera.position = Vector2(96, 64)
	if player:
		# Freeze player
		stored_player_position = player.position
		stored_player_velocity = player.velocity
		player.set_physics_process(false)

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
		cartridges[i].modulate = Color(1, 1, 1, 1)  # Full brightness
		# Keep collisions disabled during preview since physics is paused
		set_cartridge_collision_enabled(cartridges[i], false)

func confirm_cartridge_change():
	current_cartridge_index = preview_cartridge_index
	update_cartridge_visibility()
	update_player_abilities()
	set_playing_view()

func update_cartridge_visibility():
	for i in range(cartridges.size()):
		var is_active = (i == current_cartridge_index)
		cartridges[i].visible = is_active
		cartridges[i].modulate = Color(1, 1, 1, 1)  # Reset modulation
		# Enable collisions only for the active cartridge
		set_cartridge_collision_enabled(cartridges[i], is_active)

func set_cartridge_collision_enabled(cartridge: Node2D, enabled: bool):
	# Find all TileMapLayer nodes and toggle their collision
	for child in cartridge.get_children():
		if child is TileMapLayer:
			# Instead of disabling the entire layer, just toggle collision
			if enabled:
				child.collision_enabled = true
			else:
				child.collision_enabled = false

func update_player_abilities():
	if player and current_cartridge_index < cartridge_abilities.size():
		var abilities = cartridge_abilities[current_cartridge_index]
		player.set_cartridge_abilities(abilities[0], abilities[1])
