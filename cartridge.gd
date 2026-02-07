extends Node2D
class_name Cartridge

## Lightweight node attached to instantiated cartridge scenes.
## All configuration (type, abilities) is handled by CartridgeConfig resource
## and the GameManager. This script just provides collision toggling.

## Enable/disable collision on all TileMapLayer children
func set_collision_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is TileMapLayer:
			child.collision_enabled = enabled
