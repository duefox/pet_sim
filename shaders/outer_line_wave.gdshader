shader_type canvas_item;

/* ───── 可在 Inspector 调的参数 ───── */
uniform vec4 outline_color : source_color = vec4(0.16, 0.85, 1.00, 1.0); // 描边颜色
uniform float outline_size: hint_range(0.0, 3.0) = 1.0;   // 基础粗细（像素）
uniform float wave_amplitude: hint_range(0.0, 1.0) = 1.2;   // 额外粗细摆动幅度（像素）
uniform float wave_frequency: hint_range(0.0, 1.0) = 9.0;   // 波纹“条数” ≈ 越大越密
uniform float wave_speed: hint_range(0.0, 1.0) = 1.8;   // 波动速度（>0 正向，<0 反向）

/* ───── 用 8 个方向做邻域取样 ───── */
const int   DIR_COUNT = 8;
const float PI_4      = 3.14159265 / 4.0;

void fragment()
{
    vec4 tex      = texture(TEXTURE,  UV);
    float alpha   = tex.a;

    float outline_mask = 0.0;

    for (int i = 0; i < DIR_COUNT; i++)
    {
        float angle = PI_4 * float(i);
        vec2 dir    = vec2(cos(angle), sin(angle));

        /* 计算动态偏移 = （基础粗细 + 正弦形波动）/ 像素尺寸 */
        float wave  = sin(TIME * wave_speed + dot(UV, dir) * wave_frequency) * wave_amplitude;
        vec2 offset = dir * (outline_size + wave) * TEXTURE_PIXEL_SIZE;

        float sample_alpha = texture(TEXTURE, UV + offset).a;
        outline_mask       = max(outline_mask, sample_alpha);
    }

    /* 条件：邻居有内容且自身 alpha≈0 => 描边像素 */
    float is_outline = step(0.5, outline_mask) * (1.0 - step(0.5, alpha));

    /* 输出，它比多分支 if 更易编译器优化 */
    vec4 out_color =
        mix(                                                                        // 先放描边
            vec4(outline_color.rgb, outline_color.a * is_outline),
            tex,                                                                    // 再把原贴图覆盖回内部
            alpha
        );

    COLOR = out_color;
}