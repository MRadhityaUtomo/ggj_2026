shader_type canvas_item;

uniform vec2 target_size = vec2(384.0,256.0);
uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform float thickness = 2.0;
uniform vec4 color : source_color = vec4(1.0,1.0,1.0,1.0);

void fragment() {
    vec2 screen = vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
    vec2 center = screen * 0.5;

    vec2 max_size = screen;
    vec2 size = mix(max_size, target_size, progress);

    vec2 half = size * 0.5;
    vec2 pos = SCREEN_UV * screen - center;

    float border =
        step(half.x - thickness, abs(pos.x)) *
        step(abs(pos.y), half.y)
      +
        step(half.y - thickness, abs(pos.y)) *
        step(abs(pos.x), half.x);

    COLOR = color * border;
}
