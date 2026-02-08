extends Area2D

@onready var audio_player = $AudioStreamPlayer2D
const Flag_sfx = preload("res://sounds/grab_flag.wav")
signal level_completed

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Check if parent cartridge is active before triggering completion
		var parent_cartridge = get_parent()
		if not parent_cartridge:
			return
			
		# Check if the cartridge is visible and has collision enabled (active)
		var is_active = parent_cartridge.visible
		if parent_cartridge is Cartridge:
			# Double-check by looking for enabled collision in TileMapLayers
			var has_collision = false
			for child in parent_cartridge.get_children():
				if child is TileMapLayer and child.collision_enabled:
					has_collision = true
					break
			is_active = is_active and has_collision
		
		# Only trigger level completion if cartridge is active
		if not is_active:
			return
		
		# Emit signal that level is completed
		if not audio_player.playing:
			audio_player.stream = Flag_sfx
			audio_player.play()
			await get_tree().create_timer(.2).timeout
		level_completed.emit()
		LevelProgression.finish_level(LevelProgression.get_current_level_index())
		print(LevelProgression.get_current_level_index())
		ScreenTransition.level_completed_transition(func(): LevelProgression.load_level_scene(LevelProgression.get_current_level_index()))
		
		queue_free()
