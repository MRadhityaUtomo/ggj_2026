shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = no border, 1 = fully closed
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float border_width = 0.15; // How thick the border can get

void fragment() {
	// Distance from edges (0 at edges, 0.5 at center)
	float dist_x = abs(UV.x - 0.5);
	float dist_y = abs(UV.y - 0.5);
	
	// Maximum distance to determine if we're in the border zone
	float max_dist = max(dist_x * 2.0, dist_y * 2.0); // 0 at center, 1 at edges
	
	// Invert so that 1 is at center, 0 at edges
	float inverted_dist = 1.0 - max_dist;
	
	// Border starts from outside (1.0) and closes in to center (0.0)
	float border_threshold = 1.0 - (progress * (1.0 + border_width));
	
	// Show white where we're past the threshold
	float alpha = step(border_threshold, max_dist);
	
	COLOR = vec4(outline_color.rgb, alpha * outline_color.a);
}
