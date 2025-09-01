shader_type canvas_item;
uniform float size_x:hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float size_y:hint_range(0.0, 1.0, 0.01) = 0.05;
void fragment() {
    vec2 uv = SCREEN_UV;
    uv -= mod(uv, vec2(size_x, size_y));
    COLOR.rgb = textureLod(TEXTURE, uv, 0.0).rgb;
}