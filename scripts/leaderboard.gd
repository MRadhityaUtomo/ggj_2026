extends Node

## Global Leaderboard Manager
## Stores and retrieves local challenge mode scores (username + time)

const SAVE_PATH = "user://leaderboard.json"

# Each entry: { "username": String, "time": float }
var entries: Array[Dictionary] = []

func _ready() -> void:
	load_entries()

# ─── DATA MANAGEMENT ──────────────────────────────────────────────────────────

## Add a new score entry and save
func add_entry(username: String, time_seconds: float) -> void:
	entries.append({ "username": username, "time": time_seconds })
	entries.sort_custom(_sort_by_time)
	save_entries()

## Get all entries sorted by time (fastest first)
func get_entries() -> Array[Dictionary]:
	return entries

## Get top N entries
func get_top_entries(count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(min(count, entries.size())):
		result.append(entries[i])
	return result

## Format time as MM:SS.mm
static func format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

# ─── PERSISTENCE ──────────────────────────────────────────────────────────────

func save_entries() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data: Array = []
		for entry in entries:
			data.append({ "username": entry["username"], "time": entry["time"] })
		file.store_string(JSON.stringify(data))
		file.close()

func load_entries() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		file.close()
		if err == OK and json.data is Array:
			entries.clear()
			for item in json.data:
				if item is Dictionary and item.has("username") and item.has("time"):
					entries.append({ "username": str(item["username"]), "time": float(item["time"]) })
			entries.sort_custom(_sort_by_time)

func _sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a["time"] < b["time"]
