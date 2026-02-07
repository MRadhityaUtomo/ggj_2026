extends Resource
class_name CartridgeConfig

## The type of this cartridge — determines player abilities
## RED = basic, BLUE = dash, GREEN = double jump
enum CartridgeType { RED, BLUE, GREEN }

@export var scene: PackedScene
@export var type: CartridgeType = CartridgeType.RED

## Returns ability flags based on type
func get_abilities() -> Dictionary:
	match type:
		CartridgeType.RED:
			return { "can_dash": false, "can_double_jump": false }
		CartridgeType.BLUE:
			return { "can_dash": true, "can_double_jump": false }
		CartridgeType.GREEN:
			return { "can_dash": false, "can_double_jump": true }
	return { "can_dash": false, "can_double_jump": false }
