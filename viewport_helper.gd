class_name ViewportHelper

## Call this from any game manager's _ready() to set up the SubViewport.
## Returns a dictionary with references to the created nodes.
##
## Usage:
##   var vp = ViewportHelper.setup(self)
##   # Now add gameplay nodes to vp.sub_viewport instead of self
##   vp.sub_viewport.add_child(my_node)
##   # Add UI nodes to vp.ui_layer
##   vp.ui_layer.add_child(my_label)

static func setup(parent: Node) -> Dictionary:
	# ─── SubViewportContainer (fills the screen, nearest filter) ──────────
	var container = SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Force the container to fill the full project resolution
	container.offset_left = 0
	container.offset_top = 0
	container.offset_right = 0
	container.offset_bottom = 0
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(container)

	# ─── SubViewport (pixel-art sandbox at original resolution) ───────────
	var sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2i(192, 128)
	sub_viewport.canvas_item_default_texture_filter = SubViewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sub_viewport.snap_2d_transforms_to_pixel = true
	sub_viewport.snap_2d_vertices_to_pixel = true
	sub_viewport.handle_input_locally = true
	sub_viewport.physics_object_picking = true
	container.add_child(sub_viewport)

	# ─── CanvasLayer for crisp UI at native resolution ────────────────────
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	parent.add_child(ui_layer)

	return {
		"container": container,
		"sub_viewport": sub_viewport,
		"ui_layer": ui_layer,
	}
