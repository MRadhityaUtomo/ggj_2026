extends Area2D

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
		level_completed.emit()
		LevelProgression.finish_level(LevelProgression.get_current_level_index())
		print(LevelProgression.get_current_level_index())
		LevelProgression.load_level_scene(LevelProgression.get_current_level_index())
		# Optional: Play a sound or animation here
		queue_free()
