extends Control

## Leaderboard Screen - Shows challenge mode scores
## 1st place bigger, 2nd smaller, 3rd even smaller, rest in a scrollable list

@onready var podium_container: VBoxContainer = $VBoxContainer/PodiumContainer
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var scroll_list: VBoxContainer = $VBoxContainer/ScrollContainer/ScrollList
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var no_entries_label: Label = $VBoxContainer/NoEntriesLabel

var font: Font = null

func _ready():
	font = load("res://assets/boldpixels/BoldsPixels.ttf")
	back_button.pressed.connect(_on_back_pressed)
	_populate_leaderboard()

func _populate_leaderboard():
	var entries = Leaderboard.get_entries()
	
	if entries.is_empty():
		no_entries_label.visible = true
		podium_container.visible = false
		scroll_container.visible = false
		return
	
	no_entries_label.visible = false
	
	# Podium entries (top 3)
	for i in range(min(3, entries.size())):
		var entry = entries[i]
		var label = _create_entry_label(i + 1, entry["username"], entry["time"])
		podium_container.add_child(label)
	
	# Remaining entries in scrollable list
	if entries.size() > 3:
		scroll_container.visible = true
		for i in range(3, entries.size()):
			var entry = entries[i]
			var label = _create_entry_label(i + 1, entry["username"], entry["time"])
			scroll_list.add_child(label)
	else:
		scroll_container.visible = false

func _create_entry_label(rank: int, username: String, time: float) -> Label:
	var label = Label.new()
	var time_str = Leaderboard.format_time(time)
	label.text = "#%d  %s  -  %s" % [rank, username, time_str]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if font:
		label.add_theme_font_override("font", font)
	
	# Size based on rank
	match rank:
		1:
			label.add_theme_font_size_override("font_size", 36)
			label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold
		2:
			label.add_theme_font_size_override("font_size", 28)
			label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))  # Silver
		3:
			label.add_theme_font_size_override("font_size", 24)
			label.add_theme_color_override("font_color", Color(0.80, 0.50, 0.20))  # Bronze
		_:
			label.add_theme_font_size_override("font_size", 20)
			label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	return label

func _on_back_pressed():
	# Return to title screen
	get_tree().change_scene_to_file("res://scenes/title_screen/title_screen.tscn")
