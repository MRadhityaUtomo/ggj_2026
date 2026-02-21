extends Control

@onready var time_label: Label = $TopBar/TimeLabel if has_node("TopBar/TimeLabel") else null
@onready var custom_container: Control = %CustomElements

var game_time: float = 0.0

# Decor slide system
var _decor_sprites: Array[Control] = []
var _decor_home_positions: Dictionary = {}
var _decor_home_rotations: Dictionary = {}
var _decor_shown: bool = false
var _decor_tween: Tween = null
var _game_node: Node = null

const SLIDE_DURATION: float = 0.3
const SLIDE_STAGGER: float = 0.03

var _active_tweens: Array[Tween] = []
var _find_attempts: int = 0
const MAX_FIND_ATTEMPTS: int = 120  # Stop searching after ~2 seconds

func _ready():
	_collect_decor_sprites()
	_place_all_offscreen()
	call_deferred("_find_game_node")

func _process(delta: float):
	game_time += delta
	update_time_display()
	
	if not _game_node:
		if _find_attempts < MAX_FIND_ATTEMPTS:
			_try_find_game_node()
			_find_attempts += 1
	else:
		_check_zoom_state()
	
	if _decor_shown:
		for sprite in _decor_sprites:
			if sprite.has_meta("spin_speed"):
				var speed = sprite.get_meta("spin_speed")
				sprite.rotation += deg_to_rad(speed) * delta

func update_time_display():
	if not time_label:
		return
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60

func add_custom_element(element: Control):
	custom_container.add_child(element)

func clear_custom_elements():
	for child in custom_container.get_children():
		child.queue_free()

# ─── GAME NODE DETECTION ─────────────────────────────────────────────────────

func _find_game_node():
	_try_find_game_node()

func _try_find_game_node():
	var node = self
	while node:
		node = node.get_parent()
		if node and node.name == "viewport_wrapper":
			var sub_viewport = node.get_node_or_null("SubViewportContainer/SubViewport")
			if sub_viewport:
				for child in sub_viewport.get_children():
					if child is CanvasLayer:
						continue
					if "current_state" in child:
						_game_node = child
						return
					for grandchild in child.get_children():
						if "current_state" in grandchild:
							_game_node = grandchild
							return
			return

func _check_zoom_state():
	if not _game_node:
		return
	var is_zoomed_out = (_game_node.current_state == 1)
	if is_zoomed_out and not _decor_shown:
		show_decor()
	elif not is_zoomed_out and _decor_shown:
		hide_decor()

# ─── DECOR SLIDE SYSTEM ──────────────────────────────────────────────────────

func _collect_decor_sprites():
	_decor_sprites.clear()
	_decor_home_positions.clear()
	_decor_home_rotations.clear()
	for child in get_children():
		if child is Control and child.has_meta("slide_from"):
			_decor_sprites.append(child)
			_decor_home_positions[child] = child.position
			_decor_home_rotations[child] = child.rotation

func show_decor(duration: float = SLIDE_DURATION):
	if _decor_shown:
		return
	_decor_shown = true
	
	_kill_all_tweens()
	
	for i in range(_decor_sprites.size()):
		var sprite = _decor_sprites[i]
		var home_pos = _decor_home_positions[sprite]
		var home_rot = _decor_home_rotations[sprite]
		var from_pos = _get_offscreen_position(sprite, home_pos)
		sprite.position = from_pos
		sprite.modulate.a = 0.0
		sprite.rotation = home_rot
		sprite.visible = true
		
		var t = create_tween()
		_active_tweens.append(t)
		t.set_parallel(true)
		t.tween_property(sprite, "position", home_pos, duration) \
			.from(from_pos) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT) \
			.set_delay(i * SLIDE_STAGGER)
		t.tween_property(sprite, "modulate:a", 1.0, duration * 0.4) \
			.from(0.0) \
			.set_delay(i * SLIDE_STAGGER)

func hide_decor(duration: float = SLIDE_DURATION * 0.5):
	if not _decor_shown:
		return
	_decor_shown = false
	
	_kill_all_tweens()
	
	for i in range(_decor_sprites.size()):
		var sprite = _decor_sprites[i]
		var home_pos = _decor_home_positions[sprite]
		var off_pos = _get_offscreen_position(sprite, home_pos)
		
		var t = create_tween()
		_active_tweens.append(t)
		t.set_parallel(true)
		t.tween_property(sprite, "position", off_pos, duration) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_IN) \
			.set_delay(i * SLIDE_STAGGER)
		t.tween_property(sprite, "modulate:a", 0.0, duration * 0.4) \
			.set_delay(i * SLIDE_STAGGER)

func _kill_all_tweens():
	for t in _active_tweens:
		if t and t.is_valid():
			t.kill()
	_active_tweens.clear()

func _place_all_offscreen():
	for sprite in _decor_sprites:
		var home_pos = _decor_home_positions[sprite]
		sprite.position = _get_offscreen_position(sprite, home_pos)
		sprite.modulate.a = 0.0

func _get_offscreen_position(sprite: Control, home_pos: Vector2) -> Vector2:
	var screen_size = Vector2(DisplayServer.window_get_size())
	var sprite_size = sprite.size if sprite.size != Vector2.ZERO else Vector2(300, 340)
	var slide_dir = sprite.get_meta("slide_from", "left")
	
	match slide_dir:
		"left":
			return Vector2(-sprite_size.x - 50, home_pos.y)
		"right":
			return Vector2(screen_size.x + 50, home_pos.y)
		"top":
			return Vector2(home_pos.x, -sprite_size.y - 50)
		"bottom":
			return Vector2(home_pos.x, screen_size.y + 50)
		"top_left":
			return Vector2(-sprite_size.x - 50, -sprite_size.y - 50)
		"top_right":
			return Vector2(screen_size.x + 50, -sprite_size.y - 50)
		"bottom_left":
			return Vector2(-sprite_size.x - 50, screen_size.y + 50)
		"bottom_right":
			return Vector2(screen_size.x + 50, screen_size.y + 50)
		_:
			return Vector2(-sprite_size.x - 50, home_pos.y)
