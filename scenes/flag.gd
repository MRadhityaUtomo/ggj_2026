extends Area2D

@onready var audio_player = $AudioStreamPlayer2D
const Flag_sfx = preload("res://sounds/grab_flag.wav")
signal level_completed

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Emit signal that level is completed
		if not audio_player.playing:
			audio_player.stream = Flag_sfx
			audio_player.play()
			await audio_player.finished
		level_completed.emit()
		LevelProgression.finish_level(LevelProgression.get_current_level_index())
		print(LevelProgression.get_current_level_index())
		LevelProgression.load_level_scene(LevelProgression.get_current_level_index())
		# Optional: Play a sound or animation here
		
		queue_free()
