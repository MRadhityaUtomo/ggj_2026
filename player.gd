extends CharacterBody2D

@onready var audio_player = $AudioStreamPlayer2D

const WALK_SFX = preload("res://sounds/walk_sfx.wav")
const JUMP_SFX = preload("res://sounds/error Sfx.wav")#Will Change
const DASH_SFX = preload("res://sounds/temp_dash.wav")
const DEATH_SFX = preload("res://sounds/death_sfx.wav")

# Movement parameters
const SPEED = 180.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 1160.0
const MAX_FALL_SPEED = 600.0
const JUMP_CUT_MULTIPLIER = 0.5 

# Coyote time (grace period after leaving ground)
const COYOTE_TIME = 0.1
var coyote_timer = 0.0

# Jump buffer (press jump slightly before landing)
const JUMP_BUFFER_TIME = 0.1
var jump_buffer_timer = 0.0

# Dash parameters (Celeste-style)
const DASH_SPEED = 480.0
const DASH_DURATION = 0.15
const DASH_END_SPEED = 80.0  # Speed retained after dash ends
const DASH_COOLDOWN = 0.2
var dash_cooldown_timer = 0.0

# Cartridge abilities
var can_dash = true
var can_double_jump = false
var has_used_double_jump = false
var is_dashing = false
var dash_timer = 0.0
var dash_direction = 0  # 1 for right, -1 for left
var parent_rotation: float = 0.0  # Track parent rotation for counter-rotation
var is_dying: bool = false  # Guard against multiple die() calls
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	pass

func _physics_process(delta):
	# Update timers
	dash_cooldown_timer = max(0, dash_cooldown_timer - delta)
	jump_buffer_timer = max(0, jump_buffer_timer - delta)
	
	# Coyote time: grace period after leaving ground
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		has_used_double_jump = false
	else:
		coyote_timer = max(0, coyote_timer - delta)
	
	# Handle dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
		else:
			# During dash, maintain constant velocity
			velocity = dash_direction * DASH_SPEED
			move_and_slide()
			update_animation()
			return  # Skip normal movement during dash
	
	# Apply gravity
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		
		# Jump cut: release jump early for variable height
		if velocity.y < 0 and not Input.is_action_pressed("up"):
			velocity.y *= JUMP_CUT_MULTIPLIER
	
	# Jump buffering: remember jump input slightly before landing
	if Input.is_action_just_pressed("up"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	# Handle jump with coyote time and buffering
	if jump_buffer_timer > 0:
		if coyote_timer > 0:
			jump()
			jump_buffer_timer = 0
			coyote_timer = 0
		elif can_double_jump and not has_used_double_jump and not is_on_floor():
			double_jump()
			jump_buffer_timer = 0
	
	# Handle dash input
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer == 0:
		start_dash()
	
	# Horizontal movement (instant speed, no acceleration)
	var input_direction = Input.get_axis("left", "right")
	
	if input_direction != 0:
		velocity.x = input_direction * SPEED
		
		# Update facing direction
		if input_direction > 0:
			dash_direction = Vector2.RIGHT
		elif input_direction < 0:
			dash_direction = Vector2.LEFT
	else:
		velocity.x = 0
	
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

func start_dash():
	# Get dash direction from input or last facing direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir.length() > 0:
		dash_direction = input_dir.normalized()
	elif dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT  # Default right if no direction
	
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	
	# Freeze gravity during dash
	velocity = dash_direction * DASH_SPEED

func end_dash():
	is_dashing = false
	
	# Retain some momentum after dash (Celeste-style)
	velocity = dash_direction * DASH_END_SPEED
	
	# If dashing upward, give slight upward boost
	if dash_direction.y < 0:
		velocity.y = min(velocity.y, -DASH_END_SPEED * 0.5)

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
		if is_dying:
			return
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMapLayer:
			handle_tile_collision(collider)
		elif collider is StaticBody2D:
			handle_active_collision(collider)

func update_animation():
	if not animated_sprite:
		return
	
	# Update sprite direction based on movement
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
	
	# Choose animation based on state
	if is_dashing:
		animated_sprite.play("dash")  # Add a dash animation if you have one
	elif not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("mid_jumping")
	else:
		if abs(velocity.x) > 5:
			animated_sprite.play("move")
		else:
			animated_sprite.play("default")

func handle_tile_collision(tile_layer: TileMapLayer):
	# Example:
	if tile_layer.name == "Obstacle" or tile_layer.name == "Obstacle2" or tile_layer.name == "Spikes":
		die()
	pass
func handle_active_collision(enemy_instance: Node):
	# Example:
	if enemy_instance.name == "MovingSpike":
		die()
	pass

func die():
	if is_dying:
		return
	is_dying = true
	set_physics_process(false)
	audio_player.stream = DEATH_SFX
	audio_player.play()
	await get_tree().create_timer(.2).timeout
	# Use a direct Callable instead of a lambda to avoid capturing freed 'self'
	ScreenTransition.death_transition(LevelProgression.on_lose_condition_met)
