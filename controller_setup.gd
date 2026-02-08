extends Node

## Autoload that adds Xbox controller bindings to existing input actions.
## Add this as an autoload named "ControllerSetup" in Project Settings.

func _ready() -> void:
	# Movement: Left stick + D-pad
	_add_joy_binding("left", JOY_AXIS_LEFT_X, -1.0)        # Left stick left
	_add_joy_binding("right", JOY_AXIS_LEFT_X, 1.0)         # Left stick right
	_add_joy_button("left", JOY_BUTTON_DPAD_LEFT)            # D-pad left
	_add_joy_button("right", JOY_BUTTON_DPAD_RIGHT)          # D-pad right
	_add_joy_button("up", JOY_BUTTON_DPAD_UP)                # D-pad up
	_add_joy_button("down", JOY_BUTTON_DPAD_DOWN)            # D-pad down

	# A button → Jump (player.gd uses "up" for jump)
	_add_joy_button("up", JOY_BUTTON_A)                      # A to jump
	_add_joy_button("ui_accept", JOY_BUTTON_A)               # A to confirm in menus

	# B button → Dash
	_add_joy_button("dash", JOY_BUTTON_B)                    # B to dash

	# Y button → Open / confirm cartridge screen
	_add_joy_button("exit", JOY_BUTTON_Y)                    # Y (triangle) to open cartridge screen

	# Cycle cartridges: LB / RB
	_ensure_action("cycle_left")
	_ensure_action("cycle_right")
	_add_joy_button("cycle_left", JOY_BUTTON_LEFT_SHOULDER)   # LB
	_add_joy_button("cycle_right", JOY_BUTTON_RIGHT_SHOULDER) # RB

	# Spin level: LT / RT
	_ensure_action("rotate_left")
	_ensure_action("rotate_right")
	_add_joy_axis_button("rotate_left", JOY_AXIS_TRIGGER_LEFT, 0.5)    # LT
	_add_joy_axis_button("rotate_right", JOY_AXIS_TRIGGER_RIGHT, 0.5)  # RT

func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

func _add_joy_button(action: String, button: JoyButton) -> void:
	var event = InputEventJoypadButton.new()
	event.button_index = button
	if InputMap.has_action(action):
		InputMap.action_add_event(action, event)

func _add_joy_binding(action: String, axis: JoyAxis, axis_value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	if InputMap.has_action(action):
		InputMap.action_add_event(action, event)

func _add_joy_axis_button(action: String, axis: JoyAxis, deadzone: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = 1.0
	if InputMap.has_action(action):
		InputMap.action_add_event(action, event)
