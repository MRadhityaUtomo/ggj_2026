shader_type canvas_item;

uniform float enabled = 0.0;
uniform float progress : hint_range(0.0,1.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float thickness = 10000.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float left  = texture(TEXTURE, UV + vec2(-thickness,0.0)/TEXTURE_PIXEL_SIZE).a;
	float right = texture(TEXTURE, UV + vec2(thickness,0.0)/TEXTURE_PIXEL_SIZE).a;
	float up    = texture(TEXTURE, UV + vec2(0.0,-thickness)/TEXTURE_PIXEL_SIZE).a;
	float down  = texture(TEXTURE, UV + vec2(0.0,thickness)/TEXTURE_PIXEL_SIZE).a;

	float outline = step(0.1, left+right+up+down) * (1.0 - tex.a);

	// closing-in effect mask
	float mask = step(progress, abs(UV.x-0.5)*2.0);

	float final_outline = outline * mask * enabled;

	COLOR = tex + outline_color * final_outline;
}
