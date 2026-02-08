extends Control

# ─── WAVE ANIMATION SETTINGS ──────────────────────────────────────────────────
const WAVE_SPEED: float = 3.0        # How fast the wave oscillates
const WAVE_AMPLITUDE: float = 2.0    # Pixels of vertical sway
const WAVE_PHASE_OFFSET: float = 0.6 # Phase shift between each button

var wave_time: float = 0.0

# ─── TITLE MODE ────────────────────────────────────────────────────────────────
## Toggle in the Inspector: false = text label, true = sprite image
@export var use_sprite_title: bool = false

# ─── NODE REFERENCES ──────────────────────────────────────────────────────────
@onready var title_label: Label = $TitleLabel
@onready var title_sprite: TextureRect = $TitleSprite
@onready var start_button: Button = $StartButton
@onready var tutorial_button: Button = $TutorialButton
@onready var credits_button: Button = $CreditsButton
@onready var cartridge_container: HBoxContainer = $CartridgeContainer

var buttons: Array = []
var button_base_y: Array = []

func _ready() -> void:
	# Title display mode
	title_label.visible = not use_sprite_title
	title_sprite.visible = use_sprite_title

	# Store button references and their resting Y positions for wave anim
	buttons = [start_button, tutorial_button, credits_button]
	for btn in buttons:
		button_base_y.append(btn.position.y)

	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	credits_button.pressed.connect(_on_credits_pressed)

	# Setup cartridge visuals & click handling
	_setup_cartridges()

func _process(delta: float) -> void:
	# Gentle wave animation on menu buttons
	wave_time += delta
	for i in buttons.size():
		var offset = sin(wave_time * WAVE_SPEED + i * WAVE_PHASE_OFFSET) * WAVE_AMPLITUDE
		buttons[i].position.y = button_base_y[i] + offset

# ─── CARTRIDGE LOGIC ──────────────────────────────────────────────────────────

func _setup_cartridges() -> void:
	var slots = cartridge_container.get_children()
	for i in slots.size():
		var slot = slots[i]
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_cartridge_input.bind(i))

		if _is_cartridge_unlocked(i):
			slot.modulate = Color.WHITE
		else:
			slot.modulate = Color(0.15, 0.15, 0.15, 0.7)

func _is_cartridge_unlocked(index: int) -> bool:
	# First cartridge is always available; others unlock when the previous level is beaten
	if index == 0:
		return true
	return LevelProgression.level_flags[index - 1]

func _on_cartridge_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_cartridge_unlocked(index):
			LevelProgression.load_level_scene(index)

# ─── BUTTON CALLBACKS ─────────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	var idx = LevelProgression.get_current_level_index()
	LevelProgression.load_level_scene(idx)

func _on_tutorial_pressed() -> void:
	# TODO: replace with your tutorial scene path
	print("Tutorial pressed")

func _on_credits_pressed() -> void:
	# TODO: replace with your credits scene path
	print("Credits pressed")

# ─── TITLE HELPERS (call at runtime to swap) ──────────────────────────────────

func set_title_text_mode() -> void:
	title_label.visible = true
	title_sprite.visible = false

func set_title_sprite_mode() -> void:
	title_label.visible = false
	title_sprite.visible = true
