extends TextureRect

## Attach this to TextureRect children inside DecorContainer
## for per-sprite slide configuration.

## Which edge to slide in from: "left", "right", "top", "bottom", or "" for auto
@export_enum("auto", "left", "right", "top", "bottom") var slide_from: String = "auto"

## Custom duration override (-1 uses parent's default)
@export var custom_duration: float = -1.0

## Custom rotation to apply during slide (degrees, lerps to 0 on arrival)
@export var slide_rotation_degrees: float = 0.0

func _ready():
    if slide_from != "auto":
        set_meta("slide_from", slide_from)
    mouse_filter = Control.MOUSE_FILTER_IGNORE