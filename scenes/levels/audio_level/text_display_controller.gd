extends Node2D

@onready var voice_manager: Node = $VoiceManager
@onready var alphabets_tile: TileMapLayer = $Alphabets
@onready var mic_ui: Node2D = get_node("../MicUI") if has_node("../MicUI") else null
@onready var mic_level_bar: ColorRect = get_node("../MicUI/MicLevelBar") if has_node("../MicUI/MicLevelBar") else null

var text_from: Vector2
var text_to: Vector2
var is_active: bool = false
var record_bus_index: int = -1
var buffered_text: String = ""  # Buffer untuk text yang belum di-render

const MIC_BAR_TOP_FULL: float = 21.0  # Top position when at full volume
const MIC_BAR_BOTTOM: float = 27.0  # Bottom position (fixed)
const MIC_BAR_MAX_HEIGHT: float = 6.0  # Max height (27 - 21 = 6)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make this node always process to check visibility
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if voice_manager:
		voice_manager.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not alphabets_tile:
		push_error("Alphabets TileMapLayer not found!")
		return
	
	if not voice_manager:
		push_error("VoiceManager not found!")
		return
	
	# Get the Record bus index for audio level monitoring
	record_bus_index = AudioServer.get_bus_index("Record")
	
	# Initially hide MicUI (will be shown when cartridge becomes active)
	if mic_ui:
		mic_ui.visible = false
	
	#_generate_text("test")
	
	if voice_manager.has_signal("command_detected"):
		voice_manager.connect("command_detected", _on_command_detected)
	else:
		push_warning("VoiceManager does not have 'command_detected' signal")

func _process(_delta: float) -> void:
	# Check if parent cartridge is visible AND has collision enabled (means it's active, not in preview)
	var parent_cartridge = get_parent()
	if not parent_cartridge:
		return
	
	# Check if any TileMapLayer in the cartridge has collision enabled
	var has_collision = false
	for child in parent_cartridge.get_children():
		if child is TileMapLayer and child.collision_enabled:
			has_collision = true
			break
	
	var should_be_active = parent_cartridge.visible and has_collision
	
	if should_be_active != is_active:
		var was_inactive = not is_active
		is_active = should_be_active
		
		# Toggle MicUI visibility
		if mic_ui:
			mic_ui.visible = is_active
		
		# Initialize VoiceManager saat cartridge pertama kali aktif
		if is_active and was_inactive:
			if voice_manager and voice_manager.has_method("initialize"):
				voice_manager.initialize()
			
			# Render buffered text jika ada
			if buffered_text != "":
				_generate_text(buffered_text)
	
	# Update mic level bar
	if mic_level_bar and is_active and record_bus_index >= 0:
		var volume_db = AudioServer.get_bus_peak_volume_left_db(record_bus_index, 0)
		# Normalize and clamp (dB usually ranges from -60 to 0)
		var normalized = clamp((volume_db + 60.0) / 60.0, 0.0, 1.0)
		
		# Calculate the target height
		var target_height = normalized * MIC_BAR_MAX_HEIGHT
		var current_height = mic_level_bar.size.y
		var smooth_height = lerp(current_height, target_height, 0.3)
		
		# Update the bar to grow from bottom to top
		mic_level_bar.offset_top = MIC_BAR_BOTTOM - smooth_height
		mic_level_bar.offset_bottom = MIC_BAR_BOTTOM

func _on_command_detected(text: String) -> void:
	# Selalu simpan ke buffer
	buffered_text = text
	
	# Render langsung jika cartridge sedang aktif
	if is_active:
		_generate_text(text)

func _generate_text(text : String) -> void:
	# from (1, 5) to (10, 5)
	var n = min(text.length(), 10) 
	for i in range(10):
		alphabets_tile.set_cell(Vector2(1+i, 5), -1)
	for i in range(n):
		var c = text[i]
		if c not in "abcdefghijklmnopqrstuvwxyz":
			continue
		var target = _char_to_tile_asset(c)
		alphabets_tile.set_cell(Vector2(1+i, 5), 0, target)
	
func _char_to_tile_asset(char: String) -> Vector2:
	var num = char.unicode_at(0) - "a".unicode_at(0)
	var x = num % 6
	var y = int(num / 6)
	#print(num)
	#print("x: ", x)
	#print("y: ", y)
	return Vector2(x, y)
