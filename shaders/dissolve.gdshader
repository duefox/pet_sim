shader_type canvas_item;
//消融噪声
uniform sampler2D dissolveNoise;
//消融速度
uniform float speed:hint_range(0.0, 10.0, 0.1) = 5.0;

void fragment() {
	float sinValue = (sin(TIME*speed)+ 1.0)*0.5;
	vec4 dissolveColor = texture(dissolveNoise,UV);
	float alphaValue = step(sinValue,dissolveColor.x);
	vec4 originColor = texture(TEXTURE,UV);
	COLOR.a = alphaValue * originColor.a;
}
