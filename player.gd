extends CharacterBody2D

# Movement parameters
const SPEED = 80.0
const JUMP_VELOCITY = -200.0  # Adjusted for 2-tile jump height
const GRAVITY = 580.0

# Cartridge abilities (to be enabled/disabled per cartridge)
var can_dash = false
var can_double_jump = false
var has_used_double_jump = false

func _ready():
	# Player setup
	pass

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		# Reset double jump when landing
		has_used_double_jump = false
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			jump()
		elif can_double_jump and not has_used_double_jump:
			double_jump()
	
	# Handle horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# TODO: Add dash ability here when needed
	# if Input.is_action_just_pressed("ui_dash") and can_dash:
	#     dash()
	
	move_and_slide()

func jump():
	velocity.y = JUMP_VELOCITY

func double_jump():
	velocity.y = JUMP_VELOCITY
	has_used_double_jump = true

func dash():
	# Placeholder for dash ability
	pass

# Called by game_manager when cartridge changes
func set_cartridge_abilities(dash: bool, double_jump: bool):
	can_dash = dash
	can_double_jump = double_jump
	has_used_double_jump = false
