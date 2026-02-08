extends CharacterBody2D

@onready var audio_player = $AudioStreamPlayer2D

const WALK_SFX = preload("res://sounds/walk_sfx.wav")
const JUMP_SFX = preload("res://sounds/error Sfx.wav")#Will Change
const DASH_SFX = preload("res://sounds/temp_dash.wav")
const DEATH_SFX = preload("res://sounds/death_sfx.wav")

# Movement parameters
const SPEED = 80.0
const JUMP_VELOCITY = -200.0  # Adjusted for 2-tile jump height
const GRAVITY = 580.0
const DASH_DISTANCE = 20.0  
const DASH_DURATION = 0.08  # Time in seconds for dash to complete

# Cartridge abilities (to be enabled/disabled per cartridge)
var can_dash = true
var can_double_jump = false
var has_used_double_jump = false
var has_used_dash = false
var is_dashing = false
var dash_timer = 0.0
var dash_direction = 0  # 1 for right, -1 for left
var parent_rotation: float = 0.0  # Track parent rotation for counter-rotation
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Player setup
	pass

func _physics_process(delta):
	# Handle dash timing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	
	# Apply gravity (skip during dash for flat horizontal movement)
	if not is_on_floor() and not is_dashing:
		velocity.y += GRAVITY * delta
	else:
		# Reset double jump when landing
		has_used_double_jump = false
		# Reset dash when landing
		has_used_dash = false
	
	# Handle jump
	if Input.is_action_just_pressed("up"):
		if is_on_floor():
			jump()
		elif can_double_jump and not has_used_double_jump:
			double_jump()
	
	# Handle dash
	if Input.is_action_just_pressed("dash") and can_dash and not has_used_dash:
		dash()

	# Handle horizontal movement
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		dash_direction = direction  # Update facing direction
		
		if is_on_floor() and not is_dashing:
			if not audio_player.playing:
				audio_player.stream = WALK_SFX
				audio_player.play()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if audio_player.stream == WALK_SFX and audio_player.playing:
			audio_player.stop()
	
	# Override velocity if dashing — flat horizontal, no vertical
	if is_dashing and dash_direction != 0:
		velocity.x = dash_direction * (DASH_DISTANCE / DASH_DURATION)
		velocity.y = 0
	
	move_and_slide()
	check_tile_collisions()
	counter_rotate_sprite()
	update_animation()

func jump():
	audio_player.stop()
	velocity.y = JUMP_VELOCITY
	audio_player.stream = JUMP_SFX
	audio_player.volume_db = -20
	audio_player.play()
	audio_player.volume_db = 0

func double_jump():
	velocity.y = JUMP_VELOCITY
	has_used_double_jump = true
	audio_player.stream = JUMP_SFX
	audio_player.volume_db = -20
	audio_player.play()
	audio_player.volume_db = 0

func dash():
	if dash_direction != 0:  # Only dash if we have a direction
		is_dashing = true
		dash_timer = DASH_DURATION
		has_used_dash = true
		velocity.y = 0  # Zero out vertical so we move flat
		velocity.x = dash_direction * (DASH_DISTANCE / DASH_DURATION)
		audio_player.stream = DASH_SFX
		audio_player.play()

# Called by game_manager when cartridge changes
func set_cartridge_abilities(dash: bool, double_jump: bool):
	can_dash = dash
	can_double_jump = double_jump
	has_used_double_jump = false

# Called by game_manager when TV/gravity rotates
func set_parent_rotation(rotation_rad: float):
	parent_rotation = rotation_rad

# Counter-rotate the entire player so it stays upright
func counter_rotate_sprite():
	self.rotation = -parent_rotation

func check_tile_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if we collided with a TileMapLayer
		if collider is TileMapLayer:
			handle_tile_collision(collider)

func update_animation():
	if not animated_sprite:
		return
	
	# Update sprite direction based on movement
	if dash_direction != 0:
		animated_sprite.flip_h = dash_direction < 0
	
	# Choose animation based on state
	if not is_on_floor():
		# In the air
		if velocity.y < 0:
			# Going up
			animated_sprite.play("jump")
		else:
			# Falling down
			animated_sprite.play("mid_jumping")
	else:
		# On the ground
		if abs(velocity.x) > 5:
			# Moving
			animated_sprite.play("move")
		else:
			# Idle
			animated_sprite.play("default")

func handle_tile_collision(tile_layer: TileMapLayer):
	# Example:
	if tile_layer.name == "Obstacle" or tile_layer.name == "Obstacle2" :
		die()
	pass

func die():
	set_physics_process(false)
	audio_player.stream = DEATH_SFX
	audio_player.play()
	await get_tree().create_timer(.2).timeout
	ScreenTransition.death_transition(func(): LevelProgression.on_lose_condition_met())
