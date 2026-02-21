extends Area2D

@onready var audio_player = $AudioStreamPlayer2D
const Flag_sfx = preload("res://sounds/grab_flag.wav")
signal level_completed

# NEW: Prevent multiple triggers
var is_collecting: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# 1. Immediate exit if we are already in the middle of collecting or it's not the player
	if is_collecting or body.name != "Player":
		return
		
	# Check parent cartridge logic...
	var parent_cartridge = get_parent()
	if not parent_cartridge:
		return
			
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
	
	# 2. LOCK THE GATE: Everything below only runs ONCE
	is_collecting = true
	
	# Emit signal that level is completed
	$AnimatedSprite2D.play("got")
	audio_player.stream = Flag_sfx
	audio_player.play()
	
	# We also disable collision immediately so physics stops checking
	monitoring = false 
	
	await get_tree().create_timer(1).timeout
	level_completed.emit()
	
	# Finish current level and load next logic...
	var current = LevelProgression.get_active_level_index()
	if current >= LevelProgression.level_scenes.size() - 1:
		if LevelProgression.is_challenge_mode():
			var final_time = LevelProgression.finish_challenge_mode()
			ScreenTransition.level_completed_transition(func():
				LevelProgression.set_meta("challenge_final_time", final_time)
				LevelProgression.get_tree().change_scene_to_file("res://scenes/title_screen/username_entry.tscn")
			)
		else:
			print("All levels completed! Returning to main menu...")
			ScreenTransition.level_completed_transition(func(): LevelProgression.go_to_main_menu())
	else:
		print("Loading next level...")
		ScreenTransition.level_completed_transition(func(): LevelProgression.load_level_scene(LevelProgression.get_active_level_index()+1))
	
	queue_free()
