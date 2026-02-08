extends Node2D

## Main Menu - Cartridge Selection as Level Selector
@export var level_cartridge_configs: Array[LevelCartridgeConfig] = []

## ─── INTERNAL STATE ──────────────────────────────────────────────────────────
var cartridges: Array[Cartridge] = []
var preview_cartridge_index = 0

# Game states
enum MenuState {SELECTION}
var current_state = MenuState.SELECTION

# Camera
var camera: Camera2D
var zoom_tween: Tween

# TV visuals
var tv_container: Node2D
var tv_frame: Sprite2D
var tv_frame_area: Area2D
var tv_rotation: float = 0.0
var rotation_index: int = 0

# Zoom animation settings
const ZOOM_DURATION = 0.3
const ZOOM_TRANS_TYPE = Tween.TRANS_CUBIC
const ZOOM_EASE_TYPE = Tween.EASE_IN_OUT

func _ready():
	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	camera.position_smoothing_enabled = false
	
	# Create TV container
	tv_container = Node2D.new()
	add_child(tv_container)
	tv_container.z_index = 100
	tv_container.position = Vector2(96, 64)
	
	# Add TV frame sprite
	tv_frame = Sprite2D.new()
	tv_frame.texture = preload("res://tv_frame.png")
	tv_frame.centered = true
	tv_frame.position = Vector2.ZERO
	tv_frame.visible = true  # Always visible in menu
	tv_container.add_child(tv_frame)
	
	# Create clickable area for the TV frame
	tv_frame_area = Area2D.new()
	tv_frame.add_child(tv_frame_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(384, 256)
	collision_shape.shape = shape
	tv_frame_area.add_child(collision_shape)
	
	tv_frame_area.input_event.connect(_on_tv_frame_input)
	tv_frame_area.mouse_entered.connect(_on_tv_frame_mouse_entered)
	tv_frame_area.mouse_exited.connect(_on_tv_frame_mouse_exited)
	tv_frame_area.input_pickable = true
	
	# Instantiate level selection cartridges
	for config in level_cartridge_configs:
		if config and config.scene:
			var instance = config.scene.instantiate()
			if not instance is Cartridge:
				instance.set_script(preload("res://cartridge.gd"))
			tv_container.add_child(instance)
			instance.position -= Vector2(96, 64)
			cartridges.append(instance)
	
	# Start zoomed out
	camera.zoom = Vector2(0.5, 0.5)
	camera.position = Vector2(96, 64)
	
	# Show first cartridge
	update_cartridge_preview()

func _process(_delta):
	if Input.is_action_just_pressed("left"):
		cycle_preview(-1)
	elif Input.is_action_just_pressed("right"):
		cycle_preview(1)
	elif Input.is_action_just_pressed("ui_accept"):  # Enter to start level
		start_selected_level()

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
		cartridges[i].set_collision_enabled(false)  # No collision in menu

func start_selected_level():
	if preview_cartridge_index < level_cartridge_configs.size():
		var config = level_cartridge_configs[preview_cartridge_index]
		if config.level_scene_path:
			# Check if level is unlocked
			if config.level_index <= LevelProgression.get_current_level_index():
				get_tree().change_scene_to_file(config.level_scene_path)
			else:
				print("Level locked!")
				# Optional: play locked sound/animation

func rotate_tv_90_degrees():
	rotation_index = (rotation_index + 1) % 4
	tv_rotation = deg_to_rad(rotation_index * 90)
	
	var tween = create_tween()
	tween.tween_property(tv_container, "rotation", tv_rotation, 0.5).set_trans(Tween.TRANS_CUBIC)

func _on_tv_frame_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			rotate_tv_90_degrees()

func _on_tv_frame_mouse_entered():
	if tv_frame:
		tv_frame.modulate = Color(1.2, 1.2, 1.2)

func _on_tv_frame_mouse_exited():
	if tv_frame:
		tv_frame.modulate = Color(1, 1, 1)
