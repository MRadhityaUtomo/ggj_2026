extends Control

const MAIN_SCENE = "res://main_scene_manager.tscn"

func _ready() -> void:
	ResourceLoader.load_threaded_request(MAIN_SCENE)
	set_process(true)

func _process(_delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(MAIN_SCENE)
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var scene = ResourceLoader.load_threaded_get(MAIN_SCENE)
			# Wait a couple frames so your loading animation has time to show
			await get_tree().process_frame
			await get_tree().process_frame
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load main scene manager!")
			set_process(false)
