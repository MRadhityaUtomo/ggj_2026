extends Node2D
class_name Cartridge

## Lightweight node attached to instantiated cartridge scenes.
## All configuration (type, abilities) is handled by CartridgeConfig resource
## and the GameManager. This script just provides collision toggling.

## Enable/disable collision on all TileMapLayer children (recursively)
func set_collision_enabled(enabled: bool) -> void:
	_set_collision_recursive(self, enabled)

func _set_collision_recursive(node: Node, enabled: bool) -> void:
	if node is TileMapLayer:
		node.collision_enabled = enabled
	
	for child in node.get_children():
		_set_collision_recursive(child, enabled)
