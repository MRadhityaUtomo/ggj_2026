extends Resource
class_name LevelCartridgeConfig

## Visual representation (cartridge scene with level preview/thumbnail)
@export var scene: PackedScene

## Path to the actual level scene to load
@export_file("*.tscn") var level_scene_path: String

## Level number for progression tracking (1-based)
@export var level_index: int = 1

## Display name
@export var level_name: String = "Level 1"