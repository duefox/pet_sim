shader_type canvas_item;

// 通用设置
uniform vec3 wave_color: source_color = vec3(0.0, 0.5, 1.0);
uniform vec3 edge_color: source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D wave_texture : hint_default_black;
uniform float wave_opacity: hint_range(0.0, 1.0) = 0.5;
uniform float water_alpha: hint_range(0.0, 1.0) = 0.6;
uniform float texture_blend: hint_range(0.0, 1.0) = 0.2;

// 波浪形态控制
uniform float speed: hint_range(0.1, 10.0) = 1.0;
uniform float wave_frequency: hint_range(1.0, 100.0) = 1.0;
uniform float wave_offset:hint_range(0.0, 1.0, 0.01)=0.06;
uniform float peak_amplitude: hint_range(0.01, 0.2) = 0.01;
uniform float trough_amplitude: hint_range(0.01, 0.2) = 0.01;
uniform float secondary_ripple_blend: hint_range(0.0, 1.0) = 0.1;
uniform float tertiary_ripple_blend: hint_range(0.0, 1.0) = 0.1;

// 边缘效果控制
uniform float edge_width: hint_range(0.0, 0.1) = 0.02;
uniform float edge_pixel_size: hint_range(0.001, 0.05) = 0.004;

// 气泡控制
uniform vec3 bubble_color: source_color = vec3(1.0, 1.0, 1.0);
uniform int bubble_count: hint_range(0, 50) = 10;
uniform float bubble_opacity: hint_range(0.0, 1.0) = 0.5;
uniform float bubble_speed_min: hint_range(0.0, 20.0) = 1.0;
uniform float bubble_speed_max: hint_range(0.0, 20.0) = 4.0;
uniform float bubble_radius_min: hint_range(0.001, 0.05, 0.001) = 0.004;
uniform float bubble_radius_max: hint_range(0.001, 0.05, 0.001) = 0.01;
uniform float bubble_spawn_x_min: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float bubble_spawn_x_max: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float bubble_spawn_y_min: hint_range(0.0, 1.5, 0.01) = 0.0;
uniform float bubble_spawn_y_max: hint_range(0.0, 1.5, 0.01) = 1.0;
uniform float bubble_pixel_size: hint_range(0.001, 0.05) = 0.002;

// 生成一个基于整数输入的伪随机数 (0.0 to 1.0)
float get_random_value(int i) {
    return fract(sin(float(i) * 12.9898) * 43758.5453);
}

void fragment() {
    // 透明背景
    vec4 col = vec4(0.0, 0.0, 0.0, 0.0);
    // 平滑的波浪动画
    float sine_raw = sin(UV.x * wave_frequency + (TIME * 0.3 * speed));
    float scaled_peaks = max(0.0, sine_raw) * peak_amplitude;
    float scaled_troughs = min(0.0, sine_raw) * trough_amplitude;
    float sine = scaled_peaks + scaled_troughs + wave_offset;

    // 次级和三级波纹
    float sine_2 = sin(UV.x * 1.0 + (TIME * 0.6 * speed)) * 0.05 * secondary_ripple_blend;
    float sine_3 = sin(UV.x * 12.0 + (TIME * 0.9 * speed)) * 0.02 * tertiary_ripple_blend;
    float wave_height = sine + sine_2 + sine_3;

    // 像素化边缘
    vec2 snapped_uv = floor(UV / edge_pixel_size) * edge_pixel_size;
    float edge_mask = smoothstep(wave_height - edge_width * 0.2, wave_height, snapped_uv.y);
    float wave_mask = smoothstep(wave_height, wave_height + edge_width * 0.9, snapped_uv.y);
    // 应用颜色和 Alpha
    vec4 edge_color_with_alpha = vec4(edge_color, wave_opacity);
    vec4 wave_color_with_alpha = vec4(wave_color, wave_opacity * water_alpha);
    col = mix(col, edge_color_with_alpha, edge_mask);
    col = mix(col, wave_color_with_alpha, wave_mask);

    // 混合纹理
    vec4 texture_color = texture(wave_texture, UV);
    col.rgb = mix(col.rgb, texture_color.rgb, texture_blend * wave_mask);

    // 气泡
    for (int i = 1; i <= bubble_count; i++) {
        float random_x = get_random_value(i);
        float particle_x = mix(bubble_spawn_x_min, bubble_spawn_x_max, random_x);

        float random_size = get_random_value(i + 5);
        float bubble_radius = mix(bubble_radius_min, bubble_radius_max, random_size);

        float time_offset = get_random_value(i + 2) * 40.0;
        float random_speed_mix = get_random_value(i + 3);
        float bubble_current_speed = mix(bubble_speed_min, bubble_speed_max, random_speed_mix);

        float y_progress = fract((TIME + time_offset) * (-0.06 * bubble_current_speed));
        float particle_y = mix(bubble_spawn_y_min, bubble_spawn_y_max, y_progress);
        vec2 particle = vec2(particle_x, particle_y);

        // --- 修改部分开始 ---
        // 校正UV坐标，使其不受长宽比影响
        vec2 corrected_uv = UV;
        vec2 corrected_particle = particle;
        float aspect_ratio = (1.0 / TEXTURE_PIXEL_SIZE.x) / (1.0 / TEXTURE_PIXEL_SIZE.y);
        
        // 修正x或y轴，以确保在任何长宽比下都为正圆
        if (aspect_ratio > 1.0) {
            corrected_uv.x *= aspect_ratio;
            corrected_particle.x *= aspect_ratio;
        } else {
            corrected_uv.y /= aspect_ratio;
            corrected_particle.y /= aspect_ratio;
        }

        // 像素化气泡位置和半径
        vec2 snapped_uv_bubble = floor(corrected_uv / bubble_pixel_size) * bubble_pixel_size;
        vec2 snapped_particle = floor(corrected_particle / bubble_pixel_size) * bubble_pixel_size;
        float snapped_bubble_radius = floor(bubble_radius / bubble_pixel_size) * bubble_pixel_size;

        // 使用像素化的值生成像素化的圆形
        float circle = step(length(snapped_uv_bubble - snapped_particle), snapped_bubble_radius);
        float inner_circle = step(length(snapped_uv_bubble - snapped_particle), snapped_bubble_radius * 0.7);
        // --- 修改部分结束 ---

        float bubble_wave_dist = abs(UV.y - wave_height);
        float pop_threshold = 0.0005;
        float pop_factor = smoothstep(pop_threshold, 0.0, bubble_wave_dist);
        vec4 bubble_col = vec4(bubble_color, bubble_opacity * pop_factor);

        float bubble_mask = circle - inner_circle * 0.7;
        col.rgb = mix(col.rgb, bubble_col.rgb, bubble_mask);
        col.a = max(col.a, bubble_mask * bubble_col.a);
    }
    COLOR = col;
}