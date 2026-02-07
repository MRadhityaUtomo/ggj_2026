extends Node2D

@onready var voice_manager: Node = $VoiceManager
@onready var alphabets_tile: TileMapLayer = $Alphabets

var text_from: Vector2
var text_to: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var cells = alphabets_tile.get_used_cells()
	
	#for cell in cells:
		#print("Tile at:", cell)
	
	_generate_text("test")
	voice_manager.connect("command_detected", _generate_text)

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
