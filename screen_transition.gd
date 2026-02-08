extends CanvasLayer

## Autoload singleton for screen transitions
## - Death: dark fade in, animated ". . ." dots, fade out
## - Win: green-tinted fade in/out
## - M key: return to main menu

var color_rect: ColorRect
var dot_label: Label
var is_transitioning: bool = false

# Transition settings
const FADE_DURATION: float = 0.4
const DOT_DELAY: float = 0.35
const HOLD_DURATION: float = 0.1
const TYPE_SPEED: float = 0.03  # Time per character for typewriter effect

func _ready() -> void:
	layer = 128  # Render above everything
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when tree is paused

	# Full-screen overlay
	color_rect = ColorRect.new()
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	color_rect.size = Vector2(192, 128)
	color_rect.color = Color(0, 0, 0, 0)  # Start fully transparent
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

	# Dot label for death screen
	dot_label = Label.new()
	dot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot_label.anchors_preset = Control.PRESET_FULL_RECT
	dot_label.size = Vector2(192, 128)
	dot_label.text = ""
	dot_label.visible = false
	dot_label.add_theme_color_override("font_color", Color.WHITE)

	# Try to load the project's pixel font
	var font = load("res://assets/boldpixels/BoldsPixels.ttf")
	if font:
		dot_label.add_theme_font_override("font", font)
	dot_label.add_theme_font_size_override("font_size", 16)

	add_child(dot_label)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M or event.physical_keycode == KEY_M:
			transition_to_main_menu()
		elif event.keycode == KEY_R or event.physical_keycode == KEY_R:
			restart_level_transition()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_BACK:       # Select/View → main menu
			transition_to_main_menu()
		elif event.button_index == JOY_BUTTON_START:     # Start/Menu → restart level
			restart_level_transition()

# ─── DEATH TRANSITION ────────────────────────────────────────────────────────

func death_transition(callback: Callable) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input during transition

	# Phase 1: Fade to black
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), FADE_DURATION)
	await fade_in_tween.finished

	# Phase 2: Animated dots ". . ."
	dot_label.visible = true
	dot_label.text = ""
	await get_tree().create_timer(DOT_DELAY).timeout

	dot_label.text = "."
	await get_tree().create_timer(DOT_DELAY).timeout

	dot_label.text = ". ."
	await get_tree().create_timer(DOT_DELAY).timeout

	dot_label.text = ". . ."
	await get_tree().create_timer(DOT_DELAY).timeout

	# Phase 3: Execute the scene change while screen is black
	callback.call()

	# Small hold so the new scene has a frame to load
	await get_tree().create_timer(HOLD_DURATION).timeout

	# Phase 4: Fade out from black
	dot_label.visible = false
	dot_label.text = ""
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), FADE_DURATION)
	await fade_out_tween.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

# ─── WIN TRANSITION ──────────────────────────────────────────────────────────

func win_transition(callback: Callable) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Phase 1: Fade to translucent green
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color", Color(0.1, 0.8, 0.2, 0.6), FADE_DURATION)
	await fade_in_tween.finished

	# Brief hold at green
	await get_tree().create_timer(HOLD_DURATION).timeout

	# Fade to fully opaque green-black for scene switch
	var cover_tween = create_tween()
	cover_tween.tween_property(color_rect, "color", Color(0.05, 0.3, 0.1, 1.0), FADE_DURATION * 0.5)
	await cover_tween.finished

	# Execute scene change while covered
	callback.call()

	await get_tree().create_timer(HOLD_DURATION).timeout

	# Phase 2: Fade out
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), FADE_DURATION)
	await fade_out_tween.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

# ─── LEVEL COMPLETED TRANSITION ──────────────────────────────────────────────

func level_completed_transition(callback: Callable) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Phase 1: Fade to grey
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color", Color(0.111, 0.111, 0.111, 1.0), FADE_DURATION)
	await fade_in_tween.finished

	# Phase 2: Typewriter text "Level Completed?"
	dot_label.visible = true
	dot_label.text = ""
	var complete_text = "Level Completed"
	
	for i in range(complete_text.length()):
		dot_label.text = complete_text.substr(0, i + 1)
		await get_tree().create_timer(TYPE_SPEED).timeout

	# Phase 3: Hold with text visible
	await get_tree().create_timer(HOLD_DURATION * 2).timeout

	# Phase 4: Execute callback while still showing
	callback.call()

	await get_tree().create_timer(HOLD_DURATION).timeout

	# Phase 5: Fade out
	dot_label.visible = false
	dot_label.text = ""
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), FADE_DURATION)
	await fade_out_tween.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

# ─── MAIN MENU TRANSITION ───────────────────────────────────────────────────

func transition_to_main_menu() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Quick dark fade
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), FADE_DURATION)
	await fade_in_tween.finished

	LevelProgression.go_to_main_menu()

	await get_tree().create_timer(HOLD_DURATION).timeout

	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), FADE_DURATION)
	await fade_out_tween.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

# ─── RESTART LEVEL TRANSITION ────────────────────────────────────────────────

func restart_level_transition() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Quick dark fade
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), FADE_DURATION)
	await fade_in_tween.finished

	LevelProgression.on_lose_condition_met()

	await get_tree().create_timer(HOLD_DURATION).timeout

	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), FADE_DURATION)
	await fade_out_tween.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
