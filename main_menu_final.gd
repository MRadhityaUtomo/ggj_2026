extends Node2D

## ─── INTERNAL STATE ──────────────────────────────────────────────────────────
var current_preview_index = 0

# States
enum MenuState {MENU, SELECTION}
var current_state = MenuState.MENU

# Camera
var camera: Camera2D
var zoom_tween: Tween

# Zoom animation settings
const ZOOM_DURATION = 0.3
const ZOOM_TRANS_TYPE = Tween.TRANS_CUBIC
const ZOOM_EASE_TYPE = Tween.EASE_IN_OUT

# TV container
var tv_container: Node2D
var tv_frame: Sprite2D
var tv_frame_area: Area2D

# Menu display
var menu_scene = preload("res://scenes/cartridge/menu.tscn")
var menu_instance: Node2D

# Level preview images
var level_preview_textures: Array[Texture2D] = []
var level_preview_sprite: Sprite2D

func _ready():
	# Load level preview textures
	load_level_previews()
	
	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	camera.position_smoothing_enabled = false
	camera.position = Vector2(96, 64)
	
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
	tv_frame.visible = false
	tv_container.add_child(tv_frame)
	
	# Create clickable area for the TV frame
	tv_frame_area = Area2D.new()
	tv_frame.add_child(tv_frame_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(384, 256)
	collision_shape.shape = shape
	tv_frame_area.add_child(collision_shape)
	tv_frame_area.input_pickable = true
	
	# Instantiate menu scene
	menu_instance = menu_scene.instantiate()
	tv_container.add_child(menu_instance)
	menu_instance.position = -Vector2(96, 64)
	
	# Create level preview sprite (hidden by default)
	level_preview_sprite = Sprite2D.new()
	level_preview_sprite.centered = true
	level_preview_sprite.position = Vector2.ZERO
	level_preview_sprite.visible = false
	# Scale down the preview to fit the TV screen (192x128)
	level_preview_sprite.scale = Vector2(0.15, 0.15)
	tv_container.add_child(level_preview_sprite)
	
	# Create level label to show current selection
	create_level_indicator()
	
	# Start in menu view
	set_menu_view()

func load_level_previews():
	# Load all level preview images
	for i in range(1, 7):  # level1.png to level6.png
		var path = "res://assets/levels_preview/level%d.png" % i
		if ResourceLoader.exists(path):
			var texture = load(path)
			level_preview_textures.append(texture)
		else:
			push_warning("Level preview not found: %s" % path)

func _process(_delta):
	match current_state:
		MenuState.MENU:
			if Input.is_action_just_pressed("ui_cancel"):
				enter_selection_mode()
			if Input.is_action_just_pressed("ui_accept"):
				# Direct start - go to first level
				start_level(0)
		
		MenuState.SELECTION:
			if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("cycle_left"):
				cycle_preview(-1)
			elif Input.is_action_just_pressed("right") or Input.is_action_just_pressed("cycle_right"):
				cycle_preview(1)
			elif Input.is_action_just_pressed("ui_accept"):
				start_level(current_preview_index)
			elif Input.is_action_just_pressed("ui_cancel"):
				exit_selection_mode()

func create_level_indicator():
	# Create a simple label to show which level is selected
	var label = Label.new()
	label.name = "LevelIndicator"
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(96 - 50, 140)  # Below the TV
	label.size = Vector2(100, 30)
	label.visible = false
	add_child(label)

func set_menu_view():
	current_state = MenuState.MENU
	animate_camera_zoom(Vector2(1.0, 1.0))
	tv_frame.visible = false
	
	# Show menu, hide preview
	menu_instance.visible = true
	level_preview_sprite.visible = false
	
	var label = get_node_or_null("LevelIndicator")
	if label:
		label.visible = false

func enter_selection_mode():
	current_state = MenuState.SELECTION
	animate_camera_zoom(Vector2(0.5, 0.5))
	tv_frame.visible = true
	
	# Hide menu, show preview
	menu_instance.visible = false
	level_preview_sprite.visible = true
	
	update_level_preview()

func exit_selection_mode():
	set_menu_view()

func animate_camera_zoom(target_zoom: Vector2):
	if zoom_tween:
		zoom_tween.kill()
	
	zoom_tween = create_tween()
	zoom_tween.set_trans(ZOOM_TRANS_TYPE)
	zoom_tween.set_ease(ZOOM_EASE_TYPE)
	zoom_tween.tween_property(camera, "zoom", target_zoom, ZOOM_DURATION)

func cycle_preview(direction: int):
	if LevelProgression.level_scenes.size() == 0:
		return
	
	current_preview_index = (current_preview_index + direction) % LevelProgression.level_scenes.size()
	if current_preview_index < 0:
		current_preview_index = LevelProgression.level_scenes.size() - 1
	
	update_level_preview()

func update_level_preview():
	# Update preview image
	if current_preview_index < level_preview_textures.size():
		level_preview_sprite.texture = level_preview_textures[current_preview_index]
	
	# Update label
	var label = get_node_or_null("LevelIndicator")
	if label:
		label.visible = true
		label.text = "Level %d" % (current_preview_index + 1)

func start_level(index: int):
	if index >= 0 and index < LevelProgression.level_scenes.size():
		# Use the main scene manager directly
		var main_manager = get_tree().root.get_node_or_null("MainSceneManager")
		if main_manager and main_manager.has_method("change_level"):
			main_manager.change_level(index)
		else:
			push_error("MainSceneManager not found! Cannot load level.")
	else:
		push_error("MainMenu: Invalid level index: %d" % index)
