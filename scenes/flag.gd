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
			var has_collision = false
			for child in parent_cartridge.get_children():
				if child is TileMapLayer and child.collision_enabled:
					has_collision = true
					break
			is_active = is_active and has_collision
		
		if not is_active:
			return
		
		# Emit signal that level is completed
		audio_player.stream = Flag_sfx
		audio_player.play()
		await get_tree().create_timer(.2).timeout
		level_completed.emit()
		
		# Finish current level and load next
		var current = LevelProgression.get_active_level_index()
		LevelProgression.finish_level(current)
		print("Completed level %d, loading next..." % current)
		ScreenTransition.level_completed_transition(func(): LevelProgression.load_level_scene(LevelProgression.get_active_level_index()))
		
		queue_free()
