shader_type canvas_item;

//描边的宽度
uniform float outlineWidth:hint_range(0.0, 5.0, 0.01) = 2.0;
//描边的颜色
uniform vec4 outlineColor:source_color = vec4(1.0,1.0,1.0,1.0);

void fragment() {
	vec2 uv = UV;
	vec2 uvUp = uv + vec2(0.0,TEXTURE_PIXEL_SIZE.y)*outlineWidth;
	vec2 uvDwon = uv + vec2(0.0,-TEXTURE_PIXEL_SIZE.y)*outlineWidth;
	vec2 uvLeft = uv + vec2(TEXTURE_PIXEL_SIZE.x,0.0)*outlineWidth;
	vec2 uvRight = uv + vec2(-TEXTURE_PIXEL_SIZE.x,0.0)*outlineWidth;
	vec4 colorUp = texture(TEXTURE,uvUp);
	vec4 colorDwon = texture(TEXTURE,uvDwon);
	vec4 colorLeft = texture(TEXTURE,uvLeft);
	vec4 colorRight = texture(TEXTURE,uvRight);
	vec4 borderColor = colorUp + colorDwon + colorLeft + colorRight;
	borderColor.rgb = outlineColor.rgb;
	borderColor.a = min(borderColor.a,1);
	vec4 originColor = texture(TEXTURE,UV);
	vec4 displayColor = mix(borderColor,originColor,originColor.a);

	COLOR = displayColor;

}
