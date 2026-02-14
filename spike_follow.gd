extends Sprite2D

## ─── MODE ────────────────────────────────────────────────────────────────────
enum Mode { FOLLOW_PLAYER, FOLLOW_PATH }
@export var mode: Mode = Mode.FOLLOW_PLAYER

## ─── SPEED / ACCELERATION ────────────────────────────────────────────────────
@export var start_speed: float = 120.0        ## Initial movement speed (px/s)
@export var max_speed: float = 240.0          ## Cap speed (px/s)
@export var acceleration: float = 40.0        ## Speed gained per second

## ─── SPIN ────────────────────────────────────────────────────────────────────
@export var spin_speed: float = 360.0        ## Degrees per second

## ─── PATH MODE ───────────────────────────────────────────────────────────────
## Assign waypoints in the editor (local positions relative to parent).
@export var path_points: Array[Vector2] = []
@export var path_loop: bool = true           ## Loop back to first point?
@export var path_stop_at_end: bool = false   ## Stop at last waypoint instead of looping/ping-pong?
var _path_index: int = 0
var _path_forward: bool = true               ## Used for ping-pong when not looping
var _path_reached_end: bool = false          ## Flag for stop-at-end behavior

## ─── INTERNAL ────────────────────────────────────────────────────────────────
var _current_speed: float = 0.0
var _origin_position: Vector2                ## Starting position for resets
var _spike_id: String = ""                   ## Unique identifier for persistence
var _active: bool = false                    ## Only move when parent cartridge is visible
var _static_body: StaticBody2D = null        ## Cached reference for collision toggling

func _ready() -> void:
	_origin_position = position
	_current_speed = start_speed
	_spike_id = _build_spike_id()
	
	# Cache the StaticBody2D child (for enabling/disabling collision)
	for child in get_children():
		if child is StaticBody2D:
			_static_body = child
			break
	
	# Restore position from GameManager if available
	_try_restore_position()
	# Sync collision state on spawn
	_update_collision()

func _process(delta: float) -> void:
	# Only move when the parent cartridge is active AND game is not paused
	_active = _is_cartridge_active() and not _is_game_paused()
	
	# Toggle collision based on whether this cartridge is the active one
	_update_collision()
	
	if not _active:
		return
	
	# ── Accelerate toward max speed ──
	_current_speed = min(_current_speed + acceleration * delta, max_speed)
	
	# ── Spin visual ──
	rotation_degrees += spin_speed * delta
	
	# ── Movement ──
	match mode:
		Mode.FOLLOW_PLAYER:
			_move_toward_player(delta)
		Mode.FOLLOW_PATH:
			_move_along_path(delta)
	
	# ── Persist position in GameManager ──
	_save_position()

# ─── FOLLOW PLAYER ────────────────────────────────────────────────────────────
func _move_toward_player(delta: float) -> void:
	var player_node = _find_player()
	if not player_node:
		return
	
	# Player position in our local coordinate space
	var target = _get_local_target(player_node.global_position)
	var direction = (target - position).normalized()
	var step = direction * _current_speed * delta
	
	# ── Raycast to avoid going through solid tiles ──
	var space_state = get_world_2d().direct_space_state
	if space_state:
		var from = global_position
		var to = from + step.rotated(get_parent().global_rotation if get_parent() else 0.0)
		var query = PhysicsRayQueryParameters2D.create(from, to, 1)  # layer 1 = terrain
		# Exclude our own StaticBody2D so the ray doesn't hit ourselves
		if _static_body:
			query.exclude = [_static_body.get_rid()]
		var result = space_state.intersect_ray(query)
		if result:
			# Wall hit — slide along the wall normal instead of stopping
			var wall_normal = result["normal"]
			var slide = step - wall_normal * step.dot(wall_normal)
			# Verify the slide direction is also clear
			var slide_query = PhysicsRayQueryParameters2D.create(from, from + slide.rotated(get_parent().global_rotation if get_parent() else 0.0), 1)
			if _static_body:
				slide_query.exclude = [_static_body.get_rid()]
			var slide_result = space_state.intersect_ray(slide_query)
			if not slide_result:
				position += slide
			# else: completely blocked, don't move
			return
	
	# No wall in the way — move normally
	position += step

# ─── PATH PATROL ──────────────────────────────────────────────────────────────
func _move_along_path(delta: float) -> void:
	if path_points.is_empty():
		return
	
	# If we've reached the end and stop_at_end is enabled, don't move
	if path_stop_at_end and _path_reached_end:
		return
	
	var target = path_points[_path_index]
	var step = _current_speed * delta
	
	while step > 0.0:
		var to_target = target - position
		var dist = to_target.length()
		
		if dist <= step:
			position = target
			step -= dist
			_advance_path_index()
			target = path_points[_path_index]
		else:
			position += to_target.normalized() * step
			step = 0.0

func _advance_path_index() -> void:
	if path_stop_at_end:
		# Stop at the last point
		if _path_index >= path_points.size() - 1:
			_path_reached_end = true
			_path_index = path_points.size() - 1
		else:
			_path_index += 1
	elif path_loop:
		_path_index = (_path_index + 1) % path_points.size()
	else:
		# Ping-pong (go back and forth)
		if _path_forward:
			_path_index += 1
			if _path_index >= path_points.size():
				_path_index = path_points.size() - 2
				_path_forward = false
		else:
			_path_index -= 1
			if _path_index < 0:
				_path_index = 1
				_path_forward = true

# ─── PERSISTENCE (via GameManager) ────────────────────────────────────────────
func _build_spike_id() -> String:
	# Use the scene file path + node path for a unique key
	var scene_path = ""
	var parent = get_parent()
	if parent and parent.scene_file_path != "":
		scene_path = parent.scene_file_path
	return scene_path + ":" + str(get_path())

func _save_position() -> void:
	var gm = _get_game_manager()
	if gm and gm.has_method("save_spike_state"):
		gm.save_spike_state(_spike_id, position, _current_speed, _path_index, _path_forward, _path_reached_end)

func _try_restore_position() -> void:
	var gm = _get_game_manager()
	if gm and gm.has_method("load_spike_state"):
		var state = gm.load_spike_state(_spike_id)
		if state != null:
			position = state["position"]
			_current_speed = state["speed"]
			_path_index = state["path_index"]
			_path_forward = state["path_forward"]
			_path_reached_end = state.get("path_reached_end", false)

## Reset spike to its original position (called on level restart).
func reset() -> void:
	position = _origin_position
	_current_speed = start_speed
	_path_index = 0
	_path_forward = true
	_path_reached_end = false
	_update_collision()

# ─── HELPERS ──────────────────────────────────────────────────────────────────
func _find_player() -> CharacterBody2D:
	# Walk up to the GameManager (grandparent of cartridge) and grab its player ref
	var gm = _get_game_manager()
	if gm and "player" in gm and gm.player:
		return gm.player
	# Fallback: search tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _get_game_manager():
	# Cartridge → tv_container → GameManager (Node2D with game_manager.gd)
	var node = get_parent()
	while node:
		if node.has_method("save_spike_state"):
			return node
		node = node.get_parent()
	return null

func _is_cartridge_active() -> bool:
	var parent = get_parent()
	return parent and parent.visible

func _is_game_paused() -> bool:
	var gm = _get_game_manager()
	if gm and "current_state" in gm:
		# GameState.PAUSED_SELECTION == 1
		return gm.current_state != 0  # 0 = PLAYING
	return false

## Enable collision only when this cartridge is the active one AND game is playing.
func _update_collision() -> void:
	if not _static_body:
		return
	var should_collide = _is_cartridge_active() and not _is_game_paused()
	_static_body.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT if should_collide else Node.PROCESS_MODE_DISABLED)
	# Also toggle the collision shapes directly for immediate effect
	for child in _static_body.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not should_collide)

func _get_local_target(global_pos: Vector2) -> Vector2:
	# Convert a global position into our parent's local space
	var parent = get_parent()
	if parent:
		return parent.to_local(global_pos)
	return global_pos
