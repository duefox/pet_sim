shader_type canvas_item;

// 统一的圆角半径
uniform float corner_radius : hint_range(0.0, 100.0, 1.0) = 10.0;
// 矩形的尺寸 (必须与 Control 节点的 size 相同)
uniform vec2 rect_size = vec2(100.0, 100.0);

// 新增的四个边缘距离参数（内边距/裁剪距离）
uniform float margin_top : hint_range(0.0, 50.0, 1.0) = 0.0;
uniform float margin_bottom : hint_range(0.0, 50.0, 1.0) = 0.0;
uniform float margin_left : hint_range(0.0, 50.0, 1.0) = 0.0;
uniform float margin_right : hint_range(0.0, 50.0, 1.0) = 0.0;

void fragment() {
    // 1. 获取片段在矩形中的像素坐标 (UV * 尺寸)
    vec2 pos = UV * rect_size;

    // 2. 定义有效绘制区域的边界
    // 有效区域的左上角 (min_pos) 和右下角 (max_pos)
    vec2 min_pos = vec2(margin_left, margin_top);
    vec2 max_pos = rect_size - vec2(margin_right, margin_bottom);

    // 3. 将坐标映射到有效绘制区域的中心和尺寸
    vec2 inner_rect_size = max_pos - min_pos;
    vec2 inner_half_size = inner_rect_size * 0.5;
    vec2 inner_center = min_pos + inner_half_size;

    // 4. 计算片段相对于有效区域中心的绝对坐标
    // p_abs: 片段坐标相对于有效区域中心的绝对偏差
    vec2 p_abs = abs(pos - inner_center);

    // 5. 使用 SDF 技术计算到圆角边界的距离
    // half_size_minus_radius: 圆角中心的偏移量
    vec2 half_size_minus_radius = inner_half_size - vec2(corner_radius);

    // q: 转换后的坐标，用于距离计算
    vec2 q = p_abs - half_size_minus_radius;

    // dist: 计算到圆角的距离
    float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);

    // 6. 额外检查：如果片段在 Margin 区域之外，则直接裁剪 (alpha = 0)
    if (pos.x < min_pos.x || pos.x > max_pos.x || pos.y < min_pos.y || pos.y > max_pos.y) {
        COLOR.a *= 0.0;
    } else {
        // 7. 使用 smoothstep 创建平滑过渡，实现圆角遮罩
        // alpha: 圆角部分的透明度
        float alpha = 1.0 - smoothstep(0.0, 1.0, dist / corner_radius);

        // 8. 最终透明度：将计算出的圆角透明度与节点原有的透明度相乘
        COLOR.a *= alpha;
    }
}