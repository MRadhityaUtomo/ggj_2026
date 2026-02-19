extends Control

## Container for decorative UI sprites that slide in from edges.
## Add TextureRect children in the editor, position them at their "home" (visible) spot.
## They'll start off-screen and slide in when show_decor() is called.
##
## To control slide direction per-sprite, set metadata "slide_from" to
## "left", "right", "top", or "bottom". Otherwise it auto-detects the nearest edge.

## Container for decorative UI sprites that slide in/out of the screen.
## Add children (TextureRect, Sprite2D via Node2D, etc.) and tag them
## with the DecorSprite script or metadata to control slide behavior.
##
## HOW TO USE:
## 1. Add TextureRect children to this node in the editor
## 2. Attach decor_sprite.gd to each one (or just add them — defaults work)
## 3. Position them where you want them to END UP (their "home" position)
## 4. Call show_decor() / hide_decor() from game_manager or viewport_wrapper

@export var stagger_delay: float = 0.06
@export var default_slide_duration: float = 0.45
@export var default_ease: Tween.EaseType = Tween.EASE_OUT
@export var default_trans: Tween.TransitionType = Tween.TRANS_BACK

var _sprites: Array[Control] = []
var _home_positions: Dictionary = {}
var _is_shown: bool = false
var _current_tween: Tween = null

func _ready():
	_collect_sprites()
	print("DecorContainer ready, found ", _sprites.size(), " sprites")
	# Start off-screen
	_place_all_offscreen()

func _collect_sprites():
	_sprites.clear()
	_home_positions.clear()
	for child in get_children():
		if child is Control:
			_sprites.append(child)
			_home_positions[child] = child.position

func show_decor(duration_override: float = -1.0):
	print("show_decor called, _is_shown=", _is_shown, ", sprites=", _sprites.size())
	if _is_shown:
		return
	_is_shown = true
	
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	
	var dur = duration_override if duration_override > 0 else default_slide_duration
	_current_tween = create_tween()
	_current_tween.set_parallel(false)
	
	for i in range(_sprites.size()):
		var sprite = _sprites[i]
		var home_pos = _home_positions[sprite]
		sprite.visible = true
		
		var from_pos = _get_offscreen_position(sprite, home_pos)
		sprite.position = from_pos
		sprite.modulate.a = 0.0
		
		if i > 0:
			_current_tween.tween_interval(stagger_delay)
		
		_current_tween.set_parallel(true)
		_current_tween.tween_property(sprite, "position", home_pos, dur) \
			.from(from_pos) \
			.set_trans(default_trans) \
			.set_ease(default_ease)
		_current_tween.tween_property(sprite, "modulate:a", 1.0, dur * 0.5) \
			.from(0.0)
		_current_tween.set_parallel(false)

func hide_decor(duration_override: float = -1.0):
	if not _is_shown:
		return
	_is_shown = false
	
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	
	var dur = duration_override if duration_override > 0 else default_slide_duration * 0.6
	_current_tween = create_tween()
	_current_tween.set_parallel(false)
	
	for i in range(_sprites.size() - 1, -1, -1):
		var sprite = _sprites[i]
		var home_pos = _home_positions[sprite]
		var off_pos = _get_offscreen_position(sprite, home_pos)
		
		if i < _sprites.size() - 1:
			_current_tween.tween_interval(stagger_delay * 0.4)
		
		_current_tween.set_parallel(true)
		_current_tween.tween_property(sprite, "position", off_pos, dur) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_IN)
		_current_tween.tween_property(sprite, "modulate:a", 0.0, dur * 0.6)
		_current_tween.set_parallel(false)

func _place_all_offscreen():
	for sprite in _sprites:
		var home_pos = _home_positions[sprite]
		sprite.position = _get_offscreen_position(sprite, home_pos)
		sprite.modulate.a = 0.0

func _get_offscreen_position(sprite: Control, home_pos: Vector2) -> Vector2:
	var screen_size = get_viewport_rect().size
	var sprite_size = sprite.size if sprite.size != Vector2.ZERO else Vector2(200, 200)
	
	# Check for explicit direction metadata
	var slide_dir = ""
	if sprite.has_meta("slide_from"):
		slide_dir = sprite.get_meta("slide_from")
	
	if slide_dir == "":
		var center = home_pos + sprite_size * 0.5
		var dist_left = center.x
		var dist_right = screen_size.x - center.x
		var dist_top = center.y
		var dist_bottom = screen_size.y - center.y
		var min_dist = min(dist_left, dist_right, dist_top, dist_bottom)
		
		if min_dist == dist_left:
			slide_dir = "left"
		elif min_dist == dist_right:
			slide_dir = "right"
		elif min_dist == dist_top:
			slide_dir = "top"
		else:
			slide_dir = "bottom"
	
	# Push fully off-screen from that edge
	match slide_dir:
		"left":
			return Vector2(-sprite_size.x - 50, home_pos.y)
		"right":
			return Vector2(screen_size.x + 50, home_pos.y)
		"top":
			return Vector2(home_pos.x, -sprite_size.y - 50)
		"bottom":
			return Vector2(home_pos.x, screen_size.y + 50)
		_:
			return Vector2(-sprite_size.x - 50, home_pos.y)

func refresh():
	_collect_sprites()
	if not _is_shown:
		_place_all_offscreen()

func is_shown() -> bool:
	return _is_shown
